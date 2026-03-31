import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/training.dart';
import '../models/training_cycle.dart';
import '../models/training_template.dart';
import '../services/template_service.dart';
import '../services/training_storage_service.dart';

class CreateEditTrainingPage extends StatefulWidget {
  final Training? existingTraining;

  const CreateEditTrainingPage({super.key, this.existingTraining});

  @override
  State<CreateEditTrainingPage> createState() => _CreateEditTrainingPageState();
}

class _CreateEditTrainingPageState extends State<CreateEditTrainingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final TrainingStorageService _storageService = TrainingStorageService();
  final TemplateService _templateService = TemplateService();

  final List<TextEditingController> _cycleNameControllers = [];
  final List<TextEditingController> _cycleDescriptionControllers = [];
  final List<int> _cycleRepeats = [];

  bool _isSaving = false;

  // Template picker state (create mode only)
  List<TrainingTemplate> _templates = [];
  bool _templatesLoading = false;
  bool _templatesFailed = false;

  bool get _isEditing => widget.existingTraining != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTraining!;
      _nameController.text = t.name;
      for (final cycle in t.cycles) {
        _cycleNameControllers.add(TextEditingController(text: cycle.name));
        _cycleDescriptionControllers.add(
          TextEditingController(text: cycle.description ?? ''),
        );
        _cycleRepeats.add(cycle.repeats);
      }
    } else {
      _addCycle();
      _loadTemplates();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _cycleNameControllers) {
      c.dispose();
    }
    for (final c in _cycleDescriptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _templatesLoading = true;
      _templatesFailed = false;
    });
    try {
      final templates = await _templateService.fetchTemplates();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _templatesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _templatesLoading = false;
        _templatesFailed = true;
      });
    }
  }

  void _applyTemplate(TrainingTemplate template) {
    // Dispose existing controllers
    for (final c in _cycleNameControllers) {
      c.dispose();
    }
    for (final c in _cycleDescriptionControllers) {
      c.dispose();
    }

    setState(() {
      _nameController.text = template.name;
      _cycleNameControllers.clear();
      _cycleDescriptionControllers.clear();
      _cycleRepeats.clear();

      for (final cycle in template.cycles) {
        _cycleNameControllers.add(TextEditingController(text: cycle.name));
        _cycleDescriptionControllers.add(
          TextEditingController(text: cycle.description ?? ''),
        );
        _cycleRepeats.add(cycle.repeats);
      }
    });
  }

  void _showTemplatePicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _TemplatePickerSheet(
        templates: _templates,
        onSelected: (template) {
          Navigator.of(ctx).pop();
          _applyTemplate(template);
        },
      ),
    );
  }

  void _addCycle() {
    setState(() {
      _cycleNameControllers.add(TextEditingController());
      _cycleDescriptionControllers.add(TextEditingController());
      _cycleRepeats.add(5);
    });
  }

  void _removeCycle(int index) {
    setState(() {
      _cycleNameControllers[index].dispose();
      _cycleNameControllers.removeAt(index);
      _cycleDescriptionControllers[index].dispose();
      _cycleDescriptionControllers.removeAt(index);
      _cycleRepeats.removeAt(index);
    });
  }

  void _incrementRepeats(int index) {
    setState(() {
      _cycleRepeats[index] = (_cycleRepeats[index] + 1).clamp(1, 99);
    });
  }

  void _decrementRepeats(int index) {
    setState(() {
      _cycleRepeats[index] = (_cycleRepeats[index] - 1).clamp(1, 99);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cycleNameControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one cycle')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final nameTaken = await _storageService.isNameTaken(
      name,
      excludeId: widget.existingTraining?.id,
    );

    if (!mounted) return;

    if (nameTaken) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A training with this name already exists')),
      );
      return;
    }

    final cycles = List.generate(
      _cycleNameControllers.length,
      (i) {
        final desc = _cycleDescriptionControllers[i].text.trim();
        return TrainingCycle(
          name: _cycleNameControllers[i].text.trim(),
          repeats: _cycleRepeats[i],
          description: desc.isEmpty ? null : desc,
        );
      },
    );

    final now = DateTime.now();

    if (_isEditing) {
      final updated = widget.existingTraining!.copyWith(
        name: name,
        cycles: cycles,
        updatedAt: now,
      );
      await _storageService.updateTraining(updated);
    } else {
      final training = Training(
        id: now.millisecondsSinceEpoch.toString(),
        name: name,
        cycles: cycles,
        createdAt: now,
        updatedAt: now,
      );
      await _storageService.addTraining(training);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Training' : 'New Training'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Template picker (create mode only)
              if (!_isEditing) _buildTemplatePicker(),
              if (!_isEditing) const SizedBox(height: 20),

              // Training name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Training name',
                  hintText: 'e.g. Legs training 1',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Cycles header
              Text(
                'Cycles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (_cycleNameControllers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No cycles yet. Tap "Add Cycle" to begin.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),

              // Cycle rows
              ...List.generate(_cycleNameControllers.length, (index) {
                return _buildCycleRow(index);
              }),

              const SizedBox(height: 8),

              // Add Cycle button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addCycle,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Cycle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            _isEditing ? 'Save Changes' : 'Save Training',
                            style: const TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 22,
            color: _templatesLoading || _templatesFailed
                ? colorScheme.onSurface.withValues(alpha: 0.4)
                : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start from a template',
                  style: textTheme.labelLarge?.copyWith(
                    color: _templatesLoading || _templatesFailed
                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _templatesLoading
                      ? 'Loading templates…'
                      : _templatesFailed
                          ? 'Could not load templates'
                          : '${_templates.length} templates available',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_templatesLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            )
          else if (_templatesFailed)
            IconButton(
              tooltip: 'Retry',
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              visualDensity: VisualDensity.compact,
              onPressed: _loadTemplates,
            )
          else
            FilledButton.tonal(
              onPressed: _templates.isEmpty ? null : _showTemplatePicker,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Browse'),
            ),
        ],
      ),
    );
  }

  Widget _buildCycleRow(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Cycle ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_cycleNameControllers.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: 'Remove cycle',
                    onPressed: () => _removeCycle(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cycleNameControllers[index],
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cycle name',
                hintText: 'e.g. Legs 1',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cycleDescriptionControllers[index],
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Keep your back straight',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Repeats',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _decrementRepeats(index),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${_cycleRepeats[index]}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _incrementRepeats(index),
                  icon: const Icon(Icons.add_circle_outline),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePickerSheet extends StatefulWidget {
  final List<TrainingTemplate> templates;
  final void Function(TrainingTemplate) onSelected;

  const _TemplatePickerSheet({
    required this.templates,
    required this.onSelected,
  });

  @override
  State<_TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends State<_TemplatePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TrainingTemplate> get _filtered {
    if (_query.isEmpty) return widget.templates;
    final q = _query.toLowerCase();
    return widget.templates
        .where((t) => t.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return SafeArea(
          top: false,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose a template',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search templates…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  isDense: true,
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),

            const Divider(height: 1),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No templates match "$_query"',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context2, i2) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        final cycleCount = t.cycles.length;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          title: Text(
                            t.name,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '$cycleCount ${cycleCount == 1 ? 'exercise' : 'exercises'}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          onTap: () => widget.onSelected(t),
                        );
                      },
                    ),
            ),
          ],
        ),
        );
      },
    );
  }
}

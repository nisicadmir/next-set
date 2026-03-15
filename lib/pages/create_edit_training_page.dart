import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/training.dart';
import '../models/training_cycle.dart';
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

  // Each cycle has a name controller and a repeats value
  final List<TextEditingController> _cycleNameControllers = [];
  final List<int> _cycleRepeats = [];

  bool _isSaving = false;

  bool get _isEditing => widget.existingTraining != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.existingTraining!;
      _nameController.text = t.name;
      for (final cycle in t.cycles) {
        _cycleNameControllers.add(TextEditingController(text: cycle.name));
        _cycleRepeats.add(cycle.repeats);
      }
    } else {
      // Start with one empty cycle
      _addCycle();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _cycleNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCycle() {
    setState(() {
      _cycleNameControllers.add(TextEditingController());
      _cycleRepeats.add(5);
    });
  }

  void _removeCycle(int index) {
    setState(() {
      _cycleNameControllers[index].dispose();
      _cycleNameControllers.removeAt(index);
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
      (i) => TrainingCycle(
        name: _cycleNameControllers[i].text.trim(),
        repeats: _cycleRepeats[i],
      ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cycles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addCycle,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Cycle'),
                  ),
                ],
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

              const SizedBox(height: 32),

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

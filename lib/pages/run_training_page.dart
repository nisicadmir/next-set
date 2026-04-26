import 'package:flutter/material.dart';
import '../models/training.dart';
import '../services/training_storage_service.dart';

class RunTrainingPage extends StatefulWidget {
  final Training training;

  const RunTrainingPage({super.key, required this.training});

  @override
  State<RunTrainingPage> createState() => _RunTrainingPageState();
}

class _RunTrainingPageState extends State<RunTrainingPage> {
  late List<int> _completedSets;
  final TrainingStorageService _storageService = TrainingStorageService();
  bool _markedAsUsed = false;

  @override
  void initState() {
    super.initState();
    _completedSets = List.filled(widget.training.cycles.length, 0);
  }

  bool get _allDone {
    for (int i = 0; i < widget.training.cycles.length; i++) {
      if (_completedSets[i] < widget.training.cycles[i].sets) return false;
    }
    return true;
  }

  void _incrementSet(int cycleIndex) {
    final cycle = widget.training.cycles[cycleIndex];
    if (_completedSets[cycleIndex] >= cycle.sets) return;

    setState(() {
      _completedSets[cycleIndex]++;
    });

    if (!_markedAsUsed) {
      _markedAsUsed = true;
      _storageService.markTrainingAsUsed(widget.training.id);
    }

    if (_allDone) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showCompletionDialog(),
      );
    }
  }

  void _decrementSet(int cycleIndex) {
    if (_completedSets[cycleIndex] <= 0) return;
    setState(() {
      _completedSets[cycleIndex]--;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Training Complete!'),
        content: Text('You finished "${widget.training.name}".\nGreat work!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _completedSets = List.filled(widget.training.cycles.length, 0);
              });
            },
            child: const Text('Repeat'),
          ),
        ],
      ),
    );
  }

  void _resetProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text('Are you sure you want to reset all set counts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _completedSets = List.filled(widget.training.cycles.length, 0);
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.training.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset progress',
            onPressed: _resetProgress,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.training.cycles.length,
          itemBuilder: (context, index) {
            return _buildCycleCard(index);
          },
        ),
      ),
    );
  }

  Widget _buildCycleCard(int index) {
    final cycle = widget.training.cycles[index];
    final completed = _completedSets[index];
    final total = cycle.sets;
    final isDone = completed >= total;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDone ? 0 : 2,
      color: isDone
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle name + done badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    cycle.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.45)
                          : null,
                    ),
                  ),
                ),
                if (isDone)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
              ],
            ),

            // Description (how to run this cycle)
            if (cycle.description != null && cycle.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                cycle.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDone
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.35)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _CycleMetric(
                  icon: Icons.fitness_center,
                  label: '${cycle.sets} ${cycle.sets == 1 ? 'set' : 'sets'}',
                  isDone: isDone,
                ),
                _CycleMetric(
                  icon: Icons.repeat,
                  label:
                      '${cycle.repeats} ${cycle.repeats == 1 ? 'rep' : 'reps'} / set',
                  isDone: isDone,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Rep counter + inc/dec buttons
            Row(
              children: [
                Text(
                  '$completed / $total sets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDone
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.45)
                        : null,
                  ),
                ),
                const Spacer(),
                // Decrement button
                IconButton.filled(
                  onPressed: completed > 0 ? () => _decrementSet(index) : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    disabledBackgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 8),
                // Increment button
                IconButton.filled(
                  onPressed: isDone ? null : () => _incrementSet(index),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;

  const _CycleMetric({
    required this.icon,
    required this.label,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
        : Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDone
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.45)
                : null,
          ),
        ),
      ],
    );
  }
}

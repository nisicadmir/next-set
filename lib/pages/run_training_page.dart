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
  late List<int> _completedReps;
  final TrainingStorageService _storageService = TrainingStorageService();
  bool _markedAsUsed = false;

  @override
  void initState() {
    super.initState();
    _completedReps = List.filled(widget.training.cycles.length, 0);
  }

  bool get _allDone {
    for (int i = 0; i < widget.training.cycles.length; i++) {
      if (_completedReps[i] < widget.training.cycles[i].repeats) return false;
    }
    return true;
  }

  void _incrementRep(int cycleIndex) {
    final cycle = widget.training.cycles[cycleIndex];
    if (_completedReps[cycleIndex] >= cycle.repeats) return;

    setState(() {
      _completedReps[cycleIndex]++;
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

  void _decrementRep(int cycleIndex) {
    if (_completedReps[cycleIndex] <= 0) return;
    setState(() {
      _completedReps[cycleIndex]--;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Training Complete!'),
            content: Text(
              'You finished "${widget.training.name}".\nGreat work!',
            ),
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
                    _completedReps =
                        List.filled(widget.training.cycles.length, 0);
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
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Progress'),
            content: const Text(
              'Are you sure you want to reset all rep counts?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _completedReps =
                        List.filled(widget.training.cycles.length, 0);
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
    final completed = _completedReps[index];
    final total = cycle.repeats;
    final isDone = completed >= total;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDone ? 0 : 2,
      color:
          isDone
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
                      color:
                          isDone
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
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Rep counter + inc/dec buttons
            Row(
              children: [
                Text(
                  '$completed / $total reps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isDone
                            ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.45)
                            : null,
                  ),
                ),
                const Spacer(),
                // Decrement button
                IconButton.filled(
                  onPressed:
                      completed > 0 ? () => _decrementRep(index) : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurface,
                    disabledBackgroundColor:
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                // Increment button
                IconButton.filled(
                  onPressed: isDone ? null : () => _incrementRep(index),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor:
                        Theme.of(
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

import 'package:flutter/material.dart';
import 'create_edit_set_page.dart';
import 'run_set_page.dart';
import '../models/workout_set.dart';
import '../services/set_storage_service.dart';

class SetsListPage extends StatefulWidget {
  const SetsListPage({super.key});

  @override
  State<SetsListPage> createState() => _SetsListPageState();
}

class _SetsListPageState extends State<SetsListPage> {
  final SetStorageService _storageService = SetStorageService();
  List<WorkoutSet> _sets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sets = await _storageService.getAllSets();

      if (mounted) {
        setState(() {
          _sets = sets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sets = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sets: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('All Sets'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: _sets.isEmpty ? _buildEmptyState() : _buildSetsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateEditSetPage()),
          );

          if (result != null && mounted) {
            await _loadSets();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Set'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No sets created yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first set',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sets.length,
      itemBuilder: (context, index) {
        final set = _sets[index];
        return _buildSetCard(set);
      },
    );
  }

  Widget _buildSetCard(WorkoutSet set) {
    // Convert seconds to minutes and seconds for display
    final int minutes = set.secondsPerSet ~/ 60;
    final int seconds = set.secondsPerSet % 60;
    final String timeDisplay = minutes > 0
        ? '${minutes}m ${seconds}s'
        : '${seconds}s';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _runSet(set);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Set name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      set.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editSet(set);
                        },
                        tooltip: 'Edit',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _confirmDelete(set);
                        },
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Set details
              Row(
                children: [
                  // Number of sets
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${set.numberOfSets} sets',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  // Time per set
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeDisplay,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runSet(WorkoutSet set) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => RunSetPage(workoutSet: set)),
    );
  }

  void _editSet(WorkoutSet set) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEditSetPage(existingSet: set),
      ),
    );

    if (result != null && mounted) {
      await _loadSets();
    }
  }

  void _confirmDelete(WorkoutSet set) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Are you sure you want to delete "${set.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteSet(set.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSet(String id) async {
    await _storageService.deleteSet(id);
    await _loadSets();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Set deleted')));
    }
  }
}

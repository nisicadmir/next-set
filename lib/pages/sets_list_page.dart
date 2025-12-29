import 'package:flutter/material.dart';
import 'create_edit_set_page.dart';

class SetsListPage extends StatefulWidget {
  const SetsListPage({super.key});

  @override
  State<SetsListPage> createState() => _SetsListPageState();
}

class _SetsListPageState extends State<SetsListPage> {
  // TODO: This will be replaced with actual data from local storage
  final List<Map<String, dynamic>> _sets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _sets.isEmpty ? _buildEmptyState() : _buildSetsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateEditSetPage()),
          );

          // TODO: Add the returned set data to the list and save to storage
          if (result != null && mounted) {
            setState(() {
              _sets.add(result);
            });
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No sets created yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first set',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
        return _buildSetCard(set, index);
      },
    );
  }

  Widget _buildSetCard(Map<String, dynamic> set, int index) {
    // Extract set data
    final String name = set['name'] ?? 'Unnamed Set';
    final int numberOfSets = set['numberOfSets'] ?? 0;
    final int secondsPerSet = set['secondsPerSet'] ?? 0;

    // Convert seconds to minutes and seconds for display
    final int minutes = secondsPerSet ~/ 60;
    final int seconds = secondsPerSet % 60;
    final String timeDisplay = minutes > 0
        ? '${minutes}m ${seconds}s'
        : '${seconds}s';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                    name,
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
                        _editSet(index);
                      },
                      tooltip: 'Edit',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _confirmDelete(index, name);
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
                        '$numberOfSets sets',
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
    );
  }

  void _editSet(int index) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEditSetPage(existingSet: _sets[index]),
      ),
    );

    // TODO: Update the set data in storage
    if (result != null && mounted) {
      setState(() {
        _sets[index] = result;
      });
    }
  }

  void _confirmDelete(int index, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteSet(index);
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

  void _deleteSet(int index) {
    setState(() {
      _sets.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Set deleted')));
  }
}

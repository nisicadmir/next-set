import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateEditSetPage extends StatefulWidget {
  final Map<String, dynamic>? existingSet;

  const CreateEditSetPage({super.key, this.existingSet});

  @override
  State<CreateEditSetPage> createState() => _CreateEditSetPageState();
}

class _CreateEditSetPageState extends State<CreateEditSetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roundsController = TextEditingController();
  final _roundMinutesController = TextEditingController();
  final _roundSecondsController = TextEditingController();
  final _breakMinutesController = TextEditingController();
  final _breakSecondsController = TextEditingController();

  bool _notifyEndOfRound = false;
  bool _notifyEndOfBreak = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.existingSet != null) {
      final set = widget.existingSet!;
      _nameController.text = set['name'] ?? '';
      _roundsController.text = (set['numberOfSets'] ?? '').toString();

      final secondsPerSet = set['secondsPerSet'] ?? 0;
      _roundMinutesController.text = (secondsPerSet ~/ 60).toString();
      _roundSecondsController.text = (secondsPerSet % 60).toString();

      final breakSeconds = set['breakSeconds'] ?? 0;
      _breakMinutesController.text = (breakSeconds ~/ 60).toString();
      _breakSecondsController.text = (breakSeconds % 60).toString();

      _notifyEndOfRound = set['shouldNotifyEndOfSet'] ?? false;
      _notifyEndOfBreak = set['shouldNotifyEndOfBreak'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roundsController.dispose();
    _roundMinutesController.dispose();
    _roundSecondsController.dispose();
    _breakMinutesController.dispose();
    _breakSecondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Set' : 'Create New Set'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Set Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Set Name',
                hintText: 'e.g., Upper Body Workout',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a set name';
                }
                if (value.length < 2) {
                  return 'Set name must be at least 2 characters';
                }
                // TODO: Check for duplicate names when connected to storage
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Number of Rounds
            TextFormField(
              controller: _roundsController,
              decoration: const InputDecoration(
                labelText: 'Number of Rounds',
                hintText: 'e.g., 5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter number of rounds';
                }
                final rounds = int.tryParse(value);
                if (rounds == null || rounds < 1) {
                  return 'Must be at least 1 round';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Round Duration
            Text(
              'Round Duration',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _roundMinutesController,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                      suffixText: 'min',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final minutes = int.tryParse(value);
                      if (minutes == null || minutes < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _roundSecondsController,
                    decoration: const InputDecoration(
                      labelText: 'Seconds',
                      border: OutlineInputBorder(),
                      suffixText: 'sec',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final seconds = int.tryParse(value);
                      if (seconds == null || seconds < 0 || seconds > 59) {
                        return 'Invalid';
                      }
                      // Check if total time is greater than 0
                      final minutes =
                          int.tryParse(_roundMinutesController.text) ?? 0;
                      if (minutes == 0 && seconds == 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Break Duration
            Text(
              'Break Between Rounds',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _breakMinutesController,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                      suffixText: 'min',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final minutes = int.tryParse(value);
                      if (minutes == null || minutes < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _breakSecondsController,
                    decoration: const InputDecoration(
                      labelText: 'Seconds',
                      border: OutlineInputBorder(),
                      suffixText: 'sec',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final seconds = int.tryParse(value);
                      if (seconds == null || seconds < 0 || seconds > 59) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notifications Section
            Text(
              'Notifications',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Notify End of Round
            Card(
              child: SwitchListTile(
                title: const Text('Notify Before Round Ends'),
                subtitle: const Text('10 seconds before the end of each round'),
                value: _notifyEndOfRound,
                onChanged: (value) {
                  setState(() {
                    _notifyEndOfRound = value;
                  });
                },
                secondary: const Icon(Icons.notifications_active),
              ),
            ),
            const SizedBox(height: 8),

            // Notify End of Break
            Card(
              child: SwitchListTile(
                title: const Text('Notify Before Break Ends'),
                subtitle: const Text('10 seconds before the end of each break'),
                value: _notifyEndOfBreak,
                onChanged: (value) {
                  setState(() {
                    _notifyEndOfBreak = value;
                  });
                },
                secondary: const Icon(Icons.notifications),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startWithoutSaving,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Without Saving'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveAndStart,
                    icon: const Icon(Icons.check),
                    label: const Text('Save & Start'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _startWithoutSaving() {
    // Validate basic fields but not the name
    if (!_validateBasicFields()) {
      return;
    }

    // TODO: Navigate to timer page with set configuration without saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting set without saving...')),
    );
  }

  void _saveAndStart() {
    // Validate full form including name
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Save to local storage and navigate to timer page
      final setData = _buildSetData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saving "${setData['name']}" and starting...')),
      );
      Navigator.of(context).pop(setData);
    }
  }

  bool _validateBasicFields() {
    // Manually validate required fields except name
    final rounds = int.tryParse(_roundsController.text);
    if (rounds == null || rounds < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid number of rounds')),
      );
      return false;
    }

    final roundMinutes = int.tryParse(_roundMinutesController.text) ?? 0;
    final roundSeconds = int.tryParse(_roundSecondsController.text) ?? 0;
    if (roundMinutes == 0 && roundSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Round duration must be greater than 0')),
      );
      return false;
    }

    return true;
  }

  Map<String, dynamic> _buildSetData() {
    final roundMinutes = int.tryParse(_roundMinutesController.text) ?? 0;
    final roundSeconds = int.tryParse(_roundSecondsController.text) ?? 0;
    final totalSeconds = (roundMinutes * 60) + roundSeconds;

    final breakMinutes = int.tryParse(_breakMinutesController.text) ?? 0;
    final breakSeconds = int.tryParse(_breakSecondsController.text) ?? 0;
    final totalBreakSeconds = (breakMinutes * 60) + breakSeconds;

    return {
      'name': _nameController.text.trim(),
      'numberOfSets': int.parse(_roundsController.text),
      'secondsPerSet': totalSeconds,
      'breakSeconds': totalBreakSeconds,
      'shouldNotifyEndOfSet': _notifyEndOfRound,
      'shouldNotifyEndOfBreak': _notifyEndOfBreak,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}

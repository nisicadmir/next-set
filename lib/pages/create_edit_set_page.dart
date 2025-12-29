import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_set.dart';
import '../services/set_storage_service.dart';
import 'run_set_page.dart';

class CreateEditSetPage extends StatefulWidget {
  final WorkoutSet? existingSet;

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
  final SetStorageService _storageService = SetStorageService();

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
      _nameController.text = set.name;
      _roundsController.text = set.numberOfSets.toString();

      _roundMinutesController.text = (set.secondsPerSet ~/ 60).toString();
      _roundSecondsController.text = (set.secondsPerSet % 60).toString();

      _breakMinutesController.text = (set.breakSeconds ~/ 60).toString();
      _breakSecondsController.text = (set.breakSeconds % 60).toString();

      _notifyEndOfRound = set.shouldNotifyEndOfSet;
      _notifyEndOfBreak = set.shouldNotifyEndOfBreak;
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
      body: SafeArea(
        child: Form(
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
                  subtitle: const Text(
                    '10 seconds before the end of each round',
                  ),
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
                  subtitle: const Text(
                    '10 seconds before the end of each break',
                  ),
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
                      onPressed: _saveSet,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveAndOpen,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Save and Open'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSet() async {
    // Validate full form including name
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();

      // Check for duplicate names
      final isDuplicate = await _storageService.isNameTaken(
        name,
        excludeId: widget.existingSet?.id,
      );

      if (isDuplicate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A set named "$name" already exists')),
        );
        return;
      }

      final workoutSet = _buildWorkoutSet();

      // Save or update the set
      if (widget.existingSet != null) {
        await _storageService.updateSet(workoutSet);
      } else {
        await _storageService.addSet(workoutSet);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set "${workoutSet.name}" saved')),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _saveAndOpen() async {
    // Validate full form including name
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();

      // Check for duplicate names
      final isDuplicate = await _storageService.isNameTaken(
        name,
        excludeId: widget.existingSet?.id,
      );

      if (isDuplicate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A set named "$name" already exists')),
        );
        return;
      }

      final workoutSet = _buildWorkoutSet();

      // Save or update the set
      if (widget.existingSet != null) {
        await _storageService.updateSet(workoutSet);
      } else {
        await _storageService.addSet(workoutSet);
      }

      if (mounted) {
        // Pop the create/edit page and navigate to run page
        Navigator.of(context).pop(true);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RunSetPage(workoutSet: workoutSet),
          ),
        );
      }
    }
  }

  WorkoutSet _buildWorkoutSet() {
    final roundMinutes = int.tryParse(_roundMinutesController.text) ?? 0;
    final roundSeconds = int.tryParse(_roundSecondsController.text) ?? 0;
    final totalSeconds = (roundMinutes * 60) + roundSeconds;

    final breakMinutes = int.tryParse(_breakMinutesController.text) ?? 0;
    final breakSeconds = int.tryParse(_breakSecondsController.text) ?? 0;
    final totalBreakSeconds = (breakMinutes * 60) + breakSeconds;

    final now = DateTime.now();

    if (widget.existingSet != null) {
      // Update existing set
      return widget.existingSet!.copyWith(
        name: _nameController.text.trim(),
        numberOfSets: int.parse(_roundsController.text),
        secondsPerSet: totalSeconds,
        breakSeconds: totalBreakSeconds,
        shouldNotifyEndOfSet: _notifyEndOfRound,
        shouldNotifyEndOfBreak: _notifyEndOfBreak,
        updatedAt: now,
      );
    } else {
      // Create new set
      return WorkoutSet(
        id: now.millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        numberOfSets: int.parse(_roundsController.text),
        secondsPerSet: totalSeconds,
        breakSeconds: totalBreakSeconds,
        shouldNotifyEndOfSet: _notifyEndOfRound,
        shouldNotifyEndOfBreak: _notifyEndOfBreak,
        createdAt: now,
        updatedAt: now,
      );
    }
  }
}

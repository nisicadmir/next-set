import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout_set.dart';

class RunSetPage extends StatefulWidget {
  final WorkoutSet workoutSet;

  const RunSetPage({super.key, required this.workoutSet});

  @override
  State<RunSetPage> createState() => _RunSetPageState();
}

class _RunSetPageState extends State<RunSetPage> {
  Timer? _timer;
  int _currentRound = 1;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.workoutSet.secondsPerSet;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _hasStarted = true;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          // Timer finished
          if (_isBreak) {
            // Break finished, move to next round
            _currentRound++;
            if (_currentRound > widget.workoutSet.numberOfSets) {
              // Workout complete
              _stopTimer();
              _showCompletionDialog();
            } else {
              // Start next set
              _isBreak = false;
              _remainingSeconds = widget.workoutSet.secondsPerSet;
            }
          } else {
            // Set finished
            if (_currentRound < widget.workoutSet.numberOfSets) {
              // Start break
              _isBreak = true;
              _remainingSeconds = widget.workoutSet.breakSeconds;
            } else {
              // Last set finished, workout complete
              _stopTimer();
              _showCompletionDialog();
            }
          }
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _deleteAndExit() {
    _stopTimer();
    Navigator.of(context).pop();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete!'),
        content: Text(
          'You completed all ${widget.workoutSet.numberOfSets} rounds of ${widget.workoutSet.name}!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close run page
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutSet.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Start button (shown only before workout starts)
              if (!_hasStarted)
                ElevatedButton(
                  onPressed: _startTimer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),

              // Control buttons (shown after workout starts)
              if (_hasStarted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isRunning ? _pauseTimer : _resumeTimer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _isRunning ? 'PAUSE' : 'RESUME',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _deleteAndExit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Text(
                        'DELETE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 48),

              // Timer
              Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Current round / Total rounds
              Text(
                '$_currentRound/${widget.workoutSet.numberOfSets}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 24),

              // SET or BREAK label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _isBreak
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isBreak ? 'BREAK' : 'SET',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isBreak
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

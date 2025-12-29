import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/workout_set.dart';
import '../services/set_storage_service.dart';

class RunSetPage extends StatefulWidget {
  final WorkoutSet workoutSet;

  const RunSetPage({super.key, required this.workoutSet});

  @override
  State<RunSetPage> createState() => _RunSetPageState();
}

class _RunSetPageState extends State<RunSetPage> {
  final SetStorageService _storageService = SetStorageService();
  Timer? _timer;
  int _currentRound = 1;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _hasStarted = false;

  // Audio players
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _notificationPlayer = AudioPlayer();
  bool _notificationPlayedForCurrentPhase = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.workoutSet.secondsPerSet;
    _initAudioPlayers();
  }

  Future<void> _initAudioPlayers() async {
    await _bellPlayer.setSource(AssetSource('bell_sound.mp3'));
    await _notificationPlayer.setSource(AssetSource('notification_sound.mp3'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bellPlayer.dispose();
    _notificationPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _playBellSound() async {
    await _bellPlayer.stop();
    await _bellPlayer.play(AssetSource('bell_sound.mp3'));
  }

  Future<void> _playNotificationSound() async {
    await _notificationPlayer.stop();
    await _notificationPlayer.play(AssetSource('notification_sound.mp3'));
  }

  void _startTimer() async {
    // Mark set as used when starting
    if (!_hasStarted) {
      await _storageService.markSetAsUsed(widget.workoutSet.id);
      // Enable wakelock to keep screen on during workout
      WakelockPlus.enable();
    }

    setState(() {
      _hasStarted = true;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          // Check for 10 seconds warning notification
          if (_remainingSeconds == 10 && !_notificationPlayedForCurrentPhase) {
            final shouldNotify = _isBreak
                ? widget.workoutSet.shouldNotifyEndOfBreak
                : widget.workoutSet.shouldNotifyEndOfSet;
            if (shouldNotify) {
              _playNotificationSound();
              _notificationPlayedForCurrentPhase = true;
            }
          }
          _remainingSeconds--;
        } else {
          // Timer finished - play bell sound
          _playBellSound();

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
              _notificationPlayedForCurrentPhase = false;
            }
          } else {
            // Set finished
            if (_currentRound < widget.workoutSet.numberOfSets) {
              // Start break
              _isBreak = true;
              _remainingSeconds = widget.workoutSet.breakSeconds;
              _notificationPlayedForCurrentPhase = false;
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
    WakelockPlus.disable();
    Navigator.of(context).pop();
  }

  void _showCompletionDialog() {
    // Disable wakelock when workout is complete
    WakelockPlus.disable();
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

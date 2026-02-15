import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/workout_set.dart';
import '../services/set_storage_service.dart';
import '../services/notification_service.dart';
import '../services/workout_foreground_task.dart';

class RunSetPage extends StatefulWidget {
  final WorkoutSet workoutSet;

  const RunSetPage({super.key, required this.workoutSet});

  @override
  State<RunSetPage> createState() => _RunSetPageState();
}

class _RunSetPageState extends State<RunSetPage> with WidgetsBindingObserver {
  final SetStorageService _storageService = SetStorageService();
  final NotificationService _notificationService = NotificationService();
  int _currentRound = 1;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _hasStarted = false;
  bool _isInBackground = false;

  final bool showNotificationLogs = false;

  // Audio players (for foreground playback)
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _notificationPlayer = AudioPlayer();

  // Log messages for on-screen display
  final List<String> _logMessages = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.workoutSet.secondsPerSet;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _initAudioPlayers();
    _initNotifications();

    // Set up notification log callback
    _notificationService.onLogMessage = _addLogMessage;
  }

  void _addLogMessage(String message) {
    if (mounted) {
      setState(() {
        _logMessages.add(
          '${DateTime.now().toIso8601String().substring(11, 19)}: $message',
        );
        // Keep only the last 50 messages
        if (_logMessages.length > 50) {
          _logMessages.removeAt(0);
        }
      });
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _initAudioPlayers() async {
    await _bellPlayer.setSource(AssetSource('bell_sound.mp3'));
    await _notificationPlayer.setSource(AssetSource('notification_sound.mp3'));
  }

  Future<void> _initNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isInBackground = true;
      FlutterForegroundTask.sendDataToTask(const <String, Object>{
        'cmd': 'foreground',
        'isForeground': false,
      });
    } else if (state == AppLifecycleState.resumed) {
      _isInBackground = false;
      FlutterForegroundTask.sendDataToTask(const <String, Object>{
        'cmd': 'foreground',
        'isForeground': true,
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _bellPlayer.dispose();
    _notificationPlayer.dispose();
    _logScrollController.dispose();
    _notificationService.onLogMessage = null;
    _stopWorkoutService();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _playBellSound() async {
    if (!_isInBackground) {
      await _bellPlayer.stop();
      await _bellPlayer.play(AssetSource('bell_sound.mp3'));
    }
  }

  Future<void> _playNotificationSound() async {
    if (!_isInBackground) {
      await _notificationPlayer.stop();
      await _notificationPlayer.play(AssetSource('notification_sound.mp3'));
    }
  }

  void _onTaskData(Object data) {
    if (!mounted) return;
    if (data is! Map) return;

    final type = data['type'];
    if (type == 'tick') {
      setState(() {
        _currentRound = (data['currentRound'] as int?) ?? _currentRound;
        _remainingSeconds =
            (data['remainingSeconds'] as int?) ?? _remainingSeconds;
        _isBreak = (data['isBreak'] as bool?) ?? _isBreak;
        _isRunning = (data['isRunning'] as bool?) ?? _isRunning;
        _hasStarted = true;
      });
    } else if (type == 'event') {
      final soundName = data['soundName'] as String?;
      // Play sound in-app when app is in foreground
      if (!_isInBackground) {
        if (soundName == 'bell_sound') {
          _playBellSound();
        } else if (soundName == 'notification_sound') {
          _playNotificationSound();
        }
      }
    } else if (type == 'complete') {
      // Play completion sound if app is in foreground
      if (!_isInBackground) {
        _playBellSound();
        _showCompletionDialog();
      } else {
        WakelockPlus.disable();
      }
    } else if (type == 'notification_log') {
      if (showNotificationLogs) {
        // Handle notification logs from foreground task
        final message = data['message'] as String?;
        if (message != null) {
          _addLogMessage(message);
        }
      }
    }
  }

  Future<void> _startWorkoutService() async {
    // Foreground service requires notification permission on Android 13+.
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      final requested =
          await FlutterForegroundTask.requestNotificationPermission();
      if (requested != NotificationPermission.granted) {
        debugPrint(
          'Foreground service not started: notification permission denied',
        );
        return;
      }
    }

    await saveWorkoutForegroundTaskData(
      name: widget.workoutSet.name,
      numberOfSets: widget.workoutSet.numberOfSets,
      setSeconds: widget.workoutSet.secondsPerSet,
      breakSeconds: widget.workoutSet.breakSeconds,
      shouldNotifyEndOfSet: widget.workoutSet.shouldNotifyEndOfSet,
      shouldNotifyEndOfBreak: widget.workoutSet.shouldNotifyEndOfBreak,
      currentRound: _currentRound,
      remainingSeconds: _remainingSeconds,
      isBreak: _isBreak,
      isRunning: true,
      isForeground: true,
    );

    final result = await FlutterForegroundTask.startService(
      serviceId: 1001,
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: 'NextSet',
      notificationText:
          '${_isBreak ? 'Break' : 'Set $_currentRound/${widget.workoutSet.numberOfSets}'} • ${_formatTime(_remainingSeconds)}',
      notificationButtons: const [
        NotificationButton(id: 'pause', text: 'Pause'),
        NotificationButton(id: 'stop', text: 'Stop'),
      ],
      callback: workoutStartCallback,
    );

    if (result is ServiceRequestFailure) {
      debugPrint('Foreground service failed to start: ${result.error}');
    } else {
      debugPrint('Foreground service started');
    }
  }

  Future<void> _stopWorkoutService() async {
    await FlutterForegroundTask.stopService();
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

    FlutterForegroundTask.sendDataToTask(const <String, Object>{
      'cmd': 'foreground',
      'isForeground': true,
    });
    await _startWorkoutService();
  }

  void _pauseTimer() async {
    setState(() {
      _isRunning = false;
    });
    FlutterForegroundTask.sendDataToTask(const <String, Object>{
      'cmd': 'pause',
    });
  }

  void _resumeTimer() async {
    setState(() {
      _isRunning = true;
    });
    FlutterForegroundTask.sendDataToTask(const <String, Object>{
      'cmd': 'resume',
    });
  }

  void _stopTimer() async {
    await _stopWorkoutService();
    setState(() {
      _isRunning = false;
    });
  }

  void _deleteAndExit() async {
    _stopTimer();
    WakelockPlus.disable();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showCompletionDialog() {
    // Disable wakelock when workout is complete
    WakelockPlus.disable();
    _stopWorkoutService();
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

              if (showNotificationLogs) ...[
                const SizedBox(height: 32),

                // Notification Logs (always visible)
                Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Logs:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _logMessages.isEmpty
                            ? const Center(
                                child: Text(
                                  'Waiting for notifications...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _logScrollController,
                                itemCount: _logMessages.length,
                                itemBuilder: (context, index) {
                                  final message = _logMessages[index];
                                  final isError = message.contains('ERROR');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: isError
                                            ? Colors.red
                                            : Colors.greenAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'notification_service.dart';

// Storage keys for foreground task.
const String _kWsName = 'ws_name';
const String _kWsNumberOfSets = 'ws_number_of_sets';
const String _kWsSetSeconds = 'ws_set_seconds';
const String _kWsBreakSeconds = 'ws_break_seconds';
const String _kWsNotifyEndOfSet = 'ws_notify_end_of_set';
const String _kWsNotifyEndOfBreak = 'ws_notify_end_of_break';

const String _kStateCurrentRound = 'state_current_round';
const String _kStateRemainingSeconds = 'state_remaining_seconds';
const String _kStateIsBreak = 'state_is_break';
const String _kStateIsRunning = 'state_is_running';
const String _kStateIsForeground = 'state_is_foreground';

Future<void> saveWorkoutForegroundTaskData({
  required String name,
  required int numberOfSets,
  required int setSeconds,
  required int breakSeconds,
  required bool shouldNotifyEndOfSet,
  required bool shouldNotifyEndOfBreak,
  required int currentRound,
  required int remainingSeconds,
  required bool isBreak,
  required bool isRunning,
  required bool isForeground,
}) async {
  await FlutterForegroundTask.saveData(key: _kWsName, value: name);
  await FlutterForegroundTask.saveData(
    key: _kWsNumberOfSets,
    value: numberOfSets,
  );
  await FlutterForegroundTask.saveData(key: _kWsSetSeconds, value: setSeconds);
  await FlutterForegroundTask.saveData(
    key: _kWsBreakSeconds,
    value: breakSeconds,
  );
  await FlutterForegroundTask.saveData(
    key: _kWsNotifyEndOfSet,
    value: shouldNotifyEndOfSet,
  );
  await FlutterForegroundTask.saveData(
    key: _kWsNotifyEndOfBreak,
    value: shouldNotifyEndOfBreak,
  );

  await FlutterForegroundTask.saveData(
    key: _kStateCurrentRound,
    value: currentRound,
  );
  await FlutterForegroundTask.saveData(
    key: _kStateRemainingSeconds,
    value: remainingSeconds,
  );
  await FlutterForegroundTask.saveData(key: _kStateIsBreak, value: isBreak);
  await FlutterForegroundTask.saveData(key: _kStateIsRunning, value: isRunning);
  await FlutterForegroundTask.saveData(
    key: _kStateIsForeground,
    value: isForeground,
  );
}

@pragma('vm:entry-point')
void workoutStartCallback() {
  FlutterForegroundTask.setTaskHandler(_WorkoutTaskHandler());
}

class _WorkoutTaskHandler extends TaskHandler {
  final NotificationService _notificationService = NotificationService();

  // Workout config.
  String _name = 'Workout';
  int _numberOfSets = 1;
  int _setSeconds = 0;
  int _breakSeconds = 0;
  bool _shouldNotifyEndOfSet = false;
  bool _shouldNotifyEndOfBreak = false;

  // Current state.
  int _currentRound = 1;
  int _remainingSeconds = 0;
  bool _isBreak = false;
  bool _isRunning = false;
  bool _isForeground = false;
  bool _warnedThisPhase = false;

  /// Generate a unique notification ID based on current timestamp
  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _notificationService.initialize();

    _name =
        (await FlutterForegroundTask.getData<String>(key: _kWsName)) ??
        'Workout';
    _numberOfSets =
        (await FlutterForegroundTask.getData<int>(key: _kWsNumberOfSets)) ?? 1;
    _setSeconds =
        (await FlutterForegroundTask.getData<int>(key: _kWsSetSeconds)) ?? 0;
    _breakSeconds =
        (await FlutterForegroundTask.getData<int>(key: _kWsBreakSeconds)) ?? 0;
    _shouldNotifyEndOfSet =
        (await FlutterForegroundTask.getData<bool>(key: _kWsNotifyEndOfSet)) ??
        false;
    _shouldNotifyEndOfBreak =
        (await FlutterForegroundTask.getData<bool>(
          key: _kWsNotifyEndOfBreak,
        )) ??
        false;

    _currentRound =
        (await FlutterForegroundTask.getData<int>(key: _kStateCurrentRound)) ??
        1;
    _remainingSeconds =
        (await FlutterForegroundTask.getData<int>(
          key: _kStateRemainingSeconds,
        )) ??
        _setSeconds;
    _isBreak =
        (await FlutterForegroundTask.getData<bool>(key: _kStateIsBreak)) ??
        false;
    _isRunning =
        (await FlutterForegroundTask.getData<bool>(key: _kStateIsRunning)) ??
        true;
    _isForeground =
        (await FlutterForegroundTask.getData<bool>(key: _kStateIsForeground)) ??
        false;

    _warnedThisPhase = false;

    FlutterForegroundTask.sendDataToMain(_tickPayload());
    await _updateOngoingNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // If the UI changes, re-check foreground status periodically.
    // (Keeps behavior sane across lifecycle edge-cases.)
    FlutterForegroundTask.getData<bool>(key: _kStateIsForeground).then((value) {
      if (value != null) _isForeground = value;
    });

    if (!_isRunning) {
      FlutterForegroundTask.sendDataToMain(_tickPayload());
      _updateOngoingNotification();
      return;
    }

    if (_remainingSeconds > 0) {
      // 10-second warning.
      if (_remainingSeconds == 10 && !_warnedThisPhase) {
        final shouldNotify = _isBreak
            ? _shouldNotifyEndOfBreak
            : _shouldNotifyEndOfSet;
        if (shouldNotify) {
          _warnedThisPhase = true;
          _fireEvent(
            type: 'notify',
            title: _isBreak ? 'Break ending soon!' : 'Set ending soon!',
            body: _isBreak
                ? '10 seconds left in break'
                : '10 seconds left in Set $_currentRound',
            soundName: 'notification_sound',
          );
        }
      }

      debugPrint('WorkoutTaskHandler: Remaining seconds: $_remainingSeconds');

      _remainingSeconds--;
      FlutterForegroundTask.sendDataToMain(_tickPayload());
      _updateOngoingNotification();
      return;
    }

    // Phase finished.
    if (_currentRound >= _numberOfSets) {
      _completeWorkout();
      return;
    }

    _fireEvent(
      type: 'notify',
      title: _isBreak
          ? 'Break $_currentRound Over!'
          : 'Set $_currentRound Complete!',
      body: _isBreak
          ? 'Start Set ${_currentRound + 1}'
          : 'Starting break $_currentRound',
      soundName: 'bell_sound',
    );

    if (_isBreak) {
      _currentRound++;
      _isBreak = false;
      _remainingSeconds = _setSeconds;
    } else {
      _isBreak = true;
      _remainingSeconds = _breakSeconds;
    }

    _warnedThisPhase = false;

    FlutterForegroundTask.sendDataToMain(_tickPayload());
    _updateOngoingNotification();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'type': 'stopped',
      'isTimeout': isTimeout,
    });
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final cmd = data['cmd'];
    if (cmd == 'pause') {
      _isRunning = false;
      FlutterForegroundTask.saveData(key: _kStateIsRunning, value: false);
      _updateOngoingNotification();
    } else if (cmd == 'resume') {
      _isRunning = true;
      _warnedThisPhase = false;
      FlutterForegroundTask.saveData(key: _kStateIsRunning, value: true);
      _updateOngoingNotification();
    } else if (cmd == 'stop') {
      FlutterForegroundTask.stopService();
    } else if (cmd == 'foreground') {
      final isFg = data['isForeground'];
      if (isFg is bool) {
        _isForeground = isFg;
        FlutterForegroundTask.saveData(key: _kStateIsForeground, value: isFg);
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'pause') {
      _isRunning = false;
      FlutterForegroundTask.saveData(key: _kStateIsRunning, value: false);
      _updateOngoingNotification();
      FlutterForegroundTask.sendDataToMain(_tickPayload());
    } else if (id == 'resume') {
      _isRunning = true;
      _warnedThisPhase = false;
      FlutterForegroundTask.saveData(key: _kStateIsRunning, value: true);
      _updateOngoingNotification();
      FlutterForegroundTask.sendDataToMain(_tickPayload());
    } else if (id == 'stop') {
      FlutterForegroundTask.stopService();
      FlutterForegroundTask.sendDataToMain(<String, Object>{
        'type': 'stopped',
        'isTimeout': false,
      });
    }
  }

  Map<String, Object> _tickPayload() {
    return <String, Object>{
      'type': 'tick',
      'currentRound': _currentRound,
      'numberOfSets': _numberOfSets,
      'remainingSeconds': _remainingSeconds,
      'isBreak': _isBreak,
      'isRunning': _isRunning,
    };
  }

  Future<void> _updateOngoingNotification() async {
    final phaseLabel = _isBreak ? 'Break' : 'Set $_currentRound/$_numberOfSets';
    final time = _formatTime(_remainingSeconds);
    await FlutterForegroundTask.updateService(
      notificationTitle: 'NextSet',
      notificationText: '$phaseLabel • $time',
      notificationButtons: _isRunning
          ? [
              const NotificationButton(id: 'pause', text: 'Pause'),
              const NotificationButton(id: 'stop', text: 'Stop'),
            ]
          : [
              const NotificationButton(id: 'resume', text: 'Resume'),
              const NotificationButton(id: 'stop', text: 'Stop'),
            ],
    );
  }

  Future<void> _fireEvent({
    required String type,
    required String title,
    required String body,
    required String soundName,
  }) async {
    debugPrint(
      'WorkoutTaskHandler: Firing event: $type (sound: $soundName, title: $title, body: $body, isForeground: $_isForeground)',
    );

    if (_isForeground) {
      // Always send event to UI for in-app sound playback
      FlutterForegroundTask.sendDataToMain(<String, Object>{
        'type': 'event',
        'event': type,
        'title': title,
        'body': body,
        'soundName': soundName,
      });
    }

    // Show system notification when app is in background
    if (!_isForeground) {
      debugPrint(
        '🔔 Showing notification: $title (sound: $soundName, isForeground: $_isForeground)',
      );
      final notificationId = _generateNotificationId();

      // Send log to UI
      FlutterForegroundTask.sendDataToMain(<String, Object>{
        'type': 'notification_log',
        'message':
            'Showing notification #$notificationId - "$title" with sound: $soundName (isBell: ${soundName == 'bell_sound'})',
      });

      try {
        await _notificationService.showNotification(
          id: notificationId,
          title: title,
          body: body,
          soundName: soundName,
        );

        // Send success log to UI
        FlutterForegroundTask.sendDataToMain(<String, Object>{
          'type': 'notification_log',
          'message': 'Successfully showed notification #$notificationId',
        });
      } catch (e) {
        // Send error log to UI
        FlutterForegroundTask.sendDataToMain(<String, Object>{
          'type': 'notification_log',
          'message': 'ERROR showing notification: $e',
        });
      }
    } else {
      debugPrint('🔕 Skipping notification (app is foreground): $title');
      // Send log to UI that notification was skipped
      FlutterForegroundTask.sendDataToMain(<String, Object>{
        'type': 'notification_log',
        'message': 'Skipping notification (app is foreground): $title',
      });
    }
  }

  Future<void> _completeWorkout() async {
    _isRunning = false;

    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'type': 'complete',
      'name': _name,
      'numberOfSets': _numberOfSets,
    });

    if (!_isForeground) {
      final notificationId = _generateNotificationId();

      // Send log to UI
      FlutterForegroundTask.sendDataToMain(<String, Object>{
        'type': 'notification_log',
        'message':
            'Showing notification #$notificationId - "Workout Complete!" with sound: bell_sound (isBell: true)',
      });

      try {
        await _notificationService.showNotification(
          id: notificationId,
          title: 'Workout Complete!',
          body: 'You finished all $_numberOfSets rounds of $_name!',
          soundName: 'bell_sound',
        );

        // Send success log to UI
        FlutterForegroundTask.sendDataToMain(<String, Object>{
          'type': 'notification_log',
          'message': 'Successfully showed notification #$notificationId',
        });
      } catch (e) {
        // Send error log to UI
        FlutterForegroundTask.sendDataToMain(<String, Object>{
          'type': 'notification_log',
          'message': 'ERROR showing notification: $e',
        });
      }
    }

    FlutterForegroundTask.stopService();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

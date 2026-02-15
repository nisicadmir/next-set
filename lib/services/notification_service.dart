import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _defaultChannelId = 'default_channel';
  static const String _defaultChannelName = 'Default channel';

  // ignore: unused_field
  static const String _channelBellSoundId = 'workout_channel_bell_sound_v3';
  // ignore: unused_field
  static const String _channelBellSoundName = 'Workout Bell Name v3';

  // ignore: unused_field
  static const String _channelNotificationSoundId =
      'workout_channel_notification_sound_v1';
  // ignore: unused_field
  static const String _channelNotificationSoundName =
      'Workout Notification Name v1';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Callback for sending logs to the UI
  void Function(String)? onLogMessage;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('NotificationService: Initializing...');

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    if (Platform.isAndroid) {
      const AndroidNotificationChannel defaultChannel =
          AndroidNotificationChannel(
            _defaultChannelId,
            _defaultChannelName,
            description: 'Default channel',
            importance: Importance.high,
          );
      // const AndroidNotificationChannel channelBellSound =
      //     AndroidNotificationChannel(
      //       _channelBellSoundId,
      //       _channelBellSoundName,
      //       description: 'Workout timer notifications (bell_sound_)',
      //       importance: Importance.high,

      //       sound: RawResourceAndroidNotificationSound('bell_sound'),
      //       playSound: true,
      //       enableVibration: true,
      //       audioAttributesUsage: AudioAttributesUsage.notification,
      //     );
      // const AndroidNotificationChannel channelNotificationSound =
      //     AndroidNotificationChannel(
      //       _channelNotificationSoundId,
      //       _channelNotificationSoundName,
      //       description: 'Workout timer notifications (notification_sound_)',
      //       importance: Importance.high,

      //       sound: RawResourceAndroidNotificationSound('notification_sound'),
      //       playSound: true,
      //       enableVibration: true,
      //       audioAttributesUsage: AudioAttributesUsage.notification,
      //     );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(defaultChannel);

      // await _notifications
      //     .resolvePlatformSpecificImplementation<
      //       AndroidFlutterLocalNotificationsPlugin
      //     >()
      //     ?.createNotificationChannel(channelBellSound);

      // await _notifications
      //     .resolvePlatformSpecificImplementation<
      //       AndroidFlutterLocalNotificationsPlugin
      //     >()
      //     ?.createNotificationChannel(channelNotificationSound);
    }
    _isInitialized = true;
    debugPrint('NotificationService: Initialization complete');
  }

  Future<bool> requestPermissions() async {
    // Request Android 13+ notification permission
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      if (granted != true) return false;
    }

    // Request iOS permissions
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
    }

    return true;
  }

  // ignore: unused_element
  AndroidNotificationDetails _androidDetailsForSound(String soundName) {
    // On Android, the notification sound is controlled by the *channel*.
    // Channel sound can't be changed per-notification, so use one channel per sound.
    // Using v4 to force recreation of channels with proper settings
    final channelId = 'workout_channel_${soundName}_v4';
    final channelName = soundName == 'bell_sound'
        ? 'Workout Bells'
        : 'Workout Warnings';

    debugPrint('NotificationService: channelId: $channelId');
    debugPrint('NotificationService: channelName: $channelName');
    debugPrint('NotificationService: soundName: $soundName');

    // soundName is either 'bell_sound' or 'notification_sound'

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Workout timer notifications ($soundName)',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundName),
      playSound: true,
      enableVibration: true,
      // Make end-of-phase notifications more "alarm-like" so Android is less
      // likely to suppress the audible alert when notifications are frequent.
      // category: isBell ? AndroidNotificationCategory.alarm : null,
      category: null,
      audioAttributesUsage: AudioAttributesUsage.notification,
      // Ensure notifications show over other apps
      fullScreenIntent: false,
      visibility: NotificationVisibility.public,
    );
  }

  DarwinNotificationDetails _iosDetailsForSound(String soundName) {
    return DarwinNotificationDetails(
      sound: '$soundName.mp3',
      presentAlert: true,
      presentSound: true,
    );
  }

  /// Cancel a specific notification by id
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String soundName,
  }) async {
    // Ensure initialized before showing notification
    if (!_isInitialized) {
      debugPrint(
        'NotificationService: Initializing before showing notification',
      );
      await initialize();
    }

    debugPrint(
      'NotificationService: Showing notification (admir) #$id - "$title" with sound: $soundName (isBell: ${soundName == 'bell_sound'})',
    );
    onLogMessage?.call(
      'Showing notification #$id - "$title" with sound: $soundName (isBell: ${soundName == 'bell_sound'})',
    );

    final channelId = _defaultChannelId;
    final channelName = _defaultChannelName;
    // final channelId = soundName == 'bell_sound'
    //     ? _channelBellSoundId
    //     : _channelNotificationSoundId;
    // final channelName = soundName == 'bell_sound'
    //     ? _channelBellSoundName
    //     : _channelNotificationSoundName;

    final androidDetails = AndroidNotificationDetails(channelId, channelName);

    final iosDetails = _iosDetailsForSound(soundName);

    debugPrint(
      'NotificationService: Channel ID: $channelId, Channel Name: $channelName',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(id, title, body, details);
      debugPrint('NotificationService: Successfully showed notification #$id');
      onLogMessage?.call('Successfully showed notification #$id');
    } catch (e) {
      debugPrint('NotificationService: ERROR showing notification: $e');
      onLogMessage?.call('ERROR showing notification: $e');
    }
  }
}

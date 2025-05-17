// lib/core/services/implementations/notification_service_impl.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../interfaces/notification_service.dart';
import '../interfaces/battery_service.dart';
import '../interfaces/do_not_disturb_service.dart';

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final BatteryService _batteryService;
  final DoNotDisturbService _doNotDisturbService;

  bool _respectBatteryOptimizations = true;
  bool _respectDoNotDisturb = true;

  NotificationServiceImpl(
    this._flutterLocalNotificationsPlugin,
    this._batteryService,
    this._doNotDisturbService,
  );

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // تعامل مع الـ payload إن لزم
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final bool? iosGranted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      return iosGranted ?? true;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleNotification(NotificationData notification) async {
    if (!await _canSendNotificationBasedOnSettings(notification)) {
      return false;
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notification.id,
        notification.title,
        notification.body,
        tz.TZDateTime.from(notification.scheduledDate, tz.local),
        _getNotificationDetails(notification),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleRepeatingNotification(NotificationData notification) async {
    if (notification.repeatInterval == null) {
      return false;
    }

    if (!await _canSendNotificationBasedOnSettings(notification)) {
      return false;
    }

    try {
      if (notification.repeatInterval == NotificationRepeatInterval.daily ||
          notification.repeatInterval == NotificationRepeatInterval.weekly) {
        final RepeatInterval flutterRepeatInterval =
            _mapToFlutterRepeatInterval(notification.repeatInterval!);

await _flutterLocalNotificationsPlugin.periodicallyShow(
  notification.id,
  notification.title,
  notification.body,
  flutterRepeatInterval,
  _getNotificationDetails(notification),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
);
        return true;
      } else {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notification.id,
          notification.title,
          notification.body,
          tz.TZDateTime.from(notification.scheduledDate, tz.local),
          _getNotificationDetails(notification),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Error scheduling repeating notification: $e');
      return false;
    }
  }

  RepeatInterval _mapToFlutterRepeatInterval(NotificationRepeatInterval interval) {
    switch (interval) {
      case NotificationRepeatInterval.daily:
        return RepeatInterval.daily;
      case NotificationRepeatInterval.weekly:
        return RepeatInterval.weekly;
      case NotificationRepeatInterval.monthly:
        return RepeatInterval.weekly;
    }
  }

  NotificationDetails _getNotificationDetails(NotificationData notification) {
    final Importance importance = _mapToAndroidImportance(notification.priority);
    final Priority priority = _mapToAndroidPriority(notification.priority);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'athkar_app_channel_${notification.notificationTime.name}',
      'Athkar ${notification.notificationTime.name.toUpperCase()} Notifications',
      channelDescription: 'Channel for ${notification.notificationTime.name} notifications',
      importance: importance,
      priority: priority,
      showWhen: true,
      styleInformation: const BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Importance _mapToAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
    }
  }

  Priority _mapToAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Future<void> setRespectBatteryOptimizations(bool enabled) async {
    _respectBatteryOptimizations = enabled;
  }

  @override
  Future<void> setRespectDoNotDisturb(bool enabled) async {
    _respectDoNotDisturb = enabled;
  }

  Future<bool> _canSendNotificationBasedOnSettings(NotificationData notification) async {
    if (notification.respectBatteryOptimizations && _respectBatteryOptimizations) {
      final bool canSendBasedOnBattery = await _batteryService.canSendNotification();
      if (!canSendBasedOnBattery) return false;
    }

    if (notification.respectDoNotDisturb && _respectDoNotDisturb) {
      final bool isDndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
      if (isDndEnabled) {
        return notification.priority == NotificationPriority.high;
      }
    }

    return true;
  }

  @override
  Future<bool> canSendNotificationsNow() async {
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return false;

    if (_respectBatteryOptimizations) {
      final bool canSendBasedOnBattery = await _batteryService.canSendNotification();
      if (!canSendBasedOnBattery) return false;
    }

    if (_respectDoNotDisturb) {
      final bool isDndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
      if (isDndEnabled) return false;
    }

    return true;
  }
}

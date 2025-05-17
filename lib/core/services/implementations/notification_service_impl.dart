// lib/core/services/implementations/notification_service_impl.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
// Renombrar la importación para evitar conflictos
import '../interfaces/notification_service.dart' as app_notification;
import '../interfaces/battery_service.dart';
import '../interfaces/do_not_disturb_service.dart';
import '../../../main.dart';

class NotificationServiceImpl implements app_notification.NotificationService {
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
    
    await _setupNotificationChannels();
  }

  Future<void> _setupNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel athkarChannel = AndroidNotificationChannel(
        'athkar_channel',
        'Notificaciones de Athkar',
        description: 'Para enviar recordatorios y notificaciones de Athkar',
        importance: Importance.high,
      );
      
      const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
        'prayer_channel',
        'Notificaciones de oración',
        description: 'Para enviar recordatorios y notificaciones de tiempo de oración',
        importance: Importance.high,
      );
      
      const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
        'default_channel',
        'Notificaciones generales',
        description: 'Para enviar notificaciones generales de la aplicación',
        importance: Importance.defaultImportance,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(athkarChannel);
        await androidPlugin.createNotificationChannel(prayerChannel);
        await androidPlugin.createNotificationChannel(defaultChannel);
      }
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final Map<String, dynamic> data = json.decode(payload);
        final String? type = data['type'];
        final String? route = data['route'];
        final Map<String, dynamic>? arguments = data['arguments'];
        
        if (type != null && route != null) {
          final navigatorKey = NavigationService.navigatorKey;
          if (navigatorKey.currentState != null) {
            if (arguments != null) {
              navigatorKey.currentState!.pushNamed(route, arguments: arguments);
            } else {
              navigatorKey.currentState!.pushNamed(route);
            }
          }
        }
      } catch (e) {
        debugPrint('Error al analizar payload de notificación: $e');
      }
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final bool? areEnabled = await androidPlugin.areNotificationsEnabled();
          if (areEnabled == false) {
            final bool? granted = await androidPlugin.requestNotificationsPermission();
            return granted ?? false;
          }
          return areEnabled ?? false;
        }
        return true;
      }
      
      if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error solicitando permiso: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleNotification(app_notification.NotificationData notification) async {
    if (!await _canSendNotificationBasedOnSettings(notification)) return false;

    try {
      final String payloadJson = notification.payload != null 
          ? json.encode(notification.payload)
          : '';

await _flutterLocalNotificationsPlugin.zonedSchedule(
  notification.id,
  notification.title,
  notification.body,
  tz.TZDateTime.from(notification.scheduledDate, tz.local),
  _getNotificationDetails(notification),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time, // لتكرار يومي
);
      return true;
    } catch (e) {
      debugPrint('Error al programar notificación: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleRepeatingNotification(app_notification.NotificationData notification) async {
    if (notification.repeatInterval == null) return false;
    if (!await _canSendNotificationBasedOnSettings(notification)) return false;

    try {
      final String payloadJson = notification.payload != null 
          ? json.encode(notification.payload)
          : '';

      if (notification.repeatInterval == app_notification.NotificationRepeatInterval.daily ||
          notification.repeatInterval == app_notification.NotificationRepeatInterval.weekly) {
        final RepeatInterval flutterRepeatInterval =
            _mapToFlutterRepeatInterval(notification.repeatInterval!);

        await _flutterLocalNotificationsPlugin.periodicallyShow(
          notification.id,
          notification.title,
          notification.body,
          flutterRepeatInterval,
          _getNotificationDetails(notification),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payloadJson,
        );
        return true;
      } else {
        final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
          notification.scheduledDate,
          tz.local,
        );
        
await _flutterLocalNotificationsPlugin.zonedSchedule(
  notification.id,
  notification.title,
  notification.body,
  tz.TZDateTime.from(notification.scheduledDate, tz.local),
  _getNotificationDetails(notification),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time, // لتكرار يومي
);
        return true;
      }
    } catch (e) {
      debugPrint('Error al programar notificación repetitiva: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleNotificationInTimeZone(
    app_notification.NotificationData notification, 
    String timeZone
  ) async {
    if (!await _canSendNotificationBasedOnSettings(notification)) return false;

    try {
      final location = tz.getLocation(timeZone);
      final scheduledDate = tz.TZDateTime.from(notification.scheduledDate, location);
      
      final String payloadJson = notification.payload != null 
          ? json.encode(notification.payload)
          : '';
      
await _flutterLocalNotificationsPlugin.zonedSchedule(
  notification.id,
  notification.title,
  notification.body,
  tz.TZDateTime.from(notification.scheduledDate, tz.local),
  _getNotificationDetails(notification),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time, // لتكرار يومي
);
      return true;
    } catch (e) {
      debugPrint('Error al programar notificación en zona horaria: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleNotificationWithActions(
    app_notification.NotificationData notification,
    List<app_notification.NotificationAction> actions,
  ) async {
    if (!await _canSendNotificationBasedOnSettings(notification)) return false;

    try {
      final String payloadJson = notification.payload != null 
          ? json.encode(notification.payload)
          : '';

await _flutterLocalNotificationsPlugin.zonedSchedule(
  notification.id,
  notification.title,
  notification.body,
  tz.TZDateTime.from(notification.scheduledDate, tz.local),
  _getNotificationDetails(notification),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time, // لتكرار يومي
);

      return true;
    } catch (e) {
      debugPrint('Error al programar notificación con acciones: $e');
      return false;
    }
  }

  RepeatInterval _mapToFlutterRepeatInterval(app_notification.NotificationRepeatInterval interval) {
    switch (interval) {
      case app_notification.NotificationRepeatInterval.daily:
        return RepeatInterval.daily;
      case app_notification.NotificationRepeatInterval.weekly:
        return RepeatInterval.weekly;
      case app_notification.NotificationRepeatInterval.monthly:
        return RepeatInterval.weekly;
    }
  }

  NotificationDetails _getNotificationDetails(app_notification.NotificationData notification) {
    final Importance importance = _mapToAndroidImportance(notification.priority);
    final Priority priority = _mapToAndroidPriority(notification.priority);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      notification.channelId,
      'Athkar ${notification.notificationTime.name.toUpperCase()} Notifications',
      channelDescription: 'Channel for ${notification.notificationTime.name} notifications',
      importance: importance,
      priority: priority,
      showWhen: true,
      styleInformation: const BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
      sound: notification.soundName != null ? RawResourceAndroidNotificationSound(notification.soundName!) : null,
      playSound: notification.soundName != null,
      visibility: _getAndroidVisibility(notification.visibility),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: notification.soundName != null,
      sound: notification.soundName,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Importance _mapToAndroidImportance(app_notification.NotificationPriority priority) {
    switch (priority) {
      case app_notification.NotificationPriority.low:
        return Importance.low;
      case app_notification.NotificationPriority.normal:
        return Importance.defaultImportance;
      case app_notification.NotificationPriority.high:
        return Importance.high;
      case app_notification.NotificationPriority.critical:
        return Importance.max;
    }
  }

  Priority _mapToAndroidPriority(app_notification.NotificationPriority priority) {
    switch (priority) {
      case app_notification.NotificationPriority.low:
        return Priority.low;
      case app_notification.NotificationPriority.normal:
        return Priority.defaultPriority;
      case app_notification.NotificationPriority.high:
        return Priority.high;
      case app_notification.NotificationPriority.critical:
        return Priority.max;
    }
  }

  NotificationVisibility _getAndroidVisibility(app_notification.NotificationVisibility visibility) {
    switch (visibility) {
      case app_notification.NotificationVisibility.public:
        return NotificationVisibility.public;
      case app_notification.NotificationVisibility.private:
        return NotificationVisibility.private;
      case app_notification.NotificationVisibility.secret:
        return NotificationVisibility.secret;
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
  Future<void> cancelNotificationsByIds(List<int> ids) async {
    for (final id in ids) {
      await _flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  @override
  Future<void> cancelNotificationsByTag(String tag) async {
    if (Platform.isAndroid) {
      final List<int> idsToCancel = _getNotificationIdsByTag(tag);
      await cancelNotificationsByIds(idsToCancel);
    }
  }

  List<int> _getNotificationIdsByTag(String tag) {
    switch (tag) {
      case 'athkar':
        return [1001, 1002];
      case 'prayer':
        return [2001, 2002, 2003, 2004, 2005, 2101, 2102, 2103, 2104, 2105];
      default:
        return [];
    }
  }

  @override
  Future<void> setRespectBatteryOptimizations(bool enabled) async {
    _respectBatteryOptimizations = enabled;
  }

  @override
  Future<void> setRespectDoNotDisturb(bool enabled) async {
    _respectDoNotDisturb = enabled;
  }

  Future<bool> _canSendNotificationBasedOnSettings(app_notification.NotificationData notification) async {
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return false;

    if (notification.respectBatteryOptimizations && _respectBatteryOptimizations) {
      final bool canSendBasedOnBattery = await _batteryService.canSendNotification();
      if (!canSendBasedOnBattery) {
        debugPrint('No se puede enviar notificación debido a optimizaciones de batería');
        return false;
      }
    }

    if (notification.respectDoNotDisturb && _respectDoNotDisturb) {
      final bool isDndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
      if (isDndEnabled) {
        debugPrint('DND está habilitado');
        return notification.priority == app_notification.NotificationPriority.high || 
               notification.priority == app_notification.NotificationPriority.critical;
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

  @override
  Future<void> dispose() async {
    debugPrint('NotificationService disposed');
  }
}

// lib/core/services/implementations/notification_service_impl.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
// Para evitar conflictos, renombra la importación de NotificationVisibility
import '../interfaces/notification_service.dart' hide NotificationVisibility;
import '../interfaces/battery_service.dart';
import '../interfaces/do_not_disturb_service.dart';
import '../../../main.dart';

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
    
    // إعداد قنوات الإشعارات
    await _setupNotificationChannels();
  }

  Future<void> _setupNotificationChannels() async {
    if (Platform.isAndroid) {
      // قناة إشعارات الأذكار
      const AndroidNotificationChannel athkarChannel = AndroidNotificationChannel(
        'athkar_channel',
        'إشعارات الأذكار',
        description: 'يتم استخدامها لإرسال تذكيرات وإشعارات الأذكار',
        importance: Importance.high,
      );
      
      // قناة إشعارات الصلاة
      const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
        'prayer_channel',
        'إشعارات الصلاة',
        description: 'يتم استخدامها لإرسال تذكيرات وإشعارات أوقات الصلاة',
        importance: Importance.high,
      );
      
      // قناة الإشعارات العادية
      const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
        'default_channel',
        'الإشعارات العامة',
        description: 'يتم استخدامها لإرسال الإشعارات العامة للتطبيق',
        importance: Importance.defaultImportance,
      );
      
      // بعض الإصدارات القديمة قد لا تدعم createNotificationChannels
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation
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
      // محاولة تحليل الـ payload كـ JSON
      try {
        final Map<String, dynamic> data = json.decode(payload);
        final String? type = data['type'];
        final String? route = data['route'];
        final Map<String, dynamic>? arguments = data['arguments'];
        
        if (type != null && route != null) {
          // استخدام NavigationService للانتقال إلى الشاشة المناسبة
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
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      // طلب إذن للأندرويد
      if (Platform.isAndroid) {
        // في بعض الإصدارات لا يحتاج أي أذونات خاصة
        return true;
      }
      
      // طلب إذن لنظام iOS
      if (Platform.isIOS) {
        // استخدم الطريقة المباشرة للإذن
        return await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ?? true;
      }

      return true;
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
      final String payloadJson = notification.payload != null 
          ? json.encode(notification.payload)
          : '';

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
          payload: payloadJson,
        );
        return true;
      } else {
        // جدولة شهرية - تحتاج إلى استخدام zonedSchedule مع matchDateTimeComponents
        final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
          notification.scheduledDate,
          tz.local,
        );
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notification.id,
          notification.title,
          notification.body,
          scheduledDate,
          _getNotificationDetails(notification),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Error scheduling repeating notification: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleNotificationInTimeZone(
    NotificationData notification, 
    String timeZone
  ) async {
    if (!await _canSendNotificationBasedOnSettings(notification)) {
      return false;
    }

    try {
      // تعيين المنطقة الزمنية المحددة
      final location = tz.getLocation(timeZone);
      final scheduledDate = tz.TZDateTime.from(notification.scheduledDate, location);
      
      final String payloadJson = notification.payload != null 
          ? json.encode(notification.payload)
          : '';
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notification.id,
        notification.title,
        notification.body,
        scheduledDate,
        _getNotificationDetails(notification),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payloadJson,
      );
      return true;
    } catch (e) {
      debugPrint('Error scheduling notification in timezone: $e');
      return false;
    }
  }

  @override
  Future<bool> scheduleNotificationWithActions(
    NotificationData notification,
    List<NotificationAction> actions,
  ) async {
    if (!await _canSendNotificationBasedOnSettings(notification)) {
      return false;
    }

    try {
      // في الإصدار الحالي، لا يمكننا استخدام الإجراءات مباشرة
      // نستخدم الإشعارات العادية بدون إجراءات
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
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payloadJson,
      );

      return true;
    } catch (e) {
      debugPrint('Error scheduling notification with actions: $e');
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
        return RepeatInterval.weekly; // استخدام أسبوعي والتحقق من اليوم في الشهر بشكل منفصل
    }
  }

  NotificationDetails _getNotificationDetails(NotificationData notification) {
    final Importance importance = _mapToAndroidImportance(notification.priority);
    final Priority priority = _mapToAndroidPriority(notification.priority);

    // تعيين تفاصيل الأندرويد مع مراعاة قناة الإشعارات
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

    // تعيين تفاصيل iOS مع مراعاة إعدادات الصوت
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

  Importance _mapToAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.critical:
        return Importance.max;
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
      case NotificationPriority.critical:
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
      // في الإصدار الحالي لا يمكن إلغاء الإشعارات حسب العلامة مباشرة
      // نستخدم قائمة المعرفات المرتبطة بالعلامة
      final List<int> idsToCancel = _getNotificationIdsByTag(tag);
      await cancelNotificationsByIds(idsToCancel);
    }
  }

  // طريقة وهمية للحصول على معرفات الإشعارات بناءً على العلامة - يجب استبدالها بتنفيذ فعلي
  List<int> _getNotificationIdsByTag(String tag) {
    switch (tag) {
      case 'athkar':
        return [1001, 1002]; // معرفات إشعارات الأذكار
      case 'prayer':
        return [2001, 2002, 2003, 2004, 2005, 2101, 2102, 2103, 2104, 2105]; // معرفات إشعارات وتذكيرات الصلاة
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

  Future<bool> _canSendNotificationBasedOnSettings(NotificationData notification) async {
    // التحقق من إذون الإشعارات
    final bool hasPermission = await requestPermission();
    if (!hasPermission) return false;

    if (notification.respectBatteryOptimizations && _respectBatteryOptimizations) {
      final bool canSendBasedOnBattery = await _batteryService.canSendNotification();
      if (!canSendBasedOnBattery) {
        debugPrint('Cannot send notification due to battery optimizations');
        return false;
      }
    }

    if (notification.respectDoNotDisturb && _respectDoNotDisturb) {
      final bool isDndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
      if (isDndEnabled) {
        debugPrint('DND is enabled');
        // إذا كانت الأولوية عالية أو حرجة، يمكن إرسال الإشعار حتى في وضع عدم الإزعاج
        return notification.priority == NotificationPriority.high || 
               notification.priority == NotificationPriority.critical;
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
    // تنظيف أي موارد أخرى
    debugPrint('NotificationService disposed');
  }
}

// إضافة مساحة اسم لتجنب التعارض

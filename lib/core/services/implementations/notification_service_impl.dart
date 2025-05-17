// lib/core/services/implementations/notification_service_impl.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:rxdart/rxdart.dart';
import '../interfaces/notification_service.dart';

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<NotificationData> _notificationsSubject = BehaviorSubject<NotificationData>();

  @override
  Stream<NotificationData> get notificationStream => _notificationsSubject.stream;

  @override
  Future<void> init() async {
    tz.initializeTimeZones();
    
    // تهيئة إعدادات الإشعارات لنظام Android
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // تهيئة إعدادات الإشعارات لنظام iOS
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    // تهيئة إعدادات الإشعارات
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // تهيئة البرنامج المساعد للإشعارات
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  @override
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidImplementation?.requestPermission();
      return granted ?? false;
    }
    
    return false;
  }

  @override
  Future<void> showNotification(NotificationData notification) async {
    final androidDetails = AndroidNotificationDetails(
      'test_athkar_app_${notification.type.name}',
      'Athkar ${notification.type.name}',
      channelDescription: 'Notifications for ${notification.type.name}',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iosDetails = DarwinNotificationDetails();
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      int.parse(notification.id),
      notification.title,
      notification.body,
      notificationDetails,
      payload: notification.payload != null 
          ? notification.payload.toString() 
          : null,
    );
  }

  @override
  Future<void> scheduleNotification(NotificationData notification) async {
    if (notification.scheduledTime == null) {
      throw ArgumentError('scheduledTime cannot be null for scheduled notifications');
    }
    
    final androidDetails = AndroidNotificationDetails(
      'test_athkar_app_${notification.type.name}_scheduled',
      'Scheduled ${notification.type.name}',
      channelDescription: 'Scheduled notifications for ${notification.type.name}',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iosDetails = DarwinNotificationDetails();
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.zonedSchedule(
      int.parse(notification.id),
      notification.title,
      notification.body,
      tz.TZDateTime.from(notification.scheduledTime!, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: notification.payload != null 
          ? notification.payload.toString() 
          : null,
    );
  }

  @override
  Future<void> scheduleRepeatingNotification({
    required NotificationData notification,
    required RepeatInterval repeatInterval,
  }) async {
    if (notification.scheduledTime == null) {
      throw ArgumentError('scheduledTime cannot be null for repeating notifications');
    }
    
    final androidDetails = AndroidNotificationDetails(
      'test_athkar_app_${notification.type.name}_repeating',
      'Repeating ${notification.type.name}',
      channelDescription: 'Repeating notifications for ${notification.type.name}',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final iosDetails = DarwinNotificationDetails();
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // تحويل RepeatInterval إلى RepeatFrequency لـ flutter_local_notifications
    final DateTimeComponents? dateTimeComponents = _getDateTimeComponents(repeatInterval);
    
    await _notificationsPlugin.zonedSchedule(
      int.parse(notification.id),
      notification.title,
      notification.body,
      _getNextInstanceOfDateTime(notification.scheduledTime!, repeatInterval),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: dateTimeComponents,
      payload: notification.payload != null 
          ? notification.payload.toString() 
          : null,
    );
  }

  @override
  Future<void> cancelNotification(String id) async {
    await _notificationsPlugin.cancel(int.parse(id));
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  @override
  Future<void> rescheduleNotificationsAfterReboot() async {
    // هنا سنقوم باستعادة جميع الإشعارات المخزنة في قاعدة البيانات المحلية
    // وإعادة جدولتها
    // (سيتم تنفيذ ذلك لاحقًا بعد إنشاء خدمة تخزين الإشعارات)
  }

  // معالجة الإشعارات المستلمة (iOS)
  void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    if (title != null && body != null) {
      _notificationsSubject.add(
        NotificationData(
          id: id.toString(),
          title: title,
          body: body,
          type: NotificationType.athkar, // تحديد النوع المناسب هنا
          payload: payload != null ? {'data': payload} : null,
        ),
      );
    }
  }

  // معالجة الإشعارات المستلمة (Android & iOS)
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      _notificationsSubject.add(
        NotificationData(
          id: response.id.toString(),
          title: 'Notification',
          body: 'Notification received',
          type: NotificationType.athkar, // تحديد النوع المناسب هنا
          payload: {'data': payload},
        ),
      );
    }
  }

  // تحويل RepeatInterval إلى DateTimeComponents
  DateTimeComponents? _getDateTimeComponents(RepeatInterval repeatInterval) {
    switch (repeatInterval) {
      case RepeatInterval.daily:
        return DateTimeComponents.time;
      case RepeatInterval.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatInterval.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        return null;
    }
  }

  // الحصول على الوقت التالي للتنفيذ بناءً على نوع التكرار
  tz.TZDateTime _getNextInstanceOfDateTime(
      DateTime scheduledTime, RepeatInterval repeatInterval) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    if (scheduledDateTime.isBefore(now)) {
      switch (repeatInterval) {
        case RepeatInterval.daily:
          scheduledDateTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            scheduledTime.hour,
            scheduledTime.minute,
            scheduledTime.second,
          );
          break;
        case RepeatInterval.weekly:
          scheduledDateTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            scheduledTime.hour,
            scheduledTime.minute,
            scheduledTime.second,
          );
          // إضافة أيام للوصول إلى نفس اليوم في الأسبوع
          final int daysToAdd = scheduledTime.weekday - now.weekday;
          if (daysToAdd < 0) {
            scheduledDateTime = scheduledDateTime.add(Duration(days: daysToAdd + 7));
          } else {
            scheduledDateTime = scheduledDateTime.add(Duration(days: daysToAdd));
          }
          break;
        case RepeatInterval.monthly:
          scheduledDateTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            scheduledTime.day,
            scheduledTime.hour,
            scheduledTime.minute,
            scheduledTime.second,
          );
          // إذا كان اليوم في الشهر الحالي قد مر، انتقل للشهر التالي
          if (scheduledDateTime.isBefore(now)) {
            scheduledDateTime = tz.TZDateTime(
              tz.local,
              now.year,
              now.month + 1,
              scheduledTime.day,
              scheduledTime.hour,
              scheduledTime.minute,
              scheduledTime.second,
            );
          }
          break;
      }
      
      // إذا كان الوقت المحسوب لا يزال في الماضي، أضف وحدة زمنية إضافية
      if (scheduledDateTime.isBefore(now)) {
        switch (repeatInterval) {
          case RepeatInterval.daily:
            scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
            break;
          case RepeatInterval.weekly:
            scheduledDateTime = scheduledDateTime.add(const Duration(days: 7));
            break;
          case RepeatInterval.monthly:
            // إضافة شهر آخر (تقريبًا 30 يومًا)
            scheduledDateTime = tz.TZDateTime(
              tz.local,
              scheduledDateTime.year,
              scheduledDateTime.month + 1,
              scheduledDateTime.day,
              scheduledDateTime.hour,
              scheduledDateTime.minute,
              scheduledDateTime.second,
            );
            break;
        }
      }
    }
    
    return scheduledDateTime;
  }
}
// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_service.dart';

class NotificationService {
  // Singleton implementation
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AthkarService _athkarService = AthkarService();

  // تهيئة الإشعارات
  Future<void> initialize() async {
    // تهيئة المناطق الزمنية
    tz_data.initializeTimeZones();
    final String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    // تهيئة إعدادات الإشعارات
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // طلب الأذونات
    await _requestPermissions();
  }

  // طلب أذونات الإشعارات
  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestPermission();
    }

    final DarwinFlutterLocalNotificationsPlugin? iOSImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            DarwinFlutterLocalNotificationsPlugin>();

    if (iOSImplementation != null) {
      await iOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // معالجة استلام الإشعارات (iOS)
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // يمكنك هنا تنفيذ أي إجراء عند استلام الإشعار على iOS
  }

  // معالجة النقر على الإشعارات
  void onDidReceiveNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // استخراج معرف الفئة وموقع التصفح (إن وجد)
      final parts = payload.split(':');
      final categoryId = parts[0];

      // يمكنك هنا التنقل إلى شاشة الأذكار المحددة
      // على سبيل المثال، يمكنك تخزين مرجع للـcontext أو استخدام navigatorKey
    }
  }

  // جدولة إشعارات الأذكار بناءً على الفئة والوقت
  Future<void> scheduleAthkarNotification(
      AthkarCategory category, TimeOfDay notificationTime) async {
    // إنشاء معرف فريد للإشعار بناءً على معرف الفئة
    final int notificationId = _getNotificationIdFromCategoryId(category.id);

    // إعداد الوقت المطلوب للإشعار
    final tz.TZDateTime scheduledDate = _getScheduledDate(notificationTime);

    // الحصول على عنوان ونص الإشعار
    final notificationTitle = category.notifyTitle ?? 'حان موعد ${category.title}';
    final notificationBody = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
    
    // الحصول على صوت الإشعار المخصص (إن وجد)
    String? soundName = category.notifySound;
    
    AndroidNotificationDetails androidDetails;
    if (soundName != null && soundName.isNotEmpty) {
      androidDetails = AndroidNotificationDetails(
        'athkar_channel_id',
        'أذكار',
        channelDescription: 'تنبيهات الأذكار',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        'athkar_channel_id',
        'أذكار',
        channelDescription: 'تنبيهات الأذكار',
        importance: Importance.high,
        priority: Priority.high,
      );
    }

    DarwinNotificationDetails iosDetails;
    if (soundName != null && soundName.isNotEmpty) {
      iosDetails = DarwinNotificationDetails(
        sound: '$soundName.aiff',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    } else {
      iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    }

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // جدولة الإشعار
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      notificationTitle,
      notificationBody,
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // تكرار يومي في نفس الوقت
      payload: category.id, // تضمين معرف الفئة كمعلومات إضافية
    );

    // حفظ الإعدادات
    await _saveNotificationSettings(category.id, true, notificationTime);
  }

  // جدولة إشعارات إضافية (إذا كان هناك أوقات متعددة)
  Future<void> scheduleAdditionalNotifications(AthkarCategory category) async {
    if (category.hasMultipleReminders && category.additionalNotifyTimes != null) {
      for (int i = 0; i < category.additionalNotifyTimes!.length; i++) {
        final timeString = category.additionalNotifyTimes![i];
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          
          if (hour != null && minute != null) {
            final additionalTime = TimeOfDay(hour: hour, minute: minute);
            
            // إنشاء معرف فريد للإشعار الإضافي
            final int notificationId = _getNotificationIdFromCategoryId(category.id) + (i + 1) * 1000;
            
            // إعداد الوقت المطلوب للإشعار
            final tz.TZDateTime scheduledDate = _getScheduledDate(additionalTime);
            
            // الحصول على عنوان ونص الإشعار
            final notificationTitle = category.notifyTitle ?? 'حان موعد ${category.title}';
            final notificationBody = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
            
            // إعدادات الإشعار
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'athkar_channel_id',
              'أذكار',
              channelDescription: 'تنبيهات الأذكار',
              importance: Importance.high,
              priority: Priority.high,
            );
            
            const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            );
            
            final NotificationDetails notificationDetails = NotificationDetails(
              android: androidDetails,
              iOS: iosDetails,
            );
            
            // جدولة الإشعار الإضافي
            await flutterLocalNotificationsPlugin.zonedSchedule(
              notificationId,
              notificationTitle,
              notificationBody,
              scheduledDate,
              notificationDetails,
              androidAllowWhileIdle: true,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
              payload: '${category.id}:additional_$i',
            );
          }
        }
      }
    }
  }

  // إلغاء إشعارات فئة معينة
  Future<void> cancelAthkarNotification(String categoryId) async {
    // إلغاء الإشعار الرئيسي
    final int notificationId = _getNotificationIdFromCategoryId(categoryId);
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    
    // إلغاء الإشعارات الإضافية (الحد الأقصى 10 إشعارات إضافية)
    for (int i = 1; i <= 10; i++) {
      final additionalId = notificationId + i * 1000;
      await flutterLocalNotificationsPlugin.cancel(additionalId);
    }
    
    // حفظ حالة إلغاء الإشعارات
    await _saveNotificationSettings(categoryId, false, null);
  }

  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // معرفة ما إذا كانت إشعارات فئة معينة مفعلة
  Future<bool> isNotificationEnabled(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_${categoryId}_enabled') ?? false;
  }

  // الحصول على وقت الإشعار المحفوظ لفئة معينة
  Future<TimeOfDay?> getNotificationTime(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('notification_${categoryId}_time');
    
    if (timeString != null) {
      final timeParts = timeString.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
    
    return null;
  }

  // جدولة جميع إشعارات الأذكار المحفوظة
  Future<void> scheduleAllSavedNotifications() async {
    // الحصول على جميع فئات الأذكار
    final categories = await _athkarService.loadAllAthkarCategories();
    
    for (final category in categories) {
      final isEnabled = await isNotificationEnabled(category.id);
      if (isEnabled) {
        final savedTime = await getNotificationTime(category.id);
        if (savedTime != null) {
          await scheduleAthkarNotification(category, savedTime);
          await scheduleAdditionalNotifications(category);
        } else if (category.notifyTime != null) {
          // استخدام الوقت الافتراضي المحدد في الفئة
          final defaultTimeParts = category.notifyTime!.split(':');
          if (defaultTimeParts.length == 2) {
            final hour = int.tryParse(defaultTimeParts[0]);
            final minute = int.tryParse(defaultTimeParts[1]);
            
            if (hour != null && minute != null) {
              final defaultTime = TimeOfDay(hour: hour, minute: minute);
              await scheduleAthkarNotification(category, defaultTime);
              await scheduleAdditionalNotifications(category);
            }
          }
        }
      }
    }
  }

  // حفظ إعدادات الإشعارات
  Future<void> _saveNotificationSettings(
      String categoryId, bool isEnabled, TimeOfDay? notificationTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_${categoryId}_enabled', isEnabled);
    
    if (notificationTime != null) {
      final timeString = '${notificationTime.hour}:${notificationTime.minute}';
      await prefs.setString('notification_${categoryId}_time', timeString);
    }
  }

  // إنشاء معرف فريد للإشعار من معرف الفئة
  int _getNotificationIdFromCategoryId(String categoryId) {
    // استخدام قيمة الهاش لإنشاء رقم فريد
    return categoryId.hashCode;
  }

  // الحصول على التاريخ والوقت المجدول للإشعار
  tz.TZDateTime _getScheduledDate(TimeOfDay notificationTime) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );
    
    // إذا كان الوقت قد فات اليوم، جدول للغد
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
}
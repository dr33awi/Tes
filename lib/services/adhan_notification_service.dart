// lib/services/adhan_notification_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class AdhanNotificationService {
  // تطبيق نمط Singleton
  static final AdhanNotificationService _instance = AdhanNotificationService._internal();
  factory AdhanNotificationService() => _instance;
  AdhanNotificationService._internal();

  // تعريف كائن الإشعارات
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // إعدادات تفضيلات الإشعارات
  bool _isNotificationEnabled = true;
  Map<String, bool> _prayerNotificationSettings = {
    'الفجر': true,
    'الشروق': false,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };

  // دالة التهيئة لخدمة الإشعارات
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    // تعريف إعدادات الإشعارات للأندرويد
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // تعريف إعدادات الإشعارات للآيفون
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // يمكن معالجة الإشعارات المستلمة هنا
      },
    );
    
    // تطبيق الإعدادات
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // تهيئة الإشعارات مع معالج الإجراءات
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // يمكن معالجة النقر على الإشعارات هنا
      },
    );
    
    // طلب إذن الإشعارات على نظام iOS
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    // تحميل الإعدادات المحفوظة
    await _loadNotificationSettings();
  }
  
  // تحميل إعدادات الإشعارات المحفوظة
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل حالة تفعيل الإشعارات
      _isNotificationEnabled = prefs.getBool('adhan_notification_enabled') ?? true;
      
      // تحميل إعدادات كل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        final enabled = prefs.getBool('adhan_notification_${prayer}') ?? 
            _prayerNotificationSettings[prayer]!;
        _prayerNotificationSettings[prayer] = enabled;
      }
    } catch (e) {
      debugPrint('خطأ في تحميل إعدادات الإشعارات: $e');
    }
  }
  
  // حفظ إعدادات الإشعارات
  Future<void> saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ حالة تفعيل الإشعارات
      await prefs.setBool('adhan_notification_enabled', _isNotificationEnabled);
      
      // حفظ إعدادات كل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        await prefs.setBool(
          'adhan_notification_${prayer}', 
          _prayerNotificationSettings[prayer]!
        );
      }
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات الإشعارات: $e');
    }
  }
  
  // جدولة إشعار لوقت صلاة
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    int notificationId = 0,
  }) async {
    // تحقق من تفعيل الإشعارات وإعدادات الصلاة المحددة
    if (!_isNotificationEnabled || !(_prayerNotificationSettings[prayerName] ?? false)) {
      return;
    }
    
    // التأكد من أن وقت الصلاة في المستقبل
    if (prayerTime.isBefore(DateTime.now())) {
      return;
    }
    
    try {
      // إعدادات الإشعارات للأندرويد
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'adhan_channel_id',
        'مواقيت الصلاة',
        channelDescription: 'إشعارات مواقيت الصلاة',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        styleInformation: const BigTextStyleInformation(''),
      );
      
      // إعدادات الإشعارات للآيفون
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: 'adhan.mp3',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // تجميع الإعدادات
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // إنشاء محتوى الإشعار
      final title = 'حان وقت صلاة $prayerName';
      final body = 'حان الآن وقت صلاة $prayerName';
      
      // جدولة الإشعار
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      debugPrint('تمت جدولة إشعار لصلاة $prayerName في $scheduledDate');
    } catch (e) {
      debugPrint('خطأ في جدولة الإشعار: $e');
    }
  }
  
  // جدولة إشعارات جميع الصلوات للأوقات المحددة
  Future<void> scheduleAllPrayerNotifications(List<Map<String, dynamic>> prayerTimes) async {
    // إلغاء جميع الإشعارات السابقة
    await _flutterLocalNotificationsPlugin.cancelAll();
    
    // جدولة إشعارات جديدة لكل صلاة
    for (int i = 0; i < prayerTimes.length; i++) {
      final prayer = prayerTimes[i];
      await schedulePrayerNotification(
        prayerName: prayer['name'],
        prayerTime: prayer['time'],
        notificationId: i,
      );
    }
  }
  
  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // دوال للحصول على/تعيين الإعدادات
  bool get isNotificationEnabled => _isNotificationEnabled;
  
  set isNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveNotificationSettings();
  }
  
  Map<String, bool> get prayerNotificationSettings => _prayerNotificationSettings;
  
  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    if (_prayerNotificationSettings.containsKey(prayer)) {
      _prayerNotificationSettings[prayer] = enabled;
      await saveNotificationSettings();
    }
  }
}
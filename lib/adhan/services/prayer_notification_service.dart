// lib/adhan/services/prayer_notification_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:adhan/adhan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';

/// خدمة إشعارات مواعيد الصلاة المحسنة
class PrayerNotificationService {
  // تطبيق نمط Singleton
  static final PrayerNotificationService _instance = PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

  // المكونات المساعدة
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  final BatteryOptimizationService _batteryOptimizationService = BatteryOptimizationService();
  final DoNotDisturbService _doNotDisturbService = DoNotDisturbService();
  
  // مُعرّفات الإنذار للعمل في الخلفية
  static const int fajrAlarmId = 2001;
  static const int sunriseAlarmId = 2002;
  static const int dhuhrAlarmId = 2003;
  static const int asrAlarmId = 2004;
  static const int maghribAlarmId = 2005;
  static const int ishaAlarmId = 2006;
  
  // حالة الإشعارات
  bool _isNotificationEnabled = true;
  Map<String, bool> _prayerNotificationSettings = {
    'الفجر': true,
    'الشروق': false,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };
  
  // المنطقة الزمنية
  String _deviceTimeZone = 'UTC';
  
  // حالة التهيئة
  bool _isInitialized = false;
  BuildContext? _context;
  
  /// تهيئة الخدمة
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Prayer notification service already initialized');
      return true;
    }
    
    try {
      // تهيئة المناطق الزمنية
      tz_data.initializeTimeZones();
      
      // الحصول على المنطقة الزمنية للجهاز
      try {
        _deviceTimeZone = await FlutterNativeTimezoneLatest.getLocalTimezone();
        // ضبط المنطقة الزمنية
        tz.setLocalLocation(tz.getLocation(_deviceTimeZone));
        debugPrint('Device timezone: $_deviceTimeZone');
      } catch (e) {
        debugPrint('Error getting device timezone: $e');
        // الرجوع إلى منطقة زمنية افتراضية آمنة
        _deviceTimeZone = 'UTC';
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
      
      // تهيئة إعدادات الإشعارات لنظام Android
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      // إعدادات نظام iOS
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            requestCriticalPermission: true, // للسماح بتجاوز وضع عدم الإزعاج
          );
          
      // دمج الإعدادات
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // تهيئة مكون الإشعارات
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      
      // طلب الأذونات
      await _requestPermissions();
      
      // إنشاء قنوات الإشعارات لنظام Android
      await _createNotificationChannels();
      
      // تحميل الإعدادات المحفوظة
      await _loadNotificationSettings();
      
      // تهيئة Android Alarm Manager للإشعارات الأكثر موثوقية
      if (Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }
      
      // فحص تحسين البطارية على Android
      if (Platform.isAndroid) {
        await _saveBatteryOptimizationStatus();
      }
      
      _isInitialized = true;
      debugPrint('Prayer notification service initialized successfully');
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error initializing service', 
        e
      );
      return false;
    }
  }
  
  /// حفظ حالة تحسين البطارية
  Future<void> _saveBatteryOptimizationStatus() async {
    try {
      if (Platform.isAndroid) {
        final isOptimized = await _batteryOptimizationService.isBatteryOptimizationEnabled();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_battery_optimization_prayer', isOptimized);
      }
    } catch (e) {
      debugPrint('Error saving battery optimization status: $e');
    }
  }
  
  /// طلب أذونات الإشعارات
  Future<bool> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        // بالنسبة لنظام Android 13+ (يلزم إذن الإشعارات)
        final isGranted = await Permission.notification.request().isGranted;
        
        // طلب إذن المنبهات الدقيقة (API 31+)
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
            
        return isGranted;
      } else if (Platform.isIOS) {
        // بالنسبة لنظام iOS
        final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
                
        bool? iosPermission = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true, // للتنبيهات المهمة (تجاوز وضع عدم الإزعاج)
        );
        
        return iosPermission ?? false;
      }
      
      return false;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error requesting notification permission', 
        e
      );
      return false;
    }
  }
  
  /// طلب الأذونات اللازمة
  Future<void> _requestPermissions() async {
    try {
      await requestNotificationPermission();
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }
  
  /// التحقق من حالة إذن الإشعارات
  Future<bool> checkNotificationPermission() async {
    try {
      return await Permission.notification.status.isGranted;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }
  
  /// إنشاء قنوات الإشعارات لنظام Android
  Future<void> _createNotificationChannels() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        // قناة الإشعارات الرئيسية
        const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
          'prayer_times_channel',
          'مواقيت الصلاة',
          description: 'إشعارات مواقيت الصلاة',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF4DB6AC),
        );
        
        // قناة للإشعارات الاختبارية
        const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
          'prayer_test_channel',
          'اختبار مواقيت الصلاة',
          description: 'قناة اختبار إشعارات مواقيت الصلاة',
          importance: Importance.high,
        );
        
        // إنشاء القنوات
        await androidPlugin.createNotificationChannel(mainChannel);
        await androidPlugin.createNotificationChannel(testChannel);
      }
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error creating notification channels', 
        e
      );
    }
  }
  
  /// تحميل إعدادات الإشعارات
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل حالة التبديل الرئيسي
      _isNotificationEnabled = prefs.getBool('prayer_notification_master_enabled') ?? true;
      
      // تحميل إعدادات كل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        final enabled = prefs.getBool('prayer_notification_$prayer') ?? 
            _prayerNotificationSettings[prayer]!;
        _prayerNotificationSettings[prayer] = enabled;
      }
      
      debugPrint('Notification settings loaded successfully');
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error loading notification settings', 
        e
      );
    }
  }
  
  /// حفظ إعدادات الإشعارات
  Future<void> saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ حالة التبديل الرئيسي
      await prefs.setBool('prayer_notification_master_enabled', _isNotificationEnabled);
      
      // حفظ إعدادات كل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        await prefs.setBool(
          'prayer_notification_$prayer', 
          _prayerNotificationSettings[prayer]!
        );
      }
      
      // حفظ وقت آخر تحديث
      await prefs.setString(
        'prayer_notification_last_updated',
        DateTime.now().toIso8601String()
      );
      
      debugPrint('Notification settings saved successfully');
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error saving notification settings', 
        e
      );
    }
  }
  
  /// معالجة الضغط على الإشعار
  void _onNotificationResponse(NotificationResponse response) {
    try {
      final String? payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        debugPrint('Notification tapped with payload: $payload');
        
        // يمكن هنا حفظ بيانات لاستخدامها في التنقل
        _saveNotificationInteraction(payload);
      }
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error handling notification tap', 
        e
      );
    }
  }
  
  /// حفظ بيانات التفاعل مع الإشعار
  Future<void> _saveNotificationInteraction(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ أن التطبيق تم فتحه من الإشعار
      await prefs.setBool('opened_from_prayer_notification', true);
      await prefs.setString('prayer_notification_payload', payload);
      
      // تحديث إحصائيات التفاعل
      final String prayerName = payload.split(':')[0];
      final countKey = 'prayer_notification_interaction_count_$prayerName';
      final int currentCount = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, currentCount + 1);
      
      // حفظ وقت التفاعل
      await prefs.setString(
        'prayer_notification_last_interaction',
        DateTime.now().toIso8601String()
      );
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error saving notification interaction', 
        e
      );
    }
  }
  
  /// جدولة إشعار لصلاة محددة
  Future<bool> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    required int notificationId,
  }) async {
    // التحقق من تفعيل الإشعارات لهذه الصلاة
    if (!_isNotificationEnabled || !(_prayerNotificationSettings[prayerName] ?? false)) {
      return false;
    }
    
    // التحقق من أن وقت الصلاة في المستقبل
    final now = DateTime.now();
    if (prayerTime.isBefore(now)) {
      return false;
    }
    
    try {
      // إعداد تفاصيل الإشعار
      final androidDetails = AndroidNotificationDetails(
        'prayer_times_channel',
        'مواقيت الصلاة',
        channelDescription: 'إشعارات مواقيت الصلاة',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const BigTextStyleInformation(''),
        playSound: true,
        enableVibration: true,
        color: _getPrayerColor(prayerName),
        ledColor: _getPrayerColor(prayerName),
        ledOnMs: 1000,
        ledOffMs: 500,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true, // للظهور حتى على شاشة القفل
        visibility: NotificationVisibility.public,
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active, // لتجاوز وضع التركيز
        threadIdentifier: 'prayer_times', // تجميع إشعارات الصلاة
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // محتوى الإشعار
      final title = 'حان وقت صلاة $prayerName';
      final body = _getNotificationBody(prayerName);
      
      // تحويل وقت الصلاة إلى TZDateTime
      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
      
      // جدولة الإشعار
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$prayerName:${prayerTime.millisecondsSinceEpoch}',
      );
      
      // جدولة إنذار في الخلفية لنظام Android للمزيد من الموثوقية
      if (Platform.isAndroid) {
        await _scheduleBackgroundAlarm(prayerName, prayerTime, title, body);
      }
      
      // تتبع نجاح الجدولة
      await _trackScheduledNotification(prayerName, prayerTime);
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error scheduling notification for $prayerName', 
        e
      );
      
      // محاولة طريقة النسخ الاحتياطي
      try {
        await _scheduleBackupNotification(prayerName, prayerTime);
        return true;
      } catch (backupError) {
        _errorLoggingService.logError(
          'PrayerNotificationService', 
          'Backup scheduling also failed for $prayerName', 
          backupError
        );
        return false;
      }
    }
  }
  
  /// جدولة إشعار احتياطي
  Future<void> _scheduleBackupNotification(String prayerName, DateTime prayerTime) async {
    try {
      // استخدام معرّف مختلف للإشعار الاحتياطي
      final int notificationId = _getNotificationIdFromPrayerName(prayerName) + 50000;
      
      // إعدادات إشعار أبسط
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'prayer_times_backup_channel',
        'مواقيت الصلاة (احتياطي)',
        channelDescription: 'إشعارات احتياطية لمواقيت الصلاة',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // تحويل وقت الصلاة إلى TZDateTime
      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
      
      // جدولة الإشعار
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'تذكير: حان وقت صلاة $prayerName',
        _getNotificationBody(prayerName),
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$prayerName:backup:${prayerTime.millisecondsSinceEpoch}',
      );
      
      // تتبع الإشعار الاحتياطي
      await _trackBackupNotification(prayerName);
      
      debugPrint('Backup notification scheduled for $prayerName');
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error scheduling backup notification for $prayerName', 
        e
      );
    }
  }
  
  /// الحصول على نص الإشعار بناءً على اسم الصلاة
  String _getNotificationBody(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return 'حان الآن وقت صلاة الفجر. قم وصلِ قبل طلوع الشمس';
      case 'الشروق':
        return 'الشمس تشرق الآن. وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ';
      case 'الظهر':
        return 'حان الآن وقت صلاة الظهر. حي على الصلاة';
      case 'العصر':
        return 'حان الآن وقت صلاة العصر. حي على الفلاح';
      case 'المغرب':
        return 'حان الآن وقت صلاة المغرب. وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ غُرُوبِ الشَّمْسِ';
      case 'العشاء':
        return 'حان الآن وقت صلاة العشاء. أقم الصلاة لدلوك الشمس إلى غسق الليل';
      default:
        return 'حان الآن وقت الصلاة';
    }
  }
  
  /// تتبع جدولة الإشعار
  Future<void> _trackScheduledNotification(String prayerName, DateTime prayerTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'prayer_notification_scheduled_$prayerName';
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'prayer_time': prayerTime.toIso8601String(),
      };
      await prefs.setString(key, json.encode(data));
      
      // تحديث إحصائيات الجدولة
      final countKey = 'prayer_notification_schedule_count_$prayerName';
      final int currentCount = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, currentCount + 1);
    } catch (e) {
      debugPrint('Error tracking scheduled notification: $e');
    }
  }
  
  /// تتبع الإشعار الاحتياطي
  Future<void> _trackBackupNotification(String prayerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'prayer_notification_backup_$prayerName';
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(key, json.encode(data));
      
      // تحديث إحصائيات النسخ الاحتياطي
      final countKey = 'prayer_notification_backup_count_$prayerName';
      final int currentCount = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, currentCount + 1);
    } catch (e) {
      debugPrint('Error tracking backup notification: $e');
    }
  }
  
  /// الحصول على لون لصلاة محددة
  Color _getPrayerColor(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return const Color(0xFF5B68D9); // أزرق للفجر
      case 'الشروق':
        return const Color(0xFFFF9E0D); // برتقالي للشروق
      case 'الظهر':
        return const Color(0xFFFFB746); // أصفر ذهبي للظهر
      case 'العصر':
        return const Color(0xFFFF8A65); // برتقالي محمر للعصر
      case 'المغرب':
        return const Color(0xFF5C6BC0); // أزرق للمغرب
      case 'العشاء':
        return const Color(0xFF1A237E); // أزرق داكن للعشاء
      default:
        return const Color(0xFF4DB6AC); // اللون الافتراضي
    }
  }
  
  /// جدولة إشعارات مواقيت الصلاة
  Future<int> scheduleAllPrayerNotifications(List<Map<String, dynamic>> prayerTimes) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // إلغاء الإشعارات السابقة
    await cancelAllNotifications();
    
    // التحقق من الأذونات قبل الجدولة
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      return 0;
    }
    
    // عداد الإشعارات المجدولة
    int scheduledCount = 0;
    
    // جدولة الإشعارات الجديدة
    for (int i = 0; i < prayerTimes.length; i++) {
      final prayer = prayerTimes[i];
      final success = await schedulePrayerNotification(
        prayerName: prayer['name'],
        prayerTime: prayer['time'],
        notificationId: i,
      );
      
      if (success) {
        scheduledCount++;
      }
    }
    
    // حفظ إحصائيات الجدولة
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('prayer_notifications_scheduled_count', scheduledCount);
      await prefs.setString(
        'prayer_notifications_last_scheduled',
        DateTime.now().toIso8601String()
      );
    } catch (e) {
      debugPrint('Error saving scheduling statistics: $e');
    }
    
    return scheduledCount;
  }
  
  /// جدولة إنذار في الخلفية (لنظام Android)
  Future<void> _scheduleBackgroundAlarm(
      String prayerName, DateTime prayerTime, String title, String body) async {
    if (!Platform.isAndroid) return;
    
    try {
      int alarmId = _getAlarmIdForPrayer(prayerName);
      
      // ضبط وقت الإنذار
      DateTime scheduledDateTime = prayerTime;
      
      // إذا كان الوقت قد مر اليوم، جدوله لليوم التالي
      final now = DateTime.now();
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          prayerTime.hour,
          prayerTime.minute,
        );
      }
      
      // جدولة الإنذار
      await AndroidAlarmManager.oneShotAt(
        scheduledDateTime,
        alarmId,
        _backgroundNotificationCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
        params: {
          'prayerName': prayerName,
          'notificationId': _getNotificationIdFromPrayerName(prayerName),
          'title': title,
          'body': body,
        },
      );
      
      // حفظ معرّف الإنذار
      await _saveAlarmId(prayerName, alarmId);
      
      debugPrint('Background alarm scheduled for $prayerName at ${scheduledDateTime.toIso8601String()}');
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error scheduling background alarm for $prayerName', 
        e
      );
    }
  }
  
  /// دالة استدعاء الإنذار في الخلفية
  @pragma('vm:entry-point')
  static Future<void> _backgroundNotificationCallback(int id, Map<String, dynamic>? params) async {
    if (params == null) return;
    
    try {
      // تهيئة مكوّن الإشعارات
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      
      // تهيئة المكوّن قبل عرض الإشعارات
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      
      // استخراج بيانات الإشعار
      final prayerName = params['prayerName'] as String;
      final notificationId = params['notificationId'] as int;
      final title = params['title'] as String;
      final body = params['body'] as String;
      
      // تفاصيل الإشعار المعززة
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'prayer_times_channel',
        'مواقيت الصلاة',
        channelDescription: 'إشعارات مواقيت الصلاة',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // حفظ البيانات للتنقل
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('opened_from_prayer_notification', true);
      await prefs.setString('prayer_notification_payload', prayerName);
      
      // عرض الإشعار
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: prayerName,
      );
      
      debugPrint('Background notification showed successfully for prayer: $prayerName');
    } catch (e) {
      print('Error in background notification callback: $e');
    }
  }
  
  /// حفظ معرّف الإنذار
  Future<void> _saveAlarmId(String prayerName, int alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'prayer_alarm_id_$prayerName';
      await prefs.setInt(key, alarmId);
      
      // حفظ في قائمة جميع معرّفات الإنذار
      final allAlarmsKey = 'all_prayer_alarm_ids';
      final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
      
      final alarmKey = '${prayerName}_$alarmId';
      if (!allAlarms.contains(alarmKey)) {
        allAlarms.add(alarmKey);
        await prefs.setStringList(allAlarmsKey, allAlarms);
      }
    } catch (e) {
      debugPrint('Error saving alarm ID: $e');
    }
  }
  
  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    try {
      // إلغاء جميع الإشعارات المعلقة
      await _notificationsPlugin.cancelAll();
      
      if (Platform.isAndroid) {
        // الحصول على جميع معرّفات الإنذار المحفوظة
        final prefs = await SharedPreferences.getInstance();
        final allAlarmsKey = 'all_prayer_alarm_ids';
        final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
        
        // إلغاء جميع الإنذارات المعروفة
        for (final alarmKey in allAlarms) {
          final parts = alarmKey.split('_');
          if (parts.length >= 2) {
            final alarmId = int.tryParse(parts.last) ?? 0;
            if (alarmId > 0) {
              await AndroidAlarmManager.cancel(alarmId);
            }
          }
        }
        
        // إلغاء الإنذارات الافتراضية للأمان
        await AndroidAlarmManager.cancel(fajrAlarmId);
        await AndroidAlarmManager.cancel(sunriseAlarmId);
        await AndroidAlarmManager.cancel(dhuhrAlarmId);
        await AndroidAlarmManager.cancel(asrAlarmId);
        await AndroidAlarmManager.cancel(maghribAlarmId);
        await AndroidAlarmManager.cancel(ishaAlarmId);
        
        // مسح جميع معرّفات الإشعار المحفوظة
        await prefs.remove(allAlarmsKey);
      }
      
      // تتبع إعادة ضبط الإشعارات
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_notifications_reset', DateTime.now().toIso8601String());
      
      debugPrint('All prayer notifications cancelled successfully');
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error canceling all notifications', 
        e
      );
    }
  }
  
  /// اختبار الإشعارات الفورية
  Future<void> testImmediateNotification() async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'prayer_test_channel',
        'اختبار مواقيت الصلاة',
        channelDescription: 'قناة اختبار إشعارات مواقيت الصلاة',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
      );
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notificationsPlugin.show(
        0,
        'اختبار إشعارات مواقيت الصلاة',
        'هذا إشعار تجريبي للتأكد من عمل نظام إشعارات الصلاة',
        notificationDetails,
        payload: 'test_prayer_notification',
      );
      
      // تتبع إشعار الاختبار
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_test_notification_sent', DateTime.now().toIso8601String());
      
      debugPrint('Test prayer notification sent successfully');
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error showing test notification', 
        e
      );
    }
  }
  
  /// الحصول على معرّف الإنذار بناءً على اسم الصلاة
  int _getAlarmIdForPrayer(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return fajrAlarmId;
      case 'الشروق':
        return sunriseAlarmId;
      case 'الظهر':
        return dhuhrAlarmId;
      case 'العصر':
        return asrAlarmId;
      case 'المغرب':
        return maghribAlarmId;
      case 'العشاء':
        return ishaAlarmId;
      default:
        return prayerName.hashCode.abs() % 1000 + 3000;
    }
  }
  
  /// الحصول على معرّف الإشعار من اسم الصلاة
  int _getNotificationIdFromPrayerName(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return 1001;
      case 'الشروق':
        return 1002;
      case 'الظهر':
        return 1003;
      case 'العصر':
        return 1004;
      case 'المغرب':
        return 1005;
      case 'العشاء':
        return 1006;
      default:
        return prayerName.hashCode.abs() % 100000;
    }
  }
  
  /// الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error getting pending notifications', 
        e
      );
      return [];
    }
  }
  
  /// ضبط البيانات الخارجية
  void setContext(BuildContext context) {
    _context = context;
  }
  
  /// الحصول على إحصائيات الإشعارات
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الإشعارات المعلقة
      final List<PendingNotificationRequest> pendingNotifications = 
          await getPendingNotifications();
      
      // تجميع الإحصائيات
      final stats = {
        'notifications_enabled': _isNotificationEnabled,
        'pending_count': pendingNotifications.length,
        'prayer_settings': Map<String, bool>.from(_prayerNotificationSettings),
        'last_scheduled': prefs.getString('prayer_notifications_last_scheduled') ?? 'Never',
        'last_schedule_count': prefs.getInt('prayer_notifications_scheduled_count') ?? 0,
        'last_reset': prefs.getString('prayer_notifications_reset') ?? 'Never',
        'device_timezone': _deviceTimeZone,
      };
      
      return stats;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerNotificationService', 
        'Error getting notification statistics', 
        e
      );
      return {
        'error': e.toString(),
        'pending_count': 0,
      };
    }
  }
  
  // الخصائص العامة
  
  bool get isNotificationEnabled => _isNotificationEnabled;
  
  set isNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveNotificationSettings();
  }
  
  Map<String, bool> get prayerNotificationSettings => Map.unmodifiable(_prayerNotificationSettings);
  
  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    if (_prayerNotificationSettings.containsKey(prayer)) {
      _prayerNotificationSettings[prayer] = enabled;
      await saveNotificationSettings();
    }
  }
  
  bool get isInitialized => _isInitialized;
}
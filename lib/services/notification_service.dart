// lib/services/notification/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// المكتبات الداخلية للتطبيق
import 'battery_optimization_service.dart';
import 'error_logging_service.dart';
import 'ios_notification_service.dart';
import 'notification_grouping_service.dart';
import 'do_not_disturb_service.dart';
import '../models/notification_model.dart';

/// نموذج بيانات الإشعار الموحد
class NotificationData {
  final String id;
  final String title;
  final String body;
  final String? channelId;
  final String? channelName;
  final String? icon;
  final String? payload;
  final Color? color;
  final Color? ledColor;
  final bool isRecurring;
  final bool isImportant;
  final bool bypassDnd;
  final List<String>? additionalTimes;
  final String? soundName;
  final Map<String, dynamic>? extraData;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    this.channelId,
    this.channelName,
    this.icon,
    this.payload,
    this.color,
    this.ledColor,
    this.isRecurring = false,
    this.isImportant = false,
    this.bypassDnd = false,
    this.additionalTimes,
    this.soundName,
    this.extraData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'channelId': channelId,
      'channelName': channelName,
      'icon': icon,
      'payload': payload,
      'color': color?.value,
      'ledColor': ledColor?.value,
      'isRecurring': isRecurring,
      'isImportant': isImportant,
      'bypassDnd': bypassDnd,
      'additionalTimes': additionalTimes,
      'soundName': soundName,
      'extraData': extraData,
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      channelId: json['channelId'],
      channelName: json['channelName'],
      icon: json['icon'],
      payload: json['payload'],
      color: json['color'] != null ? Color(json['color']) : null,
      ledColor: json['ledColor'] != null ? Color(json['ledColor']) : null,
      isRecurring: json['isRecurring'] ?? false,
      isImportant: json['isImportant'] ?? false,
      bypassDnd: json['bypassDnd'] ?? false,
      additionalTimes: json['additionalTimes'] != null
          ? List<String>.from(json['additionalTimes'])
          : null,
      soundName: json['soundName'],
      extraData: json['extraData'],
    );
  }
}

/// خدمة الإشعارات الموحدة للتطبيق
class NotificationService {
  // نمط Singleton للتأكد من وجود نسخة واحدة فقط
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  
  NotificationService._internal();

  // الخدمات المساعدة
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BatteryOptimizationService _batteryOptimizationService = BatteryOptimizationService();
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  final NotificationGroupingService _notificationGroupingService = NotificationGroupingService();
  final DoNotDisturbService _doNotDisturbService = DoNotDisturbService();
  late final IOSNotificationService _iosNotificationService;

  // تخزين المنطقة الزمنية للجهاز
  String _deviceTimeZone = 'UTC';
  
  // قنوات الإشعارات
  static const String defaultChannelId = 'default_channel';
  static const String defaultChannelName = 'Default Notifications';
  static const String importantChannelId = 'important_channel';
  static const String importantChannelName = 'Important Notifications';
  static const String criticalChannelId = 'critical_channel';
  static const String criticalChannelName = 'Critical Notifications';
  
  // معرفات الإنذارات للإشعارات الخلفية
  static const int dailyAlarmBaseId = 10000;
  static const int weeklyAlarmBaseId = 20000;
  static const int monthlyAlarmBaseId = 30000;
  static const int backupAlarmBaseId = 50000;
  
  // تتبع حالة التهيئة
  bool _isInitialized = false;
  
  /// تهيئة خدمة الإشعارات
  Future<bool> initialize({
    Function(NotificationResponse)? onNotificationTap,
    bool requestPermissions = true,
    bool checkBatteryOptimization = true,
  }) async {
    if (_isInitialized) return true;
    
    try {
      // تسجيل بداية التهيئة
      _errorLoggingService.logInfo('Initializing notification service');
      
      // تهيئة المناطق الزمنية
      tz_data.initializeTimeZones();
      
      // الحصول على المنطقة الزمنية للجهاز
      try {
        _deviceTimeZone = await FlutterNativeTimezoneLatest.getLocalTimezone();
        // تعيين المنطقة الزمنية
        tz.setLocalLocation(tz.getLocation(_deviceTimeZone));
        _errorLoggingService.logInfo('Device timezone: $_deviceTimeZone');
      } catch (e) {
        _errorLoggingService.logError('Error getting device timezone', e);
        // التراجع إلى قيمة افتراضية آمنة
        _deviceTimeZone = 'UTC';
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // تهيئة إعدادات الإشعارات لنظام Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // تهيئة iOS
      _iosNotificationService = IOSNotificationService();
      final DarwinInitializationSettings initializationSettingsDarwin =
          _iosNotificationService.getInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      // تهيئة Plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap ?? _defaultNotificationTapHandler,
        onDidReceiveBackgroundNotificationResponse: _backgroundNotificationTapHandler,
      );

      // طلب الأذونات إذا كان مطلوبًا
      if (requestPermissions) {
        await _requestPermissions();
      }
      
      // تهيئة مدير الإنذار لنظام Android للإشعارات الأكثر موثوقية
      if (Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
        
        // التحقق من تحسين البطارية إذا كان مطلوبًا
        if (checkBatteryOptimization) {
          await _checkBatteryOptimization();
        }
      }
      
      // إعادة جدولة الإشعارات المحفوظة
      await _rescheduleAllSavedNotifications();
      
      _isInitialized = true;
      _errorLoggingService.logInfo('Notification service initialized successfully');
      return true;
    } catch (e) {
      _errorLoggingService.logError('Error initializing notification service', e);
      return false;
    }
  }

  // التحقق من تحسين البطارية
  Future<void> _checkBatteryOptimization() async {
    try {
      if (Platform.isAndroid) {
        final isOptimized = await _batteryOptimizationService.isBatteryOptimizationEnabled();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_battery_optimization', isOptimized);
        
        _errorLoggingService.logInfo('Battery optimization status: $isOptimized');
      }
    } catch (e) {
      _errorLoggingService.logError('Error checking battery optimization', e);
    }
  }

  // طلب أذونات الإشعارات
  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // لنظام Android 13+ (مستوى API 33 وما فوق)
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
            
        // طلب إذن الإنذارات الدقيقة لـ API 31+
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
            
        _errorLoggingService.logInfo('Android notification permissions requested');
        return true;
      } else if (Platform.isIOS) {
        // لنظام iOS
        final granted = await _iosNotificationService.requestPermissions(
          flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin
        );
        _errorLoggingService.logInfo('iOS notification permissions requested: $granted');
        return granted;
      }
      return false;
    } catch (e) {
      _errorLoggingService.logError('Error requesting notification permissions', e);
      return false;
    }
  }

  // معالج النقر على الإشعار الافتراضي
  void _defaultNotificationTapHandler(NotificationResponse response) async {
    try {
      final String? payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('opened_from_notification', true);
        await prefs.setString('notification_payload', payload);
        
        _errorLoggingService.logInfo('Notification tapped with payload: $payload');
        
        // تتبع تفاعل الإشعار
        await _trackNotificationInteraction(payload);
      }
    } catch (e) {
      _errorLoggingService.logError('Error handling notification tap', e);
    }
  }
  
  // معالج النقر على الإشعار في الخلفية
  @pragma('vm:entry-point')
  static void _backgroundNotificationTapHandler(NotificationResponse details) {
    // هذه الدالة تعمل في الخلفية
    // لا يمكن استخدام المتغيرات المرتبطة بالفئة هنا
    // يمكن استخدام SharedPreferences لتخزين بيانات التفاعل
    
    try {
      // يمكن تنفيذ عمليات بسيطة هنا
      // أو استخدام MethodChannel للتواصل مع الكود الأصلي
    } catch (e) {
      print('Error handling background notification tap: $e');
    }
  }
  
  // تتبع تفاعل الإشعار
  Future<void> _trackNotificationInteraction(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ وقت التفاعل
      final key = 'notification_interaction_${payload}_${DateTime.now().day}';
      await prefs.setString(key, DateTime.now().toIso8601String());
      
      // زيادة عدد التفاعلات
      final countKey = 'notification_interaction_count_$payload';
      final int currentCount = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, currentCount + 1);
      
      _errorLoggingService.logInfo('Tracked notification interaction for: $payload');
    } catch (e) {
      _errorLoggingService.logError('Error tracking notification interaction', e);
    }
  }

  /// عرض إشعار فوري
  Future<bool> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? icon,
    Color? color,
    Color? ledColor,
    bool isImportant = false,
    bool bypassDnd = false,
    String? soundName,
    String? groupKey,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // تحديد قناة الإشعارات
      final notificationChannelId = channelId ?? (isImportant ? 
          (bypassDnd ? criticalChannelId : importantChannelId) : 
          defaultChannelId);
          
      final notificationChannelName = channelName ?? (isImportant ? 
          (bypassDnd ? criticalChannelName : importantChannelName) : 
          defaultChannelName);
      
      // إنشاء تفاصيل الإشعار
      final androidDetails = AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription: 'App notifications',
        importance: isImportant ? Importance.high : Importance.default_,
        priority: isImportant ? Priority.high : Priority.default_,
        color: color,
        ledColor: ledColor,
        ledOnMs: ledColor != null ? 1000 : null,
        ledOffMs: ledColor != null ? 500 : null,
        icon: icon ?? '@mipmap/ic_launcher',
        fullScreenIntent: isImportant,
        category: _getNotificationCategory(isImportant),
        groupKey: groupKey,
        styleInformation: BigTextStyleInformation(body),
        sound: soundName != null ? RawResourceAndroidNotificationSound(soundName) : null,
      );
      
      final iosDetails = _iosNotificationService.getNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: _getIOSInterruptionLevel(isImportant, bypassDnd),
        threadIdentifier: groupKey,
        sound: soundName,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // إنشاء معرف فريد للإشعار
      final notificationId = _generateUniqueId(id);
      
      // عرض الإشعار
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload ?? id,
      );
      
      // التحقق من وضع عدم الإزعاج
      if (bypassDnd && await _doNotDisturbService.isDndEnabled()) {
        _errorLoggingService.logInfo('DND is enabled, notification sent with bypass: $id');
      }
      
      // تتبع عرض الإشعار
      await _trackNotificationShown(id);
      
      _errorLoggingService.logInfo('Notification shown: $id');
      return true;
    } catch (e) {
      _errorLoggingService.logError('Error showing notification', e);
      
      // محاولة استخدام طريقة احتياطية إذا فشلت الطريقة الأساسية
      try {
        await _showBackupNotification(id, title, body, payload);
        return true;
      } catch (backupError) {
        _errorLoggingService.logError('Error with backup notification', backupError);
        return false;
      }
    }
  }
  
  // عرض إشعار احتياطي
  Future<void> _showBackupNotification(
    String id, 
    String title, 
    String body, 
    String? payload
  ) async {
    // استخدام إعدادات بسيطة للإشعار الاحتياطي
    final androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Channel',
      channelDescription: 'For backup notifications when main channel fails',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: _iosNotificationService.getSimpleNotificationDetails(),
    );
    
    // إنشاء معرف فريد للإشعار الاحتياطي
    final notificationId = _generateUniqueId(id) + 100000;
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'تنبيه: $title',
      body,
      notificationDetails,
      payload: payload ?? id,
    );
    
    _errorLoggingService.logInfo('Backup notification shown for: $id');
  }

  /// جدولة إشعار لوقت محدد
  Future<bool> scheduleNotification({
    required NotificationData notification,
    required TimeOfDay scheduledTime,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // إنشاء معرف فريد للإشعار
      final notificationId = _generateUniqueId(notification.id);
      
      // الحصول على التاريخ المجدول
      final tz.TZDateTime scheduledDate = _getScheduledDate(scheduledTime);

      // إنشاء تفاصيل الإشعار
      final androidDetails = AndroidNotificationDetails(
        notification.channelId ?? (notification.isImportant ? 
            (notification.bypassDnd ? criticalChannelId : importantChannelId) : 
            defaultChannelId),
        notification.channelName ?? (notification.isImportant ? 
            (notification.bypassDnd ? criticalChannelName : importantChannelName) : 
            defaultChannelName),
        channelDescription: 'Scheduled notifications',
        importance: notification.isImportant ? Importance.high : Importance.default_,
        priority: notification.isImportant ? Priority.high : Priority.default_,
        styleInformation: BigTextStyleInformation(notification.body),
        color: notification.color,
        ledColor: notification.ledColor,
        ledOnMs: notification.ledColor != null ? 1000 : null,
        ledOffMs: notification.ledColor != null ? 500 : null,
        icon: notification.icon ?? '@mipmap/ic_launcher',
        sound: notification.soundName != null ? 
            RawResourceAndroidNotificationSound(notification.soundName!) : null,
      );
      
      final iosDetails = _iosNotificationService.getNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: _getIOSInterruptionLevel(
          notification.isImportant, 
          notification.bypassDnd
        ),
        sound: notification.soundName,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // جدولة الإشعار
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notification.title,
        notification.body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: notification.isRecurring 
            ? DateTimeComponents.time 
            : DateTimeComponents.dateAndTime,
        payload: notification.payload ?? notification.id,
      );

      // جدولة إنذار في الخلفية للمزيد من الموثوقية (Android فقط)
      if (Platform.isAndroid) {
        await _scheduleBackgroundAlarm(notification, scheduledTime);
      }

      // حفظ بيانات الإشعار
      await _saveNotificationData(notification, notificationId, scheduledTime);
      
      // جدولة الإشعارات الإضافية إذا كانت موجودة
      if (notification.additionalTimes != null && notification.additionalTimes!.isNotEmpty) {
        await _scheduleAdditionalNotifications(notification);
      }
      
      // تتبع الجدولة
      await _trackNotificationScheduled(notification.id, scheduledTime);
      
      _errorLoggingService.logInfo('Scheduled notification: ${notification.id} at ${scheduledTime.hour}:${scheduledTime.minute}');
      return true;
    } catch (e) {
      _errorLoggingService.logError('Error scheduling notification', e);
      
      // محاولة جدولة احتياطية
      try {
        await _scheduleBackupNotification(notification, scheduledTime);
        return true;
      } catch (backupError) {
        _errorLoggingService.logError('Error with backup scheduling', backupError);
        return false;
      }
    }
  }
  
  // جدولة إشعار احتياطي
  Future<void> _scheduleBackupNotification(
    NotificationData notification,
    TimeOfDay scheduledTime,
  ) async {
    try {
      // إنشاء معرف فريد للإشعار الاحتياطي
      final notificationId = _generateUniqueId(notification.id) + 200000;
      
      // الحصول على التاريخ المجدول
      final tz.TZDateTime scheduledDate = _getScheduledDate(scheduledTime);
      
      // إنشاء تفاصيل الإشعار البسيطة
      final androidDetails = AndroidNotificationDetails(
        'backup_channel',
        'Backup Channel',
        channelDescription: 'For backup scheduled notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: _iosNotificationService.getSimpleNotificationDetails(),
      );
      
      // جدولة الإشعار
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notification.title,
        notification.body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: notification.isRecurring 
            ? DateTimeComponents.time 
            : DateTimeComponents.dateAndTime,
        payload: notification.payload ?? notification.id,
      );
      
      // حفظ معرف الإشعار الاحتياطي
      await _saveBackupNotificationId(notification.id, notificationId);
      
      // جدولة إنذار احتياطي إذا كان Android
      if (Platform.isAndroid) {
        final backupAlarmId = backupAlarmBaseId + notificationId % 10000;
        
        // حساب وقت الإنذار
        final now = DateTime.now();
        DateTime scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          scheduledTime.hour,
          scheduledTime.minute,
        );
        
        // إذا كان الوقت قد مر اليوم، فقم بالجدولة ليوم غد
        if (scheduledDateTime.isBefore(now)) {
          scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }
        
        // جدولة الإنذار
        await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          backupAlarmId,
          _showNotificationCallback,
          startAt: scheduledDateTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {
            'id': notification.id,
            'notificationId': notificationId,
            'title': notification.title,
            'body': notification.body,
            'payload': notification.payload ?? notification.id,
            'isBackup': true,
          },
        );
        
        // حفظ معرف الإنذار الاحتياطي
        await _saveAlarmId(notification.id, backupAlarmId, true);
      }
      
      _errorLoggingService.logInfo('Backup notification scheduled for: ${notification.id}');
    } catch (e) {
      _errorLoggingService.logError('Error scheduling backup notification', e);
      throw e;
    }
  }
  
  // جدولة إنذار في الخلفية (للأندرويد)
  Future<void> _scheduleBackgroundAlarm(
    NotificationData notification,
    TimeOfDay scheduledTime,
  ) async {
    try {
      // تحديد نوع الإنذار ومعرفه
      int alarmId = dailyAlarmBaseId;
      if (notification.extraData != null) {
        if (notification.extraData!['type'] == 'weekly') {
          alarmId = weeklyAlarmBaseId;
        } else if (notification.extraData!['type'] == 'monthly') {
          alarmId = monthlyAlarmBaseId;
        }
      }
      
      // إضافة معرف فريد
      alarmId += _generateUniqueId(notification.id) % 10000;
      
      // حساب وقت الإنذار
      final now = DateTime.now();
      DateTime scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
      
      // إذا كان الوقت قد مر اليوم، فقم بالجدولة ليوم غد
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }
      
      // جدولة الإنذار
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        _showNotificationCallback,
        startAt: scheduledDateTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'id': notification.id,
          'notificationId': _generateUniqueId(notification.id),
          'title': notification.title,
          'body': notification.body,
          'payload': notification.payload ?? notification.id,
          'isImportant': notification.isImportant,
          'channelId': notification.channelId,
          'channelName': notification.channelName,
        },
      );
      
      // حفظ معرف الإنذار
      await _saveAlarmId(notification.id, alarmId, false);
      
      _errorLoggingService.logInfo('Background alarm scheduled for: ${notification.id} (AlarmId: $alarmId)');
    } catch (e) {
      _errorLoggingService.logError('Error scheduling background alarm', e);
    }
  }
  
  // جدولة إشعارات إضافية
  Future<void> _scheduleAdditionalNotifications(NotificationData notification) async {
    if (notification.additionalTimes == null || notification.additionalTimes!.isEmpty) {
      return;
    }
    
    try {
      List<int> additionalNotificationIds = [];
      
      for (int i = 0; i < notification.additionalTimes!.length; i++) {
        final timeString = notification.additionalTimes![i];
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          
          if (hour != null && minute != null) {
            final additionalTime = TimeOfDay(hour: hour, minute: minute);
            
            // إنشاء معرف فريد للإشعار الإضافي
            final int notificationId = _generateUniqueId(notification.id) + (i + 1) * 1000;
            additionalNotificationIds.add(notificationId);
            
            // الحصول على الوقت المجدول
            final tz.TZDateTime scheduledDate = _getScheduledDate(additionalTime);
            
            // إنشاء تفاصيل الإشعار
            // تخصيص الإشعارات الإضافية بمجموعة
            final androidDetails = AndroidNotificationDetails(
              notification.channelId ?? defaultChannelId,
              notification.channelName ?? defaultChannelName,
              channelDescription: 'Additional scheduled notifications',
              importance: notification.isImportant ? Importance.high : Importance.default_,
              priority: notification.isImportant ? Priority.high : Priority.default_,
              groupKey: 'group_${notification.id}',
              setAsGroupSummary: i == 0, // أول إشعار إضافي هو ملخص المجموعة
            );
            
            final iosDetails = _iosNotificationService.getNotificationDetails(
              threadIdentifier: 'thread_${notification.id}',
            );
            
            final notificationDetails = NotificationDetails(
              android: androidDetails,
              iOS: iosDetails,
            );
            
            // جدولة الإشعار
            await flutterLocalNotificationsPlugin.zonedSchedule(
              notificationId,
              notification.title,
              notification.body,
              scheduledDate,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: notification.isRecurring 
                  ? DateTimeComponents.time 
                  : DateTimeComponents.dateAndTime,
              payload: '${notification.id}:additional_$i',
            );
            
            // جدولة إنذار إضافي للأندرويد
            if (Platform.isAndroid) {
              final additionalAlarmId = notificationId + 100000;
              
              final now = DateTime.now();
              DateTime scheduledDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                additionalTime.hour,
                additionalTime.minute,
              );
              
              if (scheduledDateTime.isBefore(now)) {
                scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
              }
              
              await AndroidAlarmManager.periodic(
                const Duration(days: 1),
                additionalAlarmId,
                _showNotificationCallback,
                startAt: scheduledDateTime,
                exact: true,
                wakeup: true,
                rescheduleOnReboot: true,
                params: {
                  'id': '${notification.id}:additional_$i',
                  'notificationId': notificationId,
                  'title': notification.title,
                  'body': notification.body,
                  'payload': '${notification.id}:additional_$i',
                },
              );
              
              // حفظ معرف الإنذار الإضافي
              await _saveAlarmId('${notification.id}_additional_$i', additionalAlarmId, false);
            }
          }
        }
      }
      
      // حفظ جميع معرفات الإشعارات الإضافية لهذا الإشعار
      await _saveAdditionalNotificationIds(notification.id, additionalNotificationIds);
      
      _errorLoggingService.logInfo('Additional notifications scheduled for: ${notification.id} (Count: ${additionalNotificationIds.length})');
    } catch (e) {
      _errorLoggingService.logError('Error scheduling additional notifications', e);
    }
  }
  
  // دالة استدعاء الإنذار لعرض الإشعارات
  @pragma('vm:entry-point')
  static Future<void> _showNotificationCallback(int id, Map<String, dynamic>? params) async {
    if (params == null) return;
    
    try {
      // تهيئة plugin الإشعارات بتهيئة مناسبة
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      
      // تحتاج إلى تهيئة الـ plugin قبل عرض الإشعارات
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      
      // استخراج بيانات الإشعار
      final notificationId = params['notificationId'] as int;
      final notificationTitle = params['title'] as String;
      final notificationBody = params['body'] as String;
      final payload = params['payload'] as String;
      final isImportant = params['isImportant'] as bool? ?? false;
      final isBackup = params['isBackup'] as bool? ?? false;
      final channelId = params['channelId'] as String? ?? (isImportant ? 'important_channel' : 'default_channel');
      final channelName = params['channelName'] as String? ?? (isImportant ? 'Important Notifications' : 'Default Notifications');
      
      // تحسين تفاصيل الإشعار لرؤية أفضل
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        isBackup ? 'backup_channel' : channelId,
        isBackup ? 'Backup Channel' : channelName,
        channelDescription: 'Notifications from background alarm',
        importance: Importance.high,
        priority: Priority.high,
        category: isImportant ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: isImportant,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // حفظ للتنقل إذا تم النقر
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notification_payload', payload);
      await prefs.setBool('opened_from_notification', true);
      await prefs.setString('notification_payload', payload);
      
      // عرض الإشعار
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        notificationTitle,
        notificationBody,
        notificationDetails,
        payload: payload,
      );
      
      // تتبع أن الإشعار تم عرضه
      await _trackNotificationShown(payload, isBackup);
      
      print('Background notification showed successfully for: $payload');
    } catch (e) {
      print('Error in background notification callback: $e');
    }
  }
  
  // تتبع عندما يتم عرض إشعار
  @pragma('vm:entry-point')
  static Future<void> _trackNotificationShown(String id, bool isBackup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ وقت عرض هذا الإشعار
      final key = 'notification_shown_${id}_${DateTime.now().day}';
      await prefs.setString(key, DateTime.now().toIso8601String());
      
      // تتبع إذا كان إشعارًا احتياطيًا
      if (isBackup) {
        final backupKey = 'backup_notification_shown_$id';
        final int count = prefs.getInt(backupKey) ?? 0;
        await prefs.setInt(backupKey, count + 1);
      }
      
      // زيادة إجمالي عدد المعروض
      final countKey = 'notification_shown_count_$id';
      final int currentCount = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, currentCount + 1);
      
    } catch (e) {
      print('Error tracking notification shown: $e');
    }
  }
  
  /// إلغاء إشعار محدد
  Future<bool> cancelNotification(String id) async {
    try {
      // الحصول على جميع معرفات الإشعارات لهذا الإشعار
      final int primaryId = await _getSavedNotificationId(id);
      final int backupId = await _getBackupNotificationId(id);
      final List<int> additionalIds = await _getAdditionalNotificationIds(id);
      
      // إلغاء الإشعار الرئيسي
      if (primaryId > 0) {
        await flutterLocalNotificationsPlugin.cancel(primaryId);
      }
      
      // إلغاء الإشعار الاحتياطي
      if (backupId > 0) {
        await flutterLocalNotificationsPlugin.cancel(backupId);
      }
      
      // إلغاء الإشعارات الإضافية
      for (final additionalId in additionalIds) {
        await flutterLocalNotificationsPlugin.cancel(additionalId);
      }
      
      // إلغاء الإنذارات الخلفية على Android
      if (Platform.isAndroid) {
        // إلغاء الإنذار الرئيسي
        final alarmId = await _getSavedAlarmId(id);
        if (alarmId > 0) {
          await AndroidAlarmManager.cancel(alarmId);
        }
        
        // إلغاء الإنذار الاحتياطي
        final backupAlarmId = await _getSavedAlarmId(id, true);
        if (backupAlarmId > 0) {
          await AndroidAlarmManager.cancel(backupAlarmId);
        }
        
        // إلغاء الإنذارات الإضافية
        final additionalAlarmIds = await _getAdditionalAlarmIds(id);
        for (final additionalAlarmId in additionalAlarmIds) {
          await AndroidAlarmManager.cancel(additionalAlarmId);
        }
      }
      
      // مسح البيانات المحفوظة
      await _clearNotificationData(id);
      
      // تتبع الإلغاء
      await _trackNotificationCancelled(id);
      
      _errorLoggingService.logInfo('Notification cancelled: $id');
      return true;
    } catch (e) {
      _errorLoggingService.logError('Error canceling notification', e);
      return false;
    }
  }
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      
      if (Platform.isAndroid) {
        // الحصول على جميع معرفات الإنذارات المحفوظة
        final allAlarmIds = await _getAllSavedAlarmIds();
        
        // إلغاء جميع الإنذارات المعروفة
        for (final alarmId in allAlarmIds) {
          await AndroidAlarmManager.cancel(alarmId);
        }
      }
      
      // مسح جميع البيانات المحفوظة
      await _clearAllNotificationData();
      
      // تتبع إعادة التعيين
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notifications_reset', DateTime.now().toIso8601String());
      
      _errorLoggingService.logInfo('All notifications cancelled');
      return true;
    } catch (e) {
      _errorLoggingService.logError('Error canceling all notifications', e);
      return false;
    }
  }
  
  /// الحصول على جميع الإشعارات المجدولة
  Future<List<PendingNotificationRequest>> getScheduledNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      _errorLoggingService.logError('Error getting scheduled notifications', e);
      return [];
    }
  }
  
  /// الحصول على جميع معرفات الإشعارات المجدولة
  Future<List<String>> getAllScheduledNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIdsKey = 'all_notification_ids';
      return prefs.getStringList(allIdsKey) ?? <String>[];
    } catch (e) {
      _errorLoggingService.logError('Error getting all notification IDs', e);
      return [];
    }
  }
  
  /// التحقق مما إذا كان إشعار مجدول
  Future<bool> isNotificationScheduled(String id) async {
    final notificationId = await _getSavedNotificationId(id);
    return notificationId > 0;
  }
  
  /// جدولة جميع الإشعارات المحفوظة
  Future<void> _rescheduleAllSavedNotifications() async {
    try {
      // الحصول على جميع الإشعارات المحفوظة
      final savedNotifications = await _getAllSavedNotifications();
      
      int successCount = 0;
      int failureCount = 0;
      
      for (final id in savedNotifications.keys) {
        try {
          final notificationData = savedNotifications[id]!;
          final timeString = await _getSavedNotificationTime(id);
          
          if (timeString != null) {
            final timeParts = timeString.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);
              
              if (hour != null && minute != null) {
                final scheduledTime = TimeOfDay(hour: hour, minute: minute);
                
                // جدولة الإشعار
                final success = await scheduleNotification(
                  notification: notificationData,
                  scheduledTime: scheduledTime,
                );
                
                if (success) {
                  successCount++;
                } else {
                  failureCount++;
                }
              }
            }
          }
        } catch (e) {
          _errorLoggingService.logError('Error rescheduling notification: $id', e);
          failureCount++;
        }
      }
      
      _errorLoggingService.logInfo('Rescheduled $successCount notifications (Failed: $failureCount)');
    } catch (e) {
      _errorLoggingService.logError('Error rescheduling saved notifications', e);
    }
  }
  
  /// اختبار إشعار فوري
  Future<bool> testNotification() async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Channel',
        channelDescription: 'For testing notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      final iosDetails = _iosNotificationService.getNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await flutterLocalNotificationsPlugin.show(
        0,
        'اختبار الإشعارات',
        'هذا إشعار تجريبي للتأكد من عمل نظام الإشعارات',
        notificationDetails,
        payload: 'test',
      );
      
      // تتبع إشعار الاختبار
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_notification_sent', DateTime.now().toIso8601String());
      
      _errorLoggingService.logInfo('Test notification sent successfully');
      return true;
    } catch (e) {
      _errorLoggingService.logError('Error showing test notification', e);
      return false;
    }
  }
  
  /// الحصول على إحصائيات الإشعارات
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على جميع الإشعارات المجدولة
      final pendingNotifications = await getScheduledNotifications();
      
      // الحصول على جميع معرفات الإشعارات
      final allIdsKey = 'all_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      // حساب متريكس التفاعل
      int totalInteractions = 0;
      int totalShown = 0;
      Map<String, int> interactionsByType = {};
      
      for (final id in allIds) {
        final countKey = 'notification_interaction_count_$id';
        final interactions = prefs.getInt(countKey) ?? 0;
        totalInteractions += interactions;
        
        final shownKey = 'notification_shown_count_$id';
        totalShown += prefs.getInt(shownKey) ?? 0;
        
        // تصنيف حسب النوع
        final type = _getCategoryFromId(id);
        interactionsByType[type] = (interactionsByType[type] ?? 0) + interactions;
      }
      
      return {
        'total_scheduled': allIds.length,
        'pending_count': pendingNotifications.length,
        'total_shown': totalShown,
        'total_interactions': totalInteractions,
        'interactions_by_type': interactionsByType,
        'last_reset': prefs.getString('notifications_reset') ?? 'Never',
        'test_notification_sent': prefs.getString('test_notification_sent'),
      };
    } catch (e) {
      _errorLoggingService.logError('Error getting notification statistics', e);
      return {
        'error': e.toString(),
        'total_scheduled': 0,
        'pending_count': 0,
      };
    }
  }
  
  /// الحصول على حالة تحسين البطارية
  Future<bool> needsBatteryOptimization() async {
    try {
      if (!Platform.isAndroid) return false;
      
      return await _batteryOptimizationService.isBatteryOptimizationEnabled();
    } catch (e) {
      _errorLoggingService.logError('Error checking battery optimization', e);
      return false;
    }
  }
  
  /// فتح إعدادات تحسين البطارية
  Future<bool> openBatteryOptimizationSettings() async {
    try {
      if (!Platform.isAndroid) return false;
      
      return await _batteryOptimizationService.openBatteryOptimizationSettings();
    } catch (e) {
      _errorLoggingService.logError('Error opening battery settings', e);
      return false;
    }
  }
  
  /// الحصول على حالة عدم الإزعاج
  Future<bool> isDndEnabled() async {
    try {
      return await _doNotDisturbService.isDndEnabled();
    } catch (e) {
      _errorLoggingService.logError('Error checking DND status', e);
      return false;
    }
  }
  
  // دوال المساعدة للتعامل مع الإشعارات والإنذارات
  
  // إنشاء معرف فريد للإشعار
  int _generateUniqueId(String id) {
    return id.hashCode.abs() % 100000;
  }
  
  // الحصول على فئة الإشعار المناسبة
  AndroidNotificationCategory _getNotificationCategory(bool isImportant) {
    return isImportant ? 
        AndroidNotificationCategory.alarm : 
        AndroidNotificationCategory.reminder;
  }
  
  // الحصول على مستوى المقاطعة المناسب لنظام iOS
  InterruptionLevel _getIOSInterruptionLevel(bool isImportant, bool bypassDnd) {
    if (bypassDnd) {
      return InterruptionLevel.critical; // أعلى مستوى - تجاوز وضع عدم الإزعاج
    } else if (isImportant) {
      return InterruptionLevel.timeSensitive; // مهم ولكن لا يتجاوز وضع عدم الإزعاج
    } else {
      return InterruptionLevel.active; // مستوى عادي
    }
  }
  
  // تحويل TimeOfDay إلى TZDateTime مجدول
  tz.TZDateTime _getScheduledDate(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // إذا كان الوقت قد مر اليوم، فقم بالجدولة ليوم غد
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  // حفظ بيانات الإشعار ومعرف الإشعار
  Future<void> _saveNotificationData(
    NotificationData notification,
    int notificationId, 
    TimeOfDay scheduledTime,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ تعيين معرف الإشعار
      final idKey = 'notification_id_${notification.id}';
      await prefs.setInt(idKey, notificationId);
      
      // حفظ بيانات الإشعار
      final dataKey = 'notification_data_${notification.id}';
      await prefs.setString(dataKey, jsonEncode(notification.toJson()));
      
      // حفظ الوقت المجدول
      final timeKey = 'notification_time_${notification.id}';
      await prefs.setString(timeKey, '${scheduledTime.hour}:${scheduledTime.minute}');
      
      // إضافة إلى قائمة معرفات الإشعارات الرئيسية
      final allIdsKey = 'all_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      if (!allIds.contains(notification.id)) {
        allIds.add(notification.id);
        await prefs.setStringList(allIdsKey, allIds);
      }
      
    } catch (e) {
      _errorLoggingService.logError('Error saving notification data', e);
    }
  }
  
  // حفظ معرف الإشعار الاحتياطي
  Future<void> _saveBackupNotificationId(String id, int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idKey = 'notification_backup_id_$id';
      await prefs.setInt(idKey, notificationId);
    } catch (e) {
      _errorLoggingService.logError('Error saving backup notification ID', e);
    }
  }
  
  // حفظ معرف الإنذار
  Future<void> _saveAlarmId(String id, int alarmId, bool isBackup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idKey = isBackup ? 'alarm_backup_id_$id' : 'alarm_id_$id';
      await prefs.setInt(idKey, alarmId);
      
      // إضافة إلى قائمة جميع معرفات الإنذارات
      final allAlarmsKey = 'all_alarm_ids';
      final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
      
      final alarmKey = isBackup ? 'backup_$id' : id;
      if (!allAlarms.contains(alarmKey)) {
        allAlarms.add(alarmKey);
        await prefs.setStringList(allAlarmsKey, allAlarms);
      }
    } catch (e) {
      _errorLoggingService.logError('Error saving alarm ID', e);
    }
  }
  
  // حفظ معرفات الإشعارات الإضافية
  Future<void> _saveAdditionalNotificationIds(String id, List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsKey = 'additional_notification_ids_$id';
      await prefs.setString(idsKey, ids.join(','));
    } catch (e) {
      _errorLoggingService.logError('Error saving additional notification IDs', e);
    }
  }
  
  // الحصول على معرف الإشعار المحفوظ
  Future<int> _getSavedNotificationId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idKey = 'notification_id_$id';
      return prefs.getInt(idKey) ?? 0;
    } catch (e) {
      _errorLoggingService.logError('Error getting saved notification ID', e);
      return 0;
    }
  }
  
  // الحصول على معرف الإشعار الاحتياطي
  Future<int> _getBackupNotificationId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idKey = 'notification_backup_id_$id';
      return prefs.getInt(idKey) ?? 0;
    } catch (e) {
      _errorLoggingService.logError('Error getting backup notification ID', e);
      return 0;
    }
  }
  
  // الحصول على معرف الإنذار المحفوظ
  Future<int> _getSavedAlarmId(String id, [bool isBackup = false]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idKey = isBackup ? 'alarm_backup_id_$id' : 'alarm_id_$id';
      return prefs.getInt(idKey) ?? 0;
    } catch (e) {
      _errorLoggingService.logError('Error getting saved alarm ID', e);
      return 0;
    }
  }
  
  // الحصول على جميع معرفات الإنذارات المحفوظة
  Future<List<int>> _getAllSavedAlarmIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allAlarmsKey = 'all_alarm_ids';
      final alarmKeys = prefs.getStringList(allAlarmsKey) ?? <String>[];
      
      List<int> alarmIds = [];
      
      for (final key in alarmKeys) {
        // استخراج معرف الإنذار
        int? alarmId;
        
        if (key.startsWith('backup_')) {
          final id = key.replaceFirst('backup_', '');
          alarmId = await _getSavedAlarmId(id, true);
        } else {
          alarmId = await _getSavedAlarmId(key);
        }
        
        if (alarmId > 0) {
          alarmIds.add(alarmId);
        }
      }
      
      return alarmIds;
    } catch (e) {
      _errorLoggingService.logError('Error getting all saved alarm IDs', e);
      return [];
    }
  }
  
  // الحصول على معرفات الإشعارات الإضافية
  Future<List<int>> _getAdditionalNotificationIds(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsKey = 'additional_notification_ids_$id';
      final idsString = prefs.getString(idsKey);
      
      if (idsString != null && idsString.isNotEmpty) {
        return idsString
            .split(',')
            .map((idStr) => int.tryParse(idStr) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      
      return [];
    } catch (e) {
      _errorLoggingService.logError('Error getting additional notification IDs', e);
      return [];
    }
  }
  
  // الحصول على معرفات الإنذارات الإضافية
  Future<List<int>> _getAdditionalAlarmIds(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allAlarmsKey = 'all_alarm_ids';
      final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
      
      List<int> additionalAlarmIds = [];
      
      // البحث عن الإنذارات المرتبطة بهذا المعرف
      for (final key in allAlarms) {
        if (key.startsWith('${id}_additional_')) {
          final alarmId = await _getSavedAlarmId(key);
          if (alarmId > 0) {
            additionalAlarmIds.add(alarmId);
          }
        }
      }
      
      return additionalAlarmIds;
    } catch (e) {
      _errorLoggingService.logError('Error getting additional alarm IDs', e);
      return [];
    }
  }
  
  // مسح بيانات الإشعار
  Future<void> _clearNotificationData(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // إزالة تعيين المعرف
      await prefs.remove('notification_id_$id');
      await prefs.remove('notification_backup_id_$id');
      
      // إزالة بيانات الإشعار
      await prefs.remove('notification_data_$id');
      
      // إزالة الوقت المجدول
      await prefs.remove('notification_time_$id');
      
      // إزالة معرفات الإشعارات الإضافية
      await prefs.remove('additional_notification_ids_$id');
      
      // إزالة معرفات الإنذارات
      await prefs.remove('alarm_id_$id');
      await prefs.remove('alarm_backup_id_$id');
      
      // تحديث القائمة الرئيسية
      final allIdsKey = 'all_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      if (allIds.contains(id)) {
        allIds.remove(id);
        await prefs.setStringList(allIdsKey, allIds);
      }
      
      // تحديث قائمة الإنذارات
      final allAlarmsKey = 'all_alarm_ids';
      final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
      
      // إزالة جميع الإنذارات المرتبطة بهذا المعرف
      allAlarms.removeWhere((key) => key == id || key == 'backup_$id' || key.startsWith('${id}_additional_'));
      await prefs.setStringList(allAlarmsKey, allAlarms);
    } catch (e) {
      _errorLoggingService.logError('Error clearing notification data', e);
    }
  }
  
  // مسح جميع بيانات الإشعارات
  Future<void> _clearAllNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على جميع معرفات الإشعارات
      final allIdsKey = 'all_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      // مسح بيانات كل إشعار
      for (final id in allIds) {
        await _clearNotificationData(id);
      }
      
      // إزالة القائمة الرئيسية
      await prefs.remove(allIdsKey);
      
      // إزالة قائمة الإنذارات
      await prefs.remove('all_alarm_ids');
      
      _errorLoggingService.logInfo('All notification data cleared');
    } catch (e) {
      _errorLoggingService.logError('Error clearing all notification data', e);
    }
  }
  
  // تتبع عندما يتم جدولة إشعار
  Future<void> _trackNotificationScheduled(String id, TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_scheduled_$id';
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'time': '${time.hour}:${time.minute}',
      };
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      _errorLoggingService.logError('Error tracking notification scheduled', e);
    }
  }
  
  // تتبع عندما يتم إلغاء إشعار
  Future<void> _trackNotificationCancelled(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_cancelled_$id';
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      _errorLoggingService.logError('Error tracking notification cancellation', e);
    }
  }
  
  // الحصول على الوقت المحفوظ للإشعار
  Future<String?> _getSavedNotificationTime(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeKey = 'notification_time_$id';
      return prefs.getString(timeKey);
    } catch (e) {
      _errorLoggingService.logError('Error getting saved notification time', e);
      return null;
    }
  }
  
  // الحصول على جميع الإشعارات المحفوظة
  Future<Map<String, NotificationData>> _getAllSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIdsKey = 'all_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      Map<String, NotificationData> savedNotifications = {};
      
      for (final id in allIds) {
        final dataKey = 'notification_data_$id';
        final dataJson = prefs.getString(dataKey);
        
        if (dataJson != null) {
          try {
            final data = NotificationData.fromJson(jsonDecode(dataJson));
            savedNotifications[id] = data;
          } catch (e) {
            _errorLoggingService.logError('Error parsing notification data for: $id', e);
          }
        }
      }
      
      return savedNotifications;
    } catch (e) {
      _errorLoggingService.logError('Error getting all saved notifications', e);
      return {};
    }
  }
  
  // الحصول على الفئة من المعرف
  String _getCategoryFromId(String id) {
    // استخراج الفئة من المعرف (مثال: "morning_123" -> "morning")
    final parts = id.split('_');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return 'unknown';
  }
  
  // الحصول على اسم المنطقة الزمنية الحالية
  String getCurrentTimezoneName() {
    return _deviceTimeZone;
  }
}
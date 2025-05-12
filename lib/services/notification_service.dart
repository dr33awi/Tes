// lib/services/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/ios_notification_service.dart';
import 'package:test_athkar_app/services/notification_navigation.dart';
import 'package:test_athkar_app/services/permissions_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// خدمة موحدة لإدارة الإشعارات في التطبيق
class NotificationService {
  // تنفيذ نمط Singleton للخدمة
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService({
    ErrorLoggingService? errorLoggingService,
    DoNotDisturbService? doNotDisturbService,
    IOSNotificationService? iosNotificationService,
    BatteryOptimizationService? batteryOptimizationService,
  }) {
    if (errorLoggingService != null) {
      _instance._errorLoggingService = errorLoggingService;
    }
    if (doNotDisturbService != null) {
      _instance._doNotDisturbService = doNotDisturbService;
    }
    if (iosNotificationService != null) {
      _instance._iosNotificationService = iosNotificationService;
    }
    if (batteryOptimizationService != null) {
      _instance._batteryOptimizationService = batteryOptimizationService;
    }
    
    return _instance;
  }
  
  // كائن FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // خدمات التبعية المعكوسة
  ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  DoNotDisturbService _doNotDisturbService = DoNotDisturbService();
  IOSNotificationService _iosNotificationService = IOSNotificationService();
  BatteryOptimizationService _batteryOptimizationService = BatteryOptimizationService();
  
  // المزيد من الخدمات التي قد تكون مطلوبة
  final PermissionsService _permissionsService = PermissionsService();
  
  // معرفات قناة الإشعارات
  static const String _defaultChannelId = 'default_channel';
  static const String _highPriorityChannelId = 'high_priority_channel';
  static const String _scheduledChannelId = 'scheduled_channel';
  static const String _reminderChannelId = 'reminder_channel';
  
  // مفاتيح التخزين المحلي
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyScheduledNotifications = 'scheduled_notifications';
  static const String _keyLastSyncTime = 'last_notification_sync';
  static const String _keyNotificationData = 'notification_data_';
  
  // المنشئ الداخلي
  NotificationService._internal();
  
  /// تهيئة خدمة الإشعارات
  Future<bool> initialize() async {
    try {
      print('بدء تهيئة خدمة الإشعارات...');
      
      // تهيئة بيانات المنطقة الزمنية
      tz_data.initializeTimeZones();
      
      // تعيين المنطقة الزمنية المحلية
      await _configureLocalTimeZone();
      
      // تهيئة قنوات الإشعارات
      await _initializeNotificationChannels();
      
      // تهيئة مدير التنبيهات لنظام Android (للاعتمادية)
      if (Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }
      
      // تكوين وضع عدم الإزعاج للإشعارات
      await _doNotDisturbService.configureNotificationChannelsForDoNotDisturb();
      
      // تهيئة الإشعارات الخاصة بنظام iOS
      if (Platform.isIOS) {
        await _iosNotificationService.initialize();
      }
      
      // تعيين معالج الإشعارات والتنقل
      await _setupNotificationHandlers();
      
      print('اكتملت تهيئة خدمة الإشعارات بنجاح');
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في تهيئة خدمة الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// إعداد قنوات الإشعارات
  Future<void> _initializeNotificationChannels() async {
    try {
      if (Platform.isAndroid) {
        // إنشاء قنوات الإشعار لنظام Android
        final AndroidInitializationSettings androidSettings = AndroidInitializationSettings('app_icon');
        
        // قائمة قنوات الإشعارات
        List<AndroidNotificationChannel> channels = [
          // القناة الافتراضية
          AndroidNotificationChannel(
            _defaultChannelId,
            'التنبيهات الافتراضية',
            description: 'التنبيهات العامة للتطبيق',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
          
          // قناة الإشعارات المجدولة
          AndroidNotificationChannel(
            _scheduledChannelId,
            'الإشعارات المجدولة',
            description: 'إشعارات مجدولة مسبقاً',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
          
          // قناة التذكيرات
          AndroidNotificationChannel(
            _reminderChannelId,
            'تذكيرات',
            description: 'تذكيرات عامة',
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
          
          // قناة ذات أولوية عالية (لتجاوز وضع عدم الإزعاج)
          AndroidNotificationChannel(
            _highPriorityChannelId,
            'تنبيهات مهمة',
            description: 'تنبيهات ذات أولوية عالية',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
            enableLights: true,
          ),
        ];
        
        // تسجيل قنوات الإشعارات
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        
        for (var channel in channels) {
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(channel);
        }
        
        // إعداد منصة Android
        final androidInitSettings = AndroidInitializationSettings('app_icon');
        
        // إعداد منصة iOS
        final darwinInitSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: true,
        );
        
        // إعداد الإشعارات
        final initSettings = InitializationSettings(
          android: androidInitSettings,
          iOS: darwinInitSettings,
        );
        
        // تهيئة الإشعارات مع تعيين معالجات الاستجابة
        await _flutterLocalNotificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationResponse,
          onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
        );
      } else if (Platform.isIOS) {
        // إعداد منصة iOS
        final darwinInitSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: true,
        );
        
        // إعداد الإشعارات
        final initSettings = InitializationSettings(
          iOS: darwinInitSettings,
        );
        
        // تهيئة الإشعارات مع تعيين معالجات الاستجابة
        await _flutterLocalNotificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationResponse,
          onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
        );
        
        // استخدام تهيئة iOS المخصصة
        await _iosNotificationService.initialize();
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في تهيئة قنوات الإشعارات', 
        e
      );
    }
  }
  
  /// تكوين المنطقة الزمنية المحلية
  Future<void> _configureLocalTimeZone() async {
    try {
      final String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('تم تكوين المنطقة الزمنية: $timeZoneName');
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في تكوين المنطقة الزمنية', 
        e
      );
      // استخدام المنطقة الزمنية الافتراضية
      tz.setLocalLocation(tz.getLocation('GMT'));
    }
  }
  
  /// إعداد معالجات الإشعارات للتنقل
  Future<void> _setupNotificationHandlers() async {
    try {
      // معالجة إشعارات الخلفية
      _flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(
          android: AndroidInitializationSettings('app_icon'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );
      
      // التحقق من فتح التطبيق من إشعار
      if (await NotificationNavigation.checkNotificationOpen()) {
        final payload = await NotificationNavigation.getNotificationPayload();
        if (payload != null && payload.isNotEmpty) {
          // سيعالج AppInitializer هذا عند بدء التشغيل
        }
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في إعداد معالجات الإشعارات', 
        e
      );
    }
  }
  
  /// معالجة استجابة الإشعار
  void _onNotificationResponse(NotificationResponse response) {
    try {
      final String? payload = response.payload;
      final String? actionId = response.actionId;
      
      print('استجابة إشعار: action=$actionId, payload=$payload');
      
      if (payload != null && payload.isNotEmpty) {
        // تخزين البيانات اللازمة للتنقل
        NotificationNavigation.setNotificationNavigationData(payload);
        
        // معالجة إجراءات الإشعار المخصصة
        if (actionId != null) {
          _handleNotificationAction(actionId, payload);
        }
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في معالجة استجابة الإشعار', 
        e
      );
    }
  }
  
  /// معالجة استجابة الإشعار في الخلفية
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // لا يمكن استخدام الخدمات في الخلفية، لذا نستخدم طريقة ثابتة
    print('استجابة إشعار في الخلفية: ${response.actionId}, ${response.payload}');
    
    // تخزين البيانات للمعالجة عند تفعيل التطبيق
    if (response.payload != null && response.payload!.isNotEmpty) {
      NotificationNavigation.setNotificationNavigationData(response.payload!);
    }
  }
  
  /// معالجة إجراءات الإشعار المخصصة
  Future<void> _handleNotificationAction(String actionId, String payload) async {
    try {
      switch (actionId) {
        case 'MARK_READ':
          await _markAsRead(payload);
          break;
        case 'SNOOZE':
        case 'REMIND_LATER':
          await _snoozeNotification(payload);
          break;
        default:
          // التنقل العادي سيتم معالجته عبر NotificationNavigation
          break;
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في معالجة إجراء الإشعار: $actionId', 
        e
      );
    }
  }
  
  /// تمييز الإشعار كمقروء
  Future<void> _markAsRead(String payload) async {
    try {
      // استخراج المعرف من البيانات
      final parts = payload.split(':');
      final notificationId = parts[0];
      
      // حفظ وقت القراءة في التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ وقت القراءة
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('${notificationId}_last_read', now);
      
      // زيادة عداد القراءة
      final readCount = prefs.getInt('${notificationId}_read_count') ?? 0;
      await prefs.setInt('${notificationId}_read_count', readCount + 1);
      
      // إرسال إشعار تأكيد
      await showSimpleNotification(
        'تم تسجيل القراءة',
        'تم تسجيل قراءة المحتوى بنجاح',
        10000 + notificationId.hashCode,
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في تمييك الإشعار كمقروء: $payload', 
        e
      );
    }
  }
  
  /// تأجيل الإشعار
  Future<void> _snoozeNotification(String payload) async {
    try {
      // استخراج المعرف من البيانات
      final parts = payload.split(':');
      final notificationId = parts[0];
      
      // جدولة تذكير بعد 30 دقيقة
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: 30));
      
      // إنشاء عنوان وجسم الإشعار
      final String title = 'تذكير مؤجل';
      final String body = 'تذكير بالمحتوى الذي تم تأجيله';
      
      // إنشاء تفاصيل الإشعار
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _reminderChannelId,
        'تذكيرات',
        channelDescription: 'قناة التذكيرات',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );
      
      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // جدولة الإشعار
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        20000 + notificationId.hashCode,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: notificationId,
      );
      
      // عرض تأكيد
      await showSimpleNotification(
        'تم تأجيل الإشعار',
        'سيتم تذكيرك بعد 30 دقيقة',
        10001 + notificationId.hashCode,
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في تأجيل الإشعار: $payload', 
        e
      );
    }
  }
  
  // ... باقي الكود
  
  /// إرسال إشعار بسيط فوري
  Future<void> showSimpleNotification(String title, String body, int id, {String? payload}) async {
    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _defaultChannelId,
        'التنبيهات الافتراضية',
        channelDescription: 'قناة التنبيهات العامة',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );
      
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في إرسال إشعار بسيط', 
        e
      );
    }
  }
  
  /// جدولة جميع الإشعارات المحفوظة سابقاً
  Future<void> scheduleAllSavedNotifications() async {
    try {
      print('جاري إعادة جدولة جميع الإشعارات المحفوظة...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // التحقق ما إذا كانت الإشعارات مفعلة
      final bool notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      if (!notificationsEnabled) {
        print('الإشعارات غير مفعلة في الإعدادات');
        return;
      }
      
      // الحصول على قائمة الإشعارات المجدولة
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      if (scheduledList.isEmpty) {
        print('لا توجد إشعارات مجدولة للإعادة');
        return;
      }
      
      // إعادة جدولة الإشعارات المحفوظة
      for (String notificationId in scheduledList) {
        final id = notificationId.hashCode.abs() % 100000;
        final infoString = prefs.getString('$_keyNotificationData$id');
        
        if (infoString != null) {
          final info = jsonDecode(infoString);
          final TimeOfDay time = TimeOfDay(
            hour: info['hour'],
            minute: info['minute'],
          );
          
          await scheduleNotification(
            notificationId: notificationId,
            title: info['title'],
            body: info['body'],
            notificationTime: time,
            channelId: info['channelId'],
            payload: info['payload'],
            color: info['color'] != null ? Color(info['color']) : null,
            priority: info['priority'],
            repeat: info['repeat'] ?? true,
          );
        } else {
          // استرجاع من الطريقة القديمة
          final timeString = prefs.getString('notification_${notificationId}_time');
          if (timeString != null) {
            final timeParts = timeString.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);
              
              if (hour != null && minute != null) {
                final time = TimeOfDay(hour: hour, minute: minute);
                
                // استرجاع معلومات الإشعار المحفوظة
                final title = prefs.getString('notification_${notificationId}_title') ?? 'تذكير';
                final body = prefs.getString('notification_${notificationId}_body') ?? 'حان وقت التذكير';
                
                // جدولة الإشعار
                await scheduleNotification(
                  notificationId: notificationId,
                  title: title,
                  body: body,
                  notificationTime: time,
                  repeat: true,
                );
              }
            }
          }
        }
      }
      
      print('تمت إعادة جدولة الإشعارات المحفوظة');
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في جدولة جميع الإشعارات المحفوظة', 
        e
      );
    }
  }
  
  /// جدولة إشعار عام
  Future<bool> scheduleNotification({
    required String notificationId,
    required String title,
    required String body,
    required TimeOfDay notificationTime,
    String? channelId,
    String? payload,
    Color? color,
    bool repeat = true,
    int? priority,
  }) async {
    try {
      // التحقق من أذونات الإشعارات
      final hasPermission = await _permissionsService.checkNotificationPermission();
      if (!hasPermission) {
        print('لا توجد أذونات للإشعارات');
        return false;
      }
      
      // حفظ معلومات الإشعار بالكامل
      await _saveFullNotificationInfo(
        notificationId: notificationId,
        title: title,
        body: body,
        notificationTime: notificationTime,
        channelId: channelId,
        payload: payload,
        color: color,
        priority: priority,
        repeat: repeat,
      );
      
      // إنشاء معرف الإشعار من المعرف المقدم
      final id = notificationId.hashCode.abs() % 100000;
      
      // جدولة الإشعار
      if (Platform.isIOS) {
        // إعدادات iOS
        DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.active,
          threadIdentifier: 'notification_$notificationId',
        );
        
        NotificationDetails details = NotificationDetails(iOS: iosDetails);
        
        // الحصول على الوقت المحدد
        final tz.TZDateTime scheduledDate = _getNextInstanceOfTime(notificationTime);
        
        // جدولة الإشعار
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: repeat ? DateTimeComponents.time : null,
          payload: payload ?? notificationId,
        );
      } else {
        // إعدادات Android
        final channel = channelId ?? _scheduledChannelId;
        
        AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          channel,
          'تنبيهات',
          channelDescription: 'قناة التنبيهات',
          importance: priority != null ? Importance.values[priority.clamp(0, 5)] : Importance.high,
          priority: priority != null ? Priority.values[priority.clamp(0, 5)] : Priority.high,
          color: color,
          ledColor: color,
          ledOnMs: 1000,
          ledOffMs: 500,
          visibility: NotificationVisibility.public,
        );
        
        NotificationDetails details = NotificationDetails(android: androidDetails);
        
        // الحصول على الوقت المحدد
        final tz.TZDateTime scheduledDate = _getNextInstanceOfTime(notificationTime);
        
        // استخدام Android Alarm Manager للدقة
        if (repeat) {
          await AndroidAlarmManager.periodic(
            const Duration(days: 1),
            id,
            () => _showScheduledNotification(id),
            startAt: scheduledDate.toLocal(),
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
          );
        } else {
          await AndroidAlarmManager.oneShotAt(
            scheduledDate.toLocal(),
            id,
            () => _showScheduledNotification(id),
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
          );
        }
      }
      
      // تحديث قائمة الإشعارات المجدولة
      await _updateScheduledNotificationsList(notificationId);
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في جدولة الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
  
  /// دالة الاستدعاء لعرض الإشعار المجدول
  @pragma('vm:entry-point')
  static void _showScheduledNotification(int alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final infoString = prefs.getString('$_keyNotificationData$alarmId');
      
      if (infoString != null) {
        final info = jsonDecode(infoString);
        
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
            FlutterLocalNotificationsPlugin();
        
        final androidDetails = AndroidNotificationDetails(
          info['channelId'] ?? 'scheduled_channel',
          'إشعار مجدول',
          channelDescription: 'إشعار مجدول',
          importance: Importance.high,
          priority: Priority.high,
          color: info['color'] != null ? Color(info['color']) : null,
          enableVibration: true,
          playSound: true,
          showWhen: true,
        );
        
        await flutterLocalNotificationsPlugin.show(
          alarmId,
          info['title'],
          info['body'],
          NotificationDetails(android: androidDetails),
          payload: info['payload'],
        );
      }
    } catch (e) {
      print('خطأ في عرض الإشعار المجدول: $e');
    }
  }
  
  /// حفظ معلومات الإشعار بالكامل
  Future<void> _saveFullNotificationInfo({
    required String notificationId,
    required String title,
    required String body,
    required TimeOfDay notificationTime,
    String? channelId,
    String? payload,
    Color? color,
    int? priority,
    bool repeat = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = notificationId.hashCode.abs() % 100000;
      
      final info = {
        'notificationId': notificationId,
        'title': title,
        'body': body,
        'channelId': channelId ?? _scheduledChannelId,
        'color': color?.value,
        'priority': priority,
        'payload': payload,
        'repeat': repeat,
        'hour': notificationTime.hour,
        'minute': notificationTime.minute,
      };
      
      await prefs.setString('$_keyNotificationData$id', jsonEncode(info));
      
      // أيضاً حفظ بالطريقة القديمة للتوافق
      final timeString = '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_${notificationId}_time', timeString);
      await prefs.setString('notification_${notificationId}_title', title);
      await prefs.setString('notification_${notificationId}_body', body);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في حفظ معلومات الإشعار', 
        e
      );
    }
  }
  
  /// تحديث قائمة الإشعارات المجدولة
  Future<void> _updateScheduledNotificationsList(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على القائمة الحالية
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      // التحقق مما إذا كان المعرف موجودًا بالفعل
      if (!scheduledList.contains(notificationId)) {
        scheduledList.add(notificationId);
        await prefs.setStringList(_keyScheduledNotifications, scheduledList);
      }
      
      // تحديث وقت آخر مزامنة
      await prefs.setInt(_keyLastSyncTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في تحديث قائمة الإشعارات المجدولة', 
        e
      );
    }
  }
  
  /// الحصول على الوقت التالي لجدولة الإشعار
  tz.TZDateTime _getNextInstanceOfTime(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    
    // إذا كان الوقت قد مر اليوم، جدولة ليوم غد
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  /// الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في الحصول على الإشعارات المعلقة', 
        e
      );
      return [];
    }
  }
  
  /// تفعيل/تعطيل جميع الإشعارات
  Future<bool> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationsEnabled, enabled);
      
      if (enabled) {
        await scheduleAllSavedNotifications();
      } else {
        await cancelAllNotifications();
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في تغيير حالة تفعيل الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      // إلغاء كل التنبيهات المجدولة عبر Android Alarm Manager
      if (Platform.isAndroid) {
        for (String notificationId in scheduledList) {
          final id = notificationId.hashCode.abs() % 100000;
          await AndroidAlarmManager.cancel(id);
          await prefs.remove('$_keyNotificationData$id');
        }
      }
      
      await prefs.setStringList(_keyScheduledNotifications, []);
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في إلغاء جميع الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// إلغاء إشعار بمعرف محدد
  Future<bool> cancelNotification(String notificationId) async {
    try {
      final id = notificationId.hashCode.abs() % 100000;
      
      await _flutterLocalNotificationsPlugin.cancel(id);
      
      if (Platform.isAndroid) {
        await AndroidAlarmManager.cancel(id);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      if (scheduledList.contains(notificationId)) {
        scheduledList.remove(notificationId);
        await prefs.setStringList(_keyScheduledNotifications, scheduledList);
      }
      
      await prefs.remove('$_keyNotificationData$id');
      await prefs.remove('notification_${notificationId}_time');
      await prefs.remove('notification_${notificationId}_title');
      await prefs.remove('notification_${notificationId}_body');
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في إلغاء الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
}
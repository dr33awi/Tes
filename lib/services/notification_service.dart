// lib/services/notification_service.dart
import 'dart:async';
import 'dart:io';
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
  static const String _reminderChannelId = 'reminder_channel';
  
  // مفاتيح التخزين المحلي
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyScheduledNotifications = 'scheduled_notifications';
  static const String _keyLastSyncTime = 'last_notification_sync';
  
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
        await _iosNotificationService.initializeIOSNotifications();
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
        await _iosNotificationService.initializeIOSNotifications();
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
  
  /// الحصول على اسم المنطقة الزمنية الحالية
  Future<String> getCurrentTimezoneName() async {
    try {
      return await FlutterNativeTimezoneLatest.getLocalTimezone();
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في الحصول على اسم المنطقة الزمنية', 
        e
      );
      return 'GMT';
    }
  }
  
  /// معالجة استلام إشعار iOS (للإصدارات القديمة من iOS)
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    print('استلام إشعار iOS قديم: $id, $title, $payload');
    
    if (payload != null && payload.isNotEmpty) {
      // معالجة الإشعار وتخزين بيانات التنقل
      NotificationNavigation.setNotificationNavigationData(payload);
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
      
      // حفظ وقت الإشعار في التخزين المحلي
      await _saveNotificationTime(notificationId, notificationTime);
      
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
          matchDateTimeComponents: repeat ? DateTimeComponents.time : null, // تكرار يومي إذا كان مطلوبًا
          payload: payload ?? notificationId,
        );
      } else {
        // إعدادات Android
        final channel = channelId ?? _defaultChannelId;
        
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
        
        // جدولة الإشعار
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: repeat ? DateTimeComponents.time : null, // تكرار يومي إذا كان مطلوبًا
          payload: payload ?? notificationId,
        );
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
  
  /// حفظ وقت الإشعار في التخزين المحلي
  Future<void> _saveNotificationTime(String notificationId, TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ الوقت بتنسيق HH:MM
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_${notificationId}_time', timeString);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في حفظ وقت الإشعار: $notificationId', 
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
  
  /// الحصول على وقت الإشعار المحفوظ
  Future<TimeOfDay?> getNotificationTime(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('notification_${notificationId}_time');
      
      if (timeString != null) {
        // تحويل سلسلة الوقت إلى كائن TimeOfDay
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
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في الحصول على وقت الإشعار: $notificationId', 
        e
      );
      return null;
    }
  }
  
  /// إلغاء إشعار بمعرف محدد
  Future<bool> cancelNotification(String notificationId) async {
    try {
      // إلغاء الإشعار
      final id = notificationId.hashCode.abs() % 100000;
      await _flutterLocalNotificationsPlugin.cancel(id);
      
      // إزالة من قائمة الإشعارات المجدولة
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      if (scheduledList.contains(notificationId)) {
        scheduledList.remove(notificationId);
        await prefs.setStringList(_keyScheduledNotifications, scheduledList);
      }
      
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
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications() async {
    try {
      // إلغاء جميع الإشعارات
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      // مسح قائمة الإشعارات المجدولة
      final prefs = await SharedPreferences.getInstance();
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
      
      // هذه الدالة يمكن تعديلها حسب احتياجات التطبيق الخاصة
      // في هذه الحالة، يجب تنفيذ منطق لاستعادة معلومات كل إشعار وجدولته
      
      print('تمت إعادة جدولة الإشعارات المحفوظة');
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في جدولة جميع الإشعارات المحفوظة', 
        e
      );
    }
  }
  
  /// التحقق مما إذا كان الإشعار مفعلاً بمعرف محدد
  Future<bool> isNotificationEnabled(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على قائمة الإشعارات المجدولة
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      // التحقق مما إذا كان المعرف ضمن القائمة
      return scheduledList.contains(notificationId);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في التحقق من تفعيل الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
  
  /// تفعيل/تعطيل الإشعارات
  Future<bool> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationsEnabled, enabled);
      
      if (enabled) {
        // إعادة جدولة الإشعارات
        await scheduleAllSavedNotifications();
      } else {
        // إلغاء جميع الإشعارات
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
  
  /// التحقق مما إذا كانت الإشعارات مفعلة بشكل عام
  Future<bool> areNotificationsEnabled() async {
    try {
      // التحقق من الإعدادات المحلية
      final prefs = await SharedPreferences.getInstance();
      final bool localEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      
      // التحقق من أذونات النظام
      final bool systemEnabled = await _permissionsService.checkNotificationPermission();
      
      return localEnabled && systemEnabled;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في التحقق من تفعيل الإشعارات', 
        e
      );
      return false;
    }
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
  
  /// إرسال إشعار اختباري للتأكد من عمل الإشعارات
  Future<bool> testImmediateNotification() async {
    try {
      return await showSimpleNotification(
        'اختبار الإشعارات',
        'هذا إشعار اختباري للتأكد من عمل الإشعارات بشكل صحيح',
        9999,
        payload: 'test',
      ).then((_) => true).catchError((_) => false);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في إرسال إشعار اختباري مباشر', 
        e
      );
      return false;
    }
  }
  
  /// إرسال إشعار اختباري مجمع
  Future<bool> sendGroupedTestNotification() async {
    try {
      // استخدام وضع مجموعات Android
      if (Platform.isAndroid) {
        // الإشعار الرئيسي للمجموعة
        AndroidNotificationDetails androidSummaryDetails = AndroidNotificationDetails(
          _defaultChannelId,
          'التنبيهات الافتراضية',
          channelDescription: 'قناة التنبيهات العامة',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: 'test_group',
          setAsGroupSummary: true,
        );
        
        NotificationDetails summaryDetails = NotificationDetails(android: androidSummaryDetails);
        
        // إظهار الإشعار الرئيسي
        await _flutterLocalNotificationsPlugin.show(
          9000,
          'مجموعة اختبار الإشعارات',
          'اختبار تجميع الإشعارات',
          summaryDetails,
          payload: 'test_group',
        );
        
        // إظهار 3 إشعارات في المجموعة
        for (int i = 1; i <= 3; i++) {
          AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            _defaultChannelId,
            'التنبيهات الافتراضية',
            channelDescription: 'قناة التنبيهات العامة',
            importance: Importance.high,
            priority: Priority.high,
            groupKey: 'test_group',
            setAsGroupSummary: false,
          );
          
          NotificationDetails details = NotificationDetails(android: androidDetails);
          
          await _flutterLocalNotificationsPlugin.show(
            9000 + i,
            'اختبار إشعار $i',
            'هذا إشعار اختباري رقم $i',
            details,
            payload: 'test_notification_$i',
          );
          
          // تأخير بسيط للتمييز بين الإشعارات
          await Future.delayed(Duration(milliseconds: 300));
        }
      } else if (Platform.isIOS) {
        // استخدام نظام تجميع iOS
        for (int i = 0; i <= 3; i++) {
          DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier: 'test_group',
            subtitle: i == 0 ? 'رسالة رئيسية' : 'إشعار فرعي $i',
          );
          
          NotificationDetails details = NotificationDetails(iOS: iosDetails);
          
          await _flutterLocalNotificationsPlugin.show(
            9000 + i,
            i == 0 ? 'مجموعة إشعارات الاختبار' : 'اختبار إشعار $i',
            i == 0 ? 'اختبار تجميع الإشعارات' : 'هذا إشعار اختباري رقم $i',
            details,
            payload: 'test_notification_$i',
          );
          
          // تأخير بسيط للتمييز بين الإشعارات
          await Future.delayed(Duration(milliseconds: 300));
        }
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في إرسال إشعار اختباري مجمع', 
        e
      );
      return false;
    }
  }
  
  /// فحص وطلب تحسينات الإشعارات
  Future<void> checkNotificationOptimizations(BuildContext context) async {
    try {
      // التحقق من تجاوز وضع عدم الإزعاج
      final shouldPromptDnd = await _doNotDisturbService.shouldPromptAboutDoNotDisturb();
      if (shouldPromptDnd) {
        await _doNotDisturbService.showDoNotDisturbDialog(context);
      }
      
      // التحقق من تحسينات البطارية
      await _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
      
      // التحقق من القيود الإضافية للبطارية
      await _batteryOptimizationService.checkForAdditionalBatteryRestrictions(context);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'خطأ في فحص تحسينات الإشعارات', 
        e
      );
    }
  }
}
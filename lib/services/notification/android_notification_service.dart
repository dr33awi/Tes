// lib/services/notification/android_notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/permissions_service.dart';
import 'package:test_athkar_app/services/notification/notification_service_interface.dart';
import 'package:test_athkar_app/services/notification/notification_helpers.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// آلية تخزين مؤقت للإعدادات لتحسين الأداء
class NotificationConfigCache {
  static NotificationConfig? _cachedConfig;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidity = Duration(minutes: 5);
  
  static NotificationConfig? getCachedConfig() {
    if (_cachedConfig != null && _lastCacheTime != null) {
      if (DateTime.now().difference(_lastCacheTime!) < _cacheValidity) {
        return _cachedConfig;
      }
    }
    return null;
  }
  
  static void cacheConfig(NotificationConfig config) {
    _cachedConfig = config;
    _lastCacheTime = DateTime.now();
  }
  
  static void clearCache() {
    _cachedConfig = null;
    _lastCacheTime = null;
  }
}

/// فئة بيانات للدفعة
class NotificationBatchItem {
  final String notificationId;
  final String title;
  final String body;
  final TimeOfDay notificationTime;
  final String? channelId;
  final String? payload;
  final Color? color;
  final int? priority;
  final String? groupKey;
  
  NotificationBatchItem({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.notificationTime,
    this.channelId,
    this.payload,
    this.color,
    this.priority,
    this.groupKey,
  });
}

/// تنفيذ خدمة الإشعارات الموحدة لنظام Android
class AndroidNotificationService implements NotificationServiceInterface {
  // كائن FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // خدمات التبعية المعكوسة
  final ErrorLoggingService _errorLoggingService;
  final DoNotDisturbService _doNotDisturbService;
  final BatteryOptimizationService _batteryOptimizationService;
  final PermissionsService _permissionsService;
  
  // معرفات قناة الإشعارات الموحدة
  static const String _defaultChannelId = 'default_channel';
  static const String _highPriorityChannelId = 'high_priority_channel';
  static const String _scheduledChannelId = 'scheduled_channel';
  static const String _reminderChannelId = 'reminder_channel';
  static const String _athkarChannelId = 'athkar_channel_id';
  
  // مفاتيح التخزين المحلي
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyScheduledNotifications = 'scheduled_notifications';
  static const String _keyNotificationConfig = 'notification_config';
  static const String _keyNotificationData = 'notification_data_';
  
  // كائن التكوين
  NotificationConfig _config = NotificationConfig();
  
  // متغير للتحقق من تهيئة timezone
  static bool _timezoneInitialized = false;
  
  // المنشئ
  AndroidNotificationService({
    required ErrorLoggingService errorLoggingService,
    required DoNotDisturbService doNotDisturbService,
    required BatteryOptimizationService batteryOptimizationService,
    required PermissionsService permissionsService,
  }) : 
    _errorLoggingService = errorLoggingService,
    _doNotDisturbService = doNotDisturbService,
    _batteryOptimizationService = batteryOptimizationService,
    _permissionsService = permissionsService;
  
  @override
  Future<bool> initialize() async {
    try {
      print('بدء تهيئة خدمة إشعارات Android الموحدة...');
      
      // تهيئة التوقيت المحلي إذا لم يتم بعد
      if (!_timezoneInitialized) {
        tz_data.initializeTimeZones();
        final location = tz.getLocation('Asia/Riyadh');
        tz.setLocalLocation(location);
        _timezoneInitialized = true;
      }
      
      // تحميل تكوين الإشعارات
      await _loadNotificationConfig();
      
      // إعداد قنوات الإشعارات
      await _initializeNotificationChannels();
      
      // تكوين معالجات الإشعارات
      await _setupNotificationHandlers();
      
      // تكوين وضع عدم الإزعاج للإشعارات
      await _doNotDisturbService.configureNotificationChannelsForDoNotDisturb();
      
      // تنظيف الإشعارات القديمة
      await cleanupOldNotifications();
      
      print('اكتملت تهيئة خدمة إشعارات Android بنجاح');
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تهيئة خدمة إشعارات Android', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> configureFromPreferences() async {
    try {
      await _loadNotificationConfig();
      await _initializeNotificationChannels();
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تكوين الإشعارات من التفضيلات', 
        e
      );
      return false;
    }
  }
  
  /// تحميل تكوين الإشعارات من التخزين المحلي
  Future<void> _loadNotificationConfig() async {
    try {
      // التحقق من الكاش أولاً
      final cachedConfig = NotificationConfigCache.getCachedConfig();
      if (cachedConfig != null) {
        _config = cachedConfig;
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString(_keyNotificationConfig);
      
      if (configString != null) {
        _config = NotificationConfig.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(configString)
          )
        );
      } else {
        _config = NotificationConfig();
      }
      
      // حفظ في الكاش
      NotificationConfigCache.cacheConfig(_config);
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تحميل تكوين الإشعارات', 
        e
      );
    }
  }
  
  /// حفظ تكوين الإشعارات
  Future<void> _saveNotificationConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationConfig, jsonEncode(_config.toJson()));
      
      // تحديث الكاش
      NotificationConfigCache.cacheConfig(_config);
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في حفظ تكوين الإشعارات', 
        e
      );
    }
  }
  
  @override
  Future<bool> checkNotificationPrerequisites(BuildContext context) async {
    try {
      // التحقق من أذونات الإشعارات
      final hasPermission = await _permissionsService.checkNotificationPermission();
      if (!hasPermission) {
        final granted = await _permissionsService.showNotificationPermissionDialog(context);
        if (!granted) {
          return false;
        }
      }
      
      // التحقق من تحسينات البطارية
      final batteryOptEnabled = await _batteryOptimizationService.isBatteryOptimizationEnabled();
      if (batteryOptEnabled) {
        await _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
      }
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في التحقق من متطلبات الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// تهيئة قنوات الإشعارات الموحدة
  Future<void> _initializeNotificationChannels() async {
    try {
      // قائمة قنوات الإشعارات الموحدة
      List<AndroidNotificationChannel> channels = [
        // القناة الافتراضية
        AndroidNotificationChannel(
          _defaultChannelId,
          'الإشعارات الافتراضية',
          description: 'الإشعارات العامة للتطبيق',
          importance: Importance.values[_config.importance],
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
          showBadge: true,
        ),
        
        // قناة الأذكار الرئيسية (مع تجاوز DND)
        AndroidNotificationChannel(
          _athkarChannelId,
          'إشعارات الأذكار',
          description: 'إشعارات تذكير بالأذكار اليومية',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          showBadge: true,
          bypassDnd: true,
        ),
        
        // قناة ذات أولوية عالية
        AndroidNotificationChannel(
          _highPriorityChannelId,
          'إشعارات مهمة',
          description: 'إشعارات ذات أولوية عالية',
          importance: Importance.max,
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
          showBadge: true,
          bypassDnd: true,
        ),
        
        // قناة الإشعارات المجدولة
        AndroidNotificationChannel(
          _scheduledChannelId,
          'الإشعارات المجدولة',
          description: 'إشعارات مجدولة مسبقاً',
          importance: Importance.high,
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
          showBadge: true,
          bypassDnd: true,
        ),
        
        // قناة التذكيرات
        AndroidNotificationChannel(
          _reminderChannelId,
          'التذكيرات',
          description: 'تذكيرات عامة',
          importance: Importance.high,
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
          showBadge: true,
        ),
      ];
      
      // تسجيل قنوات الإشعارات
      for (var channel in channels) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
      
      // إعداد منصة Android
      final androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // إعداد الإشعارات
      final initSettings = InitializationSettings(
        android: androidInitSettings,
      );
      
      // تهيئة الإشعارات مع تعيين معالجات الاستجابة
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );
      
      // طلب أذونات الإشعارات إذا لزم الأمر (Android 13+)
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          final bool? granted = await androidImplementation.requestNotificationsPermission();
          print('إذن الإشعارات: ${granted ?? false}');
        }
      }
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تهيئة قنوات الإشعارات', 
        e
      );
    }
  }
  
  /// إعداد معالجات الإشعارات
  Future<void> _setupNotificationHandlers() async {
    try {
      print('تم إعداد معالجات الإشعارات');
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
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
        _saveNotificationNavigationData(payload);
        
        if (actionId != null) {
          _handleNotificationAction(actionId, payload);
        }
      }
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في معالجة استجابة الإشعار', 
        e
      );
    }
  }
  
  /// معالجة استجابة الإشعار في الخلفية
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('استجابة إشعار في الخلفية: ${response.actionId}, ${response.payload}');
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
          break;
      }
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في معالجة إجراء الإشعار: $actionId', 
        e
      );
    }
  }
  
  /// تمييز الإشعار كمقروء
  Future<void> _markAsRead(String payload) async {
    try {
      final parts = payload.split(':');
      final notificationId = parts[0];
      
      final prefs = await SharedPreferences.getInstance();
      
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('${notificationId}_last_read', now);
      
      final readCount = prefs.getInt('${notificationId}_read_count') ?? 0;
      await prefs.setInt('${notificationId}_read_count', readCount + 1);
      
      await showSimpleNotification(
        'تم تسجيل القراءة',
        'تم تسجيل قراءة المحتوى بنجاح',
        10000 + notificationId.hashCode,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تمييز الإشعار كمقروء: $payload', 
        e
      );
    }
  }
  
  /// تأجيل الإشعار
  Future<void> _snoozeNotification(String payload) async {
    try {
      final parts = payload.split(':');
      final notificationId = parts[0];
      
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: 30));
      
      final androidDetails = AndroidNotificationDetails(
        _reminderChannelId,
        'تذكيرات مؤجلة',
        channelDescription: 'قناة التذكيرات المؤجلة',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        20000 + notificationId.hashCode,
        'تذكير مؤجل',
        'تذكير بالمحتوى الذي تم تأجيله',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: notificationId,
      );
      
      await showSimpleNotification(
        'تم تأجيل الإشعار',
        'سيتم تذكيرك بعد 30 دقيقة',
        10001 + notificationId.hashCode,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تأجيل الإشعار: $payload', 
        e
      );
    }
  }
  
  /// حفظ بيانات التنقل من الإشعار
  Future<void> _saveNotificationNavigationData(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('opened_from_notification', true);
      await prefs.setString('notification_payload', payload);
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في حفظ بيانات التنقل من الإشعار', 
        e
      );
    }
  }
  
  @override
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
      print('جدولة إشعار: $notificationId في ${notificationTime.hour}:${notificationTime.minute}');
      
      final hasPermission = await _permissionsService.checkNotificationPermission();
      if (!hasPermission) {
        print('لا توجد أذونات للإشعارات');
        return false;
      }
      
      // حفظ معلومات الإشعار الكاملة
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
      
      final id = notificationId.hashCode.abs() % 100000;
      
      // إضافة دعم التجميع إذا كان payload يحتوي على category ID
      String? groupKey;
      if (payload != null && payload.contains('athkar_')) {
        final parts = payload.split('_');
        if (parts.length > 1) {
          groupKey = NotificationHelpers.getGroupKeyForCategory(parts[1]);
        }
      }
      
      // تحسين الجدولة باستخدام flutter_local_notifications
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        notificationTime.hour,
        notificationTime.minute,
        0,
        0,
        0,
      );
      
      // إذا كان الوقت قد مر اليوم، جدولة ليوم غد
      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
      }
      
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
      
      // استخدام القناة المناسبة بناءً على الأولوية
      String actualChannelId = channelId ?? _athkarChannelId;
      if (priority != null && priority >= 4) {
        actualChannelId = _highPriorityChannelId;
      }
      
      final androidDetails = AndroidNotificationDetails(
        actualChannelId,
        'إشعارات الأذكار',
        channelDescription: 'إشعارات تذكير بالأذكار اليومية',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        enableVibration: true,
        playSound: true,
        enableLights: true,
        color: color,
        groupKey: groupKey,
        channelShowBadge: true,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'MARK_READ',
            'تم القراءة',
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'SNOOZE',
            'تأجيل',
            showsUserInterface: false,
          ),
        ],
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      // جدولة الإشعار مع إعدادات محسنة
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeat ? DateTimeComponents.time : null,
        payload: payload ?? notificationId,
      );
      
      await _updateScheduledNotificationsList(notificationId);
      
      print('تم جدولة الإشعار بنجاح: $notificationId في $tzScheduledTime');
      
      // اختبار الإشعار الفوري للتأكد من عمل النظام
      if (DateTime.now().difference(scheduledDateTime).inMinutes > 60) {
        // إذا كان الإشعار مجدول لأكثر من ساعة، أرسل إشعار تأكيد
        await showSimpleNotification(
          'تم جدولة الإشعار',
          'سيصلك إشعار "$title" في ${notificationTime.hour}:${notificationTime.minute}',
          999999,
        );
      }
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في جدولة الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
  
  /// حفظ معلومات الإشعار الكاملة
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
        'lastScheduled': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString('$_keyNotificationData$id', jsonEncode(info));
      
      // أيضاً حفظ الوقت بشكل منفصل للتوافق القديم
      final timeString = '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_${notificationId}_time', timeString);
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في حفظ معلومات الإشعار الكاملة', 
        e
      );
    }
  }
  
  @override
  Future<bool> scheduleMultipleNotifications({
    required String baseId,
    required String title,
    required String body,
    required List<TimeOfDay> notificationTimes,
    String? channelId,
    String? payload,
    Color? color,
    bool repeat = true,
  }) async {
    try {
      bool allSuccess = true;
      
      for (int i = 0; i < notificationTimes.length; i++) {
        final notificationId = '${baseId}_$i';
        final success = await scheduleNotification(
          notificationId: notificationId,
          title: title,
          body: body,
          notificationTime: notificationTimes[i],
          channelId: channelId,
          payload: payload ?? baseId,
          color: color,
          repeat: repeat,
        );
        
        if (!success) {
          allSuccess = false;
        }
      }
      
      return allSuccess;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في جدولة إشعارات متعددة', 
        e
      );
      return false;
    }
  }
  
  /// جدولة إشعارات متعددة بشكل دفعات لتحسين الأداء
  Future<bool> scheduleMultipleNotificationsBatch({
    required List<NotificationBatchItem> items,
    bool repeat = true,
  }) async {
    try {
      final hasPermission = await _permissionsService.checkNotificationPermission();
      if (!hasPermission) {
        return false;
      }
      
      // معالجة دفعات كبيرة بكفاءة
      const int batchSize = 10;
      
      for (int i = 0; i < items.length; i += batchSize) {
        final batch = items.skip(i).take(batchSize).toList();
        
        await Future.wait(batch.map((item) async {
          await scheduleNotification(
            notificationId: item.notificationId,
            title: item.title,
            body: item.body,
            notificationTime: item.notificationTime,
            channelId: item.channelId,
            payload: item.payload,
            color: item.color,
            repeat: repeat,
            priority: item.priority,
          );
        }));
        
        // تأخير بسيط بين الدفعات لتجنب إرهاق النظام
        if (i + batchSize < items.length) {
          await Future.delayed(Duration(milliseconds: 50));
        }
      }
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService',
        'خطأ في جدولة دفعة الإشعارات',
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> cancelNotification(String notificationId) async {
    try {
      final id = notificationId.hashCode.abs() % 100000;
      
      await _flutterLocalNotificationsPlugin.cancel(id);
      
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      if (scheduledList.contains(notificationId)) {
        scheduledList.remove(notificationId);
        await prefs.setStringList(_keyScheduledNotifications, scheduledList);
      }
      
      await prefs.remove('$_keyNotificationData$id');
      await prefs.remove('notification_${notificationId}_time');
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في إلغاء الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      for (String notificationId in scheduledList) {
        final id = notificationId.hashCode.abs() % 100000;
        await prefs.remove('$_keyNotificationData$id');
      }
      
      await prefs.setStringList(_keyScheduledNotifications, []);
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في إلغاء جميع الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// تحديث قائمة الإشعارات المجدولة
  Future<void> _updateScheduledNotificationsList(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      if (!scheduledList.contains(notificationId)) {
        scheduledList.add(notificationId);
        await prefs.setStringList(_keyScheduledNotifications, scheduledList);
      }
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تحديث قائمة الإشعارات المجدولة', 
        e
      );
    }
  }
  
  @override
  Future<void> scheduleAllSavedNotifications() async {
    try {
      print('جاري إعادة جدولة جميع الإشعارات المحفوظة...');
      
      final prefs = await SharedPreferences.getInstance();
      
      final bool notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      if (!notificationsEnabled) {
        print('الإشعارات غير مفعلة في الإعدادات');
        return;
      }
      
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      if (scheduledList.isEmpty) {
        print('لا توجد إشعارات مجدولة للإعادة');
        return;
      }
      
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
          // محاولة استرجاع من الطريقة القديمة
          final timeString = prefs.getString('notification_${notificationId}_time');
          if (timeString != null) {
            final timeParts = timeString.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);
              
              if (hour != null && minute != null) {
                final time = TimeOfDay(hour: hour, minute: minute);
                
                await scheduleNotification(
                  notificationId: notificationId,
                  title: 'تذكير',
                  body: 'حان وقت التذكير',
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
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في جدولة جميع الإشعارات المحفوظة', 
        e
      );
    }
  }
  
  @override
  Future<bool> isNotificationEnabled(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      return scheduledList.contains(notificationId);
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في التحقق من تفعيل الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
  
  @override
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
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تغيير حالة تفعيل الإشعارات', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool localEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      final bool systemEnabled = await _permissionsService.checkNotificationPermission();
      
      return localEnabled && systemEnabled;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في التحقق من تفعيل الإشعارات', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في الحصول على الإشعارات المعلقة', 
        e
      );
      return [];
    }
  }
  
  @override
  Future<void> checkNotificationOptimizations(BuildContext context) async {
    try {
      final shouldPromptDnd = await _doNotDisturbService.shouldPromptAboutDoNotDisturb();
      if (shouldPromptDnd) {
        await _doNotDisturbService.showDoNotDisturbDialog(context);
      }
      
      await _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
      await _batteryOptimizationService.checkForAdditionalBatteryRestrictions(context);
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في فحص تحسينات الإشعارات', 
        e
      );
    }
  }
  
  @override
  Future<TimeOfDay?> getNotificationTime(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = notificationId.hashCode.abs() % 100000;
      
      // محاولة استرجاع من الطريقة الجديدة أولاً
      final infoString = prefs.getString('$_keyNotificationData$id');
      if (infoString != null) {
        final info = jsonDecode(infoString);
        return TimeOfDay(hour: info['hour'], minute: info['minute']);
      }
      
      // محاولة من الطريقة القديمة
      final timeString = prefs.getString('notification_${notificationId}_time');
      
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
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في الحصول على وقت الإشعار: $notificationId', 
        e
      );
      return null;
    }
  }
  
  /// تنظيف الإشعارات القديمة لتحسين الأداء
  Future<void> cleanupOldNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      final List<String> activeNotifications = [];
      
      // التحقق من كل إشعار محفوظ
      for (String notificationId in scheduledList) {
        final id = notificationId.hashCode.abs() % 100000;
        final infoString = prefs.getString('$_keyNotificationData$id');
        
        if (infoString != null) {
          final info = jsonDecode(infoString);
          final lastScheduled = info['lastScheduled'];
          
          // إزالة الإشعارات التي لم تُجدول منذ 30 يوماً
          if (lastScheduled != null) {
            final lastDate = DateTime.parse(lastScheduled);
            if (DateTime.now().difference(lastDate).inDays > 30) {
              await prefs.remove('$_keyNotificationData$id');
              continue;
            }
          }
          
          activeNotifications.add(notificationId);
        }
      }
      
      // تحديث القائمة
      await prefs.setStringList(_keyScheduledNotifications, activeNotifications);
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService',
        'خطأ في تنظيف الإشعارات القديمة',
        e
      );
    }
  }
  
  // الطرق الجديدة المطلوبة لحل أخطاء البناء
  
  @override
  Future<void> showSimpleNotification(
    String title,
    String body,
    int notificationId, {
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _defaultChannelId,
        'الإشعارات الافتراضية',
        channelDescription: 'الإشعارات العامة للتطبيق',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService',
        'خطأ في إظهار الإشعار البسيط',
        e
      );
    }
  }
  
  @override
  Future<bool> testImmediateNotification() async {
    try {
      await showSimpleNotification(
        'اختبار الإشعارات',
        'هذا إشعار تجريبي فوري للتأكد من عمل النظام',
        DateTime.now().millisecondsSinceEpoch,
      );
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService',
        'خطأ في اختبار الإشعار الفوري',
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> sendGroupedTestNotification() async {
    try {
      const String groupKey = 'test_grouped_notifications';
      const String groupChannelId = 'grouped_notifications';
      
      // إنشاء قناة للإشعارات المجمعة
      const AndroidNotificationChannel groupChannel = AndroidNotificationChannel(
        groupChannelId,
        'إشعارات مجمعة',
        description: 'قناة الإشعارات المجمعة',
        importance: Importance.high,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(groupChannel);
      
      // إرسال عدة إشعارات فردية في المجموعة
      for (int i = 0; i < 3; i++) {
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          groupChannelId,
          'إشعارات مجمعة',
          channelDescription: 'قناة الإشعارات المجمعة',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: false,
          icon: '@mipmap/ic_launcher',
        );
        
        final NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
        );
        
        await _flutterLocalNotificationsPlugin.show(
          i + 1000, // IDs فريدة للإشعارات
          'إشعار مجمع ${i + 1}',
          'هذا هو الإشعار المجمع رقم ${i + 1}',
          notificationDetails,
        );
      }
      
      // إرسال إشعار ملخص المجموعة
      const AndroidNotificationDetails summaryDetails = AndroidNotificationDetails(
        groupChannelId,
        'إشعارات مجمعة',
        channelDescription: 'قناة الإشعارات المجمعة',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: groupKey,
        setAsGroupSummary: true,
        icon: '@mipmap/ic_launcher',
      );
      
      const NotificationDetails summaryNotificationDetails = NotificationDetails(
        android: summaryDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        2000, // ID فريد لملخص المجموعة
        'ملخص الإشعارات المجمعة',
        'لديك 3 إشعارات جديدة',
        summaryNotificationDetails,
      );
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService',
        'خطأ في إرسال الإشعارات المجمعة التجريبية',
        e
      );
      return false;
    }
  }
}
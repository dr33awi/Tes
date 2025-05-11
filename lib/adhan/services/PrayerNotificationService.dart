import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/adhan/models/prayer_time_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/battery_optimization_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/do_not_disturb_service.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/ios_notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';

class EnhancedPrayerNotificationService {
  // Singleton pattern implementation
  static final EnhancedPrayerNotificationService _instance = EnhancedPrayerNotificationService._internal();
  factory EnhancedPrayerNotificationService() => _instance;
  EnhancedPrayerNotificationService._internal();

  // Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // الخدمات المساعدة
  final BatteryOptimizationService _batteryService = BatteryOptimizationService();
  final DoNotDisturbService _dndService = DoNotDisturbService();
  final IOSNotificationService _iosService = IOSNotificationService();
  
  // Notification settings
  bool _isNotificationEnabled = true;
  final Map<String, bool> _prayerNotificationSettings = {
    'الفجر': true,
    'الشروق': false,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };
  
  // أوقات مسبقة للتذكير (بالدقائق)
  final Map<String, int> _prayerReminderTimes = {
    'الفجر': 15,
    'الشروق': 5,
    'الظهر': 10,
    'العصر': 10,
    'المغرب': 5,
    'العشاء': 10,
  };
  
  // إعدادات جديدة للإشعارات
  bool _bypassDND = false;  // تجاوز وضع عدم الإزعاج
  bool _useHighPriority = true;  // استخدام أولوية عالية للإشعارات
  bool _showReminderNotifications = true;  // عرض إشعارات التذكير
  bool _usePersistentNotifications = false;  // استخدام إشعارات دائمة
  bool _groupNotifications = true;  // تجميع الإشعارات
  
  // Store device timezone
  String _deviceTimeZone = 'UTC';
  
  // إحصائيات الإشعارات
  int _sentNotificationsCount = 0;
  int _interactedNotificationsCount = 0;
  DateTime? _lastNotificationSentTime;
  
  // آلية تتبع وإعادة الجدولة
  final Map<int, DateTime> _scheduledNotifications = {};
  Timer? _rescheduleCheckTimer;
  
  // Alarm IDs for background notifications
  static const int fajrAlarmId = 2001;
  static const int sunriseAlarmId = 2002;
  static const int dhuhrAlarmId = 2003;
  static const int asrAlarmId = 2004;
  static const int maghribAlarmId = 2005;
  static const int ishaAlarmId = 2006;
  
  bool _isInitialized = false;
  BuildContext? _context;
  
  // Flag to prevent recursion
  bool _isSchedulingInProgress = false;
  
  // معرف قناة الإشعارات
  static const String notificationChannelId = 'prayer_times_channel';
  
  // احصائيات وتشخيص
  final Map<String, int> _notificationStats = {
    'scheduled': 0,
    'delivered': 0,
    'failed': 0,
    'interacted': 0,
    'lastScheduleAttempt': 0,
    'lastDeliveryAttempt': 0,
  };
  
  // قائمة بآخر الأخطاء
  final List<String> _lastErrors = [];

  // Initialize the service
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Prayer notification service already initialized');
      return true;
    }
    
    try {
      debugPrint('Initializing prayer notification service...');
      
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // Get device timezone
      try {
        _deviceTimeZone = await FlutterNativeTimezoneLatest.getLocalTimezone();
        // Set the timezone
        tz.setLocalLocation(tz.getLocation(_deviceTimeZone));
        debugPrint('Device timezone: $_deviceTimeZone');
      } catch (e) {
        debugPrint('Error getting device timezone: $e');
        // Fallback to a safe default
        _deviceTimeZone = 'UTC';
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
      
      // تهيئة الخدمات المساعدة
      await _batteryService.initialize();
      await _dndService.initialize();
      
      // Initialize Android Alarm Manager
      if (Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }
      
      // Configure local notifications
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      // استخدام خدمة iOS المخصصة للتهيئة
      final darwinSettings = await _iosService.getNotificationSettings();
          
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );
      
      // تهيئة خدمة الإشعارات
      final success = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      debugPrint('Notification plugin initialization result: $success');
      
      // Load saved settings
      await _loadNotificationSettings();
      await _loadStats();
      
      // Create notification channel for Android
      await _createNotificationChannel();
      
      // بدء مؤقت فحص إعادة الجدولة
      _startRescheduleCheckTimer();
      
      _isInitialized = true;
      debugPrint('Prayer notification service initialized successfully');
      return true;
    } catch (e) {
      _addError('Error initializing notification service: $e');
      return false;
    }
  }
  
  // إضافة خطأ إلى قائمة الأخطاء
  void _addError(String error) {
    debugPrint(error);
    
    // الاحتفاظ بأحدث 10 أخطاء فقط
    if (_lastErrors.length >= 10) {
      _lastErrors.removeAt(0);
    }
    
    _lastErrors.add('${DateTime.now()}: $error');
  }
  
  // بدء مؤقت فحص إعادة الجدولة
  void _startRescheduleCheckTimer() {
    // إيقاف المؤقت السابق إن وجد
    _rescheduleCheckTimer?.cancel();
    
    // بدء مؤقت جديد يعمل كل ساعة
    _rescheduleCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndRescheduleNotifications();
    });
  }
  
  // فحص وإعادة جدولة الإشعارات الفائتة
  Future<void> _checkAndRescheduleNotifications() async {
    try {
      debugPrint('Checking for missed notifications to reschedule...');
      
      // الحصول على الوقت الحالي
      final now = DateTime.now();
      
      // تحديد الإشعارات التي يجب إعادة جدولتها
      final missedNotifications = <int>[];
      
      _scheduledNotifications.forEach((id, scheduledTime) {
        // إذا كان وقت الإشعار قد مر منذ أكثر من 3 ساعات ولم يتم تقديمه
        if (scheduledTime.isBefore(now.subtract(const Duration(hours: 3)))) {
          missedNotifications.add(id);
        }
      });
      
      if (missedNotifications.isNotEmpty) {
        debugPrint('Found ${missedNotifications.length} missed notifications to reschedule');
        
        // تحديث الإحصائيات
        _notificationStats['failed'] = (_notificationStats['failed'] ?? 0) + missedNotifications.length;
        await _saveStats();
        
        // إعادة جدولة الإشعارات الفائتة
        for (final id in missedNotifications) {
          // إزالة الإشعار من قائمة المتابعة
          _scheduledNotifications.remove(id);
        }
        
        // طلب إعادة جدولة جميع الإشعارات
        _notificationStats['lastScheduleAttempt'] = DateTime.now().millisecondsSinceEpoch;
        await _saveStats();
        
        // أي منطق آخر لتنفيذ إعادة الجدولة
      } else {
        debugPrint('No missed notifications found');
      }
    } catch (e) {
      _addError('Error checking for missed notifications: $e');
    }
  }
  
  // إنشاء قناة الإشعارات بأولوية عالية
  Future<void> _createNotificationChannel() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        // إنشاء قناة إشعارات عالية الأولوية
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          notificationChannelId,
          'Prayer Times',
          description: 'Notifications for prayer times',
          importance: _useHighPriority ? Importance.max : Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
        );
        
        await androidPlugin.createNotificationChannel(channel);
        
        // التأكد من تسجيل القناة
        final channels = await androidPlugin.getNotificationChannels();
        bool channelExists = false;
        
        if (channels != null) {
          for (var existingChannel in channels) {
            if (existingChannel.id == notificationChannelId) {
              channelExists = true;
              debugPrint('Prayer notification channel exists with importance: ${existingChannel.importance}');
              break;
            }
          }
        }
        
        debugPrint('Prayer notification channel created successfully: $channelExists');
      } else {
        debugPrint('Android plugin is null, cannot create notification channel');
      }
    } catch (e) {
      _addError('Error creating notification channel: $e');
    }
  }

  // التحقق من إذن الإشعارات
  Future<bool> checkNotificationPermission() async {
    try {
      // Check current permission status
      final status = await Permission.notification.status;
      debugPrint('Current notification permission status: $status');
      
      return status.isGranted;
    } catch (e) {
      _addError('Error checking notification permission: $e');
      return false;
    }
  }
  
  // طلب إذن الإشعارات
  Future<bool> requestNotificationPermission() async {
    try {
      debugPrint('Requesting notification permission...');
      
      // For Android 13+ (notification permission required)
      final permissionStatus = await Permission.notification.request();
      bool permissionGranted = permissionStatus.isGranted;
      
      debugPrint('Notification permission status: $permissionStatus');
      
      // For iOS
      if (Platform.isIOS) {
        permissionGranted = await _iosService.requestPermissions();
      }
      
      // Save permission status
      if (permissionGranted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('prayer_notification_permission_granted', true);
      } else {
        // إذا لم يتم منح الإذن، حاول عرض حوار توضيحي
        if (_context != null) {
          await _showNotificationPermissionDialog();
        }
      }
      
      return permissionGranted;
    } catch (e) {
      _addError('Error requesting notification permission: $e');
      return false;
    }
  }
  
  // طريقة لعرض حوار طلب الإذن
  Future<bool> _showNotificationPermissionDialog() async {
    if (_context == null) {
      debugPrint('Context is null, cannot show permission dialog');
      return false;
    }
    
    return await showDialog<bool>(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('إذن الإشعارات مطلوب'),
        content: const Text(
          'يحتاج التطبيق إلى إذن الإشعارات لتنبيهك بأوقات الصلاة. '
          'يرجى منح الإذن لتلقي إشعارات الصلاة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  void setContext(BuildContext context) {
    // Only update if different to avoid potential setState loops
    if (_context != context) {
      _context = context;
    }
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Prayer notification tapped: ${response.id}');
    debugPrint('Prayer notification payload: ${response.payload}');
    
    // زيادة عداد الإشعارات المتفاعل معها
    _interactedNotificationsCount++;
    _notificationStats['interacted'] = (_notificationStats['interacted'] ?? 0) + 1;
    _saveStats();
    
    // هنا يمكن إضافة منطق للانتقال إلى شاشة الصلوات عند النقر على الإشعار
  }
  
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load master toggle state
      _isNotificationEnabled = prefs.getBool('prayer_notification_enabled') ?? true;
      
      // Load individual prayer settings
      for (final prayer in _prayerNotificationSettings.keys) {
        final enabled = prefs.getBool('prayer_notification_$prayer') ?? 
            _prayerNotificationSettings[prayer]!;
        _prayerNotificationSettings[prayer] = enabled;
      }
      
      // تحميل أوقات التذكير المسبق
      for (final prayer in _prayerReminderTimes.keys) {
        final reminderMinutes = prefs.getInt('prayer_reminder_$prayer') ?? 
            _prayerReminderTimes[prayer]!;
        _prayerReminderTimes[prayer] = reminderMinutes;
      }
      
      // تحميل الإعدادات الجديدة
      _bypassDND = prefs.getBool('prayer_notification_bypass_dnd') ?? false;
      _useHighPriority = prefs.getBool('prayer_notification_high_priority') ?? true;
      _showReminderNotifications = prefs.getBool('prayer_notification_show_reminders') ?? true;
      _usePersistentNotifications = prefs.getBool('prayer_notification_persistent') ?? false;
      _groupNotifications = prefs.getBool('prayer_notification_group') ?? true;
      
      debugPrint('Prayer notification settings loaded successfully');
      debugPrint('Master toggle: $_isNotificationEnabled');
      debugPrint('Prayer settings: $_prayerNotificationSettings');
      debugPrint('Advanced settings: DND=$_bypassDND, HighPriority=$_useHighPriority');
    } catch (e) {
      _addError('Error loading notification settings: $e');
    }
  }
  
  Future<void> saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save master toggle state
      await prefs.setBool('prayer_notification_enabled', _isNotificationEnabled);
      
      // Save individual prayer settings
      for (final prayer in _prayerNotificationSettings.keys) {
        await prefs.setBool(
          'prayer_notification_$prayer', 
          _prayerNotificationSettings[prayer]!
        );
      }
      
      // تخزين أوقات التذكير المسبق
      for (final prayer in _prayerReminderTimes.keys) {
        await prefs.setInt(
          'prayer_reminder_$prayer', 
          _prayerReminderTimes[prayer]!
        );
      }
      
      // تخزين الإعدادات الجديدة
      await prefs.setBool('prayer_notification_bypass_dnd', _bypassDND);
      await prefs.setBool('prayer_notification_high_priority', _useHighPriority);
      await prefs.setBool('prayer_notification_show_reminders', _showReminderNotifications);
      await prefs.setBool('prayer_notification_persistent', _usePersistentNotifications);
      await prefs.setBool('prayer_notification_group', _groupNotifications);
      
      debugPrint('Prayer notification settings saved successfully');
    } catch (e) {
      _addError('Error saving notification settings: $e');
    }
  }
  
  // تحميل إحصائيات الإشعارات
  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل إحصائيات الإشعارات
      _sentNotificationsCount = prefs.getInt('prayer_notifications_sent_count') ?? 0;
      _interactedNotificationsCount = prefs.getInt('prayer_notifications_interacted_count') ?? 0;
      
      final lastSentTimeString = prefs.getString('prayer_notifications_last_sent_time');
      if (lastSentTimeString != null) {
        _lastNotificationSentTime = DateTime.parse(lastSentTimeString);
      }
      
      // تحميل إحصائيات التشخيص
      final statsString = prefs.getString('prayer_notification_stats');
      if (statsString != null) {
        final Map<String, dynamic> decoded = json.decode(statsString);
        decoded.forEach((key, value) {
          _notificationStats[key] = value as int;
        });
      }
      
      // تحميل الأخطاء
      final errorsString = prefs.getString('prayer_notification_errors');
      if (errorsString != null) {
        final List<dynamic> decoded = json.decode(errorsString);
        _lastErrors.clear();
        _lastErrors.addAll(decoded.map((e) => e.toString()));
      }
      
    } catch (e) {
      debugPrint('Error loading notification stats: $e');
    }
  }
  
  // حفظ إحصائيات الإشعارات
  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ إحصائيات الإشعارات
      await prefs.setInt('prayer_notifications_sent_count', _sentNotificationsCount);
      await prefs.setInt('prayer_notifications_interacted_count', _interactedNotificationsCount);
      
      if (_lastNotificationSentTime != null) {
        await prefs.setString('prayer_notifications_last_sent_time', _lastNotificationSentTime!.toIso8601String());
      }
      
      // حفظ إحصائيات التشخيص
      final String statsJson = json.encode(_notificationStats);
      await prefs.setString('prayer_notification_stats', statsJson);
      
      // حفظ الأخطاء
      final String errorsJson = json.encode(_lastErrors);
      await prefs.setString('prayer_notification_errors', errorsJson);
      
    } catch (e) {
      debugPrint('Error saving notification stats: $e');
    }
  }
  
  // اضافة طريقة لحفظ اخر تاريخ جدولة
  Future<void> saveLastScheduleDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      await prefs.setString('prayer_last_notification_schedule_date', today);
      debugPrint('Prayer last schedule date saved: $today');
    } catch (e) {
      _addError('Error saving prayer last schedule date: $e');
    }
  }
  
  // طريقة للتعامل مع وضع عدم الإزعاج
  Future<void> _checkAndHandleDNDMode() async {
    if (_bypassDND) {
      try {
        final isDNDActive = await _dndService.isDNDActive();
        if (isDNDActive) {
          debugPrint('DND mode is active, requesting temporary bypass...');
          // طلب تجاوز مؤقت لوضع عدم الإزعاج
          await _dndService.requestDNDBypass();
        }
      } catch (e) {
        _addError('Error checking DND mode: $e');
      }
    }
  }
  
  // التحقق من تحسين استهلاك البطارية
  Future<void> _checkAndRequestBatteryOptimization() async {
    try {
      final isBatteryOptimized = await _batteryService.isIgnoringBatteryOptimizations();
      if (!isBatteryOptimized) {
        debugPrint('Battery optimization is active, may affect notifications');
        
        // تحديث إحصائيات التشخيص
        _notificationStats['batteryOptimized'] = 1;
        await _saveStats();
      } else {
        _notificationStats['batteryOptimized'] = 0;
        await _saveStats();
      }
    } catch (e) {
      _addError('Error checking battery optimization: $e');
    }
  }
  
  // جدولة إشعار صلاة فردي محسنة
  Future<bool> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    required int notificationId,
    bool isReminder = false,
  }) async {
    // التحقق من تفعيل الإشعارات لهذه الصلاة
    if (!_isNotificationEnabled || !(_prayerNotificationSettings[prayerName] ?? false)) {
      debugPrint('Notifications disabled for $prayerName');
      return false;
    }
    
    // تخطي التذكير إذا كانت خاصية التذكير معطلة
    if (isReminder && !_showReminderNotifications) {
      debugPrint('Reminder notifications are disabled, skipping reminder for $prayerName');
      return false;
    }
    
    // التحقق من أن وقت الصلاة في المستقبل
    final now = DateTime.now();
    if (prayerTime.isBefore(now)) {
      debugPrint('Prayer time for $prayerName has already passed: $prayerTime');
      return false;
    }
    
    try {
      // التحقق من تحسين استهلاك البطارية
      await _checkAndRequestBatteryOptimization();
      
      // إعداد تفاصيل الإشعار الأندرويد بأقصى أولوية
      final androidDetails = AndroidNotificationDetails(
        notificationChannelId,
        'Prayer Times',
        channelDescription: 'Notifications for prayer times',
        importance: _useHighPriority ? Importance.max : Importance.high,
        priority: _useHighPriority ? Priority.max : Priority.high,
        styleInformation: BigTextStyleInformation(''),
        playSound: true,
        enableVibration: true,
        ticker: 'Prayer Time',
        fullScreenIntent: _useHighPriority,
        ongoing: _usePersistentNotifications && !isReminder, // الإشعارات الدائمة فقط للصلوات وليس للتذكير
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        color: _getPrayerColor(prayerName),
        ledColor: _getPrayerColor(prayerName),
        ledOnMs: 1000,
        ledOffMs: 500,
        groupKey: _groupNotifications ? 'prayer_notifications' : null,
      );
      
      // إعداد تفاصيل الإشعار iOS
      final iosDetails = await _iosService.getPrayerNotificationDetails(
        prayerName: prayerName,
        isReminder: isReminder,
        useHighPriority: _useHighPriority,
        bypassDND: _bypassDND
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // محتوى الإشعار
      String title, body;
      
      if (isReminder) {
        // تذكير قبل الصلاة
        final reminderMinutes = _prayerReminderTimes[prayerName] ?? 10;
        title = 'تذكير بصلاة $prayerName';
        body = 'سيحين وقت صلاة $prayerName بعد $reminderMinutes دقيقة';
      } else {
        // إشعار دخول وقت الصلاة
        title = 'حان وقت صلاة $prayerName';
        body = 'حان الآن وقت صلاة $prayerName';
      }
      
      // حفظ معلومات الإشعار في التخزين المشترك لاستخدامها لاحقًا
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_notification_${notificationId}_title', title);
      await prefs.setString('prayer_notification_${notificationId}_body', body);
      
      // التعامل مع وضع عدم الإزعاج إذا كان مفعلاً
      if (_bypassDND) {
        await _checkAndHandleDNDMode();
      }
      
      // تحويل DateTime إلى TZDateTime
      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);
      
      // جدولة الإشعار باستخدام المكتبة
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // للتكرار اليومي
        payload: 'prayer_$prayerName',
      );
      
      // إضافة الإشعار إلى قائمة المتابعة
      _scheduledNotifications[notificationId] = prayerTime;
      
      // جدولة الإشعار باستخدام AlarmManager للأندرويد
      if (Platform.isAndroid) {
        final alarmId = _getAlarmIdForPrayer(prayerName) + (isReminder ? 10000 : 0);
        
        // حساب الفرق الزمني بين الآن ووقت الإشعار
        final difference = prayerTime.difference(now);
        final diffInSeconds = difference.inSeconds;
        
        await AndroidAlarmManager.oneShot(
          Duration(seconds: diffInSeconds),
          alarmId,
          _showPrayerNotificationCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          allowWhileIdle: true,
          params: {
            'prayerName': prayerName,
            'notificationId': notificationId,
            'title': title,
            'body': body,
            'isReminder': isReminder,
            'useHighPriority': _useHighPriority,
            'bypassDND': _bypassDND,
            'usePersistentNotification': _usePersistentNotifications && !isReminder,
            'groupNotifications': _groupNotifications,
          },
        );
      }
      
      final timeString = '${prayerTime.hour}:${prayerTime.minute.toString().padLeft(2, '0')}';
      debugPrint('Successfully scheduled ${isReminder ? "reminder" : "notification"} for $prayerName at $timeString (ID: $notificationId)');
      
      // تحديث الإحصائيات
      _sentNotificationsCount++;
      _lastNotificationSentTime = DateTime.now();
      _notificationStats['scheduled'] = (_notificationStats['scheduled'] ?? 0) + 1;
      _notificationStats['lastScheduleAttempt'] = DateTime.now().millisecondsSinceEpoch;
      await _saveStats();
      
      return true;
    } catch (e) {
      _addError('Error scheduling prayer notification for $prayerName: $e');
      
      // تحديث إحصائيات الفشل
      _notificationStats['failed'] = (_notificationStats['failed'] ?? 0) + 1;
      await _saveStats();
      
      return false;
    }
  }
  
  // دالة ساكنة تُستدعى من قبل AlarmManager - محسنة
  @pragma('vm:entry-point')
  static void _showPrayerNotificationCallback(int id, Map<String, dynamic>? params) async {
    if (params == null) return;
    
    try {
      debugPrint('Prayer AlarmManager callback triggered for notification ID: $id');
      
      // استخراج معلومات الإشعار
      final prayerName = params['prayerName'] as String;
      final notificationId = params['notificationId'] as int;
      final title = params['title'] as String;
      final body = params['body'] as String;
      final isReminder = params['isReminder'] as bool;
      final useHighPriority = params['useHighPriority'] as bool? ?? true;
      final bypassDND = params['bypassDND'] as bool? ?? false;
      final usePersistentNotification = params['usePersistentNotification'] as bool? ?? false;
      final groupNotifications = params['groupNotifications'] as bool? ?? true;
      
      // تهيئة مكتبة الإشعارات
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await notifications.initialize(initSettings);
      
      // إنشاء قناة الإشعارات
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          notificationChannelId,
          'Prayer Times',
          description: 'Notifications for prayer times',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        
        await androidPlugin.createNotificationChannel(channel);
      }
      
      // التعامل مع وضع عدم الإزعاج
      if (bypassDND && Platform.isAndroid) {
        try {
          // التعامل مع وضع عدم الإزعاج في AlarmManager
          // هذا جزء من تحسين استدعاء AlarmManager
        } catch (e) {
          debugPrint('Error handling DND mode in AlarmManager: $e');
        }
      }
      
      // عرض الإشعار
      await notifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'Prayer Times',
            channelDescription: 'Notifications for prayer times',
            importance: useHighPriority ? Importance.max : Importance.high,
            priority: useHighPriority ? Priority.max : Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: useHighPriority,
            ongoing: usePersistentNotification,
            groupKey: groupNotifications ? 'prayer_notifications' : null,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: 'prayer_$prayerName',
      );
      
      debugPrint('AlarmManager prayer notification displayed: $title');
      
      // تحديث الإحصائيات إن أمكن
      try {
        final prefs = await SharedPreferences.getInstance();
        final sentCount = prefs.getInt('prayer_notifications_sent_count') ?? 0;
        await prefs.setInt('prayer_notifications_sent_count', sentCount + 1);
        await prefs.setString('prayer_notifications_last_sent_time', DateTime.now().toIso8601String());
        
        // تحديث إحصائيات التشخيص
        final statsString = prefs.getString('prayer_notification_stats') ?? '{}';
        final Map<String, dynamic> stats = Map<String, dynamic>.from(json.decode(statsString));
        stats['delivered'] = (stats['delivered'] ?? 0) + 1;
        stats['lastDeliveryAttempt'] = DateTime.now().millisecondsSinceEpoch;
        await prefs.setString('prayer_notification_stats', json.encode(stats));
      } catch (e) {
        debugPrint('Error updating notification stats in AlarmManager: $e');
      }
    } catch (e) {
      debugPrint('Error in AlarmManager prayer callback: $e');
      
      // تسجيل الخطأ إن أمكن
      try {
        final prefs = await SharedPreferences.getInstance();
        final errorsString = prefs.getString('prayer_notification_errors') ?? '[]';
        final List<dynamic> errors = List<dynamic>.from(json.decode(errorsString));
        errors.add('${DateTime.now()}: Error in AlarmManager: $e');
        
        // الاحتفاظ بأحدث 10 أخطاء فقط
        if (errors.length > 10) {
          errors.removeAt(0);
        }
        
        await prefs.setString('prayer_notification_errors', json.encode(errors));
        
        // تحديث إحصائيات الفشل
        final statsString = prefs.getString('prayer_notification_stats') ?? '{}';
        final Map<String, dynamic> stats = Map<String, dynamic>.from(json.decode(statsString));
        stats['failed'] = (stats['failed'] ?? 0) + 1;
        await prefs.setString('prayer_notification_stats', json.encode(stats));
      } catch (_) {
        // تجاهل الأخطاء في تسجيل الأخطاء
      }
    }
  }
  
  // الحصول على معرف الإنذار حسب اسم الصلاة
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
  
  // الحصول على لون الصلاة
  Color _getPrayerColor(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return const Color(0xFF5B68D9);
      case 'الشروق':
        return const Color(0xFFFF9E0D);
      case 'الظهر':
        return const Color(0xFFFFB746);
      case 'العصر':
        return const Color(0xFFFF8A65);
      case 'المغرب':
        return const Color(0xFF5C6BC0);
      case 'العشاء':
        return const Color(0xFF1A237E);
      default:
        return const Color(0xFF4DB6AC);
    }
  }
  
  // جدولة جميع إشعارات الصلوات - محسنة
  Future<int> schedulePrayerTimes(List<PrayerTimeModel> prayerTimes) async {
    // Prevent recursive calls
    if (_isSchedulingInProgress) {
      debugPrint('Already scheduling prayer times, returning');
      return 0;
    }
    
    _isSchedulingInProgress = true;
    
    try {
      if (!_isInitialized) {
        debugPrint('Initializing notification service before scheduling prayer notifications');
        await initialize();
      }
      
      // إلغاء الإشعارات السابقة
      debugPrint('Cancelling previous prayer notifications before scheduling new ones');
      await cancelAllNotifications();
      
      // التحقق من أذونات الإشعارات
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        debugPrint('Notification permission not granted - Requesting permission');
        final permissionRequested = await requestNotificationPermission();
        if (!permissionRequested) {
          debugPrint('Failed to get notification permission - Cannot schedule prayer notifications');
          
          // تحديث إحصائيات الفشل
          _notificationStats['permissionDenied'] = (_notificationStats['permissionDenied'] ?? 0) + 1;
          await _saveStats();
          
          return 0;
        }
      }
      
      // التحقق من تحسين استهلاك البطارية
      await _checkAndRequestBatteryOptimization();
      
      int scheduledCount = 0;
      int notificationId = 2000; // بداية بمعرف كبير لتجنب التعارض
      
      debugPrint('Starting to schedule notifications for ${prayerTimes.length} prayer times');
      
      // تحضير قائمة أوقات الصلوات القادمة فقط
      final now = DateTime.now();
      final futurePrayers = prayerTimes.where((prayer) {
        final prayerTime = prayer.time;
        // اضافة تحقق إضافي
        return prayerTime.isAfter(now.subtract(const Duration(minutes: 1))); // أضفنا هامش دقيقة
      }).toList();
      
      debugPrint('Found ${futurePrayers.length} future prayers to schedule notifications for');
      
      // جدولة الإشعارات الجديدة لكل صلاة
      for (final prayer in futurePrayers) {
        final prayerName = prayer.name;
        final prayerTime = prayer.time;
        
        // تخطي صلاة الشروق إذا كانت غير مفعلة في الإعدادات
        if (prayerName == 'الشروق' && !_prayerNotificationSettings['الشروق']!) {
          debugPrint('Skipping notifications for $prayerName as it is disabled in settings');
          continue;
        }
        
        debugPrint('Processing prayer: $prayerName at ${prayerTime.toString()}');
        
        // جدولة التذكير المسبق (قبل وقت الصلاة)
        if (_prayerNotificationSettings[prayerName] == true && _showReminderNotifications) {
          final reminderMinutes = _prayerReminderTimes[prayerName] ?? 10;
          final reminderTime = prayerTime.subtract(Duration(minutes: reminderMinutes));
          
          // تأكد من أن وقت التذكير لم يمر بعد
          if (reminderTime.isAfter(now)) {
            debugPrint('Scheduling reminder for $prayerName, ${reminderMinutes}min before prayer time');
            final success = await schedulePrayerNotification(
              prayerName: prayerName,
              prayerTime: reminderTime,
              notificationId: notificationId++,
              isReminder: true,
            );
            
            if (success) {
              scheduledCount++;
              debugPrint('Reminder for $prayerName scheduled successfully');
            }
          } else {
            debugPrint('Reminder time for $prayerName has already passed');
          }
        }
        
        // جدولة إشعار دخول وقت الصلاة
        final success = await schedulePrayerNotification(
          prayerName: prayerName,
          prayerTime: prayerTime,
          notificationId: notificationId++,
        );
        
        if (success) {
          scheduledCount++;
          debugPrint('Notification for $prayerName scheduled successfully');
        }
      }
      
      // إذا كان التجميع مفعلاً، إضافة إشعار ملخص
      if (_groupNotifications && scheduledCount > 0 && Platform.isAndroid) {
        try {
          final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
              _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
          if (androidPlugin != null) {
            // إنشاء إشعار ملخص
            const AndroidNotificationDetails summaryNotificationDetails = AndroidNotificationDetails(
              notificationChannelId,
              'Prayer Times',
              channelDescription: 'Notifications for prayer times',
              groupKey: 'prayer_notifications',
              setAsGroupSummary: true,
            );
            
            await _notificationsPlugin.show(
              9999,  // رقم معرف فريد للإشعار الملخص
              'مواقيت الصلاة',
              'لديك $scheduledCount إشعارات صلاة مجدولة لليوم',
              const NotificationDetails(android: summaryNotificationDetails),
            );
          }
        } catch (e) {
          _addError('Error creating summary notification: $e');
        }
      }
      
      // حفظ تاريخ آخر جدولة
      await saveLastScheduleDate();
      
      // التحقق من الإشعارات المجدولة
      final pendingNotifications = await getPendingNotifications();
      debugPrint('Total pending notifications after scheduling: ${pendingNotifications.length}');
      
      // تحديث إحصائيات النجاح
      _notificationStats['lastSuccessfulSchedule'] = DateTime.now().millisecondsSinceEpoch;
      _notificationStats['scheduledCount'] = scheduledCount;
      await _saveStats();
      
      debugPrint('Finished scheduling prayer notifications. Total scheduled: $scheduledCount');
      return scheduledCount;
    } catch (e) {
      _addError('Error scheduling prayer notifications: $e');
      
      // تحديث إحصائيات الفشل
      _notificationStats['lastScheduleError'] = DateTime.now().millisecondsSinceEpoch;
      _notificationStats['scheduleFailed'] = (_notificationStats['scheduleFailed'] ?? 0) + 1;
      await _saveStats();
      
      return 0;
    } finally {
      _isSchedulingInProgress = false;
    }
  }
  
  // إلغاء جميع إشعارات الصلوات - محسنة
  Future<void> cancelAllNotifications() async {
    try {
      // الحصول على جميع الإشعارات المعلقة
      final pendingNotifications = await getPendingNotifications();
      int cancelledCount = 0;
      
      // إلغاء كل إشعار معلق يبدأ بـ 'prayer_'
      for (final notification in pendingNotifications) {
        if (notification.payload?.startsWith('prayer_') ?? false) {
          await _notificationsPlugin.cancel(notification.id);
          cancelledCount++;
          
          // إزالة الإشعار من قائمة المتابعة
          _scheduledNotifications.remove(notification.id);
        }
      }
      
      // إلغاء جميع الإنذارات المرتبطة بالصلوات في Android
      if (Platform.isAndroid) {
        await AndroidAlarmManager.cancel(fajrAlarmId);
        await AndroidAlarmManager.cancel(sunriseAlarmId);
        await AndroidAlarmManager.cancel(dhuhrAlarmId);
        await AndroidAlarmManager.cancel(asrAlarmId);
        await AndroidAlarmManager.cancel(maghribAlarmId);
        await AndroidAlarmManager.cancel(ishaAlarmId);
        
        // إلغاء إنذارات التذكير
        await AndroidAlarmManager.cancel(fajrAlarmId + 10000);
        await AndroidAlarmManager.cancel(sunriseAlarmId + 10000);
        await AndroidAlarmManager.cancel(dhuhrAlarmId + 10000);
        await AndroidAlarmManager.cancel(asrAlarmId + 10000);
        await AndroidAlarmManager.cancel(maghribAlarmId + 10000);
        await AndroidAlarmManager.cancel(ishaAlarmId + 10000);
      }
      
      // إلغاء الإشعار الملخص
      await _notificationsPlugin.cancel(9999);
      
      // تحديث الإحصائيات
      _notificationStats['cancelledCount'] = cancelledCount;
      await _saveStats();
      
      debugPrint('All prayer notifications cancelled successfully: $cancelledCount');
    } catch (e) {
      _addError('Error canceling prayer notifications: $e');
    }
  }
  
  // التحقق مما إذا كان يجب تحديث الإشعارات
  Future<bool> shouldUpdateNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastScheduleDate = prefs.getString('prayer_last_notification_schedule_date');
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      
      debugPrint('Prayer last schedule date: $lastScheduleDate, Today: $today');
      
      // إذا لم يكن هناك تاريخ مسجل أو كان التاريخ مختلفًا عن اليوم الحالي
      if (lastScheduleDate == null || lastScheduleDate != today) {
        return true;
      }
      
      // التحقق من عدد الإشعارات المجدولة المرتبطة بالصلوات
      final pendingNotifications = await getPendingNotifications();
      final prayerNotifications = pendingNotifications.where(
        (notification) => notification.payload?.startsWith('prayer_') ?? false
      ).toList();
      
      if (prayerNotifications.isEmpty) {
        debugPrint('No pending prayer notifications found, should update');
        return true;
      }
      
      return false;
    } catch (e) {
      _addError('Error checking if prayer notifications should be updated: $e');
      return true; // في حالة الشك، قم بالتحديث
    }
  }
  
  // الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      _addError('Error getting pending prayer notifications: $e');
      return [];
    }
  }
  
  // اختبار الإشعارات - إرسال إشعار فوري
  Future<bool> testPrayerNotification() async {
    try {
      // التحقق من تحسين استهلاك البطارية
      await _checkAndRequestBatteryOptimization();
      
      // إعداد تفاصيل الإشعار الأندرويد بأقصى أولوية
      final androidDetails = AndroidNotificationDetails(
        notificationChannelId,
        'Prayer Times',
        channelDescription: 'Notifications for prayer times',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        ticker: 'Prayer Time Test',
        fullScreenIntent: true,
      );
      
      // إعداد تفاصيل الإشعار iOS
      final iosDetails = await _iosService.getPrayerNotificationDetails(
        prayerName: 'اختبار',
        isReminder: false,
        useHighPriority: true,
        bypassDND: _bypassDND
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // التعامل مع وضع عدم الإزعاج
      if (_bypassDND) {
        await _checkAndHandleDNDMode();
      }
      
      // إرسال إشعار اختبار
      await _notificationsPlugin.show(
        9999,
        'اختبار إشعارات الصلاة',
        'هذا اختبار للتأكد من عمل إشعارات الصلاة بشكل صحيح',
        details,
        payload: 'prayer_test',
      );
      
      // تحديث الإحصائيات
      _sentNotificationsCount++;
      _lastNotificationSentTime = DateTime.now();
      _notificationStats['testNotifications'] = (_notificationStats['testNotifications'] ?? 0) + 1;
      await _saveStats();
      
      debugPrint('Test prayer notification sent successfully');
      return true;
    } catch (e) {
      _addError('Error sending test prayer notification: $e');
      return false;
    }
  }
  
  // الحصول على معلومات تشخيصية
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final Map<String, dynamic> info = {};
    
    try {
      // إحصائيات عامة
      info['notificationsEnabled'] = _isNotificationEnabled;
      info['notificationsSent'] = _sentNotificationsCount;
      info['notificationsInteracted'] = _interactedNotificationsCount;
      
      // آخر وقت إرسال
      if (_lastNotificationSentTime != null) {
        info['lastNotificationSentTime'] = _lastNotificationSentTime!.toIso8601String();
      }
      
      // أذونات
      info['hasNotificationPermission'] = await checkNotificationPermission();
      
      // تحسين البطارية
      info['batteryOptimizationIgnored'] = await _batteryService.isIgnoringBatteryOptimizations();
      
      // وضع عدم الإزعاج
      info['isDNDActive'] = await _dndService.isDNDActive();
      info['bypassDNDEnabled'] = _bypassDND;
      
      // قائمة الإشعارات المعلقة
      final pendingNotifications = await getPendingNotifications();
      info['pendingNotificationsCount'] = pendingNotifications.length;
      
      // إحصائيات مفصلة
      info['stats'] = _notificationStats;
      
      // آخر الأخطاء
      info['lastErrors'] = _lastErrors;
      
      // إعدادات الصلوات
      info['prayerSettings'] = Map<String, bool>.from(_prayerNotificationSettings);
      info['reminderTimes'] = Map<String, int>.from(_prayerReminderTimes);
      
    } catch (e) {
      _addError('Error getting diagnostic info: $e');
    }
    
    return info;
  }
  
  // التحقق من إذا كانت الإشعارات مفعلة لصلاة معينة
  bool isPrayerNotificationEnabled(String prayerName) {
    return _isNotificationEnabled && (_prayerNotificationSettings[prayerName] ?? false);
  }
  
  // تغيير حالة تفعيل إشعارات الصلاة
  Future<void> setPrayerNotificationEnabled(String prayerName, bool enabled) async {
    if (_prayerNotificationSettings.containsKey(prayerName)) {
      _prayerNotificationSettings[prayerName] = enabled;
      await saveNotificationSettings();
    }
  }
  
  // الحصول على مهلة التذكير المسبق لصلاة معينة
  int getPrayerReminderTime(String prayerName) {
    return _prayerReminderTimes[prayerName] ?? 10;
  }
  
  // تعديل مهلة التذكير المسبق لصلاة معينة
  Future<void> setPrayerReminderTime(String prayerName, int minutes) async {
    if (_prayerReminderTimes.containsKey(prayerName)) {
      _prayerReminderTimes[prayerName] = minutes;
      await saveNotificationSettings();
    }
  }
  
  // الحصول على حالة تفعيل إشعارات الصلاة بشكل عام
  bool get isNotificationEnabled => _isNotificationEnabled;
  
  // تغيير حالة تفعيل إشعارات الصلاة بشكل عام
  set isNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveNotificationSettings();
    
    if (!value) {
      // إلغاء جميع الإشعارات إذا تم تعطيل الإشعارات
      cancelAllNotifications();
    }
  }
  
  // صلاحيات تجاوز وضع عدم الإزعاج
  bool get bypassDND => _bypassDND;
  
  set bypassDND(bool value) {
    _bypassDND = value;
    saveNotificationSettings();
  }
  
  // حالة استخدام الأولوية العالية
  bool get useHighPriority => _useHighPriority;
  
  set useHighPriority(bool value) {
    _useHighPriority = value;
    saveNotificationSettings();
    
    // إعادة إنشاء قناة الإشعارات بالأولوية الجديدة
    _createNotificationChannel();
  }
  
  // حالة عرض إشعارات التذكير
  bool get showReminderNotifications => _showReminderNotifications;
  
  set showReminderNotifications(bool value) {
    _showReminderNotifications = value;
    saveNotificationSettings();
  }
  
  // حالة استخدام الإشعارات الدائمة
  bool get usePersistentNotifications => _usePersistentNotifications;
  
  set usePersistentNotifications(bool value) {
    _usePersistentNotifications = value;
    saveNotificationSettings();
  }
  
  // حالة تجميع الإشعارات
  bool get groupNotifications => _groupNotifications;
  
  set groupNotifications(bool value) {
    _groupNotifications = value;
    saveNotificationSettings();
  }
  
  // الحصول على قائمة إعدادات إشعارات الصلوات
  Map<String, bool> get prayerNotificationSettings => Map.unmodifiable(_prayerNotificationSettings);
  
  // الحصول على قائمة مهل التذكير المسبق للصلوات
  Map<String, int> get prayerReminderTimes => Map.unmodifiable(_prayerReminderTimes);
  
  // طلب تجاهل تحسين البطارية
  Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final result = await _batteryService.requestIgnoreBatteryOptimizations();
      return result;
    } catch (e) {
      _addError('Error requesting battery optimization ignorance: $e');
      return false;
    }
  }
  
  // الحصول على الإحصائيات
  Map<String, dynamic> getStats() {
    return {
      'sent': _sentNotificationsCount,
      'interacted': _interactedNotificationsCount,
      'lastSentTime': _lastNotificationSentTime?.toIso8601String(),
      'diagnostics': _notificationStats,
    };
  }
  
  // الحصول على آخر الأخطاء
  List<String> getLastErrors() {
    return List<String>.from(_lastErrors);
  }
  
  // مسح الإحصائيات
  Future<void> clearStats() async {
    _sentNotificationsCount = 0;
    _interactedNotificationsCount = 0;
    _lastNotificationSentTime = null;
    _notificationStats.clear();
    await _saveStats();
  }
  
  // مسح الأخطاء
  Future<void> clearErrors() async {
    _lastErrors.clear();
    await _saveStats();
  }
}
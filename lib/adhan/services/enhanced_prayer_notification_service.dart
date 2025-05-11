// lib/adhan/services/enhanced_prayer_notification_service.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/adhan/models/prayer_time_model.dart';
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
  
  // Store device timezone
  String _deviceTimeZone = 'UTC';
  
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
      
      // Initialize Android Alarm Manager
      if (Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }
      
      // Configure local notifications
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            defaultPresentSound: true,
          );
          
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // تهيئة خدمة الإشعارات
      final success = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      debugPrint('Notification plugin initialization result: $success');
      
      // Load saved settings
      await _loadNotificationSettings();
      
      // Create notification channel for Android
      await _createNotificationChannel();
      
      _isInitialized = true;
      debugPrint('Prayer notification service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      return false;
    }
  }
  
  // إنشاء قناة الإشعارات بأولوية عالية
  Future<void> _createNotificationChannel() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        // إنشاء قناة إشعارات عالية الأولوية
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'prayer_times_channel',
          'Prayer Times',
          description: 'Notifications for prayer times',
          importance: Importance.max, // أقصى أولوية
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
            if (existingChannel.id == 'prayer_times_channel') {
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
      debugPrint('Error creating notification channel: $e');
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
      debugPrint('Error checking notification permission: $e');
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
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
          
      if (iosPlugin != null) {
        bool? iosPermission = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true, // لتجاوز وضع عدم الإزعاج
        );
        
        debugPrint('iOS notification permission: $iosPermission');
        permissionGranted = permissionGranted && (iosPermission ?? false);
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
      debugPrint('Error requesting notification permission: $e');
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
      
      debugPrint('Prayer notification settings loaded successfully');
      debugPrint('Master toggle: $_isNotificationEnabled');
      debugPrint('Prayer settings: $_prayerNotificationSettings');
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
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
      
      debugPrint('Prayer notification settings saved successfully');
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
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
      debugPrint('Error saving prayer last schedule date: $e');
    }
  }
  
  // جدولة إشعار صلاة فردي
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
    
    // التحقق من أن وقت الصلاة في المستقبل
    final now = DateTime.now();
    if (prayerTime.isBefore(now)) {
      debugPrint('Prayer time for $prayerName has already passed: $prayerTime');
      return false;
    }
    
    try {
      // إعداد تفاصيل الإشعار الأندرويد بأقصى أولوية
      final androidDetails = AndroidNotificationDetails(
        'prayer_times_channel',
        'Prayer Times',
        channelDescription: 'Notifications for prayer times',
        importance: Importance.max,
        priority: Priority.max,
        styleInformation: BigTextStyleInformation(''),
        playSound: true,
        enableVibration: true,
        ticker: 'Prayer Time',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        color: _getPrayerColor(prayerName),
        ledColor: _getPrayerColor(prayerName),
        ledOnMs: 1000,
        ledOffMs: 500,
      );
      
      // إعداد تفاصيل الإشعار iOS
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
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
          },
        );
      }
      
      final timeString = '${prayerTime.hour}:${prayerTime.minute.toString().padLeft(2, '0')}';
      debugPrint('Successfully scheduled ${isReminder ? "reminder" : "notification"} for $prayerName at $timeString (ID: $notificationId)');
      
      return true;
    } catch (e) {
      debugPrint('Error scheduling prayer notification for $prayerName: $e');
      return false;
    }
  }
  
  // دالة ساكنة تُستدعى من قبل AlarmManager
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
          'prayer_times_channel',
          'Prayer Times',
          description: 'Notifications for prayer times',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        
        await androidPlugin.createNotificationChannel(channel);
      }
      
      // عرض الإشعار
      await notifications.show(
        notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_times_channel',
            'Prayer Times',
            channelDescription: 'Notifications for prayer times',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'prayer_$prayerName',
      );
      
      debugPrint('AlarmManager prayer notification displayed: $title');
    } catch (e) {
      debugPrint('Error in AlarmManager prayer callback: $e');
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
  
  // جدولة جميع إشعارات الصلوات
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
          return 0;
        }
      }
      
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
        if (_prayerNotificationSettings[prayerName] == true) {
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
      
      // حفظ تاريخ آخر جدولة
      await saveLastScheduleDate();
      
      // التحقق من الإشعارات المجدولة
      final pendingNotifications = await getPendingNotifications();
      debugPrint('Total pending notifications after scheduling: ${pendingNotifications.length}');
      
      debugPrint('Finished scheduling prayer notifications. Total scheduled: $scheduledCount');
      return scheduledCount;
    } catch (e) {
      debugPrint('Error scheduling prayer notifications: $e');
      return 0;
    } finally {
      _isSchedulingInProgress = false;
    }
  }
  
  // إلغاء جميع إشعارات الصلوات
  Future<void> cancelAllNotifications() async {
    try {
      // الحصول على جميع الإشعارات المعلقة
      final pendingNotifications = await getPendingNotifications();
      
      // إلغاء كل إشعار معلق يبدأ بـ 'prayer_'
      for (final notification in pendingNotifications) {
        if (notification.payload?.startsWith('prayer_') ?? false) {
          await _notificationsPlugin.cancel(notification.id);
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
      
      debugPrint('All prayer notifications cancelled successfully');
    } catch (e) {
      debugPrint('Error canceling prayer notifications: $e');
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
      debugPrint('Error checking if prayer notifications should be updated: $e');
      return true; // في حالة الشك، قم بالتحديث
    }
  }
  
  // الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending prayer notifications: $e');
      return [];
    }
  }
  
  // اختبار الإشعارات - إرسال إشعار فوري
  Future<bool> testPrayerNotification() async {
    try {
      // إعداد تفاصيل الإشعار الأندرويد بأقصى أولوية
      final androidDetails = AndroidNotificationDetails(
        'prayer_times_channel',
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
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // إرسال إشعار اختبار
      await _notificationsPlugin.show(
        9999,
        'اختبار إشعارات الصلاة',
        'هذا اختبار للتأكد من عمل إشعارات الصلاة بشكل صحيح',
        details,
        payload: 'prayer_test',
      );
      
      debugPrint('Test prayer notification sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error sending test prayer notification: $e');
      return false;
    }
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
  
  // الحصول على قائمة إعدادات إشعارات الصلوات
  Map<String, bool> get prayerNotificationSettings => Map.unmodifiable(_prayerNotificationSettings);
  
  // الحصول على قائمة مهل التذكير المسبق للصلوات
  Map<String, int> get prayerReminderTimes => Map.unmodifiable(_prayerReminderTimes);
}
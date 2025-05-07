// lib/adhan/services/prayer_notification_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class PrayerNotificationService {
  // Singleton implementation
  static final PrayerNotificationService _instance = PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

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
  
  bool _isInitialized = false;
  BuildContext? _context;

  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Notification service already initialized');
      return true;
    }
    
    try {
      debugPrint('Initializing notification service...');
      
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // تهيئة مدير المنبهات للأندرويد
      await initAlarmManager();
      
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
  
  // تهيئة مدير المنبهات للأندرويد
  Future<bool> initAlarmManager() async {
    try {
      // تهيئة مدير المنبهات للأندرويد
      final initialized = await AndroidAlarmManager.initialize();
      debugPrint('Android Alarm Manager initialized: $initialized');
      return initialized;
    } catch (e) {
      debugPrint('Failed to initialize Android Alarm Manager: $e');
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
          'prayer_channel',
          'Prayer Times',
          description: 'Prayer time notifications',
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
            if (existingChannel.id == 'prayer_channel') {
              channelExists = true;
              debugPrint('Notification channel exists with importance: ${existingChannel.importance}');
              break;
            }
          }
        }
        
        debugPrint('Notification channel created successfully: $channelExists');
      } else {
        debugPrint('Android plugin is null, cannot create notification channel');
      }
    } catch (e) {
      debugPrint('Error creating notification channel: $e');
    }
  }

  // التحقق من إذن الإشعارات - احتفظنا بالاسم الأصلي للطريقة
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
  
  // طلب إذن الإشعارات - احتفظنا بالاسم الأصلي للطريقة
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
        );
        
        debugPrint('iOS notification permission: $iosPermission');
        permissionGranted = permissionGranted && (iosPermission ?? false);
      }
      
      // Save permission status
      if (permissionGranted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_permission_granted', true);
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
    _context = context;
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.id}');
    debugPrint('Notification payload: ${response.payload}');
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
      
      debugPrint('Notification settings loaded successfully');
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
      
      debugPrint('Notification settings saved successfully');
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }
  
  // اضافة طريقة لحفظ اخر تاريخ جدولة
  Future<void> saveLastScheduleDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      await prefs.setString('last_notification_schedule_date', today);
      debugPrint('Last schedule date saved: $today');
    } catch (e) {
      debugPrint('Error saving last schedule date: $e');
    }
  }
  
  // جدولة إشعارات الصلاة باستخدام AlarmManager
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
      final androidDetails = const AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Times',
        channelDescription: 'Prayer time notifications',
        importance: Importance.max,
        priority: Priority.max,
        styleInformation: BigTextStyleInformation(''),
        playSound: true,
        enableVibration: true,
        ticker: 'Prayer Time',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );
      
      // إعداد تفاصيل الإشعار iOS
      final iosDetails = const DarwinNotificationDetails(
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
      
      // حساب الفرق الزمني بين الآن ووقت الإشعار
      final difference = prayerTime.difference(now);
      final diffInSeconds = difference.inSeconds;
      
      // جدولة الإشعار باستخدام AlarmManager للأندرويد
      final success = await AndroidAlarmManager.oneShot(
        Duration(seconds: diffInSeconds),
        notificationId,
        _showNotificationCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );
      
      // أيضًا جدولة الإشعار باستخدام الطريقة التقليدية كنسخة احتياطية
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(prayerTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'prayer_$prayerName',
      );
      
      final timeString = '${prayerTime.hour}:${prayerTime.minute.toString().padLeft(2, '0')}';
      debugPrint('Successfully scheduled ${isReminder ? "reminder" : "notification"} for $prayerName at $timeString (ID: $notificationId)');
      debugPrint('AlarmManager scheduled: $success, Time difference: ${diffInSeconds}s');
      
      return true;
    } catch (e) {
      debugPrint('Error scheduling notification for $prayerName: $e');
      return false;
    }
  }
  
  // جدولة جميع إشعارات الصلاة بشكل محسن - مع التأكد من التسجيل
  Future<int> scheduleAllPrayerNotifications(List<Map<String, dynamic>> prayerTimes) async {
    if (!_isInitialized) {
      debugPrint('Initializing notification service before scheduling notifications');
      await initialize();
    }
    
    // إلغاء الإشعارات السابقة
    debugPrint('Cancelling previous notifications before scheduling new ones');
    await cancelAllNotifications();
    
    // التحقق من أذونات الإشعارات
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      debugPrint('Notification permission not granted - Requesting permission');
      final permissionRequested = await requestNotificationPermission();
      if (!permissionRequested) {
        debugPrint('Failed to get notification permission - Cannot schedule notifications');
        return 0;
      }
    }
    
    int scheduledCount = 0;
    int notificationId = 1000; // بداية بمعرف كبير لتجنب التعارض
    
    debugPrint('Starting to schedule notifications for ${prayerTimes.length} prayer times');
    
    // تحضير قائمة أوقات الصلوات القادمة فقط
    final now = DateTime.now();
    final futurePrayers = prayerTimes.where((prayer) {
      final prayerTime = prayer['time'] as DateTime;
      // اضافة تحقق إضافي
      return prayerTime.isAfter(now.subtract(const Duration(minutes: 1))); // أضفنا هامش دقيقة
    }).toList();
    
    debugPrint('Found ${futurePrayers.length} future prayers to schedule notifications for');
    
    // جدولة الإشعارات الجديدة لكل صلاة
    for (final prayer in futurePrayers) {
      final prayerName = prayer['name'] as String;
      final prayerTime = prayer['time'] as DateTime;
      
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
    
    debugPrint('Finished scheduling notifications. Total scheduled: $scheduledCount');
    return scheduledCount;
  }
  
  // دالة ساكنة تُستدعى من قبل AlarmManager
  @pragma('vm:entry-point')
  static void _showNotificationCallback(int id) async {
    try {
      debugPrint('AlarmManager callback triggered for notification ID: $id');
      
      // قراءة معلومات الإشعار من التخزين المشترك
      final prefs = await SharedPreferences.getInstance();
      final title = prefs.getString('prayer_notification_${id}_title') ?? 'وقت الصلاة';
      final body = prefs.getString('prayer_notification_${id}_body') ?? 'حان وقت الصلاة';
      
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
          'prayer_channel',
          'Prayer Times',
          description: 'Prayer time notifications',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        
        await androidPlugin.createNotificationChannel(channel);
      }
      
      // عرض الإشعار
      await notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Prayer Times',
            channelDescription: 'Prayer time notifications',
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
      );
      
      debugPrint('AlarmManager notification displayed: $title');
    } catch (e) {
      debugPrint('Error in AlarmManager callback: $e');
    }
  }
  
  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('All notifications cancelled successfully');
    } catch (e) {
      debugPrint('Error canceling notifications: $e');
    }
  }
  
  // فحص الإشعارات الفعالة مع تفاصيل أكثر
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('Pending notifications: ${pendingNotifications.length}');
      
      if (pendingNotifications.isNotEmpty) {
        for (var i = 0; i < pendingNotifications.length; i++) {
          final notification = pendingNotifications[i];
          debugPrint('Notification #${i+1}: ID=${notification.id}, Title=${notification.title}, Body=${notification.body}');
        }
      } else {
        debugPrint('No pending notifications found!');
      }
      
      return pendingNotifications;
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }
  
  // طريقة جديدة: اختبار إنشاء وتلقي الإشعارات على الفور
  Future<bool> testImmediateNotification() async {
    try {
      debugPrint('Testing immediate notification...');
      
      // التحقق من أذونات الإشعارات
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        debugPrint('Notification permission not granted - Requesting for test notification');
        final permissionRequested = await requestNotificationPermission();
        if (!permissionRequested) {
          debugPrint('Failed to get notification permission for test notification');
          return false;
        }
      }
      
      // إعداد تفاصيل الإشعار بأقصى أولوية
      final androidDetails = const AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Times',
        channelDescription: 'Prayer time notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        ticker: 'Test Notification',
        fullScreenIntent: true,
      );
      
      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // إنشاء إشعار فوري للاختبار
      final testId = 9999;
      await _notificationsPlugin.show(
        testId,
        'اختبار الإشعارات',
        'هذا اختبار للتأكد من عمل نظام الإشعارات بشكل صحيح.',
        details,
        payload: 'test_notification',
      );
      
      debugPrint('Test notification sent with ID: $testId');
      
      // التحقق من تسجيل الإشعار (لن يظهر في pendingNotifications لأنه فوري)
      return true;
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      return false;
    }
  }
  
  // إضافة طريقة لاختبار إشعار مجدول بعد 30 ثانية باستخدام AlarmManager
  Future<bool> testScheduledNotification() async {
    try {
      debugPrint('Testing scheduled notification with AlarmManager...');
      
      // التحقق من أذونات الإشعارات
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        final permissionRequested = await requestNotificationPermission();
        if (!permissionRequested) {
          debugPrint('Failed to get notification permission for test notification');
          return false;
        }
      }
      
      // تهيئة مدير المنبهات للأندرويد
      await initAlarmManager();
      
      // حفظ معلومات الإشعار الاختباري
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_notification_9998_title', 'اختبار إشعار مجدول');
      await prefs.setString('prayer_notification_9998_body', 'هذا اختبار للتأكد من عمل نظام الإشعارات المجدولة بعد 30 ثانية.');
      
      // تعيين منبه بعد 30 ثانية
      final testId = 9998;
      final success = await AndroidAlarmManager.oneShot(
        const Duration(seconds: 30),
        testId,
        _showNotificationCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );
      
      debugPrint('AlarmManager oneShot scheduled: $success');
      
      // أيضًا تجربة النظام العادي للإشعارات المجدولة
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));
      await _notificationsPlugin.zonedSchedule(
        testId + 1,
        'اختبار نظام الإشعارات العادي',
        'هذا اختبار للتأكد من عمل نظام الإشعارات المجدولة العادي بعد 30 ثانية.',
        scheduledTime,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'prayer_channel',
            'Prayer Times',
            channelDescription: 'Prayer time notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Test scheduled in two ways for 30 seconds from now');
      return true;
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
      return false;
    }
  }
  
  bool get isNotificationEnabled => _isNotificationEnabled;
  
  set isNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveNotificationSettings();
  }
  
  Map<String, bool> get prayerNotificationSettings => Map.unmodifiable(_prayerNotificationSettings);
  
  Map<String, int> get prayerReminderTimes => Map.unmodifiable(_prayerReminderTimes);
  
  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    if (_prayerNotificationSettings.containsKey(prayer)) {
      _prayerNotificationSettings[prayer] = enabled;
      await saveNotificationSettings();
    }
  }
  
  // إضافة طريقة لتعديل وقت التذكير المسبق
  Future<void> setPrayerReminderTime(String prayer, int minutes) async {
    if (_prayerReminderTimes.containsKey(prayer)) {
      _prayerReminderTimes[prayer] = minutes;
      await saveNotificationSettings();
    }
  }
  
  bool get isInitialized => _isInitialized;
  
  // اضافة طريقة للتحقق مما إذا كان يجب تحديث الإشعارات
  Future<bool> shouldUpdateNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastScheduleDate = prefs.getString('last_notification_schedule_date');
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      
      debugPrint('Last schedule date: $lastScheduleDate, Today: $today');
      
      // إذا لم يكن هناك تاريخ مسجل أو كان التاريخ مختلفًا عن اليوم الحالي
      if (lastScheduleDate == null || lastScheduleDate != today) {
        return true;
      }
      
      // التحقق من عدد الإشعارات المجدولة
      final pendingNotifications = await getPendingNotifications();
      if (pendingNotifications.isEmpty) {
        debugPrint('No pending notifications found, should update');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking if notifications should be updated: $e');
      return true; // في حالة الشك، قم بالتحديث
    }
  }
}
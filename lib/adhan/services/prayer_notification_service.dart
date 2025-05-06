// lib/adhan/services/prayer_notification_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

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
    'الفجر': 15,    // تذكير قبل 15 دقيقة من الفجر
    'الشروق': 5,    
    'الظهر': 10,
    'العصر': 10,
    'المغرب': 5,     // تذكير قبل 5 دقائق من المغرب
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
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // Configure local notifications
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );
          
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final bool? initResult = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
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
  
  Future<void> _createNotificationChannel() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        // تعديل: إنشاء قناة إشعارات بصوت للتنبيه
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'prayer_channel',
          'Prayer Times',
          description: 'Prayer time notifications',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true, // تفعيل الصوت
          sound: RawResourceAndroidNotificationSound('adhan'), // اسم ملف الصوت في مجلد الموارد
        );
        
        await androidPlugin.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('Error creating notification channel: $e');
    }
  }
  
  Future<bool> requestNotificationPermission() async {
    try {
      // For Android 13+ (notification permission required)
      bool permissionGranted = await Permission.notification.request().isGranted;
      
      // For iOS
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
          
      if (iosPlugin != null) {
        bool? iosPermission = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true, // طلب إذن الصوت
        );
        
        permissionGranted = permissionGranted && (iosPermission ?? false);
      }
      
      return permissionGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }
  
  Future<bool> checkNotificationPermission() async {
    try {
      return await Permission.notification.status.isGranted;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }
  
  void setContext(BuildContext context) {
    _context = context;
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.id}');
    debugPrint('Notification payload: ${response.payload}');
    
    // هنا يمكن إضافة المزيد من المنطق للانتقال إلى شاشة الصلاة أو عرض معلومات إضافية
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
      
      // تحميل أوقات التذكير المسبق (إذا تم تخزينها)
      for (final prayer in _prayerReminderTimes.keys) {
        final reminderMinutes = prefs.getInt('prayer_reminder_$prayer') ?? 
            _prayerReminderTimes[prayer]!;
        _prayerReminderTimes[prayer] = reminderMinutes;
      }
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
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }
  
  Future<bool> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    required int notificationId,
    bool isReminder = false,
  }) async {
    // Check if notifications are enabled for this prayer
    if (!_isNotificationEnabled || !(_prayerNotificationSettings[prayerName] ?? false)) {
      return false;
    }
    
    // Check if prayer time is in the future
    final now = DateTime.now();
    if (prayerTime.isBefore(now)) {
      return false;
    }
    
    try {
      // Configure notification details
      final androidDetails = AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Times',
        channelDescription: 'Prayer time notifications',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const BigTextStyleInformation(''),
        playSound: true, // تفعيل الصوت
        sound: const RawResourceAndroidNotificationSound('adhan'), // اسم ملف الصوت
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
      );
      
      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true, // تفعيل الصوت
        sound: 'adhan.aiff', // اسم ملف الصوت في مجلد الموارد
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // Notification content
      String title, body;
      
      if (isReminder) {
        // إذا كانت تذكيراً قبل الصلاة
        final reminderMinutes = _prayerReminderTimes[prayerName] ?? 10;
        title = 'تذكير بصلاة $prayerName';
        body = 'سيحين وقت صلاة $prayerName بعد $reminderMinutes دقيقة';
      } else {
        // إذا كانت إشعاراً بدخول وقت الصلاة
        title = 'حان وقت صلاة $prayerName';
        body = 'حان الآن وقت صلاة $prayerName';
      }
      
      // Schedule notification
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
      
      return true;
    } catch (e) {
      debugPrint('Error scheduling notification for $prayerName: $e');
      return false;
    }
  }
  
  Future<int> scheduleAllPrayerNotifications(List<Map<String, dynamic>> prayerTimes) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Cancel previous notifications
    await cancelAllNotifications();
    
    // Check permission before scheduling
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      return 0;
    }
    
    int scheduledCount = 0;
    int notificationId = 0;
    
    // Schedule new notifications for each prayer
    for (final prayer in prayerTimes) {
      final prayerName = prayer['name'] as String;
      final prayerTime = prayer['time'] as DateTime;
      
      // جدولة التذكير المسبق (قبل وقت الصلاة)
      if (_prayerNotificationSettings[prayerName] == true) {
        final reminderMinutes = _prayerReminderTimes[prayerName] ?? 10;
        final reminderTime = prayerTime.subtract(Duration(minutes: reminderMinutes));
        
        // تأكد من أن وقت التذكير لم يمر بعد
        if (reminderTime.isAfter(DateTime.now())) {
          final success = await schedulePrayerNotification(
            prayerName: prayerName,
            prayerTime: reminderTime,
            notificationId: notificationId++,
            isReminder: true,
          );
          
          if (success) {
            scheduledCount++;
          }
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
      }
    }
    
    return scheduledCount;
  }
  
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling notifications: $e');
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
}
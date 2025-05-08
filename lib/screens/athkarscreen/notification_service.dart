import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Flutter Local Notifications plugin instance
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Athkar service to access athkar data
  final AthkarService _athkarService = AthkarService();
  
  // Initialize the notification service
  Future<void> initialize() async {
    // Initialize time zones for scheduled notifications
    tz_data.initializeTimeZones();
    
    // Initialize Android Alarm Manager
    await AndroidAlarmManager.initialize();
    
    // Initialize notification settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize notification settings for iOS
    // Note: Removed onDidReceiveLocalNotification as it's deprecated in v18.0.1
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    // Combine platform-specific settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize the plugin
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request notification permissions (iOS)
    if (Platform.isIOS) {
      await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
    // Schedule all athkar notifications
    await scheduleAllAthkarNotifications();
  }
  
  // Handle when a local notification is tapped
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // The payload contains the category ID - handle navigation here
      print("Notification payload: ${response.payload}");
      
      // TODO: Navigate to the appropriate athkar category screen
      // Example: Navigator.pushNamed(context, '/athkar/${response.payload}');
    }
  }
  
  // Schedule notifications for all athkar categories
  Future<void> scheduleAllAthkarNotifications() async {
    // Cancel any existing notifications first
    await _notifications.cancelAll();
    
    // Load all athkar categories
    final categories = await _athkarService.loadAllAthkarCategories();
    
    // Schedule notifications for each category that has a notify_time
    for (final category in categories) {
      if (category.notifyTime != null && category.notifyTime!.isNotEmpty) {
        // Check if notifications are enabled for this category
        final isEnabled = await _athkarService.getNotificationEnabled(category.id);
        if (!isEnabled) continue;
        
        // Check if there's a custom notification time
        final customTime = await _athkarService.getCustomNotificationTime(category.id);
        final timeToUse = customTime ?? category.notifyTime!;
        
        // Schedule notification
        await _scheduleAthkarNotification(category, timeToUse);
      }
    }
    
    // Also set up a daily alarm to ensure notifications are re-scheduled each day
    const int dailyReschedulerId = 8675309; // A unique ID
    await AndroidAlarmManager.periodic(
      const Duration(days: 1), 
      dailyReschedulerId,
      _rescheduleNotificationsCallback,
      startAt: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        3, 0, // 3:00 AM
      ),
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
  
  // Callback function for periodic alarm
  @pragma('vm:entry-point')
  static Future<void> _rescheduleNotificationsCallback() async {
    // Get a new instance of the service (since this runs in a separate isolate)
    final service = NotificationService();
    await service.scheduleAllAthkarNotifications();
  }
  
  // Schedule a notification for a specific athkar category
  Future<void> _scheduleAthkarNotification(AthkarCategory category, String timeString) async {
    try {
      // Parse the time string (format: HH:MM)
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Create a DateTime for today at the specified time
      final now = DateTime.now();
      final scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If the scheduled time has passed for today, schedule for tomorrow
      DateTime notificationTime = scheduledDate;
      if (scheduledDate.isBefore(now)) {
        notificationTime = scheduledDate.add(const Duration(days: 1));
      }
      
      // Create the notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'athkar_channel',
        'أذكار المسلم',
        channelDescription: 'إشعارات أذكار المسلم',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('azan'), // Put azan.mp3 in android/app/src/main/res/raw/
        playSound: true,
        color: Color(0xFF447055), // App primary color
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'azan.aiff', // Put azan.aiff in ios/Runner/Resources/
        badgeNumber: 1,
      );
      
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Generate a unique ID for this category
      final int notificationId = category.id.hashCode;
      
      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        'حان وقت ${category.title}',
        'تذكير: لا تنس قراءة ${category.title}',
        tz.TZDateTime.from(notificationTime, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Daily at the same time
        payload: category.id, // Use the category ID as the payload
      );
      
      print('Scheduled notification for ${category.title} at $timeString');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
  
  // Toggle notification for a specific category
  Future<void> toggleCategoryNotification(String categoryId, bool enabled) async {
    await _athkarService.setNotificationEnabled(categoryId, enabled);
    await scheduleAllAthkarNotifications(); // Reschedule all notifications
  }
  
  // Set a custom time for a category notification
  Future<void> setCustomNotificationTime(String categoryId, String time) async {
    await _athkarService.setCustomNotificationTime(categoryId, time);
    await scheduleAllAthkarNotifications(); // Reschedule all notifications
  }
  
  // Send an immediate test notification
  Future<void> sendTestNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'athkar_test_channel',
      'اختبار الإشعارات',
      channelDescription: 'قناة لاختبار الإشعارات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      0, // ID
      title,
      body,
      platformDetails,
    );
  }
}
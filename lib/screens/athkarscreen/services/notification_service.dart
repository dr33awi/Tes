// lib/services/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';

class NotificationService {
  // Singleton pattern implementation
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Guarda la zona horaria del dispositivo
  String _deviceTimeZone = 'UTC';
      
  // Alarm IDs for background notifications
  static const int morningAthkarAlarmId = 1001;
  static const int eveningAthkarAlarmId = 1002;
  static const int sleepAthkarAlarmId = 1003;
  static const int wakeAthkarAlarmId = 1004;
  static const int prayerAthkarAlarmId = 1005;
  static const int homeAthkarAlarmId = 1006;
  static const int foodAthkarAlarmId = 1007;
  static const int quranAthkarAlarmId = 1008;

  // Initialize notifications
  Future<bool> initialize() async {
    try {
      // Initialize timezones
      tz_data.initializeTimeZones();
      
      // Get device timezone
      try {
        _deviceTimeZone = await FlutterNativeTimezoneLatest.getLocalTimezone();
        // Set the timezone
        tz.setLocalLocation(tz.getLocation(_deviceTimeZone));
        print('Device timezone: $_deviceTimeZone');
      } catch (e) {
        print('Error getting device timezone: $e');
        // Fallback to a safe default
        _deviceTimeZone = 'UTC';
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Initialize notification settings for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // For iOS
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      // Initialize plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Request permissions
      await _requestPermissions();
      
      // Initialize Android Alarm Manager for more reliable notifications
      if (Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }
      
      // Initialize scheduled notifications
      await scheduleAllSavedNotifications();
      
      return true;
    } catch (e) {
      print('Error initializing notification service: $e');
      return false;
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API level 33 and above)
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        // For iOS
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  // Handle notification tap
  void _onNotificationResponse(NotificationResponse response) async {
    // Save payload for navigation
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('opened_from_notification', true);
      await prefs.setString('notification_payload', payload);
      
      print('Notification tapped with payload: $payload');
    }
  }

  // Schedule athkar notification
  Future<void> scheduleAthkarNotification(
      AthkarCategory category, TimeOfDay notificationTime) async {
    try {
      // Create unique notification ID from category ID
      final int notificationId = _getNotificationIdFromCategoryId(category.id);

      // Get scheduled datetime
      final tz.TZDateTime scheduledDate = _getScheduledDate(notificationTime);

      // Set notification content
      final title = category.notifyTitle ?? 'حان موعد ${category.title}';
      final body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
      
      // Set notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'athkar_channel_id',
        'أذكار',
        channelDescription: 'تنبيهات الأذكار',
        importance: Importance.high,
        priority: Priority.high,
        sound: category.notifySound != null 
          ? RawResourceAndroidNotificationSound(category.notifySound!) 
          : null,
        icon: '@mipmap/ic_launcher',
      );
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: category.notifySound != null ? '${category.notifySound}.aiff' : null,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Daily repeat at same time
        payload: category.id,
      );

      // Schedule Android background alarm for extra reliability
      if (Platform.isAndroid) {
        await _scheduleBackgroundAlarm(category, notificationTime, title, body);
      }

      // Save settings
      await _saveNotificationSettings(category.id, true, notificationTime);
      
      return;
    } catch (e) {
      print('Error scheduling notification: $e');
      return;
    }
  }
  
  // Schedule background alarm (for Android)
  Future<void> _scheduleBackgroundAlarm(
      AthkarCategory category, TimeOfDay notificationTime, String title, String body) async {
    int alarmId = _getAlarmIdForCategory(category.id);
    
    // Calculate alarm time
    final now = DateTime.now();
    DateTime scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );
    
    // If time already passed today, schedule for tomorrow
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }
    
    // Schedule alarm
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      alarmId,
      _showAthkarNotificationCallback,
      startAt: scheduledDateTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {
        'categoryId': category.id,
        'notificationId': _getNotificationIdFromCategoryId(category.id),
        'title': title,
        'body': body,
      },
    );
  }
  
  // Get alarm ID based on category ID
  int _getAlarmIdForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return morningAthkarAlarmId;
      case 'evening':
        return eveningAthkarAlarmId;
      case 'sleep':
        return sleepAthkarAlarmId;
      case 'wake':
        return wakeAthkarAlarmId;
      case 'prayer':
        return prayerAthkarAlarmId;
      case 'home':
        return homeAthkarAlarmId;
      case 'food':
        return foodAthkarAlarmId;
      case 'quran':
        return quranAthkarAlarmId;
      default:
        return categoryId.hashCode.abs() % 1000 + 2000;
    }
  }
  
  // Callback for background alarm
  @pragma('vm:entry-point')
  static Future<void> _showAthkarNotificationCallback(int id, Map<String, dynamic>? params) async {
    if (params == null) return;
    
    // Initialize notifications plugin
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    // Set up notification details
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'athkar_channel_id',
      'أذكار',
      channelDescription: 'تنبيهات الأذكار',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    // Extract notification data
    final categoryId = params['categoryId'] as String;
    final notificationId = params['notificationId'] as int;
    final title = params['title'] as String;
    final body = params['body'] as String;
    
    // Save for navigation if tapped
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_payload', categoryId);
    
    // Show notification
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: categoryId,
    );
  }

  // Schedule additional notifications for multiple reminder times
  Future<void> scheduleAdditionalNotifications(AthkarCategory category) async {
    if (!category.hasMultipleReminders || category.additionalNotifyTimes == null) {
      return;
    }
    
    try {
      for (int i = 0; i < category.additionalNotifyTimes!.length; i++) {
        final timeString = category.additionalNotifyTimes![i];
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          
          if (hour != null && minute != null) {
            final additionalTime = TimeOfDay(hour: hour, minute: minute);
            
            // Create unique ID for additional notification
            final int notificationId = _getNotificationIdFromCategoryId(category.id) + (i + 1) * 1000;
            
            // Get scheduled time
            final tz.TZDateTime scheduledDate = _getScheduledDate(additionalTime);
            
            // Set notification content
            final title = category.notifyTitle ?? 'حان موعد ${category.title}';
            final body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
            
            // Set notification details
            final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'athkar_channel_id',
              'أذكار',
              channelDescription: 'تنبيهات الأذكار',
              importance: Importance.high,
              priority: Priority.high,
              sound: category.notifySound != null 
                ? RawResourceAndroidNotificationSound(category.notifySound!) 
                : null,
            );
            
            final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: category.notifySound != null ? '${category.notifySound}.aiff' : null,
            );
            
            final NotificationDetails notificationDetails = NotificationDetails(
              android: androidDetails,
              iOS: iosDetails,
            );
            
            // Schedule notification
            await flutterLocalNotificationsPlugin.zonedSchedule(
              notificationId,
              title,
              body,
              scheduledDate,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.time,
              payload: '${category.id}:additional_$i',
            );
            
            // Additional alarm for Android
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
                _showAthkarNotificationCallback,
                startAt: scheduledDateTime,
                exact: true,
                wakeup: true,
                rescheduleOnReboot: true,
                params: {
                  'categoryId': '${category.id}:additional_$i',
                  'notificationId': notificationId,
                  'title': title,
                  'body': body,
                },
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error scheduling additional notifications: $e');
    }
  }

  // Cancel notifications for a category
  Future<void> cancelAthkarNotification(String categoryId) async {
    try {
      // Cancel main notification
      final int notificationId = _getNotificationIdFromCategoryId(categoryId);
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      
      // Cancel additional notifications (up to 10)
      for (int i = 1; i <= 10; i++) {
        final additionalId = notificationId + i * 1000;
        await flutterLocalNotificationsPlugin.cancel(additionalId);
      }
      
      // Cancel background alarms on Android
      if (Platform.isAndroid) {
        // Cancel main alarm
        int alarmId = _getAlarmIdForCategory(categoryId);
        await AndroidAlarmManager.cancel(alarmId);
        
        // Cancel additional alarms
        for (int i = 1; i <= 10; i++) {
          final additionalAlarmId = notificationId + i * 1000 + 100000;
          await AndroidAlarmManager.cancel(additionalAlarmId);
        }
      }
      
      // Save settings
      await _saveNotificationSettings(categoryId, false, null);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      
      if (Platform.isAndroid) {
        // Cancel all known alarms
        await AndroidAlarmManager.cancel(morningAthkarAlarmId);
        await AndroidAlarmManager.cancel(eveningAthkarAlarmId);
        await AndroidAlarmManager.cancel(sleepAthkarAlarmId);
        await AndroidAlarmManager.cancel(wakeAthkarAlarmId);
        await AndroidAlarmManager.cancel(prayerAthkarAlarmId);
        await AndroidAlarmManager.cancel(homeAthkarAlarmId);
        await AndroidAlarmManager.cancel(foodAthkarAlarmId);
        await AndroidAlarmManager.cancel(quranAthkarAlarmId);
      }
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  // Check if notifications are enabled for a category
  Future<bool> isNotificationEnabled(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_${categoryId}_enabled') ?? false;
  }

  // Get saved notification time for a category
  Future<TimeOfDay?> getNotificationTime(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('notification_${categoryId}_time');
    
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
  }

  // Schedule all saved notifications
  Future<void> scheduleAllSavedNotifications() async {
    try {
      // Get all categories that have saved notification settings
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys related to notifications
      final allKeys = prefs.getKeys();
      final notificationKeys = allKeys.where((key) => key.startsWith('notification_') && key.endsWith('_enabled'));
      
      for (final key in notificationKeys) {
        // Extract category ID from key
        final categoryId = key.replaceAll('notification_', '').replaceAll('_enabled', '');
        
        // Check if notification is enabled
        final isEnabled = prefs.getBool(key) ?? false;
        
        if (isEnabled) {
          // Get saved time
          final timeKey = 'notification_${categoryId}_time';
          final timeString = prefs.getString(timeKey);
          
          if (timeString != null) {
            // Parse time
            final timeParts = timeString.split(':');
            if (timeParts.length == 2) {
              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);
              
              if (hour != null && minute != null) {
                final notificationTime = TimeOfDay(hour: hour, minute: minute);
                
                // Create dummy category for scheduling
                final category = AthkarCategory(
                  id: categoryId,
                  title: _getCategoryTitle(categoryId),
                  icon: _getCategoryIcon(categoryId),
                  color: _getCategoryColor(categoryId),
                  athkar: [],
                  notifyTime: timeString,
                );
                
                // Schedule notification
                await scheduleAthkarNotification(category, notificationTime);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error scheduling saved notifications: $e');
    }
  }

  // Save notification settings
  Future<void> _saveNotificationSettings(
      String categoryId, bool isEnabled, TimeOfDay? notificationTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_${categoryId}_enabled', isEnabled);
    
    if (notificationTime != null) {
      final timeString = '${notificationTime.hour}:${notificationTime.minute}';
      await prefs.setString('notification_${categoryId}_time', timeString);
    }
  }

  // Generate a unique notification ID from a category ID
  int _getNotificationIdFromCategoryId(String categoryId) {
    return categoryId.hashCode.abs() % 100000;
  }

  // Calculate the scheduled date for a notification using device's local timezone
  tz.TZDateTime _getScheduledDate(TimeOfDay notificationTime) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );
    
    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  // Get suggested time for a category
  static TimeOfDay getSuggestedTimeForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const TimeOfDay(hour: 6, minute: 0); // 6:00 AM
      case 'evening':
        return const TimeOfDay(hour: 16, minute: 0); // 4:00 PM
      case 'sleep':
        return const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
      case 'wake':
        return const TimeOfDay(hour: 5, minute: 30); // 5:30 AM
      case 'prayer':
        return const TimeOfDay(hour: 13, minute: 0); // 1:00 PM
      case 'home':
        return const TimeOfDay(hour: 18, minute: 0); // 6:00 PM
      case 'food':
        return const TimeOfDay(hour: 12, minute: 0); // 12:00 PM
      case 'quran':
        return const TimeOfDay(hour: 20, minute: 0); // 8:00 PM
      default:
        return const TimeOfDay(hour: 8, minute: 0); // 8:00 AM default
    }
  }
  
  // Get current timezone name
  String getCurrentTimezoneName() {
    return _deviceTimeZone;
  }
  
  // Helper methods for creating dummy categories when needed
  
  // Get category title based on ID
  String _getCategoryTitle(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return 'أذكار الصباح';
      case 'evening':
        return 'أذكار المساء';
      case 'sleep':
        return 'أذكار النوم';
      case 'wake':
        return 'أذكار الاستيقاظ';
      case 'prayer':
        return 'أذكار الصلاة';
      case 'home':
        return 'أذكار المنزل';
      case 'food':
        return 'أذكار الطعام';
      case 'quran':
        return 'أدعية قرآنية';
      default:
        return 'أذكار';
    }
  }
  
  // Get category icon based on ID
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.nightlight_round;
      case 'sleep':
        return Icons.bedtime;
      case 'wake':
        return Icons.alarm;
      case 'prayer':
        return Icons.mosque;
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'quran':
        return Icons.menu_book;
      default:
        return Icons.notifications;
    }
  }
  
  // Get category color based on ID
  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // Yellow
      case 'evening':
        return const Color(0xFFAB47BC); // Purple
      case 'sleep':
        return const Color(0xFF5C6BC0); // Blue
      case 'wake':
        return const Color(0xFFFFB74D); // Orange
      case 'prayer':
        return const Color(0xFF4DB6AC); // Teal
      case 'home':
        return const Color(0xFF66BB6A); // Green
      case 'food':
        return const Color(0xFFE57373); // Red
      case 'quran':
        return const Color(0xFF9575CD); // Light purple
      default:
        return const Color(0xFF447055); // Default app color
    }
  }
  
  // Test immediate notification
  Future<void> testImmediateNotification() async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'athkar_test_channel',
        'اختبار الأذكار',
        channelDescription: 'قناة اختبار إشعارات الأذكار',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
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
      
      print('Test notification sent successfully');
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }
  
  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
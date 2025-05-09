// lib/screens/athkarscreen/services/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';

class NotificationService {
  // Singleton implementation
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AthkarService _athkarService = AthkarService();
  
  // Alarm IDs for background notifications
  static const int morningAthkarAlarmId = 1001;
  static const int eveningAthkarAlarmId = 1002;
  static const int sleepAthkarAlarmId = 1003;
  static const int wakeAthkarAlarmId = 1004;
  static const int prayerAthkarAlarmId = 1005;

  // Initialize notifications
  Future<bool> initialize() async {
    try {
      // Initialize timezones without detecting local timezone
      tz_data.initializeTimeZones();
      
      // Set to a fixed timezone - you can replace this with a timezone appropriate for your users
      // For Middle East, common timezones include:
      // 'Asia/Riyadh', 'Asia/Dubai', 'Asia/Jerusalem', 'Asia/Baghdad', 'Asia/Tehran'
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

      // Initialize notification settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // For newer versions (19.1.0+)
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // Using the correct callback for newer versions
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          final String? payload = details.payload;
          if (payload != null && payload.isNotEmpty) {
            _handleNotificationTap(payload);
          }
        },
      );

      // Request permissions (newer API)
      await _requestPermissions();
      
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
  Future<void> _handleNotificationTap(String payload) async {
    // Save payload for navigation
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('opened_from_notification', true);
    await prefs.setString('notification_payload', payload);
    
    print('Notification tapped with payload: $payload');
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
      
      // Set notification details for newer versions
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'athkar_channel_id',
        'أذكار',
        channelDescription: 'تنبيهات الأذكار',
        importance: Importance.high,
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

      // Schedule notification using proper parameters for v19.1.0+
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
    int alarmId;
    
    // Get alarm ID based on category
    switch (category.id) {
      case 'morning':
        alarmId = morningAthkarAlarmId;
        break;
      case 'evening':
        alarmId = eveningAthkarAlarmId;
        break;
      case 'sleep':
        alarmId = sleepAthkarAlarmId;
        break;
      case 'wake':
        alarmId = wakeAthkarAlarmId;
        break;
      case 'prayer':
        alarmId = prayerAthkarAlarmId;
        break;
      default:
        alarmId = category.id.hashCode.abs() % 1000 + 2000;
    }
    
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
  
  // Callback for background alarm
  @pragma('vm:entry-point')
  static Future<void> _showAthkarNotificationCallback(int id, Map<String, dynamic>? params) async {
    if (params == null) return;
    
    // Initialize notifications plugin
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    // Set up notification details for newer versions
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
            
            // Set notification details for newer versions
            final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'athkar_channel_id',
              'أذكار',
              channelDescription: 'تنبيهات الأذكار',
              importance: Importance.high,
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
            
            // Schedule notification using proper parameters for v19.1.0+
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
        int alarmId;
        
        switch (categoryId) {
          case 'morning':
            alarmId = morningAthkarAlarmId;
            break;
          case 'evening':
            alarmId = eveningAthkarAlarmId;
            break;
          case 'sleep':
            alarmId = sleepAthkarAlarmId;
            break;
          case 'wake':
            alarmId = wakeAthkarAlarmId;
            break;
          case 'prayer':
            alarmId = prayerAthkarAlarmId;
            break;
          default:
            alarmId = categoryId.hashCode.abs() % 1000 + 2000;
        }
        
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
        await AndroidAlarmManager.cancel(morningAthkarAlarmId);
        await AndroidAlarmManager.cancel(eveningAthkarAlarmId);
        await AndroidAlarmManager.cancel(sleepAthkarAlarmId);
        await AndroidAlarmManager.cancel(wakeAthkarAlarmId);
        await AndroidAlarmManager.cancel(prayerAthkarAlarmId);
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
      // Get all categories
      final categories = await _athkarService.loadAllAthkarCategories();
      
      for (final category in categories) {
        final isEnabled = await isNotificationEnabled(category.id);
        if (isEnabled) {
          final savedTime = await getNotificationTime(category.id);
          if (savedTime != null) {
            await scheduleAthkarNotification(category, savedTime);
            await scheduleAdditionalNotifications(category);
          } else if (category.notifyTime != null) {
            // Use default time from category
            final defaultTimeParts = category.notifyTime!.split(':');
            if (defaultTimeParts.length == 2) {
              final hour = int.tryParse(defaultTimeParts[0]);
              final minute = int.tryParse(defaultTimeParts[1]);
              
              if (hour != null && minute != null) {
                final defaultTime = TimeOfDay(hour: hour, minute: minute);
                await scheduleAthkarNotification(category, defaultTime);
                await scheduleAdditionalNotifications(category);
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

  // Calculate the scheduled date for a notification
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
        return TimeOfDay.now();
    }
  }
  
  // Test functions
  
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
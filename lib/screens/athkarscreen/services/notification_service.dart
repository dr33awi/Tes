// lib/screens/athkarscreen/services/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert'; // إضافة استيراد json
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
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
      
  // Instance of BatteryOptimizationService
  final BatteryOptimizationService _batteryOptimizationService = BatteryOptimizationService();

  // Store device timezone
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
      // For iOS
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            // Remove onDidReceiveLocalNotification callback
          );

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
      
      // Check battery optimization on Android
      if (Platform.isAndroid) {
        // We'll check this later in the UI context
        await _saveBatteryOptimizationStatus();
      }
      
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

  // Save battery optimization status
  Future<void> _saveBatteryOptimizationStatus() async {
    try {
      if (Platform.isAndroid) {
        final isOptimized = await _batteryOptimizationService.isBatteryOptimizationEnabled();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_battery_optimization', isOptimized);
      }
    } catch (e) {
      print('Error saving battery optimization status: $e');
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
            
        // Request exact alarms permission for API 31+
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestExactAlarmsPermission();
      } else if (Platform.isIOS) {
        // For iOS
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true, // For critical notifications (bypass Do Not Disturb)
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
      
      // Track that the notification was interacted with
      await _trackNotificationInteraction(payload);
    }
  }
  
  // Track notification interaction
  Future<void> _trackNotificationInteraction(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Extract category ID from payload
      final String categoryId = payload.split(':')[0];
      
      // Save interaction time
      final key = 'notification_interaction_${categoryId}_${DateTime.now().day}';
      await prefs.setString(key, DateTime.now().toIso8601String());
      
      // Increment interaction count
      final countKey = 'notification_interaction_count_$categoryId';
      final int currentCount = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, currentCount + 1);
      
    } catch (e) {
      print('Error tracking notification interaction: $e');
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
      final String title = category.notifyTitle ?? 'حان موعد ${category.title}';
      final String body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
      
      // Set notification details - with improved settings
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'athkar_channel_id',
        'أذكار',
        channelDescription: 'تنبيهات الأذكار',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true, // Added to show even on locked screen
        enableLights: true,
        ledColor: _getCategoryLedColor(category.id),
        ledOnMs: 1000,
        ledOffMs: 500,
        groupKey: 'athkar_group',
        styleInformation: BigTextStyleInformation(body),
        audioAttributesUsage: AudioAttributesUsage.notification, // Added for better sound handling
      );
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active, // Added to bypass some Focus modes
        categoryIdentifier: 'athkar',
        threadIdentifier: 'athkar_${category.id}', // Group notifications by category
        sound: 'default', // Default notification sound
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

      // Save settings and notification ID
      await _saveNotificationSettings(category.id, true, notificationTime);
      await _saveScheduledNotificationId(category.id, notificationId);
      
      // Track successful scheduling
      await _trackNotificationScheduled(category.id, notificationTime);
      
      return;
    } catch (e) {
      print('Error scheduling notification: $e');
      
      // Try backup method if primary method fails
      try {
        await _scheduleBackupNotification(category, notificationTime);
      } catch (backupError) {
        print('Error with backup notification: $backupError');
      }
      
      return;
    }
  }
  
  // Schedule a backup notification if the primary method fails
  Future<void> _scheduleBackupNotification(
      AthkarCategory category, TimeOfDay notificationTime) async {
    try {
      // Use a different ID for backup notification
      final int notificationId = _getNotificationIdFromCategoryId(category.id) + 50000;
      
      // Get scheduled datetime
      final tz.TZDateTime scheduledDate = _getScheduledDate(notificationTime);
      
      // Simpler notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'athkar_backup_channel',
        'أذكار (احتياطي)',
        channelDescription: 'تنبيهات احتياطية للأذكار',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Schedule basic notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'تذكير: ${category.title}',
        'اضغط هنا لقراءة الأذكار',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: category.id,
      );
      
      // Use AlarmManager as backup
      if (Platform.isAndroid) {
        final backupAlarmId = _getAlarmIdForCategory(category.id) + 20000;
        
        final now = DateTime.now();
        DateTime scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          notificationTime.hour,
          notificationTime.minute,
        );
        
        if (scheduledDateTime.isBefore(now)) {
          scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }
        
        await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          backupAlarmId,
          _showAthkarNotificationCallback,
          startAt: scheduledDateTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {
            'categoryId': category.id,
            'notificationId': notificationId,
            'title': 'تذكير: ${category.title}',
            'body': 'اضغط هنا لقراءة الأذكار',
            'isBackup': true,
          },
        );
      }
      
      print('Backup notification scheduled successfully for ${category.title}');
      await _saveScheduledNotificationId(category.id, notificationId, isBackup: true);
      
    } catch (e) {
      print('Error scheduling backup notification: $e');
    }
  }
  
  // Track when a notification is scheduled
  Future<void> _trackNotificationScheduled(String categoryId, TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_scheduled_${categoryId}';
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'time': '${time.hour}:${time.minute}',
      };
      await prefs.setString(key, data.toString());
    } catch (e) {
      print('Error tracking notification scheduled: $e');
    }
  }
  
  // Get LED color for notification based on category
  Color _getCategoryLedColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // Yellow for morning
      case 'evening':
        return const Color(0xFFAB47BC); // Purple for evening
      case 'sleep':
        return const Color(0xFF5C6BC0); // Blue for sleep
      case 'wake':
        return const Color(0xFFFFB74D); // Orange for wake
      case 'prayer':
        return const Color(0xFF4DB6AC); // Teal for prayer
      case 'home':
        return const Color(0xFF66BB6A); // Green for home
      case 'food':
        return const Color(0xFFE57373); // Red for food
      default:
        return const Color(0xFF447055); // Default to app primary color
    }
  }
  
  // Save the scheduled notification ID
  Future<void> _saveScheduledNotificationId(String categoryId, int notificationId, {bool isBackup = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isBackup 
          ? 'notification_backup_id_$categoryId' 
          : 'notification_id_$categoryId';
      await prefs.setInt(key, notificationId);
      
      // Also save to the list of all notification IDs
      final allIdsKey = 'all_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      final idKey = '${categoryId}_${isBackup ? 'backup' : 'primary'}_$notificationId';
      
      if (!allIds.contains(idKey)) {
        allIds.add(idKey);
        await prefs.setStringList(allIdsKey, allIds);
      }
    } catch (e) {
      print('Error saving notification ID: $e');
    }
  }
  
  // Schedule background alarm (for Android)
  Future<void> _scheduleBackgroundAlarm(
      AthkarCategory category, TimeOfDay notificationTime, String title, String body) async {
    try {
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
      
      // Save alarm ID
      await _saveAlarmId(category.id, alarmId);
      
    } catch (e) {
      print('Error scheduling background alarm: $e');
    }
  }
  
  // Save alarm ID
  Future<void> _saveAlarmId(String categoryId, int alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'alarm_id_$categoryId';
      await prefs.setInt(key, alarmId);
      
      // Also save to the list of all alarm IDs
      final allAlarmsKey = 'all_alarm_ids';
      final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
      
      final alarmKey = '${categoryId}_$alarmId';
      if (!allAlarms.contains(alarmKey)) {
        allAlarms.add(alarmKey);
        await prefs.setStringList(allAlarmsKey, allAlarms);
      }
    } catch (e) {
      print('Error saving alarm ID: $e');
    }
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
    
    try {
      // Initialize notifications plugin with proper initialization
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      
      // Need to initialize the plugin before showing notifications
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      
      // Extract notification data
      final categoryId = params['categoryId'] as String;
      final notificationId = params['notificationId'] as int;
      final title = params['title'] as String;
      final body = params['body'] as String;
      final isBackup = params['isBackup'] as bool? ?? false;
      
      // Enhanced notification details for better visibility
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        isBackup ? 'athkar_backup_channel' : 'athkar_channel_id',
        isBackup ? 'أذكار (احتياطي)' : 'أذكار',
        channelDescription: 'تنبيهات الأذكار',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      // Save for navigation if tapped
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notification_payload', categoryId);
      await prefs.setBool('opened_from_notification', true);
      await prefs.setString('notification_payload', categoryId);
      
      // Show notification
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: categoryId,
      );
      
      // Track that the notification was shown
      await _trackNotificationShown(categoryId, isBackup);
      
      print('Background notification showed successfully for category: $categoryId');
    } catch (e) {
      print('Error in background notification callback: $e');
    }
  }
  
  // Track when a notification is shown
  @pragma('vm:entry-point')
  static Future<void> _trackNotificationShown(String categoryId, bool isBackup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save the time this notification was shown
      final key = 'notification_shown_${categoryId}_${DateTime.now().day}';
      await prefs.setString(key, DateTime.now().toIso8601String());
      
      // Track if it was a backup notification
      if (isBackup) {
        final backupKey = 'backup_notification_shown_$categoryId';
        final int count = prefs.getInt(backupKey) ?? 0;
        await prefs.setInt(backupKey, count + 1);
      }
      
      // Increment total shown count
      final countKey = 'notification_shown_count_$categoryId';
      final int currentCount = prefs.getInt(countKey) ?? 0;
      await prefs.setInt(countKey, currentCount + 1);
      
    } catch (e) {
      print('Error tracking notification shown: $e');
    }
  }

  // Schedule additional notifications for multiple reminder times
  Future<void> scheduleAdditionalNotifications(AthkarCategory category) async {
    if (!category.hasMultipleReminders || category.additionalNotifyTimes == null) {
      return;
    }
    
    try {
      List<int> additionalNotificationIds = [];
      
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
            additionalNotificationIds.add(notificationId);
            
            // Get scheduled time
            final tz.TZDateTime scheduledDate = _getScheduledDate(additionalTime);
            
            // Set notification content
            final title = category.notifyTitle ?? 'حان موعد ${category.title}';
            final body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
            
            // Set notification details with improved settings
            final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'athkar_channel_id',
              'أذكار',
              channelDescription: 'تنبيهات الأذكار',
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
              groupKey: 'athkar_group',
              setAsGroupSummary: i == 0, // First additional notification is the group summary
            );
            
            final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.active,
              threadIdentifier: 'athkar_${category.id}',
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
              
              // Save alarm ID
              await _saveAlarmId('${category.id}_additional_$i', additionalAlarmId);
            }
          }
        }
      }
      
      // Save all additional notification IDs for this category
      await _saveAdditionalNotificationIds(category.id, additionalNotificationIds);
      
    } catch (e) {
      print('Error scheduling additional notifications: $e');
    }
  }
  
  // Save additional notification IDs
  Future<void> _saveAdditionalNotificationIds(String categoryId, List<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'additional_notification_ids_$categoryId';
      await prefs.setString(key, ids.join(','));
    } catch (e) {
      print('Error saving additional notification IDs: $e');
    }
  }
  
  // Get additional notification IDs
  Future<List<int>> _getAdditionalNotificationIds(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'additional_notification_ids_$categoryId';
      final idsString = prefs.getString(key);
      
      if (idsString != null && idsString.isNotEmpty) {
        return idsString
            .split(',')
            .map((id) => int.tryParse(id) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting additional notification IDs: $e');
      return [];
    }
  }

  // Cancel notifications for a category
  Future<void> cancelAthkarNotification(String categoryId) async {
    try {
      // Get all notification IDs for this category
      final int primaryId = await _getSavedNotificationId(categoryId);
      final int backupId = await _getSavedNotificationId(categoryId, isBackup: true);
      final List<int> additionalIds = await _getAdditionalNotificationIds(categoryId);
      
      // Cancel primary notification
      if (primaryId > 0) {
        await flutterLocalNotificationsPlugin.cancel(primaryId);
      }
      
      // Cancel backup notification
      if (backupId > 0) {
        await flutterLocalNotificationsPlugin.cancel(backupId);
      }
      
      // Cancel additional notifications
      for (final id in additionalIds) {
        await flutterLocalNotificationsPlugin.cancel(id);
      }
      
      // Cancel background alarms on Android
      if (Platform.isAndroid) {
        // Cancel main alarm
        int alarmId = _getAlarmIdForCategory(categoryId);
        await AndroidAlarmManager.cancel(alarmId);
        
        // Get saved additional alarm IDs
        final List<int> additionalAlarmIds = await _getAdditionalAlarmIds(categoryId);
        
        // Cancel additional alarms
        for (final id in additionalAlarmIds) {
          await AndroidAlarmManager.cancel(id);
        }
        
        // Cancel backup alarm if exists
        final backupAlarmId = _getAlarmIdForCategory(categoryId) + 20000;
        await AndroidAlarmManager.cancel(backupAlarmId);
      }
      
      // Save settings
      await _saveNotificationSettings(categoryId, false, null);
      await _clearNotificationIds(categoryId);
      
      // Track cancellation
      await _trackNotificationCancelled(categoryId);
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }
  
  // Track notification cancellation
  Future<void> _trackNotificationCancelled(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_cancelled_$categoryId';
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error tracking notification cancellation: $e');
    }
  }
  
  // Get saved notification ID
  Future<int> _getSavedNotificationId(String categoryId, {bool isBackup = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isBackup 
          ? 'notification_backup_id_$categoryId' 
          : 'notification_id_$categoryId';
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      print('Error getting saved notification ID: $e');
      return 0;
    }
  }
  
  // Clear notification IDs
  Future<void> _clearNotificationIds(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_id_$categoryId');
      await prefs.remove('notification_backup_id_$categoryId');
      await prefs.remove('additional_notification_ids_$categoryId');
    } catch (e) {
      print('Error clearing notification IDs: $e');
    }
  }
  
  // Get additional alarm IDs
  Future<List<int>> _getAdditionalAlarmIds(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allAlarmsKey = 'all_alarm_ids';
      final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
      
      // Filter alarms related to this category
      final categoryAlarms = allAlarms
          .where((key) => key.startsWith('${categoryId}_additional_'))
          .map((key) {
            final parts = key.split('_');
            return int.tryParse(parts.last) ?? 0;
          })
          .where((id) => id > 0)
          .toList();
      
      return categoryAlarms;
    } catch (e) {
      print('Error getting additional alarm IDs: $e');
      return [];
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      
      if (Platform.isAndroid) {
        // Get all saved alarm IDs
        final prefs = await SharedPreferences.getInstance();
        final allAlarmsKey = 'all_alarm_ids';
        final allAlarms = prefs.getStringList(allAlarmsKey) ?? <String>[];
        
        // Cancel all known alarms
        for (final alarmKey in allAlarms) {
          final parts = alarmKey.split('_');
          if (parts.length >= 2) {
            final alarmId = int.tryParse(parts.last) ?? 0;
            if (alarmId > 0) {
              await AndroidAlarmManager.cancel(alarmId);
            }
          }
        }
        
        // Also cancel default alarms for safety
        await AndroidAlarmManager.cancel(morningAthkarAlarmId);
        await AndroidAlarmManager.cancel(eveningAthkarAlarmId);
        await AndroidAlarmManager.cancel(sleepAthkarAlarmId);
        await AndroidAlarmManager.cancel(wakeAthkarAlarmId);
        await AndroidAlarmManager.cancel(prayerAthkarAlarmId);
        await AndroidAlarmManager.cancel(homeAthkarAlarmId);
        await AndroidAlarmManager.cancel(foodAthkarAlarmId);
        await AndroidAlarmManager.cancel(quranAthkarAlarmId);
        
        // Clear all saved notification IDs
        await prefs.remove('all_alarm_ids');
        await prefs.remove('all_notification_ids');
      }
      
      // Track reset
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notifications_reset', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  // Check if notifications are enabled for a category
  Future<bool> isNotificationEnabled(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notification_${categoryId}_enabled') ?? false;
    } catch (e) {
      print('Error checking if notification is enabled: $e');
      return false;
    }
  }

  // Get saved notification time for a category
  Future<TimeOfDay?> getNotificationTime(String categoryId) async {
    try {
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
    } catch (e) {
      print('Error getting notification time: $e');
      return null;
    }
  }

  // Schedule all saved notifications
  Future<void> scheduleAllSavedNotifications() async {
    try {
      // Get all categories that have saved notification settings
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys related to notifications
      final allKeys = prefs.getKeys();
      final notificationKeys = allKeys.where((key) => key.startsWith('notification_') && key.endsWith('_enabled'));
      
      int scheduledCount = 0;
      int failedCount = 0;
      
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
                
                try {
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
                  
                  // Schedule additional notifications if applicable
                  if (await _hasAdditionalNotifyTimes(categoryId)) {
                    await _scheduleAdditionalNotificationsFromSaved(category);
                  }
                  
                  scheduledCount++;
                } catch (e) {
                  print('Error scheduling notification for $categoryId: $e');
                  failedCount++;
                  
                  // Try backup scheduling
                  try {
                    await _scheduleBackupFromSaved(categoryId, hour, minute);
                  } catch (backupError) {
                    print('Backup scheduling also failed for $categoryId: $backupError');
                  }
                }
              }
            }
          }
        }
      }
      
      print('Scheduled $scheduledCount notifications (Failed: $failedCount)');
      await prefs.setInt('last_schedule_count', scheduledCount);
      await prefs.setInt('last_schedule_failed', failedCount);
      await prefs.setString('last_schedule_time', DateTime.now().toIso8601String());
      
    } catch (e) {
      print('Error scheduling saved notifications: $e');
    }
  }
  
  // Check if a category has additional notification times
  Future<bool> _hasAdditionalNotifyTimes(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_${categoryId}_additional_times';
      return prefs.containsKey(key) && prefs.getString(key)?.isNotEmpty == true;
    } catch (e) {
      print('Error checking additional notify times: $e');
      return false;
    }
  }
  
  // Schedule additional notifications from saved settings
  Future<void> _scheduleAdditionalNotificationsFromSaved(AthkarCategory category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notification_${category.id}_additional_times';
      final timesJson = prefs.getString(key);
      
      if (timesJson != null && timesJson.isNotEmpty) {
        try {
          final List<dynamic> times = timesJson.startsWith('[') 
              ? List<String>.from(json.decode(timesJson))
              : timesJson.split(',');
          
          // Create a category with additional times
          final categoryWithTimes = AthkarCategory(
            id: category.id,
            title: category.title,
            icon: category.icon,
            color: category.color,
            athkar: [],
            hasMultipleReminders: true,
            additionalNotifyTimes: times.map((t) => t.toString()).toList(),
          );
          
          await scheduleAdditionalNotifications(categoryWithTimes);
        } catch (e) {
          print('Error parsing additional times: $e');
        }
      }
    } catch (e) {
      print('Error scheduling additional notifications from saved: $e');
    }
  }
  
  // Simplified backup scheduling
  Future<void> _scheduleBackupFromSaved(String categoryId, int hour, int minute) async {
    try {
      // Create a dummy category
      final category = AthkarCategory(
        id: categoryId,
        title: _getCategoryTitle(categoryId),
        icon: _getCategoryIcon(categoryId),
        color: _getCategoryColor(categoryId),
        athkar: [],
      );
      
      // Schedule a backup notification
      await _scheduleBackupNotification(category, TimeOfDay(hour: hour, minute: minute));
    } catch (e) {
      print('Error in backup scheduling: $e');
    }
  }

  // Save notification settings
  Future<void> _saveNotificationSettings(
      String categoryId, bool isEnabled, TimeOfDay? notificationTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_${categoryId}_enabled', isEnabled);
      
      if (notificationTime != null) {
        final timeString = '${notificationTime.hour}:${notificationTime.minute}';
        await prefs.setString('notification_${categoryId}_time', timeString);
      }
      
      // Save the last update time
      await prefs.setString(
        'notification_${categoryId}_last_updated', 
        DateTime.now().toIso8601String()
      );
    } catch (e) {
      print('Error saving notification settings: $e');
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
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
      );
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
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
      
      // Track test notification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_notification_sent', DateTime.now().toIso8601String());
      
      print('Test notification sent successfully');
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }
  
  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
  
  // Get battery optimization service
  BatteryOptimizationService getBatteryOptimizationService() {
    return _batteryOptimizationService;
  }
  
  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Total notifications
      final allNotificationIdsKey = 'all_notification_ids';
      final allIds = prefs.getStringList(allNotificationIdsKey) ?? <String>[];
      
      // Count by category
      Map<String, int> countByCategory = {};
      for (final id in allIds) {
        final parts = id.split('_');
        if (parts.isNotEmpty) {
          final categoryId = parts[0];
          countByCategory[categoryId] = (countByCategory[categoryId] ?? 0) + 1;
        }
      }
      
      // Get pending notifications
      final List<PendingNotificationRequest> pendingNotifications = 
          await getPendingNotifications();
      
      return {
        'total_notifications': allIds.length,
        'pending_count': pendingNotifications.length,
        'by_category': countByCategory,
        'last_scheduled': prefs.getString('last_schedule_time') ?? 'Never',
        'last_scheduled_count': prefs.getInt('last_schedule_count') ?? 0,
        'last_reset': prefs.getString('notifications_reset') ?? 'Never',
      };
    } catch (e) {
      print('Error getting notification statistics: $e');
      return {
        'error': e.toString(),
        'total_notifications': 0,
        'pending_count': 0,
      };
    }
  }
}
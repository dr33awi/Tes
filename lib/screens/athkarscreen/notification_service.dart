import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/athkar_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// استخدام flutter_timezone بدلاً من flutter_native_timezone_latest
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:convert';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Flutter Local Notifications plugin instance
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Athkar service to access athkar data
  final AthkarService _athkarService = AthkarService();
  
  // Random generator for automated notifications
  final Random _random = Random();
  
  // توليد معرف فريد للإشعارات بناءً على فئة الذكر والوقت
  int _generateNotificationId(String categoryId, String time) {
    // استخدام خوارزمية هاش بسيطة لإنشاء معرف فريد
    final String combinedString = '$categoryId-$time';
    return combinedString.hashCode.abs();
  }
  
  // توليد معرف فريد للإشعارات الإضافية
  int _generateAdditionalNotificationId(String categoryId, String time, int index) {
    final String combinedString = '$categoryId-$time-$index';
    return combinedString.hashCode.abs();
  }
  
  // توليد معرف فريد للإشعارات التلقائية
  int _generateAutoNotificationId(String categoryId, int thikrIndex) {
    final String combinedString = 'auto-$categoryId-$thikrIndex-${DateTime.now().millisecondsSinceEpoch}';
    return combinedString.hashCode.abs();
  }
  
  // Initialize the notification service with enhanced error handling
  Future<void> initialize() async {
    try {
      // Initialize time zones for scheduled notifications
      tz_data.initializeTimeZones();
      
      // Set local timezone using flutter_timezone instead of flutter_native_timezone_latest
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      
      // Initialize Android Alarm Manager
      await AndroidAlarmManager.initialize();
      
      // Notification channel groups (Android)
      const List<AndroidNotificationChannelGroup> channelGroups = [
        AndroidNotificationChannelGroup(
          'athkar_channel_group', 
          'أذكار المسلم',
          description: 'مجموعة إشعارات أذكار المسلم المختلفة',
        ),
        AndroidNotificationChannelGroup(
          'auto_athkar_group', 
          'الأذكار التلقائية',
          description: 'إشعارات الأذكار التلقائية خلال اليوم',
        ),
      ];
      
      // Notification channels (Android)
      const List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'athkar_morning_channel', 
          'أذكار الصباح',
          description: 'إشعارات أذكار الصباح',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          groupId: 'athkar_channel_group',
        ),
        AndroidNotificationChannel(
          'athkar_evening_channel', 
          'أذكار المساء',
          description: 'إشعارات أذكار المساء',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          groupId: 'athkar_channel_group',
        ),
        AndroidNotificationChannel(
          'athkar_sleep_channel', 
          'أذكار النوم',
          description: 'إشعارات أذكار النوم',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          groupId: 'athkar_channel_group',
        ),
        AndroidNotificationChannel(
          'athkar_wake_channel', 
          'أذكار الاستيقاظ',
          description: 'إشعارات أذكار الاستيقاظ',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          groupId: 'athkar_channel_group',
        ),
        AndroidNotificationChannel(
          'athkar_prayer_channel', 
          'أذكار الصلاة',
          description: 'إشعارات أذكار الصلاة',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          groupId: 'athkar_channel_group',
        ),
        AndroidNotificationChannel(
          'athkar_other_channel', 
          'أذكار أخرى',
          description: 'إشعارات أذكار متنوعة أخرى',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          groupId: 'athkar_channel_group',
        ),
        // قناة خاصة بالإشعارات التلقائية
        AndroidNotificationChannel(
          'auto_athkar_channel', 
          'أذكار تلقائية',
          description: 'إشعارات الأذكار التلقائية خلال اليوم',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('short_notification'),
          groupId: 'auto_athkar_group',
        ),
      ];
      
      // Setup channel groups
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
          
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannelGroups(channelGroups);
      
      // Setup channels
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannels(channels);
      
      // Initialize notification settings for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialize notification settings for iOS with enhanced permissions
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        defaultPresentSound: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'athkarCategory',
            actions: [
              DarwinNotificationAction.plain(
                'view',
                'فتح',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                'later',
                'تذكيري لاحقاً',
              ),
            ],
            options: {
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
        ],
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
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
      );
      
      // Request notification permissions (iOS)
      if (Platform.isIOS) {
        await _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
      }
      
      // Request notification permissions (Android 13+)
      if (Platform.isAndroid) {
        await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
      }
      
      // Schedule all athkar notifications
      await scheduleAllAthkarNotifications();
      
      // Schedule automatic athkar notifications if enabled
      await scheduleAutomaticAthkarNotifications();
      
      print('NotificationService initialized successfully.');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }
  
  // الحصول على قائمة المناطق الزمنية المتاحة باستخدام flutter_timezone
  Future<List<String>> getAvailableTimezones() async {
    try {
      return await FlutterTimezone.getAvailableTimezones();
    } catch (e) {
      print('Error getting available timezones: $e');
      return [];
    }
  }
  // Handle when a local notification is tapped
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // تنفيذ نفس الكود الموجود في _onNotificationTapped
    if (response.payload != null) {
      // Handle navigation through app's navigation system
      print("Background notification payload: ${response.payload}");
      
      // Store the tap data to be processed when app opens
      _storeNotificationTapData(response.payload!);
    }
  }
  
  // Store notification tap data for later processing
  static Future<void> _storeNotificationTapData(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_tapped_notification', payload);
      await prefs.setBool('has_pending_notification_tap', true);
    } catch (e) {
      print('Error storing notification tap data: $e');
    }
  }
  
  // تحقق إذا كان هناك نقرة على إشعار بانتظار المعالجة
  Future<bool> hasNotificationTapPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_pending_notification_tap') ?? false;
    } catch (e) {
      print('Error checking for pending notification taps: $e');
      return false;
    }
  }
  
  // الحصول على بيانات آخر نقرة على إشعار ومعالجتها
  Future<String?> getAndProcessPendingNotificationTap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = prefs.getString('last_tapped_notification');
      
      // مسح البيانات بعد الحصول عليها
      await prefs.setBool('has_pending_notification_tap', false);
      
      return payload;
    } catch (e) {
      print('Error processing pending notification tap: $e');
      return null;
    }
  }
  
  // Handle when a local notification is tapped
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // The payload contains the category ID (and possibly other data)
      print("Notification payload: ${response.payload}");
      
      // Store the notification tap data
      _storeNotificationTapData(response.payload!);
    }
  }

  // الحصول على قناة الإشعارات المناسبة لفئة الأذكار
  String _getNotificationChannelId(String categoryId, {bool isAuto = false}) {
    if (isAuto) {
      return 'auto_athkar_channel';
    }
    
    switch (categoryId) {
      case 'morning':
        return 'athkar_morning_channel';
      case 'evening':
        return 'athkar_evening_channel';
      case 'sleep':
        return 'athkar_sleep_channel';
      case 'wake':
        return 'athkar_wake_channel';
      case 'prayer':
        return 'athkar_prayer_channel';
      default:
        return 'athkar_other_channel';
    }
  }
  
  // Schedule notifications for all athkar categories with enhanced support for multiple times
  Future<void> scheduleAllAthkarNotifications() async {
    try {
      // Cancel any existing scheduled notifications (but keep automatic ones)
      await _cancelScheduledNotifications(keepAutomatic: true);
      
      // Load all athkar categories
      final categories = await _athkarService.loadAllAthkarCategories();
      
      // Schedule notifications for each category
      for (final category in categories) {
        // Check if notifications are enabled for this category
        final isEnabled = await _athkarService.getNotificationEnabled(category.id);
        if (!isEnabled) continue;
        
        // Schedule primary notification
        if (category.notifyTime != null && category.notifyTime!.isNotEmpty) {
          // Check if there's a custom notification time
          final customTime = await _athkarService.getCustomNotificationTime(category.id);
          final timeToUse = customTime ?? category.notifyTime!;
          
          // Schedule notification
          await _scheduleAthkarNotification(category, timeToUse);
        }
        
        // Schedule additional notifications if enabled
        if (category.hasMultipleReminders) {
          final additionalTimes = await _athkarService.getAdditionalNotificationTimes(category.id);
          
          for (int i = 0; i < additionalTimes.length; i++) {
            await _scheduleAdditionalAthkarNotification(category, additionalTimes[i], i);
          }
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
      
      print('All athkar notifications scheduled successfully.');
    } catch (e) {
      print('Error scheduling all athkar notifications: $e');
    }
  }
  
  // إلغاء الإشعارات المجدولة فقط (مع خيار للحفاظ على الإشعارات التلقائية)
  Future<void> _cancelScheduledNotifications({bool keepAutomatic = false}) async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notifications.pendingNotificationRequests();
      
      for (var notification in pendingNotifications) {
        // تحليل البيانات المرفقة للتحقق إذا كان إشعارًا تلقائيًا
        if (notification.payload != null) {
          try {
            final Map<String, dynamic> payloadData = json.decode(notification.payload!);
            final bool isAutoNotification = payloadData['type'] == 'auto';
            
            // إذا كان الإشعار تلقائيًا والخيار هو الاحتفاظ بالإشعارات التلقائية، تخطيه
            if (isAutoNotification && keepAutomatic) {
              continue;
            }
          } catch (e) {
            // إذا حدث خطأ في تحليل البيانات، افترض أنه ليس إشعارًا تلقائيًا
          }
        }
        
        // إلغاء الإشعار
        await _notifications.cancel(notification.id);
      }
      
      print('Scheduled notifications cancelled' + (keepAutomatic ? ' (keeping automatic ones)' : ''));
    } catch (e) {
      print('Error cancelling scheduled notifications: $e');
    }
  }
  
  // Callback function for periodic alarm
  @pragma('vm:entry-point')
  static Future<void> _rescheduleNotificationsCallback() async {
    // Get a new instance of the service (since this runs in a separate isolate)
    try {
      final service = NotificationService();
      await service.scheduleAllAthkarNotifications();
      print('Daily notification reschedule complete.');
    } catch (e) {
      print('Error in reschedule notifications callback: $e');
    }
  }
  
  // Schedule a notification for a specific athkar category
  Future<void> _scheduleAthkarNotification(AthkarCategory category, String timeString) async {
    try {
      // Parse the time string (format: HH:MM)
      final parts = timeString.split(':');
      if (parts.length != 2) {
        print('Invalid time format: $timeString');
        return;
      }
      
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
      
      // Get notification settings for this category
      final settings = await _athkarService.getNotificationSettings(category.id);
      
      // Create the notification details
      final String channelId = _getNotificationChannelId(category.id);
      
      // Determine the sound to use
      String soundName = 'azan';
      if (settings.customSound != null && settings.customSound!.isNotEmpty) {
        soundName = settings.customSound!;
      } else if (category.notifySound != null && category.notifySound!.isNotEmpty) {
        soundName = category.notifySound!;
      }
      
      // Create Android-specific notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        '${category.title}',
        channelDescription: 'إشعارات ${category.title}',
        importance: Importance.values[settings.importance],
        priority: Priority.values[settings.importance],
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        enableVibration: settings.vibrate,
        enableLights: settings.showLed,
        ledColor: settings.ledColor ?? const Color(0xFF447055),
        color: category.color,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        channelShowBadge: true,
        autoCancel: true,
        fullScreenIntent: false,
        visibility: NotificationVisibility.public,
        usesChronometer: false,
      );
      
      // Create iOS-specific notification details
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundName.aiff', // Name should match file in Runner/Resources
        badgeNumber: 1,
        categoryIdentifier: 'athkarCategory',
        interruptionLevel: InterruptionLevel.active,
      );
      
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Generate a unique ID for this category and time
      final int notificationId = _generateNotificationId(category.id, timeString);
      
      // Prepare notification title and body text
      String title = category.notifyTitle ?? 'حان وقت ${category.title}';
      String body = category.notifyBody ?? 'تذكير: لا تنس قراءة ${category.title}';
      
      // Get the count of completed athkar for this category
      final stats = await _athkarService.getCategoryStats(category.id);
      if (stats.totalThikrs > 0) {
        final percentage = stats.completionPercentage.toStringAsFixed(0);
        body += ' (أكملت $percentage% من الأذكار سابقاً)';
      }
      
      // Create the payload with category ID and additional data
      final Map<String, dynamic> payloadData = {
        'categoryId': category.id,
        'type': 'primary',
        'time': timeString,
      };
      final String payload = json.encode(payloadData);
      
      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(notificationTime, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Daily at the same time
        payload: payload,
      );
      
      print('Scheduled notification for ${category.title} at $timeString (ID: $notificationId)');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
  
  // Schedule an additional notification for a category
  Future<void> _scheduleAdditionalAthkarNotification(
    AthkarCategory category, 
    String timeString,
    int index
  ) async {
    try {
      // Parse the time string (format: HH:MM)
      final parts = timeString.split(':');
      if (parts.length != 2) {
        print('Invalid additional time format: $timeString');
        return;
      }
      
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
      
      // Get notification settings
      final settings = await _athkarService.getNotificationSettings(category.id);
      
      // Create the notification details
      final String channelId = _getNotificationChannelId(category.id);
      
      // Determine the sound to use
      String soundName = 'azan';
      if (settings.customSound != null && settings.customSound!.isNotEmpty) {
        soundName = settings.customSound!;
      } else if (category.notifySound != null && category.notifySound!.isNotEmpty) {
        soundName = category.notifySound!;
      }
      
      // Create Android-specific notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        '${category.title} - تذكير إضافي',
        channelDescription: 'تذكيرات إضافية لـ ${category.title}',
        importance: Importance.values[settings.importance],
        priority: Priority.values[settings.importance],
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        enableVibration: settings.vibrate,
        enableLights: settings.showLed,
        ledColor: settings.ledColor ?? const Color(0xFF447055),
        color: category.color,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        channelShowBadge: true,
      );
      
      // Create iOS-specific notification details
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundName.aiff', // Name should match file in Runner/Resources
        badgeNumber: 1,
        categoryIdentifier: 'athkarCategory',
      );
      
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Generate a unique ID for this additional notification
      final int notificationId = _generateAdditionalNotificationId(category.id, timeString, index);
      
      // Create a different message for additional notifications
      String title = 'تذكير إضافي: ${category.title}';
      String body = 'لا تنس قراءة ${category.title} في هذا الوقت أيضاً';
      
      // Create the payload with category ID and additional data
      final Map<String, dynamic> payloadData = {
        'categoryId': category.id,
        'type': 'additional',
        'time': timeString,
        'index': index,
      };
      final String payload = json.encode(payloadData);
      
      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(notificationTime, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Daily at the same time
        payload: payload,
      );
      
      print('Scheduled additional notification for ${category.title} at $timeString (ID: $notificationId)');
    } catch (e) {
      print('Error scheduling additional notification: $e');
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
  
  // إضافة وقت إشعار إضافي لفئة معينة
  Future<void> addAdditionalNotificationTime(String categoryId, String time) async {
    await _athkarService.addAdditionalNotificationTime(categoryId, time);
    await scheduleAllAthkarNotifications(); // Reschedule all notifications
  }
  
  // حذف وقت إشعار إضافي من فئة معينة
  Future<void> removeAdditionalNotificationTime(String categoryId, String time) async {
    await _athkarService.removeAdditionalNotificationTime(categoryId, time);
    await scheduleAllAthkarNotifications(); // Reschedule all notifications
  }
  
  // Send an immediate test notification
  Future<void> sendTestNotification(String categoryId, {String? customTitle, String? customBody}) async {
    try {
      // Get the category
      final category = await _athkarService.getAthkarCategory(categoryId);
      if (category == null) {
        print('Category not found: $categoryId');
        return;
      }
      
      // Get notification settings
      final settings = await _athkarService.getNotificationSettings(categoryId);
      
      // Get the appropriate channel
      final String channelId = _getNotificationChannelId(categoryId);
      
      // Determine the sound to use
      String soundName = 'azan';
      if (settings.customSound != null && settings.customSound!.isNotEmpty) {
        soundName = settings.customSound!;
      } else if (category.notifySound != null && category.notifySound!.isNotEmpty) {
        soundName = category.notifySound!;
      }
      
      // Create Android-specific notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        'اختبار الإشعارات',
        channelDescription: 'قناة لاختبار الإشعارات',
        importance: Importance.values[settings.importance],
        priority: Priority.values[settings.importance],
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        enableVibration: settings.vibrate,
        enableLights: settings.showLed,
        ledColor: settings.ledColor ?? const Color(0xFF447055),
        color: category.color,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );
      
      // Create iOS-specific notification details
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundName.aiff',
        badgeNumber: 1,
        categoryIdentifier: 'athkarCategory',
      );
      
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Create title and body
      final String title = customTitle ?? 'اختبار إشعارات ${category.title}';
      final String body = customBody ?? 'هذا إشعار تجريبي للتأكد من عمل نظام الإشعارات بشكل صحيح';
      
      // Create the payload
      final Map<String, dynamic> payloadData = {
        'categoryId': categoryId,
        'type': 'test',
      };
      final String payload = json.encode(payloadData);
      
      // Show the notification
      await _notifications.show(
        0, // ID
        title,
        body,
        platformDetails,
        payload: payload,
      );
      
      print('Test notification sent for ${category.title} (ID: 0)');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }
  
  // =============== بداية ميزة الإشعارات التلقائية للأذكار ===============
  
  // التحقق ما إذا كانت الإشعارات التلقائية مفعلة
  Future<bool> isAutomaticNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_notifications_enabled') ?? false;
  }
  
  // تفعيل/تعطيل الإشعارات التلقائية
  Future<void> setAutomaticNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_notifications_enabled', enabled);
    
    if (enabled) {
      // جدولة الإشعارات التلقائية إذا تم تفعيلها
      await scheduleAutomaticAthkarNotifications();
    } else {
      // إلغاء الإشعارات التلقائية إذا تم تعطيلها
      await cancelAutomaticAthkarNotifications();
    }
  }
  
  // الحصول على إعدادات الإشعارات التلقائية
  Future<AutoNotificationSettings> getAutomaticNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return AutoNotificationSettings(
      isEnabled: prefs.getBool('auto_notifications_enabled') ?? false,
      minFrequency: prefs.getInt('auto_notifications_min_frequency') ?? 120, // دقائق
      maxFrequency: prefs.getInt('auto_notifications_max_frequency') ?? 240, // دقائق
      timeRangeStart: prefs.getString('auto_notifications_time_range_start') ?? '08:00',
      timeRangeEnd: prefs.getString('auto_notifications_time_range_end') ?? '22:00',
      useShortSound: prefs.getBool('auto_notifications_short_sound') ?? true,
      includeQuranVerses: prefs.getBool('auto_notifications_include_quran') ?? true,
      maxPerDay: prefs.getInt('auto_notifications_max_per_day') ?? 10,
      excludedCategories: prefs.getStringList('auto_notifications_excluded_categories') ?? [],
    );
  }
  
  // حفظ إعدادات الإشعارات التلقائية
  Future<void> saveAutomaticNotificationSettings(AutoNotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('auto_notifications_enabled', settings.isEnabled);
    await prefs.setInt('auto_notifications_min_frequency', settings.minFrequency);
    await prefs.setInt('auto_notifications_max_frequency', settings.maxFrequency);
    await prefs.setString('auto_notifications_time_range_start', settings.timeRangeStart);
    await prefs.setString('auto_notifications_time_range_end', settings.timeRangeEnd);
    await prefs.setBool('auto_notifications_short_sound', settings.useShortSound);
    await prefs.setBool('auto_notifications_include_quran', settings.includeQuranVerses);
    await prefs.setInt('auto_notifications_max_per_day', settings.maxPerDay);
    await prefs.setStringList('auto_notifications_excluded_categories', settings.excludedCategories);
    
    // إعادة جدولة الإشعارات التلقائية بعد تحديث الإعدادات
    if (settings.isEnabled) {
      await scheduleAutomaticAthkarNotifications();
    } else {
      await cancelAutomaticAthkarNotifications();
    }
  }
  
  // جدولة الإشعارات التلقائية
  Future<void> scheduleAutomaticAthkarNotifications() async {
    try {
      // التحقق ما إذا كانت الإشعارات التلقائية مفعلة
      final isEnabled = await isAutomaticNotificationsEnabled();
      if (!isEnabled) {
        print('Automatic notifications are disabled.');
        return;
      }
      
      // إلغاء أي إشعارات تلقائية موجودة
      await cancelAutomaticAthkarNotifications();
      
      // الحصول على إعدادات الإشعارات التلقائية
      final settings = await getAutomaticNotificationSettings();
      
      // تحميل جميع فئات الأذكار
      final allCategories = await _athkarService.loadAllAthkarCategories();
      
      // تصفية الفئات المستثناة
      final categories = allCategories.where((cat) => 
        !settings.excludedCategories.contains(cat.id)).toList();
      
      if (categories.isEmpty) {
        print('No eligible categories found for automatic notifications.');
        return;
      }
      
      // تحليل نطاق الوقت
      final startParts = settings.timeRangeStart.split(':');
      final endParts = settings.timeRangeEnd.split(':');
      
      if (startParts.length != 2 || endParts.length != 2) {
        print('Invalid time range format.');
        return;
      }
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      // حساب عدد الدقائق المتاحة في النطاق الزمني
      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
      final endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);
      
      // التعامل مع حالة امتداد النطاق عبر منتصف الليل
      int availableMinutes;
      if (endTime.isAfter(startTime)) {
        availableMinutes = endTime.difference(startTime).inMinutes;
      } else {
        final nextDayEnd = endTime.add(const Duration(days: 1));
        availableMinutes = nextDayEnd.difference(startTime).inMinutes;
      }
      
      // حساب عدد الإشعارات الممكنة بناءً على التردد الأدنى
      final maxPossibleNotifications = availableMinutes ~/ settings.minFrequency;
      
      // تحديد عدد الإشعارات اليومية (الأقل بين العدد الأقصى المحدد والعدد الممكن)
      final notificationsCount = min(settings.maxPerDay, maxPossibleNotifications);
      
      if (notificationsCount <= 0) {
        print('No valid automatic notifications can be scheduled with current settings.');
        return;
      }
      
      print('Scheduling $notificationsCount automatic notifications within time range ${settings.timeRangeStart}-${settings.timeRangeEnd}');
      
      // تجميع جميع الأذكار في قائمة واحدة
      List<AutoThikrItem> allAthkar = [];
      
      for (final category in categories) {
        for (int i = 0; i < category.athkar.length; i++) {
          final thikr = category.athkar[i];
          
          // تخطي الآيات القرآنية إذا كان الخيار معطلاً
          if (thikr.isQuranVerse && !settings.includeQuranVerses) {
            continue;
          }
          
          allAthkar.add(AutoThikrItem(
            categoryId: category.id,
            thikrIndex: i,
            text: thikr.text,
            source: thikr.source,
            fadl: thikr.fadl,
            isQuranVerse: thikr.isQuranVerse,
            surahName: thikr.surahName,
          ));
        }
      }
      
      if (allAthkar.isEmpty) {
        print('No eligible athkar found for automatic notifications.');
        return;
      }
      
      // خلط قائمة الأذكار لعشوائية أكبر
      allAthkar.shuffle(_random);
      
      // إذا كان عدد الأذكار أقل من عدد الإشعارات المطلوبة، كرر القائمة
      if (allAthkar.length < notificationsCount) {
        final repetitions = (notificationsCount / allAthkar.length).ceil();
        final originalList = List<AutoThikrItem>.from(allAthkar);
        
        for (int i = 1; i < repetitions; i++) {
          originalList.shuffle(_random);
          allAthkar.addAll(originalList);
        }
      }
      
      // اختيار الأذكار للإشعارات
      final selectedAthkar = allAthkar.take(notificationsCount).toList();
      
      // توزيع الإشعارات على النطاق الزمني المتاح
      final intervals = _distributeRandomIntervals(
        availableMinutes, 
        notificationsCount, 
        settings.minFrequency, 
        settings.maxFrequency
      );
      
      // حساب أوقات الإشعارات
      DateTime currentTime = startTime;
      
      // تعيين بداية الوقت حسب الوقت الحالي، إذا كان الوقت الحالي ضمن النطاق
      if (now.isAfter(startTime) && (endTime.isAfter(now) || startTime.isAfter(endTime))) {
        currentTime = now;
      }
      
      // جدولة كل إشعار
      for (int i = 0; i < notificationsCount; i++) {
        // إضافة الفاصل الزمني إلى الوقت الحالي
        currentTime = currentTime.add(Duration(minutes: intervals[i]));
        
        // جدولة الإشعار
        await _scheduleAutomaticAthkarNotification(
          selectedAthkar[i], 
          currentTime, 
          settings.useShortSound
        );
      }
      
      // حفظ عدد الإشعارات التلقائية المجدولة اليوم
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auto_notifications_count_today', notificationsCount);
      await prefs.setString('auto_notifications_date', DateTime.now().toIso8601String());
      
      print('Successfully scheduled $notificationsCount automatic athkar notifications.');
      
      // تعيين منبه لإعادة جدولة الإشعارات التلقائية بعد 24 ساعة
      const int autoReschedulerId = 9876543;
      await AndroidAlarmManager.oneShot(
        const Duration(hours: 24),
        autoReschedulerId,
        _rescheduleAutomaticNotificationsCallback,
        wakeup: true,
        exact: true,
        rescheduleOnReboot: true,
      );
    } catch (e) {
      print('Error scheduling automatic athkar notifications: $e');
    }
  }
  
  // توزيع فواصل زمنية عشوائية
  List<int> _distributeRandomIntervals(int totalMinutes, int count, int minInterval, int maxInterval) {
    // إنشاء قائمة بالفواصل الزمنية
    List<int> intervals = [];
    
    // التأكد من أننا لن نستخدم أكثر من الوقت المتاح
    int remainingMinutes = totalMinutes;
    int remainingCount = count;
    
    for (int i = 0; i < count - 1; i++) {
      // حساب الحد الأقصى المسموح به لهذا الفاصل
      final maxPossible = min(maxInterval, remainingMinutes - (remainingCount - 1) * minInterval);
      
      if (maxPossible < minInterval) {
        // إذا لم يعد هناك وقت كافٍ، استخدم الحد الأدنى
        intervals.add(minInterval);
      } else {
        // اختيار فاصل زمني عشوائي ضمن النطاق المسموح
        final interval = minInterval + _random.nextInt(maxPossible - minInterval + 1);
        intervals.add(interval);
      }
      
      // تحديث الوقت المتبقي والعدد المتبقي
      remainingMinutes -= intervals.last;
      remainingCount--;
    }
    
    // الفاصل الأخير يستخدم كل الوقت المتبقي
    intervals.add(max(minInterval, remainingMinutes));
    
    return intervals;
  }
  
  // Callback function for auto reschedule
  @pragma('vm:entry-point')
  static Future<void> _rescheduleAutomaticNotificationsCallback() async {
    try {
      final service = NotificationService();
      await service.scheduleAutomaticAthkarNotifications();
      print('Automatic notifications rescheduled successfully.');
    } catch (e) {
      print('Error in automatic notifications reschedule callback: $e');
    }
  }
  
  // إلغاء الإشعارات التلقائية
  Future<void> cancelAutomaticAthkarNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notifications.pendingNotificationRequests();
      
      for (var notification in pendingNotifications) {
        if (notification.payload != null) {
          try {
            final Map<String, dynamic> payloadData = json.decode(notification.payload!);
            final bool isAutoNotification = payloadData['type'] == 'auto';
            
            if (isAutoNotification) {
              await _notifications.cancel(notification.id);
              print('Cancelled automatic notification (ID: ${notification.id})');
            }
          } catch (e) {
            // تجاهل أخطاء تحليل JSON
          }
        }
      }
    } catch (e) {
      print('Error cancelling automatic notifications: $e');
    }
  }
  
  // جدولة إشعار تلقائي معين
  Future<void> _scheduleAutomaticAthkarNotification(
    AutoThikrItem thikr,
    DateTime scheduledTime,
    bool useShortSound
  ) async {
    try {
      // الحصول على الفئة
      final category = await _athkarService.getAthkarCategory(thikr.categoryId);
      if (category == null) {
        print('Category not found: ${thikr.categoryId}');
        return;
      }
      
      // إنشاء معرف فريد للإشعار
      final int notificationId = _generateAutoNotificationId(thikr.categoryId, thikr.thikrIndex);
      
      // إعداد تفاصيل الإشعار
      final String channelId = _getNotificationChannelId(thikr.categoryId, isAuto: true);
      
      // تحديد الصوت المستخدم
      final String soundName = useShortSound ? 'short_notification' : 'notification';
      
      // Create Android-specific notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        'أذكار تلقائية',
        channelDescription: 'إشعارات الأذكار التلقائية',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: category.color,
        color: category.color,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
        channelShowBadge: true,
      );
      
      // Create iOS-specific notification details
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundName.aiff',
        badgeNumber: 1,
        categoryIdentifier: 'athkarCategory',
      );
      
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // إنشاء عنوان ونص الإشعار
      String title = 'ذكر من ${category.title}';
      String body = thikr.text;
      
      // اختصار النص إذا كان طويلاً
      if (body.length > 100) {
        body = '${body.substring(0, 97)}...';
      }
      
      // إضافة مصدر الذكر إذا كان موجوداً
      if (thikr.source != null) {
        body += '\n(${thikr.source})';
      }
      
      // إضافة اسم السورة إذا كان ذكراً قرآنياً
      if (thikr.isQuranVerse && thikr.surahName != null) {
        title = 'آية من سورة ${thikr.surahName}';
      }
      
      // إنشاء البيانات المرفقة
      final Map<String, dynamic> payloadData = {
        'categoryId': thikr.categoryId,
        'thikrIndex': thikr.thikrIndex,
        'type': 'auto',
      };
      final String payload = json.encode(payloadData);
      
      // جدولة الإشعار
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      print('Scheduled automatic notification for ${category.title} at ${scheduledTime.toString()} (ID: $notificationId)');
    } catch (e) {
      print('Error scheduling automatic notification: $e');
    }
  }

  // التحقق ما إذا كان هناك إشعارات تلقائية مجدولة
  Future<bool> hasAutomaticNotificationsScheduled() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notifications.pendingNotificationRequests();
      
      for (var notification in pendingNotifications) {
        if (notification.payload != null) {
          try {
            final Map<String, dynamic> payloadData = json.decode(notification.payload!);
            final bool isAutoNotification = payloadData['type'] == 'auto';
            
            if (isAutoNotification) {
              return true;
            }
          } catch (e) {
            // تجاهل أخطاء تحليل JSON
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking for automatic notifications: $e');
      return false;
    }
  }
  
  // الحصول على عدد الإشعارات التلقائية المجدولة اليوم
  Future<int> getAutomaticNotificationsCountToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // التحقق إذا كان التاريخ المحفوظ هو اليوم
      final dateString = prefs.getString('auto_notifications_date');
      if (dateString != null) {
        final savedDate = DateTime.parse(dateString);
        final now = DateTime.now();
        
        if (savedDate.year == now.year && savedDate.month == now.month && savedDate.day == now.day) {
          return prefs.getInt('auto_notifications_count_today') ?? 0;
        }
      }
      
      return 0;
    } catch (e) {
      print('Error getting automatic notifications count: $e');
      return 0;
    }
  }
  
  // التحقق من وجود إشعارات مجدولة لفئة معينة
  Future<bool> hasPendingNotificationsForCategory(String categoryId) async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notifications.pendingNotificationRequests();
      
      // البحث عن إشعارات تخص هذه الفئة
      for (var notification in pendingNotifications) {
        if (notification.payload != null) {
          try {
            final Map<String, dynamic> payloadData = json.decode(notification.payload!);
            if (payloadData['categoryId'] == categoryId) {
              return true;
            }
          } catch (e) {
            // تجاهل أخطاء تحليل JSON
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking pending notifications: $e');
      return false;
    }
  }

  // الحصول على جميع الإشعارات المجدولة لفئة معينة
  Future<List<PendingNotificationInfo>> getPendingNotificationsForCategory(String categoryId) async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notifications.pendingNotificationRequests();
      
      List<PendingNotificationInfo> categoryNotifications = [];
      
      // البحث عن إشعارات تخص هذه الفئة
      for (var notification in pendingNotifications) {
        if (notification.payload != null) {
          try {
            final Map<String, dynamic> payloadData = json.decode(notification.payload!);
            if (payloadData['categoryId'] == categoryId) {
              categoryNotifications.add(
                PendingNotificationInfo(
                  id: notification.id,
                  title: notification.title ?? '',
                  body: notification.body ?? '',
                  payload: payloadData,
                  type: payloadData['type'] ?? 'unknown',
                  time: payloadData['time'] ?? '',
                ),
              );
            }
          } catch (e) {
            // تجاهل أخطاء تحليل JSON
          }
        }
      }
      
      return categoryNotifications;
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
  
  // إلغاء جميع الإشعارات المجدولة لفئة معينة
  Future<void> cancelNotificationsForCategory(String categoryId) async {
    try {
      final notifications = await getPendingNotificationsForCategory(categoryId);
      
      for (var notification in notifications) {
        await _notifications.cancel(notification.id);
      }
      
      print('Cancelled all notifications for category: $categoryId');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }
  
  // إلغاء إشعار محدد بمعرفه
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('Cancelled notification with ID: $id');
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }
  
  // جدولة إشعار لوقت معين بالثواني (مفيد للتذكيرات المؤقتة)
  Future<int> scheduleReminderAfterSeconds(
    String title,
    String body,
    int seconds,
    {String? categoryId}
  ) async {
    try {
      // إنشاء معرف فريد للإشعار
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // إعداد وقت الإشعار
      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
      
      // إعداد تفاصيل الإشعار
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'athkar_reminder_channel',
        'تذكيرات مؤقتة',
        channelDescription: 'تذكيرات قصيرة المدى',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // إنشاء البيانات المرفقة
      final Map<String, dynamic> payloadData = {
        'type': 'reminder',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (categoryId != null) {
        payloadData['categoryId'] = categoryId;
      }
      
      final String payload = json.encode(payloadData);
      
      // جدولة الإشعار
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      print('Scheduled reminder notification in $seconds seconds with ID: $notificationId');
      return notificationId;
    } catch (e) {
      print('Error scheduling reminder: $e');
      return -1;
    }
  }
  
  // جدولة سلسلة من التذكيرات للأذكار التي لم يتم إكمالها
  Future<List<int>> scheduleCompletionReminders(String categoryId) async {
    try {
      final category = await _athkarService.getAthkarCategory(categoryId);
      if (category == null) {
        print('Category not found: $categoryId');
        return [];
      }
      
      // الحصول على إحصائيات الفئة
      final stats = await _athkarService.getCategoryStats(categoryId);
      
      // إذا كانت جميع الأذكار مكتملة، لا داعي للتذكير
      if (stats.completedThikrs >= stats.totalThikrs) {
        print('All athkar are completed for category: $categoryId');
        return [];
      }
      
      // عدد الأذكار التي لم يتم إكمالها
      final remainingThikrs = stats.totalThikrs - stats.completedThikrs;
      
      // جدولة سلسلة من التذكيرات
      final List<int> reminderIds = [];
      
      // التذكير الأول بعد 30 دقيقة
      final firstReminderId = await scheduleReminderAfterSeconds(
        'تذكير بإكمال ${category.title}',
        'لا يزال لديك $remainingThikrs أذكار لم تكملها بعد',
        30 * 60, // 30 دقيقة
        categoryId: categoryId,
      );
      
      if (firstReminderId != -1) {
        reminderIds.add(firstReminderId);
      }
      
      // التذكير الثاني بعد ساعتين
      final secondReminderId = await scheduleReminderAfterSeconds(
        'لم تكمل ${category.title} بعد',
        'لا تنس إكمال الأذكار المتبقية لك ($remainingThikrs ذكر)',
        2 * 60 * 60, // ساعتين
        categoryId: categoryId,
      );
      
      if (secondReminderId != -1) {
        reminderIds.add(secondReminderId);
      }
      
      return reminderIds;
    } catch (e) {
      print('Error scheduling completion reminders: $e');
      return [];
    }
  }
  
  // الحصول على وقت الإشعار التالي لفئة معينة
  Future<DateTime?> getNextNotificationTime(String categoryId) async {
    try {
      final notifications = await getPendingNotificationsForCategory(categoryId);
      
      if (notifications.isEmpty) {
        return null;
      }
      
      final category = await _athkarService.getAthkarCategory(categoryId);
      if (category == null) {
        return null;
      }
      
      // استخراج أوقات الإشعارات الرئيسية
      List<DateTime> notificationTimes = [];
      
      // الوقت الرئيسي
      String? mainTime = await _athkarService.getCustomNotificationTime(categoryId) ?? category.notifyTime;
      if (mainTime != null) {
        try {
          final parts = mainTime.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          
          // إنشاء وقت لليوم الحالي
          final now = DateTime.now();
          DateTime time = DateTime(now.year, now.month, now.day, hour, minute);
          
          // إذا كان الوقت قد مر، أضف يوم
          if (time.isBefore(now)) {
            time = time.add(const Duration(days: 1));
          }
          
          notificationTimes.add(time);
        } catch (e) {
          print('Error parsing main time: $e');
        }
      }
      
      // الأوقات الإضافية
      final additionalTimes = await _athkarService.getAdditionalNotificationTimes(categoryId);
      for (final timeString in additionalTimes) {
        try {
          final parts = timeString.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          
          // إنشاء وقت لليو// إنشاء وقت لليوم الحالي
          final now = DateTime.now();
          DateTime time = DateTime(now.year, now.month, now.day, hour, minute);
          
          // إذا كان الوقت قد مر، أضف يوم
          if (time.isBefore(now)) {
            time = time.add(const Duration(days: 1));
          }
          
          notificationTimes.add(time);
        } catch (e) {
          print('Error parsing additional time: $e');
        }
      }
      
      // ترتيب الأوقات وإرجاع الأقرب
      if (notificationTimes.isNotEmpty) {
        notificationTimes.sort();
        return notificationTimes.first;
      }
      
      return null;
    } catch (e) {
      print('Error getting next notification time: $e');
      return null;
    }
  }
}

// فئة لتمثيل معلومات الإشعار المجدول
class PendingNotificationInfo {
  final int id;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final String type; // primary, additional, test, reminder, auto
  final String time;
  
  PendingNotificationInfo({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.type,
    required this.time,
  });
}

// فئة لإعدادات الإشعارات التلقائية
class AutoNotificationSettings {
  final bool isEnabled;
  final int minFrequency; // الحد الأدنى للفاصل الزمني بين الإشعارات (بالدقائق)
  final int maxFrequency; // الحد الأقصى للفاصل الزمني بين الإشعارات (بالدقائق)
  final String timeRangeStart; // بداية نطاق الوقت (بصيغة "HH:MM")
  final String timeRangeEnd; // نهاية نطاق الوقت (بصيغة "HH:MM")
  final bool useShortSound; // استخدام صوت قصير للإشعارات
  final bool includeQuranVerses; // تضمين الآيات القرآنية في الإشعارات التلقائية
  final int maxPerDay; // الحد الأقصى لعدد الإشعارات في اليوم
  final List<String> excludedCategories; // فئات الأذكار المستثناة من الإشعارات التلقائية
  
  const AutoNotificationSettings({
    this.isEnabled = false,
    this.minFrequency = 120, // الحد الأدنى الافتراضي هو ساعتين (120 دقيقة)
    this.maxFrequency = 240, // الحد الأقصى الافتراضي هو 4 ساعات (240 دقيقة)
    this.timeRangeStart = '08:00',
    this.timeRangeEnd = '22:00',
    this.useShortSound = true,
    this.includeQuranVerses = true,
    this.maxPerDay = 10,
    this.excludedCategories = const [],
  });
  
  // إنشاء نسخة جديدة مع تعديل بعض الإعدادات
  AutoNotificationSettings copyWith({
    bool? isEnabled,
    int? minFrequency,
    int? maxFrequency,
    String? timeRangeStart,
    String? timeRangeEnd,
    bool? useShortSound,
    bool? includeQuranVerses,
    int? maxPerDay,
    List<String>? excludedCategories,
  }) {
    return AutoNotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      minFrequency: minFrequency ?? this.minFrequency,
      maxFrequency: maxFrequency ?? this.maxFrequency,
      timeRangeStart: timeRangeStart ?? this.timeRangeStart,
      timeRangeEnd: timeRangeEnd ?? this.timeRangeEnd,
      useShortSound: useShortSound ?? this.useShortSound,
      includeQuranVerses: includeQuranVerses ?? this.includeQuranVerses,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      excludedCategories: excludedCategories ?? this.excludedCategories,
    );
  }
  
  // تحويل الإعدادات إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'minFrequency': minFrequency,
      'maxFrequency': maxFrequency,
      'timeRangeStart': timeRangeStart,
      'timeRangeEnd': timeRangeEnd,
      'useShortSound': useShortSound,
      'includeQuranVerses': includeQuranVerses,
      'maxPerDay': maxPerDay,
      'excludedCategories': excludedCategories,
    };
  }
  
  // إنشاء الإعدادات من JSON
  factory AutoNotificationSettings.fromJson(Map<String, dynamic> json) {
    return AutoNotificationSettings(
      isEnabled: json['isEnabled'] ?? false,
      minFrequency: json['minFrequency'] ?? 120,
      maxFrequency: json['maxFrequency'] ?? 240,
      timeRangeStart: json['timeRangeStart'] ?? '08:00',
      timeRangeEnd: json['timeRangeEnd'] ?? '22:00',
      useShortSound: json['useShortSound'] ?? true,
      includeQuranVerses: json['includeQuranVerses'] ?? true,
      maxPerDay: json['maxPerDay'] ?? 10,
      excludedCategories: json['excludedCategories'] != null
          ? List<String>.from(json['excludedCategories'])
          : [],
    );
  }
}

// فئة لعنصر ذكر تلقائي
class AutoThikrItem {
  final String categoryId;
  final int thikrIndex;
  final String text;
  final String? source;
  final String? fadl;
  final bool isQuranVerse;
  final String? surahName;
  
  const AutoThikrItem({
    required this.categoryId,
    required this.thikrIndex,
    required this.text,
    this.source,
    this.fadl,
    this.isQuranVerse = false,
    this.surahName,
  });
}
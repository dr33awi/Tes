// lib/screens/athkarscreen/services/ios_notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service to handle iOS specific notification features
class IOSNotificationService {
  // Singleton pattern implementation
  static final IOSNotificationService _instance = IOSNotificationService._internal();
  factory IOSNotificationService() => _instance;
  IOSNotificationService._internal();
  
  // Error logging service
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  // Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // iOS Notification Categories
  static const String categoryAthkar = 'athkar_category';
  static const String categoryMorning = 'morning_category';
  static const String categoryEvening = 'evening_category';
  static const String categorySleep = 'sleep_category';
  static const String categoryWake = 'wake_category';
  
  // Initialize iOS specific notification settings
  Future<void> initializeIOSNotifications() async {
    if (!Platform.isIOS) return;
    
    try {
      // Request permissions with critical alert option
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true, // Enable critical notifications (bypass Do Not Disturb)
          );
      
      print('iOS notification permission result: $result');
      
      // Set up notification categories for iOS
      await _setupNotificationCategories();
      
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'Error initializing iOS notifications', 
        e
      );
    }
  }
  
  // Setup notification categories for iOS
  Future<void> _setupNotificationCategories() async {
    if (!Platform.isIOS) return;
    
    try {
      // Define notification categories
      final List<DarwinNotificationCategory> darwinNotificationCategories = [
        // General Athkar category
        DarwinNotificationCategory(
          categoryAthkar,
          actions: [
            // Action to mark as read
            DarwinNotificationAction.plain(
              'MARK_READ',
              'تم القراءة',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            // Action to snooze
            DarwinNotificationAction.plain(
              'SNOOZE',
              'تأجيل',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          }
        ),
        
        // Category for morning athkar
        DarwinNotificationCategory(
          categoryMorning,
          actions: [
            DarwinNotificationAction.plain(
              'MARK_READ',
              'تم القراءة',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'REMIND_LATER',
              'ذكرني لاحقاً',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        
        // Category for evening athkar
        DarwinNotificationCategory(
          categoryEvening,
          actions: [
            DarwinNotificationAction.plain(
              'MARK_READ',
              'تم القراءة',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'REMIND_LATER',
              'ذكرني لاحقاً',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ];
      
      // Set the categories
      final darwinNotificationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
        notificationCategories: darwinNotificationCategories,
      );
      
      // Initialize iOS settings
      final initializationSettings = InitializationSettings(
        iOS: darwinNotificationSettings,
      );
      
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );
      
      print('iOS notification categories initialized');
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'Error setting up notification categories', 
        e
      );
    }
  }
  
  // Handle notification action response
  void _onNotificationResponse(NotificationResponse response) {
    if (!Platform.isIOS) return;
    
    try {
      final String? payload = response.payload;
      final String? actionId = response.actionId;
      
      print('Notification response: action=$actionId, payload=$payload');
      
      if (actionId == 'MARK_READ') {
        // Handle mark as read action
        // This could update a counter or mark the athkar as completed
        _handleMarkAsRead(payload);
      } else if (actionId == 'SNOOZE' || actionId == 'REMIND_LATER') {
        // Handle snooze/remind later action
        _handleSnoozeNotification(payload);
      }
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'Error handling notification response', 
        e
      );
    }
  }
  
  // Handle background notification response
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // This is a static method that will be called when the app is in the background
    // We can only do minimal processing here
    print('Background notification response: ${response.actionId}, ${response.payload}');
  }
  
  // Handle mark as read action
  Future<void> _handleMarkAsRead(String? payload) async {
    if (payload == null) return;
    
    try {
      // We could update a counter or mark the athkar as completed in SharedPreferences
      print('Marking as read: $payload');
      
      // For now, just send a confirmation notification
      await flutterLocalNotificationsPlugin.show(
        10000,
        'تم تسجيل قراءة الأذكار',
        'بارك الله فيك',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            categoryIdentifier: categoryAthkar,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'Error handling mark as read', 
        e
      );
    }
  }
  
  // Handle snooze notification action
  Future<void> _handleSnoozeNotification(String? payload) async {
    if (payload == null) return;
    
    try {
      // Schedule a reminder after 30 minutes
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: 30));
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        20000,
        'تذكير: أذكار',
        'حان وقت قراءة الأذكار',
        scheduledDate,
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            categoryIdentifier: categoryAthkar,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      
      // Show confirmation
      await flutterLocalNotificationsPlugin.show(
        10001,
        'تم تأجيل الإشعار',
        'سيتم تذكيرك بعد 30 دقيقة',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'Error handling snooze notification', 
        e
      );
    }
  }
  
  // Create enhanced iOS notification details for a category
  DarwinNotificationDetails createIOSNotificationDetails(AthkarCategory category) {
    // Get the appropriate category identifier
    String categoryIdentifier = categoryAthkar;
    
    switch (category.id) {
      case 'morning':
        categoryIdentifier = categoryMorning;
        break;
      case 'evening':
        categoryIdentifier = categoryEvening;
        break;
      case 'sleep':
        categoryIdentifier = categorySleep;
        break;
      case 'wake':
        categoryIdentifier = categoryWake;
        break;
    }
    
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.active, // Override Do Not Disturb
      categoryIdentifier: categoryIdentifier,
      threadIdentifier: 'athkar_${category.id}', // Group by category
      attachments: null, // Could add image attachments here
      subtitle: category.title, // Add subtitle
    );
  }
  
  // Schedule an enhanced iOS notification
  Future<bool> scheduleEnhancedNotification(
    AthkarCategory category, 
    TimeOfDay notificationTime, 
    int notificationId
  ) async {
    if (!Platform.isIOS) return false;
    
    try {
      // Get scheduled datetime
      final tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        tz.TZDateTime.now(tz.local).year,
        tz.TZDateTime.now(tz.local).month,
        tz.TZDateTime.now(tz.local).day,
        notificationTime.hour,
        notificationTime.minute,
      );
      
      // If time already passed today, schedule for tomorrow
      final tz.TZDateTime adjustedDate = scheduledDate.isBefore(tz.TZDateTime.now(tz.local))
          ? scheduledDate.add(Duration(days: 1))
          : scheduledDate;
      
      // Create iOS notification details
      final iosDetails = createIOSNotificationDetails(category);
      
      // Set notification content
      final String title = category.notifyTitle ?? 'حان موعد ${category.title}';
      final String body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
      
      // Schedule notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        adjustedDate,
        NotificationDetails(iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
        payload: category.id,
      );
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'Error scheduling enhanced iOS notification', 
        e
      );
      return false;
    }
  }
  
  // Send a test notification with iOS-specific features
  Future<void> sendTestNotification() async {
    if (!Platform.isIOS) return;
    
    try {
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: categoryAthkar,
        subtitle: 'اختبار الإشعارات', // iOS subtitle
      );
      
      await flutterLocalNotificationsPlugin.show(
        30000,
        'اختبار إشعارات iOS',
        'هذا اختبار لميزات إشعارات iOS المحسنة. يمكنك استخدام الإجراءات أدناه.',
        NotificationDetails(iOS: iosDetails),
        payload: 'test',
      );
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'Error sending iOS test notification', 
        e
      );
    }
  }
}
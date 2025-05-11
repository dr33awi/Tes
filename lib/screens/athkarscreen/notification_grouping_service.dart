// lib/screens/athkarscreen/services/notification_grouping_service.dart
import 'dart:io';
import 'dart:convert'; // إضافة استيراد json
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/error_logging_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle grouping of notifications
class NotificationGroupingService {
  // Singleton pattern implementation
  static final NotificationGroupingService _instance = NotificationGroupingService._internal();
  factory NotificationGroupingService() => _instance;
  NotificationGroupingService._internal();
  
  // Error logging service
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  // Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Group keys for different types of notifications
  static const String morningGroupKey = 'morning_athkar_group';
  static const String eveningGroupKey = 'evening_athkar_group';
  static const String sleepGroupKey = 'sleep_athkar_group';
  static const String wakeGroupKey = 'wake_athkar_group';
  static const String prayerGroupKey = 'prayer_athkar_group';
  static const String homeGroupKey = 'home_athkar_group';
  static const String foodGroupKey = 'food_athkar_group';
  static const String generalGroupKey = 'athkar_group';
  
  // Get the appropriate group key for a category
  String getGroupKeyForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return morningGroupKey;
      case 'evening':
        return eveningGroupKey;
      case 'sleep':
        return sleepGroupKey;
      case 'wake':
        return wakeGroupKey;
      case 'prayer':
        return prayerGroupKey;
      case 'home':
        return homeGroupKey;
      case 'food':
        return foodGroupKey;
      default:
        return generalGroupKey;
    }
  }
  
  // Schedule a grouped notification
  Future<bool> scheduleGroupedNotification({
    required AthkarCategory category,
    required TimeOfDay notificationTime,
    required int notificationId,
    required String title,
    required String body,
    bool isSummary = false,
    int groupIndex = 0,
  }) async {
    try {
      // Get the group key for this category
      final String groupKey = getGroupKeyForCategory(category.id);
      
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
      
      if (Platform.isAndroid) {
        // Create Android specific notification details with grouping
        final androidDetails = AndroidNotificationDetails(
          'athkar_${category.id}_channel',
          '${category.title}',
          channelDescription: 'إشعارات ${category.title}',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: isSummary,
          category: AndroidNotificationCategory.reminder,
          // Use colored lights based on category
          color: _getCategoryColor(category.id),
          ledColor: _getCategoryColor(category.id),
          ledOnMs: 1000,
          ledOffMs: 500,
          visibility: NotificationVisibility.public,
          // Don't use ticker for grouped notifications
          ticker: isSummary ? null : 'حان وقت ${category.title}',
          // Style for group summary
          styleInformation: isSummary 
              ? InboxStyleInformation(
                  ['إشعارات ${category.title}'],
                  contentTitle: 'عدة إشعارات من ${category.title}',
                  summaryText: 'اضغط للاطلاع على جميع الإشعارات',
                )
              : BigTextStyleInformation(body),
        );
        
        // Create notification details
        final notificationDetails = NotificationDetails(android: androidDetails);
        
        // Schedule notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          adjustedDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
          payload: isSummary ? category.id : '${category.id}:${groupIndex}',
        );
      } else if (Platform.isIOS) {
        // Create iOS specific notification details with thread identifier
        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.active,
          threadIdentifier: groupKey, // This groups notifications in iOS
          categoryIdentifier: 'athkar',
          subtitle: category.title, // Add subtitle for better identification
        );
        
        // Create notification details
        final notificationDetails = NotificationDetails(iOS: iosDetails);
        
        // Schedule notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          adjustedDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
          payload: isSummary ? category.id : '${category.id}:${groupIndex}',
        );
      } else {
        // For other platforms, use generic notification
        final notificationDetails = const NotificationDetails();
        
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          adjustedDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
          payload: isSummary ? category.id : '${category.id}:${groupIndex}',
        );
      }
      
      // Save that we've scheduled this notification
      await _trackGroupedNotification(
        category.id, 
        notificationId, 
        notificationTime,
        isSummary,
        groupIndex
      );
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'Error scheduling grouped notification', 
        e
      );
      return false;
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
      default:
        return const Color(0xFF447055); // Default app color
    }
  }
  
  // Schedule multiple notifications for a category with grouping
  Future<bool> scheduleMultipleNotifications(
    AthkarCategory category,
    List<String> timesStringList,
    TimeOfDay mainTime,
  ) async {
    try {
      // First parse all time strings to TimeOfDay objects
      List<TimeOfDay> times = [mainTime]; // Start with main time
      
      for (final timeString in timesStringList) {
        try {
          final parts = timeString.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            
            if (hour != null && minute != null) {
              times.add(TimeOfDay(hour: hour, minute: minute));
            }
          }
        } catch (e) {
          print('Error parsing time string $timeString: $e');
        }
      }
      
      // Sort times chronologically
      times.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
      
      // Now schedule all notifications
      final baseId = category.id.hashCode.abs() % 100000;
      
      // First create a summary notification
      await scheduleGroupedNotification(
        category: category,
        notificationTime: times.first, // Use first time for summary
        notificationId: baseId,
        title: 'إشعارات ${category.title}',
        body: 'لديك عدة تذكيرات لـ ${category.title}',
        isSummary: true,
      );
      
      // Then schedule individual notifications
      int successCount = 0;
      
      for (int i = 0; i < times.length; i++) {
        final title = i == 0 
            ? 'حان موعد ${category.title}' 
            : 'تذكير: ${category.title} ${i + 1}';
        
        final body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
        
        final success = await scheduleGroupedNotification(
          category: category,
          notificationTime: times[i],
          notificationId: baseId + (i + 1) * 100,
          title: title,
          body: body,
          isSummary: false,
          groupIndex: i + 1,
        );
        
        if (success) {
          successCount++;
        }
      }
      
      return successCount > 0;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'Error scheduling multiple notifications', 
        e
      );
      return false;
    }
  }
  
  // Schedule individual notification for a category
  Future<bool> scheduleSingleNotification(
    AthkarCategory category,
    TimeOfDay notificationTime,
  ) async {
    try {
      final title = category.notifyTitle ?? 'حان موعد ${category.title}';
      final body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
      final notificationId = category.id.hashCode.abs() % 100000;
      
      return await scheduleGroupedNotification(
        category: category,
        notificationTime: notificationTime,
        notificationId: notificationId,
        title: title,
        body: body,
        isSummary: false,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'Error scheduling single notification', 
        e
      );
      return false;
    }
  }
  
  // Track grouped notification
  Future<void> _trackGroupedNotification(
    String categoryId, 
    int notificationId, 
    TimeOfDay time,
    bool isSummary,
    int groupIndex,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save to the list of all notification IDs
      final allIdsKey = 'grouped_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      final notificationKey = '$categoryId:${isSummary ? "summary" : groupIndex}:$notificationId';
      
      if (!allIds.contains(notificationKey)) {
        allIds.add(notificationKey);
        await prefs.setStringList(allIdsKey, allIds);
      }
      
      // Save details of this notification
      await prefs.setString(
        'notification_details_$notificationId',
        '${categoryId}:${time.hour}:${time.minute}:${isSummary ? 1 : 0}:$groupIndex'
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'Error tracking grouped notification', 
        e
      );
    }
  }
  
  // Cancel all grouped notifications for a category
  Future<void> cancelGroupedNotifications(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIdsKey = 'grouped_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      // Find all notifications for this category
      final categoryIds = allIds.where((id) => id.startsWith('$categoryId:')).toList();
      
      // Cancel each notification
      for (final idString in categoryIds) {
        final parts = idString.split(':');
        if (parts.length >= 3) {
          final notificationId = int.tryParse(parts[2]);
          if (notificationId != null) {
            await flutterLocalNotificationsPlugin.cancel(notificationId);
          }
        }
      }
      
      // Remove from the list
      for (final id in categoryIds) {
        allIds.remove(id);
      }
      await prefs.setStringList(allIdsKey, allIds);
      
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'Error canceling grouped notifications', 
        e
      );
    }
  }
  
  // Get all grouped notification IDs for a category
  Future<List<int>> getGroupedNotificationIds(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIdsKey = 'grouped_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      // Find all notifications for this category
      final categoryIds = allIds.where((id) => id.startsWith('$categoryId:')).toList();
      
      // Extract notification IDs
      List<int> notificationIds = [];
      for (final idString in categoryIds) {
        final parts = idString.split(':');
        if (parts.length >= 3) {
          final notificationId = int.tryParse(parts[2]);
          if (notificationId != null) {
            notificationIds.add(notificationId);
          }
        }
      }
      
      return notificationIds;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'Error getting grouped notification IDs', 
        e
      );
      return [];
    }
  }
  
  // Show a grouped notification immediately (for testing)
  Future<void> showGroupedTestNotification(AthkarCategory category) async {
    try {
      // Get the group key for this category
      final String groupKey = getGroupKeyForCategory(category.id);
      
      if (Platform.isAndroid) {
        // First show a summary notification
        final summaryNotificationId = category.id.hashCode.abs() % 100000 + 50000;
        
        // Create a summary notification
        final androidSummaryDetails = AndroidNotificationDetails(
          'athkar_test_channel',
          'اختبار الأذكار',
          channelDescription: 'قناة اختبار إشعارات الأذكار',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
          category: AndroidNotificationCategory.reminder,
          color: _getCategoryColor(category.id),
          visibility: NotificationVisibility.public,
          styleInformation: InboxStyleInformation(
            ['اختبار مجموعة إشعارات ${category.title}'],
            contentTitle: 'عدة إشعارات من ${category.title}',
            summaryText: 'إشعارات الاختبار',
          ),
        );
        
        // Show the summary notification
        await flutterLocalNotificationsPlugin.show(
          summaryNotificationId,
          'مجموعة إشعارات ${category.title}',
          'اضغط للاطلاع على الإشعارات',
          NotificationDetails(android: androidSummaryDetails),
          payload: '${category.id}:test_summary',
        );
        
        // Show individual notifications in the group
        for (int i = 1; i <= 3; i++) {
          final androidDetails = AndroidNotificationDetails(
            'athkar_test_channel',
            'اختبار الأذكار',
            channelDescription: 'قناة اختبار إشعارات الأذكار',
            importance: Importance.high,
            priority: Priority.high,
            groupKey: groupKey,
            setAsGroupSummary: false,
            category: AndroidNotificationCategory.reminder,
            color: _getCategoryColor(category.id),
            visibility: NotificationVisibility.public,
          );
          
          await flutterLocalNotificationsPlugin.show(
            summaryNotificationId + i,
            'اختبار ${category.title} $i',
            'هذا اختبار للإشعارات المجمعة. اضغط هنا.',
            NotificationDetails(android: androidDetails),
            payload: '${category.id}:test_$i',
          );
          
          // Add a small delay to ensure notifications appear in correct order
          await Future.delayed(Duration(milliseconds: 200));
        }
      } else if (Platform.isIOS) {
        // For iOS, just use thread identifier to group notifications
        for (int i = 0; i <= 3; i++) {
          final iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            threadIdentifier: groupKey,
            subtitle: i == 0 ? 'مجموعة الإشعارات' : 'إشعار $i',
          );
          
          await flutterLocalNotificationsPlugin.show(
            category.id.hashCode.abs() % 100000 + 50000 + i,
            i == 0 ? 'مجموعة إشعارات ${category.title}' : 'اختبار ${category.title} $i',
            i == 0 ? 'اختبار مجموعة الإشعارات' : 'هذا اختبار للإشعار رقم $i',
            NotificationDetails(iOS: iosDetails),
            payload: '${category.id}:test_$i',
          );
          
          // Add a small delay to ensure notifications appear in correct order
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'Error showing grouped test notification', 
        e
      );
    }
  }
}
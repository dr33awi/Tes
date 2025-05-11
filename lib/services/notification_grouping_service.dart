// lib/services/notification_grouping_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة للتعامل مع تجميع الإشعارات
class NotificationGroupingService {
  // تنفيذ نمط Singleton مع التبعية المعكوسة
  static final NotificationGroupingService _instance = NotificationGroupingService._internal();
  
  factory NotificationGroupingService({
    ErrorLoggingService? errorLoggingService,
    FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin,
  }) {
    _instance._errorLoggingService = errorLoggingService ?? ErrorLoggingService();
    _instance._flutterLocalNotificationsPlugin = flutterLocalNotificationsPlugin ?? FlutterLocalNotificationsPlugin();
    return _instance;
  }
  
  NotificationGroupingService._internal();
  
  // التبعية المعكوسة
  late ErrorLoggingService _errorLoggingService;
  
  // كائن Flutter Local Notifications Plugin
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  
  // مفاتيح المجموعات لأنواع مختلفة من الإشعارات
  static const String morningGroupKey = 'morning_athkar_group';
  static const String eveningGroupKey = 'evening_athkar_group';
  static const String sleepGroupKey = 'sleep_athkar_group';
  static const String wakeGroupKey = 'wake_athkar_group';
  static const String prayerGroupKey = 'prayer_athkar_group';
  static const String homeGroupKey = 'home_athkar_group';
  static const String foodGroupKey = 'food_athkar_group';
  static const String generalGroupKey = 'athkar_group';
  
  /// الحصول على مفتاح المجموعة المناسب لفئة معينة
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
  
  /// جدولة إشعار مجمع
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
      // الحصول على مفتاح المجموعة لهذه الفئة
      final String groupKey = getGroupKeyForCategory(category.id);
      
      // الحصول على وقت الجدولة
      final tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        tz.TZDateTime.now(tz.local).year,
        tz.TZDateTime.now(tz.local).month,
        tz.TZDateTime.now(tz.local).day,
        notificationTime.hour,
        notificationTime.minute,
      );
      
      // إذا كان الوقت قد مر اليوم، قم بالجدولة لغدًا
      final tz.TZDateTime adjustedDate = scheduledDate.isBefore(tz.TZDateTime.now(tz.local))
          ? scheduledDate.add(Duration(days: 1))
          : scheduledDate;
      
      if (Platform.isAndroid) {
        // إنشاء تفاصيل إشعار أندرويد محددة مع التجميع
        final androidDetails = AndroidNotificationDetails(
          'athkar_${category.id}_channel',
          '${category.title}',
          channelDescription: 'إشعارات ${category.title}',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: isSummary,
          category: AndroidNotificationCategory.reminder,
          // استخدام أضواء ملونة بناءً على الفئة
          color: _getCategoryColor(category.id),
          ledColor: _getCategoryColor(category.id),
          ledOnMs: 1000,
          ledOffMs: 500,
          visibility: NotificationVisibility.public,
          // عدم استخدام ticker للإشعارات المجمعة
          ticker: isSummary ? null : 'حان وقت ${category.title}',
          // نمط لملخص المجموعة
          styleInformation: isSummary 
              ? InboxStyleInformation(
                  ['إشعارات ${category.title}'],
                  contentTitle: 'عدة إشعارات من ${category.title}',
                  summaryText: 'اضغط للاطلاع على جميع الإشعارات',
                )
              : BigTextStyleInformation(body),
        );
        
        // إنشاء تفاصيل الإشعار
        final notificationDetails = NotificationDetails(android: androidDetails);
        
        // جدولة الإشعار
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          adjustedDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // تكرار يومي
          payload: isSummary ? category.id : '${category.id}:${groupIndex}',
        );
      } else if (Platform.isIOS) {
        // إنشاء تفاصيل إشعار iOS محددة مع معرف المؤشر
        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.active,
          threadIdentifier: groupKey, // هذا يجمع الإشعارات في iOS
          categoryIdentifier: 'athkar',
          subtitle: category.title, // إضافة عنوان فرعي لتعريف أفضل
        );
        
        // إنشاء تفاصيل الإشعار
        final notificationDetails = NotificationDetails(iOS: iosDetails);
        
        // جدولة الإشعار
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          adjustedDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // تكرار يومي
          payload: isSummary ? category.id : '${category.id}:${groupIndex}',
        );
      } else {
        // للمنصات الأخرى، استخدم إشعارًا عامًا
        final notificationDetails = const NotificationDetails();
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          adjustedDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // تكرار يومي
          payload: isSummary ? category.id : '${category.id}:${groupIndex}',
        );
      }
      
      // حفظ أننا قمنا بجدولة هذا الإشعار
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
        'خطأ في جدولة إشعار مجمع', 
        e
      );
      return false;
    }
  }
  
  /// الحصول على لون الفئة بناءً على المعرف
  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // أصفر
      case 'evening':
        return const Color(0xFFAB47BC); // بنفسجي
      case 'sleep':
        return const Color(0xFF5C6BC0); // أزرق
      case 'wake':
        return const Color(0xFFFFB74D); // برتقالي
      case 'prayer':
        return const Color(0xFF4DB6AC); // أزرق فاتح
      case 'home':
        return const Color(0xFF66BB6A); // أخضر
      case 'food':
        return const Color(0xFFE57373); // أحمر
      default:
        return const Color(0xFF447055); // اللون الافتراضي للتطبيق
    }
  }
  
  /// جدولة عدة إشعارات لفئة مع التجميع
  Future<bool> scheduleMultipleNotifications(
    AthkarCategory category,
    List<String> timesStringList,
    TimeOfDay mainTime,
  ) async {
    try {
      // أولاً قم بتحليل جميع سلاسل الوقت إلى كائنات TimeOfDay
      List<TimeOfDay> times = [mainTime]; // البدء بالوقت الرئيسي
      
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
          print('خطأ في تحليل سلسلة الوقت $timeString: $e');
          await _errorLoggingService.logError(
            'NotificationGroupingService', 
            'خطأ في تحليل سلسلة الوقت $timeString', 
            e
          );
        }
      }
      
      // ترتيب الأوقات زمنيًا
      times.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
      
      // الآن قم بجدولة جميع الإشعارات
      final baseId = category.id.hashCode.abs() % 100000;
      
      // أولاً إنشاء إشعار ملخص
      await scheduleGroupedNotification(
        category: category,
        notificationTime: times.first, // استخدام الوقت الأول للملخص
        notificationId: baseId,
        title: 'إشعارات ${category.title}',
        body: 'لديك عدة تذكيرات لـ ${category.title}',
        isSummary: true,
      );
      
      // ثم جدولة الإشعارات الفردية
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
        'خطأ في جدولة إشعارات متعددة', 
        e
      );
      return false;
    }
  }
  
  /// جدولة إشعار فردي لفئة
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
        'خطأ في جدولة إشعار فردي', 
        e
      );
      return false;
    }
  }
  
  /// تتبع الإشعار المجمع
  Future<void> _trackGroupedNotification(
    String categoryId, 
    int notificationId, 
    TimeOfDay time,
    bool isSummary,
    int groupIndex,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحفظ في قائمة جميع معرفات الإشعارات
      final allIdsKey = 'grouped_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      final notificationKey = '$categoryId:${isSummary ? "summary" : groupIndex}:$notificationId';
      
      if (!allIds.contains(notificationKey)) {
        allIds.add(notificationKey);
        await prefs.setStringList(allIdsKey, allIds);
      }
      
      // حفظ تفاصيل هذا الإشعار
      await prefs.setString(
        'notification_details_$notificationId',
        '${categoryId}:${time.hour}:${time.minute}:${isSummary ? 1 : 0}:$groupIndex'
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'خطأ في تتبع الإشعار المجمع', 
        e
      );
    }
  }
  
  /// إلغاء جميع الإشعارات المجمعة لفئة
  Future<void> cancelGroupedNotifications(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIdsKey = 'grouped_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      // البحث عن جميع الإشعارات لهذه الفئة
      final categoryIds = allIds.where((id) => id.startsWith('$categoryId:')).toList();
      
      // إلغاء كل إشعار
      for (final idString in categoryIds) {
        final parts = idString.split(':');
        if (parts.length >= 3) {
          final notificationId = int.tryParse(parts[2]);
          if (notificationId != null) {
            await _flutterLocalNotificationsPlugin.cancel(notificationId);
          }
        }
      }
      
      // الإزالة من القائمة
      for (final id in categoryIds) {
        allIds.remove(id);
      }
      await prefs.setStringList(allIdsKey, allIds);
      
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'خطأ في إلغاء الإشعارات المجمعة', 
        e
      );
    }
  }
  
  /// الحصول على جميع معرفات الإشعارات المجمعة لفئة
  Future<List<int>> getGroupedNotificationIds(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIdsKey = 'grouped_notification_ids';
      final allIds = prefs.getStringList(allIdsKey) ?? <String>[];
      
      // البحث عن جميع الإشعارات لهذه الفئة
      final categoryIds = allIds.where((id) => id.startsWith('$categoryId:')).toList();
      
      // استخراج معرفات الإشعارات
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
        'خطأ في الحصول على معرفات الإشعارات المجمعة', 
        e
      );
      return [];
    }
  }
  
  /// عرض إشعار مجمع فورًا (للاختبار)
  Future<void> showGroupedTestNotification(AthkarCategory category) async {
    try {
      // الحصول على مفتاح المجموعة لهذه الفئة
      final String groupKey = getGroupKeyForCategory(category.id);
      
      if (Platform.isAndroid) {
        // أولاً عرض إشعار ملخص
        final summaryNotificationId = category.id.hashCode.abs() % 100000 + 50000;
        
        // إنشاء إشعار ملخص
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
        
        // عرض إشعار الملخص
        await _flutterLocalNotificationsPlugin.show(
          summaryNotificationId,
          'مجموعة إشعارات ${category.title}',
          'اضغط للاطلاع على الإشعارات',
          NotificationDetails(android: androidSummaryDetails),
          payload: '${category.id}:test_summary',
        );
        
        // عرض إشعارات فردية في المجموعة
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
          
          await _flutterLocalNotificationsPlugin.show(
            summaryNotificationId + i,
            'اختبار ${category.title} $i',
            'هذا اختبار للإشعارات المجمعة. اضغط هنا.',
            NotificationDetails(android: androidDetails),
            payload: '${category.id}:test_$i',
          );
          
          // إضافة تأخير صغير لضمان ظهور الإشعارات بالترتيب الصحيح
          await Future.delayed(Duration(milliseconds: 200));
        }
      } else if (Platform.isIOS) {
        // لنظام iOS، فقط استخدم معرف المؤشر لتجميع الإشعارات
        for (int i = 0; i <= 3; i++) {
          final iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            threadIdentifier: groupKey,
            subtitle: i == 0 ? 'مجموعة الإشعارات' : 'إشعار $i',
          );
          
          await _flutterLocalNotificationsPlugin.show(
            category.id.hashCode.abs() % 100000 + 50000 + i,
            i == 0 ? 'مجموعة إشعارات ${category.title}' : 'اختبار ${category.title} $i',
            i == 0 ? 'اختبار مجموعة الإشعارات' : 'هذا اختبار للإشعار رقم $i',
            NotificationDetails(iOS: iosDetails),
            payload: '${category.id}:test_$i',
          );
          
          // إضافة تأخير صغير لضمان ظهور الإشعارات بالترتيب الصحيح
          await Future.delayed(Duration(milliseconds: 200));
        }
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationGroupingService', 
        'خطأ في عرض إشعار اختبار مجمع', 
        e
      );
    }
  }
}
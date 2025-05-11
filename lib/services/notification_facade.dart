// lib/services/notification_facade.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:test_athkar_app/services/notification_manager.dart';
import 'package:test_athkar_app/services/retry_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/permissions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// واجهة موحدة لجميع وظائف الإشعارات
/// توفر نقطة وصول واحدة لجميع ميزات الإشعارات
class NotificationFacade {
  static NotificationFacade? _instance;
  
  // الخدمات المطلوبة
  late final NotificationManager _notificationManager;
  late final RetryService _retryService;
  late final ErrorLoggingService _errorLoggingService;
  late final DoNotDisturbService _doNotDisturbService;
  late final BatteryOptimizationService _batteryOptimizationService;
  late final PermissionsService _permissionsService;
  
  // مفاتيح التخزين
  static const String _keyQuickSettings = 'notification_quick_settings';
  static const String _keyScheduledCategories = 'scheduled_categories';
  
  // إنشاء المثيل الوحيد
  static NotificationFacade get instance {
    _instance ??= NotificationFacade._internal();
    return _instance!;
  }
  
  NotificationFacade._internal() {
    // تهيئة الخدمات
    _notificationManager = serviceLocator<NotificationManager>();
    _retryService = serviceLocator<RetryService>();
    _errorLoggingService = serviceLocator<ErrorLoggingService>();
    _doNotDisturbService = serviceLocator<DoNotDisturbService>();
    _batteryOptimizationService = serviceLocator<BatteryOptimizationService>();
    _permissionsService = serviceLocator<PermissionsService>();
  }
  
  // ==================== التهيئة الأساسية ====================
  
  /// تهيئة نظام الإشعارات بالكامل
  Future<bool> initialize() async {
    try {
      print('بدء تهيئة نظام الإشعارات الموحد...');
      
      // تهيئة الخدمات الأساسية
      await _errorLoggingService.initialize();
      await _batteryOptimizationService.initialize();
      
      // تهيئة مدير الإشعارات
      final success = await _notificationManager.initialize();
      
      if (success) {
        print('تمت تهيئة نظام الإشعارات بنجاح');
        
        // استعادة الإشعارات المحفوظة
        await rescheduleAllSavedNotifications();
      }
      
      return success;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في تهيئة نظام الإشعارات',
        e
      );
      return false;
    }
  }
  
  // ==================== إدارة الأذونات ====================
  
  /// التحقق من جميع الأذونات المطلوبة
  Future<NotificationPermissionsStatus> checkAllPermissions(BuildContext context) async {
    try {
      final notificationPermission = await _permissionsService.checkNotificationPermission();
      final canBypassDnd = await _doNotDisturbService.canBypassDoNotDisturb();
      final batteryOptimizationEnabled = await _batteryOptimizationService.isBatteryOptimizationEnabled();
      
      return NotificationPermissionsStatus(
        hasNotificationPermission: notificationPermission,
        canBypassDoNotDisturb: canBypassDnd,
        isBatteryOptimized: !batteryOptimizationEnabled,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في التحقق من الأذونات',
        e
      );
      return NotificationPermissionsStatus();
    }
  }
  
  /// طلب جميع الأذونات المطلوبة
  Future<bool> requestAllPermissions(BuildContext context) async {
    try {
      // طلب أذونات الإشعارات
      final notificationGranted = await _permissionsService.showNotificationPermissionDialog(context);
      
      if (!notificationGranted) return false;
      
      // التحقق من تحسينات البطارية
      await _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
      
      // التحقق من وضع عدم الإزعاج
      final shouldPromptDnd = await _doNotDisturbService.shouldPromptAboutDoNotDisturb();
      if (shouldPromptDnd) {
        await _doNotDisturbService.showDoNotDisturbDialog(context);
      }
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في طلب الأذونات',
        e
      );
      return false;
    }
  }
  
  // ==================== الجدولة الأساسية ====================
  
  /// جدولة إشعار بسيط
  Future<NotificationResult> scheduleNotification({
    required String notificationId,
    required String title,
    required String body,
    required TimeOfDay notificationTime,
    String? channelId,
    String? payload,
    Color? color,
    bool repeat = true,
    int? priority,
  }) async {
    try {
      final result = await _retryService.executeWithRetry<bool>(
        operation: () => _notificationManager.scheduleNotification(
          notificationId: notificationId,
          title: title,
          body: body,
          notificationTime: notificationTime,
          channelId: channelId,
          payload: payload,
          color: color,
          repeat: repeat,
          priority: priority,
        ),
        operationName: 'schedule_notification_$notificationId',
        config: RetryConfig.quickDefault,
      );
      
      return NotificationResult(
        success: result.success && (result.value ?? false),
        notificationId: notificationId,
        error: result.error,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في جدولة إشعار',
        e
      );
      return NotificationResult(
        success: false,
        notificationId: notificationId,
        error: e,
      );
    }
  }
  
  /// جدولة إشعارات متعددة
  Future<List<NotificationResult>> scheduleMultipleNotifications({
    required String baseId,
    required String title,
    required String body,
    required List<TimeOfDay> notificationTimes,
    String? channelId,
    String? payload,
    Color? color,
    bool repeat = true,
  }) async {
    try {
      final results = <NotificationResult>[];
      
      for (int i = 0; i < notificationTimes.length; i++) {
        final notificationId = '${baseId}_$i';
        final result = await scheduleNotification(
          notificationId: notificationId,
          title: title,
          body: body,
          notificationTime: notificationTimes[i],
          channelId: channelId,
          payload: payload,
          color: color,
          repeat: repeat,
        );
        results.add(result);
      }
      
      return results;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في جدولة إشعارات متعددة',
        e
      );
      return [];
    }
  }
  
  // ==================== جدولة الأذكار ====================
  
  /// جدولة إشعارات لفئة أذكار
  Future<AthkarNotificationResult> scheduleAthkarNotifications({
    required String categoryId,
    required String categoryTitle,
    required List<TimeOfDay> times,
    String? customTitle,
    String? customBody,
    Color? color,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // إلغاء الإشعارات السابقة لهذه الفئة
      await cancelAthkarNotifications(categoryId);
      
      // جدولة الإشعارات الجديدة
      final results = await scheduleMultipleNotifications(
        baseId: 'athkar_$categoryId',
        title: customTitle ?? 'حان وقت $categoryTitle',
        body: customBody ?? 'اضغط هنا لقراءة $categoryTitle',
        notificationTimes: times,
        channelId: 'athkar_channel',
        payload: categoryId,
        color: color ?? _getCategoryColor(categoryId),
        repeat: true,
      );
      
      // حفظ حالة الجدولة
      final scheduledCategories = prefs.getStringList(_keyScheduledCategories) ?? [];
      if (!scheduledCategories.contains(categoryId)) {
        scheduledCategories.add(categoryId);
        await prefs.setStringList(_keyScheduledCategories, scheduledCategories);
      }
      
      // حفظ أوقات الإشعارات
      final timesString = times.map((time) => 
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      ).toList();
      await prefs.setStringList('${categoryId}_notification_times', timesString);
      await prefs.setBool('${categoryId}_notifications_enabled', true);
      
      final successCount = results.where((r) => r.success).length;
      
      return AthkarNotificationResult(
        categoryId: categoryId,
        totalScheduled: successCount,
        totalFailed: results.length - successCount,
        notificationIds: results.map((r) => r.notificationId).toList(),
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في جدولة إشعارات الأذكار',
        e
      );
      return AthkarNotificationResult(
        categoryId: categoryId,
        totalScheduled: 0,
        totalFailed: 0,
        notificationIds: [],
        error: e,
      );
    }
  }
  
  /// إلغاء إشعارات فئة أذكار
  Future<bool> cancelAthkarNotifications(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على أوقات الإشعارات المحفوظة
      final timesString = prefs.getStringList('${categoryId}_notification_times') ?? [];
      
      // إلغاء كل إشعار
      for (int i = 0; i < timesString.length; i++) {
        await _notificationManager.cancelNotification('athkar_${categoryId}_$i');
      }
      
      // إزالة من القائمة المجدولة
      final scheduledCategories = prefs.getStringList(_keyScheduledCategories) ?? [];
      scheduledCategories.remove(categoryId);
      await prefs.setStringList(_keyScheduledCategories, scheduledCategories);
      
      // تحديث الحالة
      await prefs.setBool('${categoryId}_notifications_enabled', false);
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في إلغاء إشعارات الأذكار',
        e
      );
      return false;
    }
  }
  
  /// الحصول على حالة إشعارات فئة أذكار
  Future<AthkarNotificationStatus> getAthkarNotificationStatus(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isEnabled = prefs.getBool('${categoryId}_notifications_enabled') ?? false;
      final timesString = prefs.getStringList('${categoryId}_notification_times') ?? [];
      
      final times = timesString.map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
      
      return AthkarNotificationStatus(
        categoryId: categoryId,
        isEnabled: isEnabled,
        scheduledTimes: times,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في الحصول على حالة إشعارات الأذكار',
        e
      );
      return AthkarNotificationStatus(
        categoryId: categoryId,
        isEnabled: false,
        scheduledTimes: [],
      );
    }
  }
  
  // ==================== الإشعارات الفورية ====================
  
  /// إرسال إشعار فوري
  Future<bool> sendInstantNotification({
    required String title,
    required String body,
    String? payload,
    Color? color,
  }) async {
    try {
      await _notificationManager.showSimpleNotification(
        title,
        body,
        payload: payload,
      );
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في إرسال إشعار فوري',
        e
      );
      return false;
    }
  }
  
  /// إرسال إشعار اختباري
  Future<bool> sendTestNotification() async {
    try {
      return await _notificationManager.sendTestNotification();
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في إرسال إشعار اختباري',
        e
      );
      return false;
    }
  }
  
  // ==================== إدارة الإشعارات ====================
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications() async {
    try {
      final success = await _notificationManager.cancelAllNotifications();
      
      // مسح البيانات المحفوظة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyScheduledCategories, []);
      
      return success;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في إلغاء جميع الإشعارات',
        e
      );
      return false;
    }
  }
  
  /// إعادة جدولة جميع الإشعارات المحفوظة
  Future<void> rescheduleAllSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledCategories = prefs.getStringList(_keyScheduledCategories) ?? [];
      
      for (final categoryId in scheduledCategories) {
        final status = await getAthkarNotificationStatus(categoryId);
        
        if (status.isEnabled && status.scheduledTimes.isNotEmpty) {
          // إعادة جدولة
          await scheduleAthkarNotifications(
            categoryId: categoryId,
            categoryTitle: _getCategoryTitle(categoryId),
            times: status.scheduledTimes,
            color: _getCategoryColor(categoryId),
          );
        }
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في إعادة جدولة الإشعارات المحفوظة',
        e
      );
    }
  }
  
  /// الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationManager.getPendingNotifications();
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في الحصول على الإشعارات المعلقة',
        e
      );
      return [];
    }
  }
  
  // ==================== الإعدادات السريعة ====================
  
  /// تفعيل/تعطيل جميع الإشعارات
  Future<bool> setAllNotificationsEnabled(bool enabled) async {
    try {
      return await _notificationManager.setNotificationsEnabled(enabled);
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في تغيير حالة الإشعارات',
        e
      );
      return false;
    }
  }
  
  /// جدولة إشعارات افتراضية للأذكار
  Future<void> scheduleDefaultAthkarNotifications() async {
    try {
      // أذكار الصباح
      await scheduleAthkarNotifications(
        categoryId: 'morning',
        categoryTitle: 'أذكار الصباح',
        times: [TimeOfDay(hour: 6, minute: 0)],
      );
      
      // أذكار المساء
      await scheduleAthkarNotifications(
        categoryId: 'evening',
        categoryTitle: 'أذكار المساء',
        times: [TimeOfDay(hour: 18, minute: 0)],
      );
      
      // أذكار النوم
      await scheduleAthkarNotifications(
        categoryId: 'sleep',
        categoryTitle: 'أذكار النوم',
        times: [TimeOfDay(hour: 22, minute: 0)],
      );
      
      // أذكار الاستيقاظ
      await scheduleAthkarNotifications(
        categoryId: 'wake',
        categoryTitle: 'أذكار الاستيقاظ',
        times: [TimeOfDay(hour: 5, minute: 30)],
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في جدولة الإشعارات الافتراضية',
        e
      );
    }
  }
  
  // ==================== وظائف التحليل ====================
  
  /// الحصول على إحصائيات الإشعارات
  Future<NotificationStatistics> getNotificationStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledCategories = prefs.getStringList(_keyScheduledCategories) ?? [];
      
      int totalScheduled = 0;
      int totalActive = 0;
      Map<String, int> categoryCount = {};
      
      for (final categoryId in scheduledCategories) {
        final status = await getAthkarNotificationStatus(categoryId);
        final count = status.scheduledTimes.length;
        
        totalScheduled += count;
        if (status.isEnabled) {
          totalActive += count;
        }
        
        categoryCount[categoryId] = count;
      }
      
      final pendingNotifications = await getPendingNotifications();
      
      return NotificationStatistics(
        totalScheduled: totalScheduled,
        totalActive: totalActive,
        totalPending: pendingNotifications.length,
        categoriesCount: categoryCount,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationFacade',
        'خطأ في الحصول على إحصائيات الإشعارات',
        e
      );
      return NotificationStatistics();
    }
  }
  
  // ==================== دوال مساعدة ====================
  
  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F);
      case 'evening':
        return const Color(0xFFAB47BC);
      case 'sleep':
        return const Color(0xFF5C6BC0);
      case 'wake':
        return const Color(0xFFFFB74D);
      case 'prayer':
        return const Color(0xFF4DB6AC);
      default:
        return const Color(0xFF447055);
    }
  }
  
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
      default:
        return 'أذكار';
    }
  }
}

// ==================== نماذج البيانات ====================

/// نتيجة عملية إشعار
class NotificationResult {
  final bool success;
  final String notificationId;
  final dynamic error;
  
  NotificationResult({
    required this.success,
    required this.notificationId,
    this.error,
  });
}

/// نتيجة جدولة إشعارات الأذكار
class AthkarNotificationResult {
  final String categoryId;
  final int totalScheduled;
  final int totalFailed;
  final List<String> notificationIds;
  final dynamic error;
  
  AthkarNotificationResult({
    required this.categoryId,
    required this.totalScheduled,
    required this.totalFailed,
    required this.notificationIds,
    this.error,
  });
  
  bool get success => totalFailed == 0 && error == null;
}

/// حالة إشعارات فئة أذكار
class AthkarNotificationStatus {
  final String categoryId;
  final bool isEnabled;
  final List<TimeOfDay> scheduledTimes;
  
  AthkarNotificationStatus({
    required this.categoryId,
    required this.isEnabled,
    required this.scheduledTimes,
  });
}

/// حالة الأذونات
class NotificationPermissionsStatus {
  final bool hasNotificationPermission;
  final bool canBypassDoNotDisturb;
  final bool isBatteryOptimized;
  
  NotificationPermissionsStatus({
    this.hasNotificationPermission = false,
    this.canBypassDoNotDisturb = false,
    this.isBatteryOptimized = false,
  });
  
  bool get allPermissionsGranted => 
    hasNotificationPermission && canBypassDoNotDisturb && isBatteryOptimized;
}

/// إحصائيات الإشعارات
class NotificationStatistics {
  final int totalScheduled;
  final int totalActive;
  final int totalPending;
  final Map<String, int> categoriesCount;
  
  NotificationStatistics({
    this.totalScheduled = 0,
    this.totalActive = 0,
    this.totalPending = 0,
    this.categoriesCount = const {},
  });
}

// ==================== امتداد سهل الاستخدام ====================

extension NotificationFacadeExtension on BuildContext {
  NotificationFacade get notifications => NotificationFacade.instance;
}
// lib/services/notification_manager.dart
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/notification/notification_service_interface.dart';
import 'package:test_athkar_app/services/notification/notification_service.dart';
import 'package:test_athkar_app/services/notification/notification_helpers.dart';
import 'package:test_athkar_app/services/retry_service.dart';


/// مدير مركزي لجميع وظائف الإشعارات في التطبيق
class NotificationManager {
  // الخدمة المحددة للمنصة
  late NotificationServiceInterface _notificationService;
  
  // التبعيات
  final ErrorLoggingService _errorLoggingService;
  final RetryService _retryService;
  
  // ثوابت للتخزين المحلي
  static const String _keyNotificationSettings = 'notification_settings';
  static const String _keyScheduledCategories = 'scheduled_categories';
  
  // إعدادات المستخدم
  NotificationSettings _settings = NotificationSettings();
  
  NotificationManager({
    required ErrorLoggingService errorLoggingService,
    RetryService? retryService,
  }) : _errorLoggingService = errorLoggingService,
       _retryService = retryService ?? RetryService(errorLoggingService: errorLoggingService) {
    _initPlatformService();
  }
  
  /// تهيئة الخدمة المناسبة للمنصة
  void _initPlatformService() {
    _notificationService = NotificationService(
      errorLoggingService: _errorLoggingService,
    );
  }
  
  /// تهيئة مدير الإشعارات
  Future<bool> initialize() async {
    try {
      await _loadSettings();
      final result = await _notificationService.initialize();
      
      if (result) {
        await _notificationService.configureFromPreferences();
      }
      
      return result;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في تهيئة مدير الإشعارات', 
        e
      );
      return false;
    }
  }
  
  // ==================== وظائف الأذكار من NotificationFacade ====================
  
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
        color: color ?? NotificationHelpers.getCategoryColor(categoryId),
        repeat: true,
      );
      
      // حفظ حالة الجدولة
      final scheduledCategories = prefs.getStringList(_keyScheduledCategories) ?? [];
      if (!scheduledCategories.contains(categoryId)) {
        scheduledCategories.add(categoryId);
        await prefs.setStringList(_keyScheduledCategories, scheduledCategories);
      }
      
      return AthkarNotificationResult(
        categoryId: categoryId,
        totalScheduled: results,
        totalFailed: 0,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager',
        'خطأ في جدولة إشعارات الأذكار',
        e
      );
      return AthkarNotificationResult(
        categoryId: categoryId,
        totalScheduled: 0,
        totalFailed: 1,
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
        await _notificationService.cancelNotification('athkar_${categoryId}_$i');
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
        'NotificationManager',
        'خطأ في إلغاء إشعارات الأذكار',
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
        'NotificationManager',
        'خطأ في جدولة الإشعارات الافتراضية',
        e
      );
    }
  }
  
  /// الحصول على إحصائيات الإشعارات
  Future<NotificationStatistics> getNotificationStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledCategories = prefs.getStringList(_keyScheduledCategories) ?? [];
      
      int totalScheduled = 0;
      int totalActive = 0;
      Map<String, int> categoryCount = {};
      
      for (final categoryId in scheduledCategories) {
        final timesString = prefs.getStringList('${categoryId}_notification_times') ?? [];
        final isEnabled = prefs.getBool('${categoryId}_notifications_enabled') ?? false;
        
        totalScheduled += timesString.length;
        if (isEnabled) {
          totalActive += timesString.length;
        }
        
        categoryCount[categoryId] = timesString.length;
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
        'NotificationManager',
        'خطأ في الحصول على إحصائيات الإشعارات',
        e
      );
      return NotificationStatistics();
    }
  }
  
  // ==================== الوظائف الأساسية ====================
  
  /// تحميل إعدادات المستخدم من التخزين المحلي
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsStr = prefs.getString(_keyNotificationSettings);
      
      if (settingsStr != null) {
        _settings = NotificationSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(settingsStr))
        );
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في تحميل إعدادات الإشعارات', 
        e
      );
    }
  }
  
  /// حفظ إعدادات المستخدم في التخزين المحلي
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationSettings, jsonEncode(_settings.toJson()));
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في حفظ إعدادات الإشعارات', 
        e
      );
    }
  }
  
  /// الحصول على إعدادات المستخدم الحالية
  NotificationSettings get settings => _settings;
  
  /// تحديث إعدادات المستخدم
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    await _notificationService.configureFromPreferences();
  }
  
  /// تفعيل أو تعطيل جميع الإشعارات
  Future<bool> setNotificationsEnabled(bool enabled) async {
    try {
      final result = await _notificationService.setNotificationsEnabled(enabled);
      if (result) {
        _settings = _settings.copyWith(enabled: enabled);
        await _saveSettings();
      }
      return result;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في تغيير حالة الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// التحقق من جميع المتطلبات والأذونات الضرورية
  Future<bool> checkNotificationPrerequisites(BuildContext context) async {
    return await _notificationService.checkNotificationPrerequisites(context);
  }
  
  /// جدولة إشعار عام
  Future<bool> scheduleNotification({
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
      if (!_settings.enabled) return false;
      
      final result = await _retryService.executeWithRetry<bool>(
        operation: () => _notificationService.scheduleNotification(
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
      
      return result.success && (result.value ?? false);
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في جدولة إشعار', 
        e
      );
      return false;
    }
  }
  
  /// جدولة إشعارات متعددة
  Future<int> scheduleMultipleNotifications({
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
      if (!_settings.enabled) return 0;
      
      int successCount = 0;
      
      for (int i = 0; i < notificationTimes.length; i++) {
        final success = await scheduleNotification(
          notificationId: '${baseId}_$i',
          title: title,
          body: body,
          notificationTime: notificationTimes[i],
          channelId: channelId,
          payload: payload,
          color: color,
          repeat: repeat,
        );
        
        if (success) successCount++;
      }
      
      return successCount;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في جدولة إشعارات متعددة', 
        e
      );
      return 0;
    }
  }
  
  /// إلغاء إشعار
  Future<bool> cancelNotification(String notificationId) async {
    return await _notificationService.cancelNotification(notificationId);
  }
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications() async {
    try {
      final success = await _notificationService.cancelAllNotifications();
      
      // مسح البيانات المحفوظة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyScheduledCategories, []);
      
      return success;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في إلغاء جميع الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// إعادة جدولة جميع الإشعارات المحفوظة
  Future<void> rescheduleAllNotifications() async {
    await _notificationService.scheduleAllSavedNotifications();
  }
  
  /// إرسال إشعار اختباري
  Future<bool> sendTestNotification() async {
    return await _notificationService.testImmediateNotification();
  }
  
  /// التحقق من الإعدادات وتحسينات النظام
  Future<void> checkNotificationOptimizations(BuildContext context) async {
    await _notificationService.checkNotificationOptimizations(context);
  }
  
  /// إظهار إشعار بسيط فوري
  Future<void> showSimpleNotification(String title, String body, {String? payload}) async {
    await _notificationService.showSimpleNotification(
      title,
      body,
      DateTime.now().millisecondsSinceEpoch,
      payload: payload,
    );
  }
  
  /// الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationService.getPendingNotifications();
  }
  
  /// التحقق من حالة إشعار معين
  Future<bool> isNotificationEnabled(String notificationId) async {
    return await _notificationService.isNotificationEnabled(notificationId);
  }
  
  /// الحصول على وقت إشعار محفوظ
  Future<TimeOfDay?> getNotificationTime(String notificationId) async {
    return await _notificationService.getNotificationTime(notificationId);
  }
}

/// إعدادات المستخدم للإشعارات
class NotificationSettings {
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool lightsEnabled;
  final bool shouldBypassDnd;
  final bool groupSimilarNotifications;
  
  NotificationSettings({
    this.enabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.lightsEnabled = true,
    this.shouldBypassDnd = false,
    this.groupSimilarNotifications = true,
  });
  
  /// إنشاء من JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      lightsEnabled: json['lightsEnabled'] ?? true,
      shouldBypassDnd: json['shouldBypassDnd'] ?? false,
      groupSimilarNotifications: json['groupSimilarNotifications'] ?? true,
    );
  }
  
  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'lightsEnabled': lightsEnabled,
      'shouldBypassDnd': shouldBypassDnd,
      'groupSimilarNotifications': groupSimilarNotifications,
    };
  }
  
  /// إنشاء نسخة مع تعديلات
  NotificationSettings copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? lightsEnabled,
    bool? shouldBypassDnd,
    bool? groupSimilarNotifications,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      lightsEnabled: lightsEnabled ?? this.lightsEnabled,
      shouldBypassDnd: shouldBypassDnd ?? this.shouldBypassDnd,
      groupSimilarNotifications: groupSimilarNotifications ?? this.groupSimilarNotifications,
    );
  }
}

// ==================== نماذج البيانات من NotificationFacade ====================

/// نتيجة جدولة إشعارات الأذكار
class AthkarNotificationResult {
  final String categoryId;
  final int totalScheduled;
  final int totalFailed;
  final dynamic error;
  
  AthkarNotificationResult({
    required this.categoryId,
    required this.totalScheduled,
    required this.totalFailed,
    this.error,
  });
  
  bool get success => totalFailed == 0 && error == null;
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
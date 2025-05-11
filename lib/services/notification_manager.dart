// lib/services/notification_manager.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/notification_service_interface.dart';
import 'package:test_athkar_app/services/android_notification_service.dart';
import 'package:test_athkar_app/services/ios_notification_service.dart';
import 'dart:io' show Platform;

/// مدير مركزي لجميع وظائف الإشعارات في التطبيق
class NotificationManager {
  // الخدمة المحددة للمنصة
  late NotificationServiceInterface _notificationService;
  
  // التبعيات
  final ErrorLoggingService _errorLoggingService;
  
  // ثوابت للتخزين المحلي
  static const String _keyNotificationSettings = 'notification_settings';
  
  // إعدادات المستخدم
  NotificationSettings _settings = NotificationSettings();
  
  NotificationManager({
    required ErrorLoggingService errorLoggingService,
  }) : _errorLoggingService = errorLoggingService {
    _initPlatformService();
  }
  
  /// تهيئة الخدمة المناسبة للمنصة
  void _initPlatformService() {
    final serviceLocator = GetIt.instance;
    
    if (Platform.isAndroid) {
      _notificationService = serviceLocator<AndroidNotificationService>();
    } else if (Platform.isIOS) {
      _notificationService = serviceLocator<IOSNotificationService>();
    } else {
      // خدمة احتياطية
      _notificationService = serviceLocator<AndroidNotificationService>();
    }
  }
  
  /// تهيئة مدير الإشعارات
  Future<bool> initialize() async {
    try {
      // تحميل إعدادات المستخدم
      await _loadSettings();
      
      // تهيئة الخدمة الخاصة بالمنصة
      final result = await _notificationService.initialize();
      
      // تكوين الخدمة بناءً على إعدادات المستخدم
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
      
      return await _notificationService.scheduleNotification(
        notificationId: notificationId,
        title: title,
        body: body,
        notificationTime: notificationTime,
        channelId: channelId,
        payload: payload,
        color: color,
        repeat: repeat,
        priority: priority,
      );
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
  Future<bool> scheduleMultipleNotifications({
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
      if (!_settings.enabled) return false;
      
      return await _notificationService.scheduleMultipleNotifications(
        baseId: baseId,
        title: title,
        body: body,
        notificationTimes: notificationTimes,
        channelId: channelId,
        payload: payload,
        color: color,
        repeat: repeat,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'خطأ في جدولة إشعارات متعددة', 
        e
      );
      return false;
    }
  }
  
  /// إلغاء إشعار
  Future<bool> cancelNotification(String notificationId) async {
    return await _notificationService.cancelNotification(notificationId);
  }
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications() async {
    return await _notificationService.cancelAllNotifications();
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
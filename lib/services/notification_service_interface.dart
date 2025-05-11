// lib/services/notification_service_interface.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// واجهة موحدة لخدمات الإشعارات عبر المنصات المختلفة
abstract class NotificationServiceInterface {
  /// تهيئة خدمة الإشعارات
  Future<bool> initialize();
  
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
  });
  
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
  });
  
  /// إلغاء إشعار بمعرف محدد
  Future<bool> cancelNotification(String notificationId);
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications();
  
  /// إعادة جدولة جميع الإشعارات المحفوظة سابقاً
  Future<void> scheduleAllSavedNotifications();
  
  /// التحقق مما إذا كان الإشعار مفعلاً بمعرف محدد
  Future<bool> isNotificationEnabled(String notificationId);
  
  /// تفعيل/تعطيل الإشعارات
  Future<bool> setNotificationsEnabled(bool enabled);
  
  /// التحقق مما إذا كانت الإشعارات مفعلة بشكل عام
  Future<bool> areNotificationsEnabled();
  
  /// الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications();
  
  /// إرسال إشعار بسيط فوري
  Future<void> showSimpleNotification(
    String title,
    String body,
    int id, {
    String? payload,
  });
  
  /// إرسال إشعار اختباري للتأكد من عمل الإشعارات
  Future<bool> testImmediateNotification();
  
  /// إرسال إشعار اختباري مجمع
  Future<bool> sendGroupedTestNotification();
  
  /// التحقق وطلب تحسينات الإشعارات
  Future<void> checkNotificationOptimizations(BuildContext context);
  
  /// الحصول على وقت الإشعار المحفوظ
  Future<TimeOfDay?> getNotificationTime(String notificationId);
  
  /// تكوين خدمة الإشعارات حسب تفضيلات المستخدم
  Future<bool> configureFromPreferences();
  
  /// التحقق من الأذونات والإعدادات قبل جدولة الإشعارات
  Future<bool> checkNotificationPrerequisites(BuildContext context);
}

/// فئة نموذج لتكوين الإشعارات
class NotificationConfig {
  final bool enableSound;
  final bool enableVibration;
  final bool enableLights;
  final bool bypassDnd;
  final bool groupSimilar;
  final String sound;
  final int importance;
  final int priority;
  
  const NotificationConfig({
    this.enableSound = true,
    this.enableVibration = true,
    this.enableLights = true,
    this.bypassDnd = false,
    this.groupSimilar = true,
    this.sound = 'default',
    this.importance = 4, // مرتفع
    this.priority = 1,   // مرتفع
  });
  
  /// إنشاء من خصائص
  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    return NotificationConfig(
      enableSound: json['enableSound'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      enableLights: json['enableLights'] ?? true,
      bypassDnd: json['bypassDnd'] ?? false,
      groupSimilar: json['groupSimilar'] ?? true,
      sound: json['sound'] ?? 'default',
      importance: json['importance'] ?? 4,
      priority: json['priority'] ?? 1,
    );
  }
  
  /// تحويل إلى خصائص
  Map<String, dynamic> toJson() {
    return {
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'enableLights': enableLights,
      'bypassDnd': bypassDnd,
      'groupSimilar': groupSimilar,
      'sound': sound,
      'importance': importance,
      'priority': priority,
    };
  }
  
  /// نسخة مع تعديلات
  NotificationConfig copyWith({
    bool? enableSound,
    bool? enableVibration,
    bool? enableLights,
    bool? bypassDnd,
    bool? groupSimilar,
    String? sound,
    int? importance,
    int? priority,
  }) {
    return NotificationConfig(
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableLights: enableLights ?? this.enableLights,
      bypassDnd: bypassDnd ?? this.bypassDnd,
      groupSimilar: groupSimilar ?? this.groupSimilar,
      sound: sound ?? this.sound,
      importance: importance ?? this.importance,
      priority: priority ?? this.priority,
    );
  }
}
// lib/core/services/interfaces/notification_service.dart
import 'package:flutter/material.dart';

/// نوع تكرار الإشعارات
enum NotificationRepeatInterval {
  daily,
  weekly,
  monthly
}

/// وقت إرسال الإشعار (صباحًا أو مساءً أو أوقات محددة للصلوات)
enum NotificationTime {
  morning,
  evening,
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
  custom
}

/// أولوية الإشعار
enum NotificationPriority {
  low,
  normal,
  high,
  critical
}

/// ظهور الإشعار في شاشة القفل (استخدام اسم مختلف لتجنب التعارض)
enum NotificationVisibility {
  public,   // ظاهر تمامًا
  secret,   // مخفي تمامًا
  private,  // يظهر عنوان الإشعار فقط
}

/// بيانات الإشعار
class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final NotificationRepeatInterval? repeatInterval;
  final NotificationTime notificationTime;
  final NotificationPriority priority;
  final bool respectBatteryOptimizations;
  final bool respectDoNotDisturb;
  
  // إضافة خيارات جديدة
  final String? soundName;
  final String channelId;
  final Map<String, dynamic>? payload;
  final NotificationVisibility visibility;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.repeatInterval,
    this.notificationTime = NotificationTime.custom,
    this.priority = NotificationPriority.normal,
    this.respectBatteryOptimizations = true,
    this.respectDoNotDisturb = true,
    this.soundName,
    this.channelId = 'default_channel',
    this.payload,
    this.visibility = NotificationVisibility.public,
  });
}

/// كلاس لتمثيل إجراء الإشعار
class NotificationAction {
  final String id;
  final String title;
  final bool showsUserInterface;
  final bool cancelNotification;

  NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface = true,
    this.cancelNotification = false,
  });
}

abstract class NotificationService {
  /// تهيئة خدمة الإشعارات
  Future<void> initialize();
  
  /// طلب أذونات الإشعارات
  Future<bool> requestPermission();
  
  /// جدولة إشعار في وقت محدد
  Future<bool> scheduleNotification(NotificationData notification);
  
  /// جدولة إشعار متكرر في وقت محدد
  Future<bool> scheduleRepeatingNotification(NotificationData notification);
  
  /// جدولة إشعار مع مراعاة المنطقة الزمنية
  Future<bool> scheduleNotificationInTimeZone(
    NotificationData notification, 
    String timeZone
  );
  
  /// جدولة إشعار مع إجراءات تفاعلية
  Future<bool> scheduleNotificationWithActions(
    NotificationData notification,
    List<NotificationAction> actions,
  );
  
  /// إلغاء إشعار محدد
  Future<void> cancelNotification(int id);
  
  /// إلغاء مجموعة من الإشعارات بواسطة معرفاتها
  Future<void> cancelNotificationsByIds(List<int> ids);
  
  /// إلغاء إشعارات بواسطة علامة
  Future<void> cancelNotificationsByTag(String tag);
  
  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications();
  
  /// تعيين استراتيجية إرسال الإشعارات حسب حالة البطارية
  Future<void> setRespectBatteryOptimizations(bool enabled);
  
  /// تعيين استراتيجية إرسال الإشعارات حسب وضع عدم الإزعاج
  Future<void> setRespectDoNotDisturb(bool enabled);
  
  /// التحقق مما إذا كان يمكن إرسال الإشعارات حاليًا
  Future<bool> canSendNotificationsNow();
  
  /// تنظيف الموارد عند الانتهاء
  Future<void> dispose();
}
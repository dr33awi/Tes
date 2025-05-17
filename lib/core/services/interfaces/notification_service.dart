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
  high
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
  });
}

abstract class NotificationService {
  /// تهيئة خدمة الإشعارات
  Future<void> initialize();
  
  /// طلب أذونات الإشعارات
  Future<bool> requestPermission();
  
  /// جدولة إشعار في وقت محدد
  /// 
  /// يمكن تحديد تكرار الإشعار من خلال [repeatInterval]
  /// ويمكن تحديد أولوية الإشعار من خلال [priority]
  /// ويمكن تحديد ما إذا كان الإشعار يحترم إعدادات البطارية من خلال [respectBatteryOptimizations]
  /// ويمكن تحديد ما إذا كان الإشعار يحترم وضع عدم الإزعاج من خلال [respectDoNotDisturb]
  Future<bool> scheduleNotification(NotificationData notification);
  
  /// جدولة إشعار متكرر في وقت محدد
  Future<bool> scheduleRepeatingNotification(NotificationData notification);
  
  /// إلغاء إشعار محدد
  Future<void> cancelNotification(int id);
  
  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications();
  
  /// تعيين استراتيجية إرسال الإشعارات حسب حالة البطارية
  /// 
  /// إذا كانت [enabled] تساوي true، فسيتم التحقق من حالة البطارية قبل إرسال الإشعارات
  Future<void> setRespectBatteryOptimizations(bool enabled);
  
  /// تعيين استراتيجية إرسال الإشعارات حسب وضع عدم الإزعاج
  /// 
  /// إذا كانت [enabled] تساوي true، فلن يتم إرسال الإشعارات عندما يكون وضع عدم الإزعاج مفعلاً
  Future<void> setRespectDoNotDisturb(bool enabled);
  
  /// التحقق مما إذا كان يمكن إرسال الإشعارات حاليًا
  Future<bool> canSendNotificationsNow();
}
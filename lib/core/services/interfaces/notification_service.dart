// lib/core/services/interfaces/notification_service.dart
import 'package:flutter/foundation.dart';

enum NotificationType {
  athkar,
  prayerTime,
  reminder,
}

class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;
  final DateTime? scheduledTime;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    this.scheduledTime,
  });
}

abstract class NotificationService {
  /// تهيئة خدمة الإشعارات
  Future<void> init();
  
  /// طلب أذونات الإشعارات
  Future<bool> requestPermissions();
  
  /// إنشاء وعرض إشعار فوري
  Future<void> showNotification(NotificationData notification);
  
  /// جدولة إشعار في وقت محدد
  Future<void> scheduleNotification(NotificationData notification);
  
  /// جدولة إشعار يتكرر
  Future<void> scheduleRepeatingNotification({
    required NotificationData notification,
    required RepeatInterval repeatInterval,
  });
  
  /// إلغاء إشعار محدد
  Future<void> cancelNotification(String id);
  
  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications();
  
  /// إعادة جدولة الإشعارات بعد إعادة تشغيل الجهاز
  Future<void> rescheduleNotificationsAfterReboot();
  
  /// استماع لأحداث الإشعارات
  Stream<NotificationData> get notificationStream;
}

enum RepeatInterval {
  daily,
  weekly,
  monthly,
}
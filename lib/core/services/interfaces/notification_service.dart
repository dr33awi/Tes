// lib/core/services/interfaces/notification_service.dart
import 'package:flutter/material.dart';

/// نوع تكرار الإشعارات
enum NotificationRepeatInterval {
  daily,   // يومي
  weekly,  // أسبوعي
  monthly  // شهري
}

/// وقت إرسال الإشعار (صباحًا أو مساءً أو أوقات محددة للصلوات)
enum NotificationTime {
  morning,  // الصباح
  evening,  // المساء
  fajr,     // الفجر
  dhuhr,    // الظهر
  asr,      // العصر
  maghrib,  // المغرب
  isha,     // العشاء
  custom    // مخصص
}

/// أولوية الإشعار
enum NotificationPriority {
  low,      // منخفضة
  normal,   // عادية
  high,     // عالية
  critical  // حرجة
}

/// ظهور الإشعار في شاشة القفل (استخدام اسم مختلف لتجنب التعارض)
enum NotificationVisibility {
  public,   // ظاهر تمامًا
  secret,   // مخفي تمامًا
  private,  // يظهر عنوان الإشعار فقط
}

/// بيانات الإشعار
class NotificationData {
  /// معرف فريد للإشعار
  final int id;
  
  /// عنوان الإشعار
  final String title;
  
  /// محتوى الإشعار
  final String body;
  
  /// وقت جدولة الإشعار
  final DateTime scheduledDate;
  
  /// نمط تكرار الإشعار (يومي، أسبوعي، شهري)
  final NotificationRepeatInterval? repeatInterval;
  
  /// وقت الإشعار (صباح، مساء، صلوات)
  final NotificationTime notificationTime;
  
  /// أولوية الإشعار
  final NotificationPriority priority;
  
  /// هل يحترم تحسينات البطارية؟
  final bool respectBatteryOptimizations;
  
  /// هل يحترم وضع عدم الإزعاج؟
  final bool respectDoNotDisturb;
  
  /// اسم ملف الصوت للإشعار
  final String? soundName;
  
  /// معرف قناة الإشعار
  final String channelId;
  
  /// بيانات إضافية للإشعار
  final Map<String, dynamic>? payload;
  
  /// ظهور الإشعار في شاشة القفل
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
  /// معرف الإجراء
  final String id;
  
  /// عنوان الإجراء
  final String title;
  
  /// هل يفتح واجهة المستخدم؟
  final bool showsUserInterface;
  
  /// هل يلغي الإشعار؟
  final bool cancelNotification;

  NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface = true,
    this.cancelNotification = false,
  });
}

/// واجهة خدمة الإشعارات
abstract class NotificationService {
  /// تهيئة خدمة الإشعارات
  /// يتم استدعاؤها عند بدء التطبيق
  Future<void> initialize();
  
  /// طلب أذونات الإشعارات
  /// يتم استدعاؤها عند الحاجة لإرسال إشعارات
  Future<bool> requestPermission();
  
  /// جدولة إشعار في وقت محدد
  /// [notification] بيانات الإشعار المراد جدولته
  /// يرجع قيمة [bool] تشير إلى نجاح العملية
  Future<bool> scheduleNotification(NotificationData notification);
  
  /// جدولة إشعار متكرر في وقت محدد
  /// [notification] بيانات الإشعار المراد جدولته
  /// يرجع قيمة [bool] تشير إلى نجاح العملية
  Future<bool> scheduleRepeatingNotification(NotificationData notification);
  
  /// جدولة إشعار مع مراعاة المنطقة الزمنية
  /// [notification] بيانات الإشعار المراد جدولته
  /// [timeZone] المنطقة الزمنية المطلوبة
  /// يرجع قيمة [bool] تشير إلى نجاح العملية
  Future<bool> scheduleNotificationInTimeZone(
    NotificationData notification, 
    String timeZone
  );
  
  /// جدولة إشعار مع إجراءات تفاعلية
  /// [notification] بيانات الإشعار المراد جدولته
  /// [actions] قائمة الإجراءات التفاعلية
  /// يرجع قيمة [bool] تشير إلى نجاح العملية
  Future<bool> scheduleNotificationWithActions(
    NotificationData notification,
    List<NotificationAction> actions,
  );
  
  /// إلغاء إشعار محدد
  /// [id] معرف الإشعار المراد إلغاؤه
  Future<void> cancelNotification(int id);
  
  /// إلغاء مجموعة من الإشعارات بواسطة معرفاتها
  /// [ids] قائمة معرفات الإشعارات المراد إلغاؤها
  Future<void> cancelNotificationsByIds(List<int> ids);
  
  /// إلغاء إشعارات بواسطة علامة
  /// [tag] علامة الإشعارات المراد إلغاؤها
  Future<void> cancelNotificationsByTag(String tag);
  
  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications();
  
  /// تعيين استراتيجية إرسال الإشعارات حسب حالة البطارية
  /// [enabled] تفعيل/تعطيل احترام تحسينات البطارية
  Future<void> setRespectBatteryOptimizations(bool enabled);
  
  /// تعيين استراتيجية إرسال الإشعارات حسب وضع عدم الإزعاج
  /// [enabled] تفعيل/تعطيل احترام وضع عدم الإزعاج
  Future<void> setRespectDoNotDisturb(bool enabled);
  
  /// التحقق مما إذا كان يمكن إرسال الإشعارات حاليًا
  /// يرجع قيمة [bool] تشير إلى إمكانية إرسال الإشعارات
  Future<bool> canSendNotificationsNow();
  
  /// تنظيف الموارد عند الانتهاء
  Future<void> dispose();
}
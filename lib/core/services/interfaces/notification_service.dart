// استخدم اسم مختلف لتجنب التضارب مع حزمة flutter_local_notifications
enum NotificationRepeatInterval {
  daily,
  weekly,
  monthly
}

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationRepeatInterval repeatInterval,
  });
  
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
}
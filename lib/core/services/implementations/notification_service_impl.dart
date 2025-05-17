import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../interfaces/notification_service.dart';

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  
  NotificationServiceImpl(this._flutterLocalNotificationsPlugin);
  
  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    // تعديل إعدادات التهيئة لتتوافق مع الإصدار الجديد
    const AndroidInitializationSettings androidInitSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosInitSettings = 
        DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }
  
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // التعامل مع الاستجابة للإشعار هنا
  }
  
  @override
  Future<bool> requestPermission() async {
    // طلب الأذونات حسب الإصدار الجديد
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>();
            
    final bool? granted = await androidImplementation?.requestNotificationPermissions();
    
    final DarwinFlutterLocalNotificationsPlugin? iosImplementation = 
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation
            DarwinFlutterLocalNotificationsPlugin>();
            
    final bool? iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    return granted ?? iosGranted ?? false;
  }
  
  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  @override
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationRepeatInterval repeatInterval,
  }) async {
    final RepeatInterval flutterRepeatInterval = _mapToFlutterRepeatInterval(repeatInterval);
    
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      flutterRepeatInterval,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
  
  RepeatInterval _mapToFlutterRepeatInterval(NotificationRepeatInterval interval) {
    switch (interval) {
      case NotificationRepeatInterval.daily:
        return RepeatInterval.daily;
      case NotificationRepeatInterval.weekly:
        return RepeatInterval.weekly;
      case NotificationRepeatInterval.monthly:
        return RepeatInterval.monthly;
    }
  }
  
  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'athkar_app_channel',
      'Athkar Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }
  
  @override
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
  
  @override
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
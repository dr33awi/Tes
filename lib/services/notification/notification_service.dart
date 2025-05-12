// lib/services/notification/notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:test_athkar_app/services/notification/notification_service_interface.dart';
import 'package:test_athkar_app/services/notification/android_notification_service.dart';
import 'package:test_athkar_app/services/notification/ios_notification_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// خدمة موحدة بسيطة للإشعارات - تعمل كـ wrapper للخدمات الخاصة بالمنصة
class NotificationService implements NotificationServiceInterface {
  late NotificationServiceInterface _platformService;
  final ErrorLoggingService _errorLoggingService;
  
  NotificationService({
    required ErrorLoggingService errorLoggingService,
  }) : _errorLoggingService = errorLoggingService {
    _initializePlatformService();
  }
  
  void _initializePlatformService() {
    try {
      if (Platform.isAndroid) {
        _platformService = serviceLocator<AndroidNotificationService>();
      } else if (Platform.isIOS) {
        _platformService = serviceLocator<IOSNotificationService>();
      } else {
        throw UnsupportedError('المنصة غير مدعومة');
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationService',
        'خطأ في تهيئة خدمة المنصة',
        e
      );
    }
  }
  
  @override
  Future<bool> initialize() => _platformService.initialize();
  
  @override
  Future<bool> configureFromPreferences() => _platformService.configureFromPreferences();
  
  @override
  Future<bool> checkNotificationPrerequisites(BuildContext context) => 
    _platformService.checkNotificationPrerequisites(context);
  
  @override
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
  }) => _platformService.scheduleNotification(
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
  
  @override
  Future<bool> scheduleMultipleNotifications({
    required String baseId,
    required String title,
    required String body,
    required List<TimeOfDay> notificationTimes,
    String? channelId,
    String? payload,
    Color? color,
    bool repeat = true,
  }) => _platformService.scheduleMultipleNotifications(
    baseId: baseId,
    title: title,
    body: body,
    notificationTimes: notificationTimes,
    channelId: channelId,
    payload: payload,
    color: color,
    repeat: repeat,
  );
  
  @override
  Future<bool> cancelNotification(String notificationId) => 
    _platformService.cancelNotification(notificationId);
  
  @override
  Future<bool> cancelAllNotifications() => 
    _platformService.cancelAllNotifications();
  
  @override
  Future<void> scheduleAllSavedNotifications() => 
    _platformService.scheduleAllSavedNotifications();
  
  @override
  Future<bool> isNotificationEnabled(String notificationId) => 
    _platformService.isNotificationEnabled(notificationId);
  
  @override
  Future<bool> setNotificationsEnabled(bool enabled) => 
    _platformService.setNotificationsEnabled(enabled);
  
  @override
  Future<bool> areNotificationsEnabled() => 
    _platformService.areNotificationsEnabled();
  
  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() => 
    _platformService.getPendingNotifications();
  
  @override
  Future<void> showSimpleNotification(
    String title,
    String body,
    int id, {
    String? payload,
  }) => _platformService.showSimpleNotification(title, body, id, payload: payload);
  
  @override
  Future<bool> testImmediateNotification() => 
    _platformService.testImmediateNotification();
  
  @override
  Future<bool> sendGroupedTestNotification() => 
    _platformService.sendGroupedTestNotification();
  
  @override
  Future<void> checkNotificationOptimizations(BuildContext context) => 
    _platformService.checkNotificationOptimizations(context);
  
  @override
  Future<TimeOfDay?> getNotificationTime(String notificationId) => 
    _platformService.getNotificationTime(notificationId);
}
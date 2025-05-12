// lib/services/app_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/services/notification/notification_navigation.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/services/di_container.dart';

/// فئة مساعدة لتهيئة خدمات التطبيق
class AppInitializer {
  // مؤشر لمعرفة ما إذا تمت تهيئة التطبيق بالفعل
  static bool _isInitialized = false;
  
  /// تهيئة جميع خدمات التطبيق
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }
    
    try {
      // تعيين اتجاه الشاشة
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // تهيئة حاوية التبعيات
      await setupServiceLocator();
      
      // تهيئة خدمة الإشعارات الموحدة
      final notificationManager = serviceLocator<NotificationManager>();
      await notificationManager.initialize();
      
      // تهيئة التنقل من الإشعارات
      await NotificationNavigation.initialize();
      
      // إعادة جدولة الإشعارات المحفوظة
      await notificationManager.rescheduleAllNotifications();
      
      _isInitialized = true;
      print("اكتملت تهيئة التطبيق بنجاح");
      return true;
    } catch (e) {
      print('خطأ في تهيئة التطبيق: $e');
      return false;
    }
  }
  
  /// الحصول على مفتاح التنقل للتطبيق
  static GlobalKey<NavigatorState> getNavigatorKey() {
    return NotificationNavigation.navigatorKey;
  }
  
  /// التحقق من تحسينات الإشعارات عند بدء التطبيق
  static Future<void> checkNotificationOptimizations(BuildContext context) async {
    try {
      final notificationManager = serviceLocator<NotificationManager>();
      
      // إضافة تأخير قصير لتجنب عرض حوارات متعددة
      await Future.delayed(Duration(seconds: 1));
      
      await notificationManager.checkNotificationOptimizations(context);
    } catch (e) {
      print('خطأ في التحقق من تحسينات الإشعارات: $e');
    }
  }
  /// التحقق وإعادة جدولة الإشعارات إذا لزم الأمر
  static Future<void> checkAndRescheduleNotifications() async {
    try {
      print("جاري التحقق من جداول الإشعارات...");
      
      final NotificationManager notificationManager = 
          serviceLocator<NotificationManager>();
      
      await notificationManager.rescheduleAllNotifications();
      
      print("اكتمل التحقق من الإشعارات");
    } catch (e) {
      print('خطأ في التحقق من الإشعارات: $e');
    }
  }
}
// lib/services/app_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/services/notification_navigation.dart';
import 'package:test_athkar_app/services/notification_manager.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
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
      await _initializeNotifications();
      
      // تهيئة التنقل من الإشعارات
      await NotificationNavigation.initialize();
      
      _isInitialized = true;
      print("اكتملت تهيئة التطبيق بنجاح");
      return true;
    } catch (e) {
      // في حالة عدم تهيئة serviceLocator بعد، استخدم ErrorLoggingService مباشرةً
      if (serviceLocator.isRegistered<ErrorLoggingService>()) {
        serviceLocator<ErrorLoggingService>().logError(
          'AppInitializer', 
          'خطأ في تهيئة التطبيق', 
          e
        );
      } else {
        print('خطأ في تهيئة التطبيق: $e');
      }
      return false;
    }
  }
  
  /// تهيئة خدمة الإشعارات الموحدة
  static Future<void> _initializeNotifications() async {
    try {
      print("جاري تهيئة خدمات الإشعارات...");
      
      // استخدام NotificationManager بدلاً من NotificationService
      final NotificationManager notificationManager = 
          serviceLocator<NotificationManager>();
      
      final initialized = await notificationManager.initialize();
      
      if (initialized) {
        print("تم تهيئة خدمة الإشعارات بنجاح");
        
        // إعادة جدولة جميع الإشعارات المحفوظة للتأكد من عملها
        await notificationManager.rescheduleAllNotifications();
        
        // التحقق من الإشعارات المعلقة (معلومات التصحيح)
        final pendingNotifications = await notificationManager.getPendingNotifications();
        print("عدد الإشعارات المعلقة: ${pendingNotifications.length}");
      } else {
        print("فشل في تهيئة خدمة الإشعارات");
        
        // محاولة التهيئة مرة أخرى بعد فترة
        await Future.delayed(Duration(seconds: 2));
        await notificationManager.initialize();
      }
    } catch (e) {
      serviceLocator<ErrorLoggingService>().logError(
        'AppInitializer', 
        'خطأ في تهيئة الإشعارات', 
        e
      );
    }
  }
  
  /// الحصول على مفتاح التنقل للتطبيق
  static GlobalKey<NavigatorState> getNavigatorKey() {
    return NotificationNavigation.navigatorKey;
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
      serviceLocator<ErrorLoggingService>().logError(
        'AppInitializer', 
        'خطأ في التحقق من الإشعارات', 
        e
      );
    }
  }
  
  /// التحقق من تحسينات الإشعارات عند بدء التطبيق
  /// مع تحسين منطق العمل لتجنب إزعاج المستخدم
  static Future<void> checkNotificationOptimizations(BuildContext context) async {
    try {
      final BatteryOptimizationService batteryService = 
          serviceLocator<BatteryOptimizationService>();
      
      final DoNotDisturbService dndService = 
          serviceLocator<DoNotDisturbService>();
      
      // التحقق من تحسينات البطارية
      if (await batteryService.shouldCheckBatteryOptimization()) {
        await batteryService.checkAndRequestBatteryOptimization(context);
      }
      
      // التحقق من وضع عدم الإزعاج بعد فترة قصيرة لتجنب عرض حوارات متعددة في وقت واحد
      await Future.delayed(Duration(seconds: 1));
      
      final shouldPrompt = await dndService.shouldPromptAboutDoNotDisturb();
      if (shouldPrompt) {
        await dndService.showDoNotDisturbDialog(context);
      }
    } catch (e) {
      serviceLocator<ErrorLoggingService>().logError(
        'AppInitializer', 
        'خطأ في التحقق من تحسينات الإشعارات', 
        e
      );
    }
  }
  
  /// الحصول على كائن مدير الإشعارات
  static NotificationManager getNotificationManager() {
    return serviceLocator<NotificationManager>();
  }
  
  /// الحصول على كائن خدمة الإشعارات (للتوافق القديم)
  static NotificationManager getNotificationService() {
    return serviceLocator<NotificationManager>();
  }
}
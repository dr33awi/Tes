// lib/services/app_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/services/notification_navigation.dart';
import 'package:test_athkar_app/services/notification_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/ios_notification_service.dart';
import 'package:test_athkar_app/services/notification_grouping_service.dart';

/// فئة مساعدة لتهيئة خدمات التطبيق
class AppInitializer {
  // خدمات التبعية المعكوسة
  static final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  static late NotificationService _notificationService;
  static late BatteryOptimizationService _batteryOptimizationService;
  static late DoNotDisturbService _doNotDisturbService;
  
  /// تهيئة جميع خدمات التطبيق
  static Future<void> initialize() async {
    try {
      // تعيين اتجاه الشاشة
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // تهيئة الخدمات باستخدام التبعية المعكوسة
      _initializeServices();
      
      // تهيئة خدمة الإشعارات
      await _initializeNotifications();
      
      // تهيئة التنقل من الإشعارات
      await NotificationNavigation.initialize();
      
      print("اكتملت تهيئة التطبيق بنجاح");
    } catch (e) {
      _errorLoggingService.logError('AppInitializer', 'خطأ في تهيئة التطبيق', e);
    }
  }
  
  /// تهيئة الخدمات باستخدام التبعية المعكوسة
  static void _initializeServices() {
    try {
      // إنشاء كائنات الخدمات المطلوبة
      final iosNotificationService = IOSNotificationService();
      final notificationGroupingService = NotificationGroupingService();
      _batteryOptimizationService = BatteryOptimizationService();
      _doNotDisturbService = DoNotDisturbService();
      
      // تهيئة خدمة الإشعارات مع كائنات التبعية المعكوسة
      _notificationService = NotificationService(
        errorLoggingService: _errorLoggingService,
        doNotDisturbService: _doNotDisturbService,
        iosNotificationService: iosNotificationService,
        notificationGroupingService: notificationGroupingService,
        batteryOptimizationService: _batteryOptimizationService,
      );
    } catch (e) {
      _errorLoggingService.logError('AppInitializer', 'خطأ في تهيئة الخدمات', e);
    }
  }
  
  /// تهيئة خدمة الإشعارات
  static Future<void> _initializeNotifications() async {
    try {
      print("جاري تهيئة خدمات الإشعارات...");
      
      final initialized = await _notificationService.initialize();
      
      if (initialized) {
        print("تم تهيئة خدمة الإشعارات بنجاح");
        
        // إعادة جدولة جميع الإشعارات المحفوظة للتأكد من عملها
        await _notificationService.scheduleAllSavedNotifications();
        
        // التحقق من الإشعارات المعلقة (معلومات التصحيح)
        final pendingNotifications = await _notificationService.getPendingNotifications();
        print("عدد الإشعارات المعلقة: ${pendingNotifications.length}");
      } else {
        print("فشل في تهيئة خدمة الإشعارات");
      }
    } catch (e) {
      _errorLoggingService.logError('AppInitializer', 'خطأ في تهيئة الإشعارات', e);
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
      
      await _notificationService.scheduleAllSavedNotifications();
      
      print("اكتمل التحقق من الإشعارات");
    } catch (e) {
      _errorLoggingService.logError('AppInitializer', 'خطأ في التحقق من الإشعارات', e);
    }
  }
  
  /// التحقق من تحسينات الإشعارات عند بدء التطبيق
  static Future<void> checkNotificationOptimizations(BuildContext context) async {
    try {
      // التحقق من تحسينات البطارية
      await _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
      
      // التحقق من القيود الإضافية للبطارية
      await _batteryOptimizationService.checkForAdditionalBatteryRestrictions(context);
      
      // التحقق من وضع عدم الإزعاج
      final shouldPrompt = await _doNotDisturbService.shouldPromptAboutDoNotDisturb();
      if (shouldPrompt) {
        await _doNotDisturbService.showDoNotDisturbDialog(context);
      }
    } catch (e) {
      _errorLoggingService.logError('AppInitializer', 'خطأ في التحقق من تحسينات الإشعارات', e);
    }
  }
  
  /// الحصول على كائن خدمة الإشعارات
  static NotificationService getNotificationService() {
    return _notificationService;
  }
}
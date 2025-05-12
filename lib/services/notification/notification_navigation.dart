// lib/services/notification/notification_navigation.dart
import 'dart:convert'; // أضف هذا السطر لاستيراد jsonDecode و jsonEncode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// فئة مساعدة للتعامل مع التنقل من الإشعارات
class NotificationNavigation {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  // خريطة لتخزين معالجات التنقل المخصصة
  static final Map<String, Function(BuildContext, String, Map<String, dynamic>?)> _navigationHandlers = {};
  
  /// تسجيل معالج تنقل مخصص
  static void registerNavigationHandler(
    String handlerId,
    Function(BuildContext, String, Map<String, dynamic>?) handler,
  ) {
    _navigationHandlers[handlerId] = handler;
  }
  
  /// إلغاء تسجيل معالج تنقل
  static void unregisterNavigationHandler(String handlerId) {
    _navigationHandlers.remove(handlerId);
  }
  
  /// تهيئة التنقل من الإشعارات
  static Future<void> initialize() async {
    try {
      // التحقق مما إذا تم فتح التطبيق من إشعار
      final isFromNotification = await checkNotificationOpen();
      if (isFromNotification) {
        final payload = await getNotificationPayload();
        if (payload != null && payload.isNotEmpty) {
          // تأخير التنقل للتأكد من تحميل التطبيق بالكامل
          Future.delayed(const Duration(milliseconds: 500), () {
            handleNotificationNavigation(payload);
          });
        }
        
        // مسح بيانات الإشعار
        await clearNotificationData();
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في تهيئة التنقل من الإشعارات', 
        e
      );
    }
  }
  
  /// التحقق مما إذا تم فتح التطبيق من إشعار
  static Future<bool> checkNotificationOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('opened_from_notification') ?? false;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في التحقق من فتح الإشعار', 
        e
      );
      return false;
    }
  }
  
  /// الحصول على بيانات الإشعار الذي فتح التطبيق
  static Future<String?> getNotificationPayload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('notification_payload');
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في الحصول على بيانات الإشعار', 
        e
      );
      return null;
    }
  }
  
  /// مسح بيانات فتح الإشعار
  static Future<void> clearNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('opened_from_notification', false);
      await prefs.remove('notification_payload');
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في مسح بيانات الإشعار', 
        e
      );
    }
  }

  /// التنقل إلى الشاشة المناسبة بناءً على بيانات الإشعار
  static Future<void> handleNotificationNavigation(String payload) async {
    if (payload.isEmpty) return;
    
    try {
      // تحليل البيانات
      final Map<String, dynamic> data = _parsePayload(payload);
      final String navigationId = data['navigationId'] ?? 'default';
      final String targetId = data['targetId'] ?? '';
      final Map<String, dynamic>? extraData = data['extraData'];
      
      // الحصول على سياق التنقل
      final context = navigatorKey.currentState?.context;
      if (context == null) {
        await _errorLoggingService.logError(
          'NotificationNavigation', 
          'تعذر الحصول على سياق التنقل', 
          Exception('Navigator context is null')
        );
        return;
      }
      
      // البحث عن معالج مسجل
      final handler = _navigationHandlers[navigationId];
      if (handler != null) {
        handler(context, targetId, extraData);
      } else {
        // معالج افتراضي
        _defaultNavigationHandler(context, navigationId, targetId, extraData);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في معالجة التنقل من الإشعار: $payload', 
        e
      );
    }
  }
  
  /// تحليل بيانات الإشعار
  static Map<String, dynamic> _parsePayload(String payload) {
    try {
      // محاولة تحليل JSON
      return Map<String, dynamic>.from(jsonDecode(payload));
    } catch (e) {
      // إذا فشل، استخدم تحليل بسيط
      final parts = payload.split(':');
      return {
        'navigationId': parts.isNotEmpty ? parts[0] : 'default',
        'targetId': parts.length > 1 ? parts[1] : '',
        'extraData': parts.length > 2 ? {'extra': parts.sublist(2).join(':')} : null,
      };
    }
  }
  
  /// معالج التنقل الافتراضي
  static void _defaultNavigationHandler(
    BuildContext context,
    String navigationId,
    String targetId,
    Map<String, dynamic>? extraData,
  ) {
    // يمكن تخصيص هذا حسب احتياجات التطبيق
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم النقر على إشعار: $navigationId'),
      ),
    );
  }
  
  /// تنفيذ التنقل المخصص من الإشعار
  static Future<void> navigateFromNotification(
    BuildContext context,
    String navigationId,
    String targetId, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // البحث عن معالج مسجل
      final handler = _navigationHandlers[navigationId];
      if (handler != null) {
        handler(context, targetId, extraData);
      } else {
        // استخدام المعالج الافتراضي
        _defaultNavigationHandler(context, navigationId, targetId, extraData);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في التنقل المخصص من الإشعار: $navigationId', 
        e
      );
    }
  }
  
  /// تخزين البيانات للتنقل من الإشعار
  static Future<void> setNotificationNavigationData(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('opened_from_notification', true);
      await prefs.setString('notification_payload', payload);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في تخزين بيانات التنقل من الإشعار', 
        e
      );
    }
  }
  
  /// إنشاء بيانات موحدة للإشعار
  static String createNavigationPayload({
    required String navigationId,
    required String targetId,
    Map<String, dynamic>? extraData,
  }) {
    try {
      final data = {
        'navigationId': navigationId,
        'targetId': targetId,
        'extraData': extraData,
      };
      return jsonEncode(data);
    } catch (e) {
      // طريقة بديلة بسيطة
      if (extraData != null && extraData.isNotEmpty) {
        return '$navigationId:$targetId:${extraData.toString()}';
      }
      return '$navigationId:$targetId';
    }
  }
}
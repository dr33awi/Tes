// lib/services/notification_navigation.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/athkarscreen/screen/athkar_details_screen.dart';
import 'package:test_athkar_app/screens/athkarscreen/services/athkar_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// فئة مساعدة للتعامل مع التنقل من الإشعارات
class NotificationNavigation {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
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
      // استخراج معرف الفئة وأي معلمات إضافية
      final parts = payload.split(':');
      final categoryId = parts[0];
      
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
      
      // تحميل فئة الأذكار
      final AthkarService athkarService = AthkarService();
      final category = await athkarService.getAthkarCategory(categoryId);
      
      if (category != null) {
        // التنقل إلى شاشة تفاصيل الأذكار
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AthkarDetailsScreen(category: category),
          ),
        );
      } else {
        await _errorLoggingService.logError(
          'NotificationNavigation', 
          'تعذر العثور على الفئة: $categoryId', 
          Exception('Category not found')
        );
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في معالجة التنقل من الإشعار: $payload', 
        e
      );
    }
  }
  
  /// الحصول على أيقونة فئة الأذكار بناءً على المعرف
  static IconData getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.nightlight_round;
      case 'sleep':
        return Icons.bedtime;
      case 'wake':
        return Icons.alarm;
      case 'prayer':
        return Icons.mosque;
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'quran':
        return Icons.menu_book;
      default:
        return Icons.notifications;
    }
  }
  
  /// الحصول على لون فئة الأذكار بناءً على المعرف
  static Color getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // أصفر للصباح
      case 'evening':
        return const Color(0xFFAB47BC); // بنفسجي للمساء
      case 'sleep':
        return const Color(0xFF5C6BC0); // أزرق للنوم
      case 'wake':
        return const Color(0xFFFFB74D); // برتقالي للاستيقاظ
      case 'prayer':
        return const Color(0xFF4DB6AC); // أزرق فاتح للصلاة
      case 'home':
        return const Color(0xFF66BB6A); // أخضر للمنزل
      case 'food':
        return const Color(0xFFE57373); // أحمر للطعام
      case 'quran':
        return const Color(0xFF9575CD); // بنفسجي فاتح للقرآن
      default:
        return const Color(0xFF447055); // اللون الافتراضي للتطبيق
    }
  }
  
  /// تنفيذ التنقل المخصص من الإشعار
  static Future<void> navigateFromNotification(BuildContext context, String categoryId, {Map<String, dynamic>? extraData}) async {
    try {
      // تحميل فئة الأذكار
      final AthkarService athkarService = AthkarService();
      final category = await athkarService.getAthkarCategory(categoryId);
      
      if (category != null) {
        // التنقل إلى شاشة تفاصيل الأذكار
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AthkarDetailsScreen(category: category),
          ),
        );
      } else {
        await _errorLoggingService.logError(
          'NotificationNavigation', 
          'تعذر العثور على الفئة أثناء التنقل المخصص: $categoryId', 
          Exception('Category not found')
        );
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationNavigation', 
        'خطأ في التنقل المخصص من الإشعار: $categoryId', 
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
}
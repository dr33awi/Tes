// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'app/di/service_locator.dart';
import 'core/services/interfaces/notification_service.dart';
import 'core/services/interfaces/timezone_service.dart';
import 'domain/usecases/settings/get_settings.dart';
import 'core/services/utils/notification_scheduler.dart';

Future<void> main() async {
  // تهيئة ربط Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تعيين اتجاه التطبيق
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  try {
    // تهيئة خدمات التطبيق الأساسية فقط
    await _initBasicServices();
    
    // إنشاء NavigationService
    _setupNavigationService();
    
    // تسجيل Observer لمراقبة دورة حياة التطبيق
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
    
    runApp(const AthkarApp());
    
    // تهيئة الخدمات غير الأساسية في الخلفية
    _initNonEssentialServices();
  } catch (e) {
    debugPrint('Error al iniciar la aplicación: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('حدث خطأ أثناء تهيئة التطبيق: $e'),
          ),
        ),
      ),
    );
  }
}

/// تهيئة الخدمات الأساسية المطلوبة لبدء التطبيق
Future<void> _initBasicServices() async {
  // تهيئة خدمات التطبيق الأساسية فقط
  await ServiceLocator().initBasicServices();
  
  // التأكد من تهيئة التوقيت
  final timezoneService = getIt<TimezoneService>();
  await timezoneService.initializeTimeZones();
}

/// تهيئة الخدمات غير الأساسية في الخلفية
Future<void> _initNonEssentialServices() async {
  // إكمال تهيئة باقي الخدمات
  await ServiceLocator().initRemainingServices();
  
  // طلب أذونات الإشعارات عند بدء التطبيق
  await _requestNotificationPermissions();
  
  // جدولة الإشعارات بناءً على الإعدادات المحفوظة
  await _scheduleNotifications();
}

/// إعداد خدمة التنقل
void _setupNavigationService() {
  // إعداد NavigationKey للوصول إلى السياق
  NavigationService.navigatorKey = GlobalKey<NavigatorState>();
}

/// طلب أذونات الإشعارات
Future<void> _requestNotificationPermissions() async {
  try {
    final notificationService = getIt<NotificationService>();
    final hasPermission = await notificationService.requestPermission();
    debugPrint('Permiso de notificaciones: $hasPermission');
  } catch (e) {
    debugPrint('Error requesting notification permissions: $e');
  }
}

/// جدولة الإشعارات عند بدء التطبيق
Future<void> _scheduleNotifications() async {
  try {
    // الحصول على الإعدادات المحفوظة
    final settings = await getIt<GetSettings>().call();
    
    // جدولة الإشعارات
    if (settings.enableNotifications) {
      final notificationScheduler = getIt<NotificationScheduler>();
      await notificationScheduler.scheduleAllNotifications(settings);
      debugPrint('Notificaciones programadas correctamente');
    }
  } catch (e) {
    debugPrint('حدث خطأ أثناء جدولة الإشعارات: $e');
  }
}

// خدمة التنقل للوصول إلى السياق العام للتطبيق
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// مراقب دورة حياة التطبيق لتنظيف الموارد عند إغلاق التطبيق
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Estado de ciclo de vida cambiado a: $state');
    
    if (state == AppLifecycleState.detached) {
      // عندما يتم إغلاق التطبيق نهائيًا
      _disposeResources();
    }
  }
  
  /// تنظيف الموارد عند إغلاق التطبيق
  Future<void> _disposeResources() async {
    try {
      debugPrint('Disposing resources...');
      
      // تنظيف موارد خدمة الإشعارات
      if (getIt.isRegistered<NotificationService>()) {
        final notificationService = getIt<NotificationService>();
        await notificationService.dispose();
      }
      
      // تنظيف موارد جميع الخدمات
      await ServiceLocator().dispose();
      
      debugPrint('Resources disposed successfully');
    } catch (e) {
      debugPrint('Error disposing resources: $e');
    }
  }
}

/// تسجيل الخروج من التطبيق
class AppShutdownManager {
  static Future<bool> shutdownApp() async {
    try {
      // تنظيف الموارد
      await ServiceLocator().dispose();
      return true;
    } catch (e) {
      debugPrint('Error during app shutdown: $e');
      return false;
    }
  }
}
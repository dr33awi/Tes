// lib/main.dart
import 'dart:async';
import 'package:athkar_app/core/services/utils/notification_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'app/di/service_locator.dart';
import 'core/services/interfaces/notification_service.dart';
import 'core/services/interfaces/timezone_service.dart';
import 'domain/usecases/settings/get_settings.dart';

Future<void> main() async {
  // تهيئة ربط Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تعيين اتجاه التطبيق من اليمين إلى اليسار
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  try {
    // تهيئة خدمات التطبيق
    await ServiceLocator().init();
    
    // التأكد من تهيئة التوقيت
    await _initializeTimeZones();
    
    // إنشاء NavigationService
    await _setupNavigationService();
    
    // طلب أذونات الإشعارات عند بدء التطبيق
    await _requestNotificationPermissions();
    
    // جدولة الإشعارات بناءً على الإعدادات المحفوظة
    await _scheduleNotifications();
    
    // تسجيل Observer لمراقبة دورة حياة التطبيق
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
    
    runApp(const AthkarApp());
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

/// التأكد من تهيئة المناطق الزمنية
Future<void> _initializeTimeZones() async {
  try {
    final timezoneService = getIt<TimezoneService>();
    await timezoneService.initializeTimeZones();
    debugPrint('Zonas horarias inicializadas correctamente');
  } catch (e) {
    debugPrint('Error inicializando zonas horarias: $e');
  }
}

/// إعداد خدمة التنقل
Future<void> _setupNavigationService() async {
  // إضافة NavigationService للوصول إلى السياق
  runApp(MaterialApp(
    navigatorKey: NavigationService.navigatorKey,
    home: Container(), // هذا فقط لتهيئة NavigatorKey
  ));
  
  // انتظار قليلاً للسماح للتطبيق بإعداد السياق
  await Future.delayed(const Duration(milliseconds: 100));
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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
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
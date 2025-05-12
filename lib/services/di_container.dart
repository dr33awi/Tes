// lib/services/di_container.dart
import 'package:get_it/get_it.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/notification/notification_service.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/services/notification/android_notification_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/notification/ios_notification_service.dart';
import 'package:test_athkar_app/services/permissions_service.dart';
import 'package:test_athkar_app/services/daily_quote_service.dart';
import 'package:test_athkar_app/services/retry_service.dart';

// إنشاء مثيل من حاوية التبعيات
final GetIt serviceLocator = GetIt.instance;

/// تهيئة حاوية التبعيات مع جميع الخدمات المطلوبة
Future<void> setupServiceLocator() async {
  // 1. تسجيل الخدمات الأساسية
  serviceLocator.registerLazySingleton<ErrorLoggingService>(
    () => ErrorLoggingService(),
  );
  
  // 2. تسجيل الخدمات التي تعتمد على الخدمات الأساسية
  serviceLocator.registerLazySingleton<PermissionsService>(
    () => PermissionsService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<BatteryOptimizationService>(
    () => BatteryOptimizationService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<DoNotDisturbService>(
    () => DoNotDisturbService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<DailyQuoteService>(
    () => DailyQuoteService(),
  );
  
  serviceLocator.registerLazySingleton<RetryService>(
    () => RetryService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
    ),
  );
  
  // 3. تسجيل خدمات الإشعارات الخاصة بالمنصات
  serviceLocator.registerLazySingleton<IOSNotificationService>(
    () => IOSNotificationService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<AndroidNotificationService>(
    () => AndroidNotificationService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
      doNotDisturbService: serviceLocator<DoNotDisturbService>(),
      batteryOptimizationService: serviceLocator<BatteryOptimizationService>(),
      permissionsService: serviceLocator<PermissionsService>(),
    ),
  );
  
  // 4. تسجيل خدمة الإشعارات الموحدة
  serviceLocator.registerLazySingleton<NotificationService>(
    () => NotificationService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
    ),
  );
  
  // 5. تسجيل مدير الإشعارات
  serviceLocator.registerLazySingleton<NotificationManager>(
    () => NotificationManager(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
      retryService: serviceLocator<RetryService>(),
    ),
  );
  
  // 6. تهيئة الخدمات التي تحتاج لتهيئة
  await serviceLocator<ErrorLoggingService>().initialize();
  await serviceLocator<DailyQuoteService>().initialize();
  await serviceLocator<BatteryOptimizationService>().initialize();
}
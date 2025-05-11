// lib/services/di_container.dart
import 'package:get_it/get_it.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/notification_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/ios_notification_service.dart';
import 'package:test_athkar_app/services/permissions_service.dart';
import 'package:test_athkar_app/services/daily_quote_service.dart';

// إنشاء مثيل من حاوية التبعيات
final GetIt serviceLocator = GetIt.instance;

/// تهيئة حاوية التبعيات مع جميع الخدمات المطلوبة
Future<void> setupServiceLocator() async {
  // تسجيل الخدمات كـ singletons
  // ترتيب التسجيل مهم بسبب الاعتماديات
  
  // 1. تسجيل الخدمات الأساسية التي لا تعتمد على خدمات أخرى
  serviceLocator.registerLazySingleton<ErrorLoggingService>(
    () => ErrorLoggingService(),
  );
  
  // 2. تسجيل الخدمات التي تعتمد على الخدمات الأساسية
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
  
  serviceLocator.registerLazySingleton<PermissionsService>(
    () => PermissionsService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<DailyQuoteService>(
    () => DailyQuoteService(),
  );
  
  // 3. تسجيل الخدمات التي تعتمد على الخدمات المذكورة أعلاه
  serviceLocator.registerLazySingleton<IOSNotificationService>(
    () => IOSNotificationService(),
  );
  
  // 4. أخيرًا، تسجيل الخدمات المعقدة التي تعتمد على عدة خدمات
  serviceLocator.registerLazySingleton<NotificationService>(
    () => NotificationService(
      errorLoggingService: serviceLocator<ErrorLoggingService>(),
      doNotDisturbService: serviceLocator<DoNotDisturbService>(),
      iosNotificationService: serviceLocator<IOSNotificationService>(),
      batteryOptimizationService: serviceLocator<BatteryOptimizationService>(),
      // إزالة notificationGroupingService من هنا
    ),
  );
  
  // 5. تهيئة الخدمات التي تحتاج لتهيئة
  await serviceLocator<ErrorLoggingService>().initialize();
  await serviceLocator<DailyQuoteService>().initialize();
}
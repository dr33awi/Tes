// lib/app/di/service_locator.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/interfaces/notification_service.dart';
import '../../core/services/implementations/notification_service_impl.dart';
import '../../core/services/interfaces/storage_service.dart';
import '../../core/services/implementations/storage_service_impl.dart';
import '../../core/services/interfaces/prayer_times_service.dart';
import '../../core/services/implementations/prayer_times_service_impl.dart';
import '../../core/services/interfaces/qibla_service.dart';
import '../../core/services/implementations/qibla_service_impl.dart';
import '../../core/services/interfaces/battery_service.dart';
import '../../core/services/implementations/battery_service_impl.dart';
import '../../core/services/interfaces/do_not_disturb_service.dart';
import '../../core/services/implementations/do_not_disturb_service_impl.dart';
import '../../core/services/interfaces/timezone_service.dart';
import '../../core/services/implementations/timezone_service_impl.dart';
import '../../core/services/interfaces/permission_service.dart';
import '../../core/services/implementations/permission_service_impl.dart';
import '../../core/services/permission_manager.dart';
import '../../data/datasources/local/athkar_local_data_source.dart';
import '../../data/datasources/local/settings_local_data_source.dart';
import '../../data/repositories/athkar_repository_impl.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/athkar_repository.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/athkar/get_athkar_by_category.dart';
import '../../domain/usecases/athkar/get_athkar_categories.dart';
import '../../domain/usecases/prayers/get_prayer_times.dart';
import '../../domain/usecases/prayers/get_qibla_direction.dart';
import '../../domain/usecases/settings/get_settings.dart';
import '../../domain/usecases/settings/update_settings.dart';
import '../../core/services/utils/notification_scheduler.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _basicServicesInitialized = false;
  bool _fullInitialized = false;

  /// تهيئة الخدمات الأساسية المطلوبة لبدء التطبيق
  Future<void> initBasicServices() async {
    if (_basicServicesInitialized) return;

    // External Services
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    
    // Core Services
    getIt.registerSingleton<StorageService>(
      StorageServiceImpl(sharedPreferences),
    );
    
    // Timezone Service
    getIt.registerSingleton<TimezoneService>(
      TimezoneServiceImpl(),
    );
    
    // Permission Service
getIt.registerSingleton<PermissionService>(
  PermissionServiceImpl(),
);
    
    // Permission Manager
getIt.registerSingleton<PermissionManager>(
  PermissionManager(getIt<PermissionService>()),
);
    
    // Data Sources
    getIt.registerSingleton<SettingsLocalDataSource>(
      SettingsLocalDataSourceImpl(getIt<StorageService>()),
    );

    // Repositories
    getIt.registerSingleton<SettingsRepository>(
      SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()),
    );

    // Use Cases
    getIt.registerLazySingleton(() => GetSettings(getIt<SettingsRepository>()));
    getIt.registerLazySingleton(() => UpdateSettings(getIt<SettingsRepository>()));

    _basicServicesInitialized = true;
    debugPrint('Basic services initialized successfully');
  }

  /// تهيئة باقي الخدمات في الخلفية
  Future<void> initRemainingServices() async {
    if (_fullInitialized) return;
    if (!_basicServicesInitialized) await initBasicServices();

    // External Services
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    getIt.registerSingleton<FlutterLocalNotificationsPlugin>(flutterLocalNotificationsPlugin);

    // Core Services
    getIt.registerSingleton<BatteryService>(
      BatteryServiceImpl(),
    );
    
    getIt.registerSingleton<DoNotDisturbService>(
      DoNotDisturbServiceImpl(),
    );
    
    // Registro del servicio de notificaciones con los nuevos servicios
    getIt.registerSingleton<NotificationService>(
      NotificationServiceImpl(
        flutterLocalNotificationsPlugin,
        getIt<BatteryService>(),
        getIt<DoNotDisturbService>(),
        getIt<TimezoneService>(),
      ),
    );
    
    getIt.registerSingleton<PrayerTimesService>(
      PrayerTimesServiceImpl(),
    );
    
    getIt.registerSingleton<QiblaService>(
      QiblaServiceImpl(),
    );
    
    // Registro del programador de notificaciones
    getIt.registerSingleton<NotificationScheduler>(
      NotificationScheduler(),
    );

    // Data Sources
    getIt.registerSingleton<AthkarLocalDataSource>(
      AthkarLocalDataSourceImpl(),
    );

    // Repositories
    getIt.registerSingleton<AthkarRepository>(
      AthkarRepositoryImpl(getIt<AthkarLocalDataSource>()),
    );
    
    getIt.registerSingleton<PrayerTimesRepository>(
      PrayerTimesRepositoryImpl(getIt<PrayerTimesService>()),
    );

    // Use Cases
    getIt.registerLazySingleton(() => GetAthkarByCategory(getIt<AthkarRepository>()));
    getIt.registerLazySingleton(() => GetAthkarCategories(getIt<AthkarRepository>()));
    getIt.registerLazySingleton(() => GetPrayerTimes(getIt<PrayerTimesRepository>()));
    getIt.registerLazySingleton(() => GetQiblaDirection(getIt<PrayerTimesRepository>()));

    // Inicialización del servicio de notificaciones
    await getIt<NotificationService>().initialize();
    
    // Inicialización del servicio de zonas horarias
    await getIt<TimezoneService>().initializeTimeZones();

    _fullInitialized = true;
    debugPrint('All services initialized successfully');
  }
  void setupServiceLocator() {
  getIt.registerSingleton<PermissionService>(PermissionServiceImpl());
}

  /// تهيئة جميع الخدمات (الطريقة القديمة للتوافق الخلفي)
  Future<void> init() async {
    if (_fullInitialized) return;
    
    await initBasicServices();
    await initRemainingServices();
  }
  
  /// تنظيف الموارد عند إغلاق التطبيق
  Future<void> dispose() async {
    if (!_basicServicesInitialized) return;
    
    try {
      // Limpieza del servicio de notificaciones
      if (getIt.isRegistered<NotificationService>()) {
        await getIt<NotificationService>().dispose();
      }
      
      // Limpieza del servicio de brújula
      if (getIt.isRegistered<QiblaService>()) {
        getIt<QiblaService>().dispose();
      }
      
      // Limpieza del servicio No molestar
      if (getIt.isRegistered<DoNotDisturbService>()) {
        await getIt<DoNotDisturbService>().unregisterDoNotDisturbListener();
      }
      
      // Limpieza del servicio de batería
      if (getIt.isRegistered<BatteryService>()) {
        await getIt<BatteryService>().dispose();
      }
      
      // Restablecer el estado de registro
      await getIt.reset();
      _basicServicesInitialized = false;
      _fullInitialized = false;
      
      debugPrint('Todos los servicios se han eliminado correctamente');
    } catch (e) {
      debugPrint('Error al eliminar servicios: $e');
    }
  }
  
  // لاستخدام خلال الاختبارات
  Future<void> reset() async {
    await dispose();
  }
}
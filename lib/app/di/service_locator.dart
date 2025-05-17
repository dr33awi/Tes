// lib/app/di/service_locator.dart
import 'package:flutter/material.dart';  // Añade esta importación para debugPrint
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

  bool _isInitialized = false;

  /// Inicialización de servicios de la aplicación
  Future<void> init() async {
    if (_isInitialized) return;

    // External Services
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    getIt.registerSingleton<FlutterLocalNotificationsPlugin>(flutterLocalNotificationsPlugin);

    // Core Services
    getIt.registerSingleton<StorageService>(
      StorageServiceImpl(sharedPreferences),
    );
    
    // Registro de nuevos servicios
    getIt.registerSingleton<BatteryService>(
      BatteryServiceImpl(),
    );
    
    getIt.registerSingleton<DoNotDisturbService>(
      DoNotDisturbServiceImpl(),
    );
    
    getIt.registerSingleton<TimezoneService>(
      TimezoneServiceImpl(),
    );
    
    // Registro del servicio de notificaciones con los nuevos servicios
    getIt.registerSingleton<NotificationService>(
      NotificationServiceImpl(
        flutterLocalNotificationsPlugin,
        getIt<BatteryService>(),
        getIt<DoNotDisturbService>(),
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
    
    getIt.registerSingleton<SettingsLocalDataSource>(
      SettingsLocalDataSourceImpl(getIt<StorageService>()),
    );

    // Repositories
    getIt.registerSingleton<AthkarRepository>(
      AthkarRepositoryImpl(getIt<AthkarLocalDataSource>()),
    );
    
    getIt.registerSingleton<PrayerTimesRepository>(
      PrayerTimesRepositoryImpl(getIt<PrayerTimesService>()),
    );
    
    getIt.registerSingleton<SettingsRepository>(
      SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()),
    );

    // Use Cases
    getIt.registerLazySingleton(() => GetAthkarByCategory(getIt<AthkarRepository>()));
    getIt.registerLazySingleton(() => GetAthkarCategories(getIt<AthkarRepository>()));
    getIt.registerLazySingleton(() => GetPrayerTimes(getIt<PrayerTimesRepository>()));
    getIt.registerLazySingleton(() => GetQiblaDirection(getIt<PrayerTimesRepository>()));
    getIt.registerLazySingleton(() => GetSettings(getIt<SettingsRepository>()));
    getIt.registerLazySingleton(() => UpdateSettings(getIt<SettingsRepository>()));

    // Inicialización del servicio de notificaciones
    await getIt<NotificationService>().initialize();
    
    // Inicialización del servicio de zonas horarias
    await getIt<TimezoneService>().initializeTimeZones();

    _isInitialized = true;
  }
  
  /// Limpieza de recursos al cerrar la aplicación
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
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
      
      // Restablecer el estado de registro
      await getIt.reset();
      _isInitialized = false;
      
      debugPrint('Todos los servicios se han eliminado correctamente');
    } catch (e) {
      debugPrint('Error al eliminar servicios: $e');
    }
  }
  
  // Para uso durante las pruebas de la aplicación
  Future<void> reset() async {
    await dispose();
  }
}
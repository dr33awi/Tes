// lib/app/di/service_locator.dart
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

final getIt = GetIt.instance;

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _isInitialized = false;

  /// تهيئة خدمات التطبيق
  Future<void> init() async {
    if (_isInitialized) return;

    // External Services
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    // Core Services
    getIt.registerSingleton<StorageService>(
      StorageServiceImpl(sharedPreferences),
    );
    
    getIt.registerSingleton<NotificationService>(
      NotificationServiceImpl(),
    );
    
    getIt.registerSingleton<PrayerTimesService>(
      PrayerTimesServiceImpl(),
    );
    
    getIt.registerSingleton<QiblaService>(
      QiblaServiceImpl(),
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

    _isInitialized = true;
  }
  
  // لاستخدامه عند اختبار التطبيق
  Future<void> reset() async {
    await getIt.reset();
    _isInitialized = false;
  }
}
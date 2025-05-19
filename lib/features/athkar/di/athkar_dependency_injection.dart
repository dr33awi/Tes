// lib/features/athkar/di/athkar_dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';

import '../data/datasources/athkar_local_data_source.dart';
import '../data/datasources/athkar_service.dart';
import '../data/repositories/athkar_repository_impl.dart';
import '../domain/repositories/athkar_repository.dart';
import '../domain/usecases/get_athkar_by_category.dart';
import '../domain/usecases/get_athkar_categories.dart';
import '../presentation/providers/athkar_provider.dart';

/// ملف لتهيئة التبعيات المتعلقة بميزة الأذكار
class AthkarDependencyInjection {
  static final GetIt getIt = GetIt.instance;
  
  /// تهيئة كل التبعيات الخاصة بالأذكار
  static Future<void> init() async {
    // مصادر البيانات
    if (!getIt.isRegistered<AthkarLocalDataSource>()) {
      getIt.registerLazySingleton<AthkarLocalDataSource>(
        () => AthkarLocalDataSourceImpl(),
      );
    }
    
    if (!getIt.isRegistered<AthkarService>()) {
      getIt.registerSingleton<AthkarService>(AthkarService());
    }
    
    // المستودعات
    if (!getIt.isRegistered<AthkarRepository>()) {
      getIt.registerLazySingleton<AthkarRepository>(
        () => AthkarRepositoryImpl(getIt<AthkarLocalDataSource>()),
      );
    }
    
    // حالات الاستخدام
    if (!getIt.isRegistered<GetAthkarCategories>()) {
      getIt.registerLazySingleton<GetAthkarCategories>(
        () => GetAthkarCategories(getIt<AthkarRepository>()),
      );
    }
    
    if (!getIt.isRegistered<GetAthkarByCategory>()) {
      getIt.registerLazySingleton<GetAthkarByCategory>(
        () => GetAthkarByCategory(getIt<AthkarRepository>()),
      );
    }
    
    // مزودات الحالة
    if (!getIt.isRegistered<AthkarProvider>()) {
      getIt.registerFactory<AthkarProvider>(
        () => AthkarProvider(
          getAthkarCategories: getIt<GetAthkarCategories>(),
          getAthkarByCategory: getIt<GetAthkarByCategory>(),
        ),
      );
    }
    
    debugPrint('تم تهيئة جميع تبعيات الأذكار بنجاح');
  }
}
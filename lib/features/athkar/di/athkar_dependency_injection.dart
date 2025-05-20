// lib/features/athkar/di/athkar_dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';

import '../data/datasources/athkar_local_data_source.dart';
import '../data/datasources/athkar_service.dart';
import '../data/repositories/athkar_repository_impl.dart';
import '../domain/repositories/athkar_repository.dart';
import '../domain/usecases/get_athkar_by_category.dart';
import '../domain/usecases/get_athkar_categories.dart';
import '../domain/usecases/get_athkar_by_id.dart';
import '../domain/usecases/save_athkar_favorite.dart';
import '../domain/usecases/get_favorite_athkar.dart';
import '../domain/usecases/search_athkar.dart';
import '../presentation/providers/athkar_provider.dart';

/// مدير تهيئة التبعيات لميزة الأذكار
///
/// يوفر هذا الصف طرقًا لتهيئة وتسجيل كل التبعيات المطلوبة لميزة الأذكار
/// في حاوية حقن التبعيات [GetIt]
class AthkarDependencyInjection {
  /// مثيل حاوية حقن التبعيات
  static final GetIt getIt = GetIt.instance;
  
  /// تهيئة كل التبعيات الخاصة بالأذكار
  ///
  /// يقوم بتسجيل كل التبعيات المطلوبة في حاوية حقن التبعيات [GetIt]
  /// مما يسهل الوصول إليها من أي مكان في التطبيق
  static Future<void> init() async {
    // مصادر البيانات - طبقة البيانات
    _registerDataSources();
    
    // المستودعات - طبقة البيانات
    _registerRepositories();
    
    // حالات الاستخدام - طبقة المجال
    _registerUseCases();
    
    // مزودات الحالة - طبقة العرض
    _registerProviders();
    
    debugPrint('✅ تم تهيئة جميع تبعيات الأذكار بنجاح');
  }
  
  /// تسجيل مصادر البيانات
  ///
  /// يقوم بتسجيل مصادر البيانات في حاوية حقن التبعيات [GetIt]
  static void _registerDataSources() {
    // مصدر البيانات المحلي
    if (!getIt.isRegistered<AthkarLocalDataSource>()) {
      getIt.registerLazySingleton<AthkarLocalDataSource>(
        () => AthkarLocalDataSourceImpl(),
      );
    }
    
    // خدمة الأذكار
    if (!getIt.isRegistered<AthkarService>()) {
      getIt.registerSingleton<AthkarService>(AthkarService());
    }
  }
  
  /// تسجيل المستودعات
  ///
  /// يقوم بتسجيل المستودعات في حاوية حقن التبعيات [GetIt]
  static void _registerRepositories() {
    // مستودع الأذكار
    if (!getIt.isRegistered<AthkarRepository>()) {
      getIt.registerLazySingleton<AthkarRepository>(
        () => AthkarRepositoryImpl(getIt<AthkarLocalDataSource>()),
      );
    }
  }
  
  /// تسجيل حالات الاستخدام
  ///
  /// يقوم بتسجيل حالات الاستخدام في حاوية حقن التبعيات [GetIt]
  static void _registerUseCases() {
    // الحصول على فئات الأذكار
    if (!getIt.isRegistered<GetAthkarCategories>()) {
      getIt.registerLazySingleton<GetAthkarCategories>(
        () => GetAthkarCategories(getIt<AthkarRepository>()),
      );
    }
    
    // الحصول على الأذكار حسب الفئة
    if (!getIt.isRegistered<GetAthkarByCategory>()) {
      getIt.registerLazySingleton<GetAthkarByCategory>(
        () => GetAthkarByCategory(getIt<AthkarRepository>()),
      );
    }
    
    // الحصول على ذكر محدد
    if (!getIt.isRegistered<GetAthkarById>()) {
      getIt.registerLazySingleton<GetAthkarById>(
        () => GetAthkarById(getIt<AthkarRepository>()),
      );
    }
    
    // حفظ ذكر في المفضلة
    if (!getIt.isRegistered<SaveAthkarFavorite>()) {
      getIt.registerLazySingleton<SaveAthkarFavorite>(
        () => SaveAthkarFavorite(getIt<AthkarRepository>()),
      );
    }
    
    // الحصول على الأذكار المفضلة
    if (!getIt.isRegistered<GetFavoriteAthkar>()) {
      getIt.registerLazySingleton<GetFavoriteAthkar>(
        () => GetFavoriteAthkar(getIt<AthkarRepository>()),
      );
    }
    
    // البحث في الأذكار
    if (!getIt.isRegistered<SearchAthkar>()) {
      getIt.registerLazySingleton<SearchAthkar>(
        () => SearchAthkar(getIt<AthkarRepository>()),
      );
    }
  }
  
  /// تسجيل مزودات الحالة
  ///
  /// يقوم بتسجيل مزودات الحالة في حاوية حقن التبعيات [GetIt]
  static void _registerProviders() {
    // مزود حالة الأذكار
    if (!getIt.isRegistered<AthkarProvider>()) {
      getIt.registerFactory<AthkarProvider>(
        () => AthkarProvider(
          getAthkarCategories: getIt<GetAthkarCategories>(),
          getAthkarByCategory: getIt<GetAthkarByCategory>(),
          getAthkarById: getIt<GetAthkarById>(),  // إضافة هذه المعلمة المفقودة
          saveFavorite: getIt<SaveAthkarFavorite>(),
          getFavorites: getIt<GetFavoriteAthkar>(),
          searchAthkar: getIt<SearchAthkar>(),
        ),
      );
    }
  }
  
  /// إعادة تسجيل مزودات الحالة
  ///
  /// يستخدم هذا الأسلوب لإعادة إنشاء مزودات الحالة
  /// مما يؤدي إلى تحديث الحالة في واجهة المستخدم
  static void refreshProviders() {
    // إذا كان المزود مسجلاً، قم بإزالته وإعادة تسجيله
    if (getIt.isRegistered<AthkarProvider>()) {
      getIt.unregister<AthkarProvider>();
      _registerProviders();
    }
  }
  
  /// إعادة تعيين البيانات
  ///
  /// يقوم بإعادة تعيين جميع البيانات إلى الوضع الافتراضي
  static Future<void> resetAllData() async {
    try {
      // إعادة تعيين البيانات في مصدر البيانات المحلي
      final localDataSource = getIt<AthkarLocalDataSource>();
      if (localDataSource is AthkarLocalDataSourceImpl) {
        await localDataSource.resetData();
      }
      
      // مسح التخزين المؤقت في المستودع
      final repository = getIt<AthkarRepository>();
      if (repository is AthkarRepositoryImpl) {
        repository.clearCache();
      }
      
      // إعادة تهيئة مزودات الحالة
      refreshProviders();
      
      debugPrint('✅ تم إعادة تعيين بيانات الأذكار بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين البيانات: $e');
    }
  }
}
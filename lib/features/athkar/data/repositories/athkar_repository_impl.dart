// lib/features/athkar/data/repositories/athkar_repository_impl.dart
import 'package:flutter/material.dart';
import '../../domain/entities/athkar.dart';
import '../../domain/repositories/athkar_repository.dart';
import '../datasources/athkar_local_data_source.dart';
import '../models/athkar_model.dart';

/// تنفيذ مستودع الأذكار
///
/// يوفر هذا الصف تنفيذًا لواجهة مستودع الأذكار [AthkarRepository]
/// يستخدم مصدر البيانات المحلي [AthkarLocalDataSource] للوصول إلى البيانات
class AthkarRepositoryImpl implements AthkarRepository {
  final AthkarLocalDataSource localDataSource;

  /// المُنشئ
  ///
  /// @param localDataSource مصدر البيانات المحلي
  AthkarRepositoryImpl(this.localDataSource);
  
  /// تخزين مؤقت للفئات
  final Map<String, List<AthkarCategory>> _categoriesCache = {};
  
  /// تخزين مؤقت للأذكار حسب الفئة
  final Map<String, List<Athkar>> _athkarByCategory = {};
  
  /// تخزين مؤقت للأذكار حسب المعرف
  final Map<String, Athkar> _athkarById = {};

  @override
  Future<List<AthkarCategory>> getCategories() async {
    try {
      // تحقق من وجود البيانات في التخزين المؤقت
      if (_categoriesCache.containsKey('all')) {
        return _categoriesCache['all']!;
      }
      
      // تحميل فئات الأذكار من مصدر البيانات المحلي
      final categoriesData = await localDataSource.getCategories();
      
      // تحويل البيانات إلى كيانات
      List<AthkarCategory> categories = _mapCategoriesToEntities(categoriesData);
      
      // حفظ في التخزين المؤقت
      _categoriesCache['all'] = categories;
      
      return categories;
    } catch (e) {
      // إعادة رمي الاستثناء بعد تسجيله
      _logError('Error getting categories', e);
      rethrow;
    }
  }

  @override
  Future<List<Athkar>> getAthkarByCategory(String categoryId) async {
    try {
      // تحقق من وجود البيانات في التخزين المؤقت
      if (_athkarByCategory.containsKey(categoryId)) {
        return _athkarByCategory[categoryId]!;
      }
      
      // تحميل الأذكار حسب الفئة من مصدر البيانات المحلي
      final athkarData = await localDataSource.getAthkarByCategory(categoryId);
      
      // تحويل البيانات إلى كيانات
      List<Athkar> athkarList = _mapAthkarToEntities(athkarData, categoryId);
      
      // حفظ في التخزين المؤقت
      _athkarByCategory[categoryId] = athkarList;
      
      // أيضًا تخزين كل ذكر بمعرفه للوصول السريع لاحقًا
      for (var athkar in athkarList) {
        _athkarById[athkar.id] = athkar;
      }
      
      return athkarList;
    } catch (e) {
      // إعادة رمي الاستثناء بعد تسجيله
      _logError('Error getting athkar by category: $categoryId', e);
      rethrow;
    }
  }

  @override
  Future<Athkar?> getAthkarById(String id) async {
    try {
      // تحقق من وجود الذكر في التخزين المؤقت
      if (_athkarById.containsKey(id)) {
        return _athkarById[id];
      }
      
      // تحميل الذكر حسب المعرف
      final athkarData = await localDataSource.getAthkarById(id);
      
      // إذا لم يتم العثور على الذكر، إرجاع null
      if (athkarData == null) {
        return null;
      }
      
      // تحويل البيانات إلى كيان
      Athkar athkar = _mapSingleAthkarToEntity(athkarData);
      
      // حفظ في التخزين المؤقت
      _athkarById[athkar.id] = athkar;
      
      return athkar;
    } catch (e) {
      // إعادة رمي الاستثناء بعد تسجيله
      _logError('Error getting athkar by id: $id', e);
      rethrow;
    }
  }
  
  @override
  Future<void> saveAthkarFavorite(String id, bool isFavorite) async {
    try {
      await localDataSource.saveAthkarFavorite(id, isFavorite);
      
      // تحديث التخزين المؤقت إذا كان الذكر موجودًا فيه
      if (_athkarById.containsKey(id)) {
        // غير ممكن تعديل الكائن مباشرة لأنه ثابت
        // نحتاج لإنشاء كائن جديد ووضعه في التخزين المؤقت
        final updatedAthkar = Athkar(
          id: _athkarById[id]!.id,
          title: _athkarById[id]!.title,
          content: _athkarById[id]!.content,
          count: _athkarById[id]!.count,
          categoryId: _athkarById[id]!.categoryId,
          source: _athkarById[id]!.source,
          notes: _athkarById[id]!.notes,
          fadl: _athkarById[id]!.fadl,
          isFavorite: isFavorite, // تحديث حالة المفضلة
        );
        
        _athkarById[id] = updatedAthkar;
        
        // تحديث قائمة الأذكار حسب الفئة أيضًا
        final categoryId = updatedAthkar.categoryId;
        if (_athkarByCategory.containsKey(categoryId)) {
          final index = _athkarByCategory[categoryId]!.indexWhere((athkar) => athkar.id == id);
          if (index >= 0) {
            final updatedList = List<Athkar>.from(_athkarByCategory[categoryId]!);
            updatedList[index] = updatedAthkar;
            _athkarByCategory[categoryId] = updatedList;
          }
        }
      }
    } catch (e) {
      // إعادة رمي الاستثناء بعد تسجيله
      _logError('Error saving athkar favorite: $id, $isFavorite', e);
      rethrow;
    }
  }
  
  @override
  Future<List<Athkar>> getFavoriteAthkar() async {
    try {
      // تحميل الأذكار المفضلة من مصدر البيانات المحلي
      final favoritesData = await localDataSource.getFavoriteAthkar();
      
      // تحويل البيانات إلى كيانات
      List<Athkar> favoriteList = _mapAthkarToEntities(favoritesData);
      
      // تحديث التخزين المؤقت للأذكار حسب المعرف
      for (var athkar in favoriteList) {
        athkar = Athkar(
          id: athkar.id,
          title: athkar.title,
          content: athkar.content,
          count: athkar.count,
          categoryId: athkar.categoryId,
          source: athkar.source,
          notes: athkar.notes,
          fadl: athkar.fadl,
          isFavorite: true, // تأكيد أنه مفضل
        );
        
        _athkarById[athkar.id] = athkar;
      }
      
      return favoriteList;
    } catch (e) {
      // إعادة رمي الاستثناء بعد تسجيله
      _logError('Error getting favorite athkar', e);
      rethrow;
    }
  }

  @override
  Future<List<Athkar>> searchAthkar(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }
      
      // تحميل نتائج البحث
      final filteredAthkar = await localDataSource.searchAthkar(query);
      
      // تحويل البيانات إلى كيانات
      return _mapAthkarToEntities(filteredAthkar);
    } catch (e) {
      // إعادة رمي الاستثناء بعد تسجيله
      _logError('Error searching athkar: $query', e);
      rethrow;
    }
  }
  
  /// تحويل بيانات الفئات إلى كيانات
  ///
  /// طريقة مساعدة لتحويل بيانات الفئات من مصدر البيانات المحلي إلى كيانات
  /// @param categoriesData بيانات الفئات
  /// @return قائمة كيانات الفئات
  List<AthkarCategory> _mapCategoriesToEntities(List<Map<String, dynamic>> categoriesData) {
    List<AthkarCategory> categories = [];
    
    for (var data in categoriesData) {
      try {
        // في حالة وجود خطأ في بيانات فئة معينة، لا تتوقف المعالجة بل تخطى هذه الفئة
        var model = AthkarCategoryModel.fromJson(data);
        categories.add(model.toEntity());
      } catch (e) {
        _logError('Error mapping category: ${data['id']}', e);
        // تخطي هذه الفئة والاستمرار
        continue;
      }
    }
    
    return categories;
  }
  
  /// تحويل بيانات الأذكار إلى كيانات
  ///
  /// طريقة مساعدة لتحويل بيانات الأذكار من مصدر البيانات المحلي إلى كيانات
  /// @param athkarData بيانات الأذكار
  /// @param categoryId معرف الفئة (اختياري)
  /// @return قائمة كيانات الأذكار
  List<Athkar> _mapAthkarToEntities(List<Map<String, dynamic>> athkarData, [String? categoryId]) {
    List<Athkar> athkarList = [];
    
    for (var data in athkarData) {
      try {
        // في حالة وجود خطأ في بيانات ذكر معين، لا تتوقف المعالجة بل تخطى هذا الذكر
        var model = ThikrModel.fromJson(data);
        var athkar = model.toEntity(categoryId: data['categoryId'] ?? categoryId ?? '');
        
        // التحقق من حالة المفضلة
        final isFavorite = data['isFavorite'] as bool? ?? false;
        
        athkar = Athkar(
          id: athkar.id,
          title: athkar.title,
          content: athkar.content,
          count: athkar.count,
          categoryId: athkar.categoryId,
          source: athkar.source,
          notes: athkar.notes,
          fadl: athkar.fadl,
          isFavorite: isFavorite,
        );
        
        athkarList.add(athkar);
      } catch (e) {
        _logError('Error mapping athkar: ${data['id']}', e);
        // تخطي هذا الذكر والاستمرار
        continue;
      }
    }
    
    return athkarList;
  }
  
  /// تحويل بيانات ذكر واحد إلى كيان
  ///
  /// طريقة مساعدة لتحويل بيانات ذكر واحد من مصدر البيانات المحلي إلى كيان
  /// @param athkarData بيانات الذكر
  /// @return كيان الذكر
  Athkar _mapSingleAthkarToEntity(Map<String, dynamic> athkarData) {
    var model = ThikrModel.fromJson(athkarData);
    var athkar = model.toEntity(categoryId: athkarData['categoryId'] ?? '');
    
    // التحقق من حالة المفضلة
    final isFavorite = athkarData['isFavorite'] as bool? ?? false;
    
    return Athkar(
      id: athkar.id,
      title: athkar.title,
      content: athkar.content,
      count: athkar.count,
      categoryId: athkar.categoryId,
      source: athkar.source,
      notes: athkar.notes,
      fadl: athkar.fadl,
      isFavorite: isFavorite,
    );
  }
  
  /// تسجيل الأخطاء
  ///
  /// طريقة مساعدة لتسجيل الأخطاء بشكل موحد
  /// @param message رسالة الخطأ
  /// @param error الخطأ نفسه
  void _logError(String message, Object error) {
    debugPrint('AthkarRepositoryImpl: $message - $error');
  }
  
  /// مسح التخزين المؤقت
  ///
  /// يمكن استدعاء هذه الطريقة عند الحاجة لإعادة تحميل البيانات
  void clearCache() {
    _categoriesCache.clear();
    _athkarByCategory.clear();
    _athkarById.clear();
  }
}
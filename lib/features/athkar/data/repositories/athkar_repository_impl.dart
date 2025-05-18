// lib/data/repositories/athkar_repository_impl.dart
import '../../domain/entities/athkar.dart';
import '../../domain/repositories/athkar_repository.dart';
import '../datasources/athkar_local_data_source.dart';
import '../models/athkar_model.dart';

class AthkarRepositoryImpl implements AthkarRepository {
  final AthkarLocalDataSource localDataSource;

  AthkarRepositoryImpl(this.localDataSource);

  @override
  Future<List<AthkarCategory>> getCategories() async {
    // تحميل فئات الأذكار من مصدر البيانات المحلي
    final categoriesData = await localDataSource.getCategories();
    
    // تحويل البيانات إلى كيانات
    return categoriesData.map((data) => AthkarCategoryModel.fromJson(data).toEntity()).toList();
  }

  @override
  Future<List<Athkar>> getAthkarByCategory(String categoryId) async {
    // تحميل الأذكار حسب الفئة من مصدر البيانات المحلي
    final athkarData = await localDataSource.getAthkarByCategory(categoryId);
    
    // تحويل البيانات إلى كيانات
    return athkarData.map((data) => AthkarModel.fromJson(data).toEntity()).toList();
  }

  @override
  Future<Athkar?> getAthkarById(String id) async {
    // تحميل الذكر حسب المعرف
    final athkarData = await localDataSource.getAthkarById(id);
    
    // إذا لم يتم العثور على الذكر، إرجاع null
    if (athkarData == null) {
      return null;
    }
    
    // تحويل البيانات إلى كيان
    return AthkarModel.fromJson(athkarData).toEntity();
  }
  
  @override
  Future<void> saveAthkarFavorite(String id, bool isFavorite) async {
    await localDataSource.saveAthkarFavorite(id, isFavorite);
  }
  
  @override
  Future<List<Athkar>> getFavoriteAthkar() async {
    final favoritesData = await localDataSource.getFavoriteAthkar();
    return favoritesData.map((data) => AthkarModel.fromJson(data).toEntity()).toList();
  }

  @override
  Future<List<Athkar>> searchAthkar(String query) async {
    // تحميل جميع الأذكار
    final filteredAthkar = await localDataSource.searchAthkar(query);
    
    // تحويل البيانات إلى كيانات
    return filteredAthkar.map((data) => AthkarModel.fromJson(data).toEntity()).toList();
  }
}
// lib/data/repositories/athkar_repository_impl.dart
import '../domain/entities/athkar.dart';
import '../domain/repositories/athkar_repository.dart';
import '../datasources/datasources/local/athkar_local_data_source.dart';
import '../datasources/models/athkar_model.dart';

class AthkarRepositoryImpl implements AthkarRepository {
  final AthkarLocalDataSource localDataSource;

  AthkarRepositoryImpl(this.localDataSource);

  @override
  Future<List<AthkarCategory>> getCategories() async {
    // تحميل فئات الأذكار من مصدر البيانات المحلي
    final categoriesData = await localDataSource.loadCategories();
    
    // تحويل البيانات إلى كيانات
    return categoriesData.map((data) => AthkarCategoryModel.fromJson(data).toEntity()).toList();
  }

  @override
  Future<List<Athkar>> getAthkarByCategory(String categoryId) async {
    // تحميل الأذكار حسب الفئة من مصدر البيانات المحلي
    final athkarData = await localDataSource.loadAthkarByCategory(categoryId);
    
    // تحويل البيانات إلى كيانات
    return athkarData.map((data) => AthkarModel.fromJson(data).toEntity()).toList();
  }

  @override
  Future<Athkar?> getAthkarById(String id) async {
    // تحميل جميع الأذكار
    final allAthkar = await localDataSource.loadAllAthkar();
    
    // البحث عن الذكر المطلوب
    final athkarData = allAthkar.firstWhere(
      (data) => data['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    
    // إذا لم يتم العثور على الذكر، إرجاع null
    if (athkarData.isEmpty) {
      return null;
    }
    
    // تحويل البيانات إلى كيان
    return AthkarModel.fromJson(athkarData).toEntity();
  }

  @override
  Future<List<Athkar>> searchAthkar(String query) async {
    // تحميل جميع الأذكار
    final allAthkar = await localDataSource.loadAllAthkar();
    
    // تصفية الأذكار حسب النص المطلوب
    final filteredAthkar = allAthkar.where((data) {
      final title = data['title'] as String? ?? '';
      final content = data['content'] as String? ?? '';
      
      return title.contains(query) || content.contains(query);
    }).toList();
    
    // تحويل البيانات إلى كيانات
    return filteredAthkar.map((data) => AthkarModel.fromJson(data).toEntity()).toList();
  }
}
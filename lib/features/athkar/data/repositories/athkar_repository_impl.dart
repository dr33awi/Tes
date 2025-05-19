// lib/features/athkar/data/repositories/athkar_repository_impl.dart
import '../../domain/entities/athkar.dart';
import '../../domain/repositories/athkar_repository.dart';
import '../datasources/athkar_local_data_source.dart';
import '../models/athkar_model.dart'; // تأكد من استيراد النموذج بشكل صحيح

class AthkarRepositoryImpl implements AthkarRepository {
  final AthkarLocalDataSource localDataSource;

  AthkarRepositoryImpl(this.localDataSource);

  @override
  Future<List<AthkarCategory>> getCategories() async {
    // تحميل فئات الأذكار من مصدر البيانات المحلي
    final categoriesData = await localDataSource.getCategories();
    
    // تحويل البيانات إلى كيانات
    List<AthkarCategory> categories = [];
    for (var data in categoriesData) {
      var model = AthkarCategoryModel.fromJson(data);
      categories.add(model.toEntity());
    }
    
    return categories;
  }

  @override
  Future<List<Athkar>> getAthkarByCategory(String categoryId) async {
    // تحميل الأذكار حسب الفئة من مصدر البيانات المحلي
    final athkarData = await localDataSource.getAthkarByCategory(categoryId);
    
    // تحويل البيانات إلى كيانات
    List<Athkar> athkarList = [];
    for (var data in athkarData) {
      var model = ThikrModel.fromJson(data);
      Athkar athkar = model.toEntity();
      // تعيين معرف الفئة للذكر
      athkar = Athkar(
        id: athkar.id,
        title: athkar.title,
        content: athkar.content,
        count: athkar.count,
        categoryId: categoryId, // تعيين معرف الفئة
        source: athkar.source,
        notes: athkar.notes,
        fadl: athkar.fadl,
      );
      athkarList.add(athkar);
    }
    
    return athkarList;
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
    var model = ThikrModel.fromJson(athkarData);
    var athkar = model.toEntity();
    
    // تعيين معرف الفئة إذا كان متاحًا في البيانات
    String categoryId = athkarData['categoryId'] ?? '';
    return Athkar(
      id: athkar.id,
      title: athkar.title,
      content: athkar.content,
      count: athkar.count,
      categoryId: categoryId,
      source: athkar.source,
      notes: athkar.notes,
      fadl: athkar.fadl,
    );
  }
  
  @override
  Future<void> saveAthkarFavorite(String id, bool isFavorite) async {
    await localDataSource.saveAthkarFavorite(id, isFavorite);
  }
  
  @override
  Future<List<Athkar>> getFavoriteAthkar() async {
    final favoritesData = await localDataSource.getFavoriteAthkar();
    
    // تحويل البيانات إلى كيانات
    List<Athkar> favoriteList = [];
    for (var data in favoritesData) {
      var model = ThikrModel.fromJson(data);
      Athkar athkar = model.toEntity();
      // تعيين معرف الفئة للذكر إذا كان متاحًا
      String categoryId = data['categoryId'] ?? '';
      athkar = Athkar(
        id: athkar.id,
        title: athkar.title,
        content: athkar.content,
        count: athkar.count,
        categoryId: categoryId,
        source: athkar.source,
        notes: athkar.notes,
        fadl: athkar.fadl,
      );
      favoriteList.add(athkar);
    }
    
    return favoriteList;
  }

  @override
  Future<List<Athkar>> searchAthkar(String query) async {
    // تحميل جميع الأذكار
    final filteredAthkar = await localDataSource.searchAthkar(query);
    
    // تحويل البيانات إلى كيانات
    List<Athkar> searchResults = [];
    for (var data in filteredAthkar) {
      var model = ThikrModel.fromJson(data);
      Athkar athkar = model.toEntity();
      // تعيين معرف الفئة للذكر إذا كان متاحًا
      String categoryId = data['categoryId'] ?? '';
      athkar = Athkar(
        id: athkar.id,
        title: athkar.title,
        content: athkar.content,
        count: athkar.count,
        categoryId: categoryId,
        source: athkar.source,
        notes: athkar.notes,
        fadl: athkar.fadl,
      );
      searchResults.add(athkar);
    }
    
    return searchResults;
  }
}
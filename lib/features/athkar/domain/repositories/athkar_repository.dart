// lib/domain/repositories/athkar_repository.dart
import '../entities/athkar.dart';
abstract class AthkarRepository {
  Future<List<AthkarCategory>> getCategories();
  Future<List<Athkar>> getAthkarByCategory(String categoryId);
  Future<Athkar?> getAthkarById(String id);
  Future<void> saveAthkarFavorite(String id, bool isFavorite);
  Future<List<Athkar>> getFavoriteAthkar();
  Future<List<Athkar>> searchAthkar(String query);
}
/// واجهة مستودع الأذكار
///
/// توفر هذه الواجهة طرقًا للتفاعل مع بيانات الأذكار
    abstract class AthkarRepository {
  /// الحصول على فئات الأذكار
  /// 
  /// @return قائمة فئات الأذكار
  Future<List<AthkarCategory>> getCategories();
  
  /// الحصول على الأذكار حسب الفئة
  /// 
  /// @param categoryId معرف الفئة
  /// @return قائمة الأذكار في الفئة المحددة
  Future<List<Athkar>> getAthkarByCategory(String categoryId);
  
  /// الحصول على ذكر محدد بواسطة المعرف
  /// 
  /// @param id معرف الذكر
  /// @return ذكر محدد أو null إذا لم يتم العثور عليه
  Future<Athkar?> getAthkarById(String id);
  
  /// حفظ ذكر في المفضلة
  /// 
  /// @param id معرف الذكر
  /// @param isFavorite حالة المفضلة (true للإضافة، false للإزالة)
  Future<void> saveAthkarFavorite(String id, bool isFavorite);
  
  /// الحصول على الأذكار المفضلة
  /// 
  /// @return قائمة الأذكار المفضلة
  Future<List<Athkar>> getFavoriteAthkar();
  
  /// البحث في الأذكار
  /// 
  /// @param query استعلام البحث
  /// @return قائمة الأذكار التي تطابق استعلام البحث
  Future<List<Athkar>> searchAthkar(String query);
}
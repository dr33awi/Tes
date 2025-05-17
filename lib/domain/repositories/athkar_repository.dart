// lib/domain/repositories/athkar_repository.dart
import '../entities/athkar.dart';

abstract class AthkarRepository {
  /// الحصول على جميع فئات الأذكار
  Future<List<AthkarCategory>> getCategories();
  
  /// الحصول على الأذكار حسب الفئة
  Future<List<Athkar>> getAthkarByCategory(String categoryId);
  
  /// الحصول على ذكر محدد بواسطة المعرف
  Future<Athkar?> getAthkarById(String id);
  
  /// البحث في الأذكار
  Future<List<Athkar>> searchAthkar(String query);
}
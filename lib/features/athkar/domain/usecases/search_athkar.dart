// lib/features/athkar/domain/usecases/search_athkar.dart
import '../entities/athkar.dart';
import '../repositories/athkar_repository.dart';

/// حالة استخدام للبحث في الأذكار
///
/// تستخدم هذه الحالة للبحث في الأذكار باستخدام استعلام نصي
class SearchAthkar {
  final AthkarRepository repository;

  /// المُنشئ
  /// 
  /// @param repository مستودع الأذكار
  SearchAthkar(this.repository);

  /// التنفيذ
  /// 
  /// @param query استعلام البحث
  /// @return قائمة الأذكار التي تطابق استعلام البحث
  Future<List<Athkar>> call(String query) async {
    return await repository.searchAthkar(query);
  }
}
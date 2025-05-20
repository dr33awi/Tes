// lib/features/athkar/domain/usecases/get_favorite_athkar.dart
import '../entities/athkar.dart';
import '../repositories/athkar_repository.dart';

/// حالة استخدام للحصول على الأذكار المفضلة
///
/// تستخدم هذه الحالة للحصول على قائمة الأذكار المضافة للمفضلة
class GetFavoriteAthkar {
  final AthkarRepository repository;

  /// المُنشئ
  /// 
  /// @param repository مستودع الأذكار
  GetFavoriteAthkar(this.repository);

  /// التنفيذ
  /// 
  /// @return قائمة الأذكار المفضلة
  Future<List<Athkar>> call() async {
    return await repository.getFavoriteAthkar();
  }
}
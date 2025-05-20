// lib/features/athkar/domain/usecases/save_athkar_favorite.dart
import '../repositories/athkar_repository.dart';

/// حالة استخدام لحفظ ذكر في المفضلة
///
/// تستخدم هذه الحالة لحفظ ذكر في المفضلة أو إزالته منها
class SaveAthkarFavorite {
  final AthkarRepository repository;

  /// المُنشئ
  /// 
  /// @param repository مستودع الأذكار
  SaveAthkarFavorite(this.repository);

  /// التنفيذ
  /// 
  /// @param id معرف الذكر
  /// @param isFavorite حالة المفضلة (true للإضافة، false للإزالة)
  Future<void> call(String id, bool isFavorite) async {
    return await repository.saveAthkarFavorite(id, isFavorite);
  }
}
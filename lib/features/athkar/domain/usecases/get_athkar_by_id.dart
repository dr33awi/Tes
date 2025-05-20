// lib/features/athkar/domain/usecases/get_athkar_by_id.dart
import '../entities/athkar.dart';
import '../repositories/athkar_repository.dart';

/// حالة استخدام للحصول على ذكر محدد بواسطة المعرف
///
/// تستخدم هذه الحالة للحصول على ذكر واحد من المستودع باستخدام معرفه الفريد
class GetAthkarById {
  final AthkarRepository repository;

  /// المُنشئ
  /// 
  /// @param repository مستودع الأذكار
  GetAthkarById(this.repository);

  /// التنفيذ
  /// 
  /// @param id معرف الذكر
  /// @return ذكر محدد أو null إذا لم يتم العثور عليه
  Future<Athkar?> call(String id) async {
    return await repository.getAthkarById(id);
  }
}
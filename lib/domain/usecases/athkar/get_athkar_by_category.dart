// lib/domain/usecases/athkar/get_athkar_by_category.dart
import '../../entities/athkar.dart';
import '../../repositories/athkar_repository.dart';

class GetAthkarByCategory {
  final AthkarRepository repository;

  GetAthkarByCategory(this.repository);

  Future<List<Athkar>> call(String categoryId) async {
    return await repository.getAthkarByCategory(categoryId);
  }
}
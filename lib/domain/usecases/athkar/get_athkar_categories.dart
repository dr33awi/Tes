// lib/domain/usecases/athkar/get_athkar_categories.dart
import '../../entities/athkar.dart';
import '../../repositories/athkar_repository.dart';

class GetAthkarCategories {
  final AthkarRepository repository;

  GetAthkarCategories(this.repository);

  Future<List<AthkarCategory>> call() async {
    return await repository.getCategories();
  }
}
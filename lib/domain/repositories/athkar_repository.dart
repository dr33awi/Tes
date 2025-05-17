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
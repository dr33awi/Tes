// lib/domain/usecases/prayers/get_qibla_direction.dart
import '../../repositories/prayer_times_repository.dart';

class GetQiblaDirection {
  final PrayerTimesRepository repository;

  GetQiblaDirection(this.repository);

  Future<double> call({
    required double latitude,
    required double longitude,
  }) async {
    return await repository.getQiblaDirection(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
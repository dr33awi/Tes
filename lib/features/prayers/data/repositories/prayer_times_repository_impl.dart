// lib/data/repositories/prayer_times_repository_impl.dart
import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  final PrayerTimesService _prayerTimesService;

  PrayerTimesRepositoryImpl(this._prayerTimesService);

  @override
  Future<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required PrayerTimesCalculationParams params,
    required double latitude,
    required double longitude,
  }) async {
    return await _prayerTimesService.getPrayerTimes(
      date: date,
      params: params,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<List<PrayerTimes>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    required PrayerTimesCalculationParams params,
    required double latitude,
    required double longitude,
  }) async {
    return await _prayerTimesService.getPrayerTimesForRange(
      startDate: startDate,
      endDate: endDate,
      params: params,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    return await _prayerTimesService.getQiblaDirection(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
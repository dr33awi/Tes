// lib/data/repositories/prayer_times_repository_impl.dart
import '../../core/services/interfaces/prayer_times_service.dart';
import '../../core/services/interfaces/qibla_service.dart';
import '../../domain/repositories/prayer_times_repository.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  final PrayerTimesService _prayerTimesService;

  PrayerTimesRepositoryImpl(this._prayerTimesService);

  @override
  Future<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required PrayerTimesCalculationParams params,
  }) async {
    return await _prayerTimesService.getPrayerTimes(
      date: date,
      params: params,
    );
  }

  @override
  Future<List<PrayerTimes>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    required PrayerTimesCalculationParams params,
  }) async {
    return await _prayerTimesService.getPrayerTimesForRange(
      startDate: startDate,
      endDate: endDate,
      params: params,
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
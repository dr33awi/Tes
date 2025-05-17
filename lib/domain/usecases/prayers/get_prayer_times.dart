// lib/domain/usecases/prayers/get_prayer_times.dart
import '../../entities/prayer_times.dart';
import '../../repositories/prayer_times_repository.dart';
import '../../../core/services/interfaces/prayer_times_service.dart';

class GetPrayerTimes {
  final PrayerTimesRepository repository;

  GetPrayerTimes(this.repository);

  Future<PrayerTimes> call({
    required DateTime date,
    required PrayerTimesCalculationParams params,
    required double latitude,
    required double longitude,
  }) async {
    return await repository.getPrayerTimes(
      date: date,
      params: params,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<PrayerTimes> getTodayPrayerTimes(
    PrayerTimesCalculationParams params, {
    required double latitude,
    required double longitude,
  }) async {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    
    return call(
      date: date, 
      params: params,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<PrayerTimes>> getPrayerTimesForRange({
    required PrayerTimesCalculationParams params,
    required DateTime startDate,
    required DateTime endDate,
    required double latitude,
    required double longitude,
  }) async {
    return await repository.getPrayerTimesForRange(
      startDate: startDate,
      endDate: endDate,
      params: params,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
// lib/domain/usecases/prayers/get_prayer_times.dart
import '../../core/services/interfaces/prayer_times_service.dart';
import '../../repositories/prayer_times_repository.dart';

class GetPrayerTimes {
  final PrayerTimesRepository repository;

  GetPrayerTimes(this.repository);

  Future<PrayerTimes> call({
    required DateTime date,
    required PrayerTimesCalculationParams params,
  }) async {
    return await repository.getPrayerTimes(
      date: date,
      params: params,
    );
  }

  Future<PrayerTimes> getTodayPrayerTimes(
    PrayerTimesCalculationParams params,
  ) async {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    
    return call(date: date, params: params);
  }

  Future<List<PrayerTimes>> getPrayerTimesForRange({
    required PrayerTimesCalculationParams params,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getPrayerTimesForRange(
      startDate: startDate,
      endDate: endDate,
      params: params,
    );
  }
}
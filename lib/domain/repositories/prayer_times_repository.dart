// lib/domain/repositories/prayer_times_repository.dart
import '../../core/services/interfaces/prayer_times_service.dart';

abstract class PrayerTimesRepository {
  /// الحصول على مواقيت الصلاة ليوم معين
  Future<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required PrayerTimesCalculationParams params,
  });
  
  /// الحصول على مواقيت الصلاة لعدة أيام
  Future<List<PrayerTimes>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    required PrayerTimesCalculationParams params,
  });
  
  /// الحصول على اتجاه القبلة
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
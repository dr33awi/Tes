// lib/domain/repositories/prayer_times_repository.dart
import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../entities/prayer_times.dart';

abstract class PrayerTimesRepository {
  /// الحصول على مواقيت الصلاة ليوم معين
  Future<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required PrayerTimesCalculationParams params,
    required double latitude,
    required double longitude,
  });
  
  /// الحصول على مواقيت الصلاة لعدة أيام
  Future<List<PrayerTimes>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    required PrayerTimesCalculationParams params,
    required double latitude,
    required double longitude,
  });
  
  /// الحصول على اتجاه القبلة
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
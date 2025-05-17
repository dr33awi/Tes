import 'package:adhan/adhan.dart' as adhan;

// إعادة تصدير الأنواع من حزمة adhan بأسماء مختلفة لتجنب التضارب
typedef PrayerData = adhan.PrayerTimes;
typedef PrayerName = adhan.Prayer;

abstract class PrayerTimesService {
  Future<PrayerData> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerTimesCalculationParams params,
  });
  
  Future<PrayerData> getTodayPrayerTimes({
    required double latitude,
    required double longitude,
    required PrayerTimesCalculationParams params,
  });
  
  Future<List<PrayerData>> getPrayerTimesForRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required PrayerTimesCalculationParams params,
  });
  
  Future<DateTime> getNextPrayerTime();
  Future<PrayerName> getNextPrayer();
}

// تعريف النوع المفقود
class PrayerTimesCalculationParams {
  final String calculationMethod;
  final int adjustmentMinutes;
  
  PrayerTimesCalculationParams({
    required this.calculationMethod,
    this.adjustmentMinutes = 0,
  });
}
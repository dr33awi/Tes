// lib/core/services/interfaces/prayer_times_service.dart
import 'package:adhan/adhan.dart' as adhan;
import '../../../features/prayers/domain/entities/prayer_times.dart';

// استخدام نوع PrayerTimes المخصص
typedef PrayerData = PrayerTimes;
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
  
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  });
}

// تعريف النوع المفقود
class PrayerTimesCalculationParams {
  final String calculationMethod;
  final int adjustmentMinutes;
  final int asrMethodIndex;
  
  PrayerTimesCalculationParams({
    required this.calculationMethod,
    this.adjustmentMinutes = 0,
    this.asrMethodIndex = 0,
  });
  
  // تحويل إلى معلمات حساب مكتبة Adhan
  adhan.CalculationParameters toAdhanParams() {
    final adhan.CalculationParameters params = _getCalculationMethod(calculationMethod);
    
    // تطبيق تعديلات الوقت
    if (adjustmentMinutes != 0) {
      params.adjustments.fajr = adjustmentMinutes;
      params.adjustments.sunrise = adjustmentMinutes;
      params.adjustments.dhuhr = adjustmentMinutes;
      params.adjustments.asr = adjustmentMinutes;
      params.adjustments.maghrib = adjustmentMinutes;
      params.adjustments.isha = adjustmentMinutes;
    }
    
    // تعيين طريقة حساب العصر
    if (asrMethodIndex == 1) {
      params.madhab = adhan.Madhab.hanafi;
    } else {
      params.madhab = adhan.Madhab.shafi;
    }
    
    return params;
  }
  
  adhan.CalculationParameters _getCalculationMethod(String method) {
    switch (method) {
      case 'north_america':
        return adhan.CalculationMethod.north_america.getParameters();
      case 'muslim_world_league':
        return adhan.CalculationMethod.muslim_world_league.getParameters();
      case 'egyptian':
        return adhan.CalculationMethod.egyptian.getParameters();
      case 'karachi':
        return adhan.CalculationMethod.karachi.getParameters();
      case 'umm_al_qura':
        return adhan.CalculationMethod.umm_al_qura.getParameters();
      case 'dubai':
        return adhan.CalculationMethod.dubai.getParameters();
      case 'qatar':
        return adhan.CalculationMethod.qatar.getParameters();
      case 'kuwait':
        return adhan.CalculationMethod.kuwait.getParameters();
      case 'moonsighting_committee':
        return adhan.CalculationMethod.moon_sighting_committee.getParameters();
      case 'singapore':
        return adhan.CalculationMethod.singapore.getParameters();
      case 'turkey':
        return adhan.CalculationMethod.turkey.getParameters();
      case 'tehran':
        return adhan.CalculationMethod.tehran.getParameters();
      default:
        return adhan.CalculationMethod.muslim_world_league.getParameters();
    }
  }
}
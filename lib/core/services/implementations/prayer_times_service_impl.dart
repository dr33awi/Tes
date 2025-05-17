import 'package:adhan/adhan.dart' as adhan;
import '../interfaces/prayer_times_service.dart';

class PrayerTimesServiceImpl implements PrayerTimesService {
  @override
  Future<PrayerData> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerTimesCalculationParams params,
  }) async {
    final adhan.Coordinates coordinates = adhan.Coordinates(latitude, longitude);
    final adhan.CalculationParameters calculationParameters = _getCalculationMethod(params.calculationMethod);
    
    if (params.adjustmentMinutes != 0) {
      calculationParameters.adjustments.fajr = params.adjustmentMinutes;
      calculationParameters.adjustments.sunrise = params.adjustmentMinutes;
      calculationParameters.adjustments.dhuhr = params.adjustmentMinutes;
      calculationParameters.adjustments.asr = params.adjustmentMinutes;
      calculationParameters.adjustments.maghrib = params.adjustmentMinutes;
      calculationParameters.adjustments.isha = params.adjustmentMinutes;
    }
    
    final adhan.PrayerTimes prayerTimes = adhan.PrayerTimes(
      coordinates,
      DateComponents.from(date),
      calculationParameters,
    );
    
    return prayerTimes as PrayerData;
  }
  
  @override
  Future<PrayerData> getTodayPrayerTimes({
    required double latitude,
    required double longitude,
    required PrayerTimesCalculationParams params,
  }) async {
    return getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: DateTime.now(),
      params: params,
    );
  }
  
  @override
  Future<List<PrayerData>> getPrayerTimesForRange({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required PrayerTimesCalculationParams params,
  }) async {
    final List<PrayerData> prayerTimesList = [];
    
    for (DateTime date = startDate;
         date.isBefore(endDate.add(const Duration(days: 1)));
         date = date.add(const Duration(days: 1))) {
      final PrayerData prayerTimes = await getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: date,
        params: params,
      );
      
      prayerTimesList.add(prayerTimes);
    }
    
    return prayerTimesList;
  }
  
  @override
  Future<DateTime> getNextPrayerTime() async {
    final DateTime now = DateTime.now();
    final adhan.Coordinates coordinates = adhan.Coordinates(0, 0); // استبدل بإحداثيات المستخدم الفعلية
    final adhan.CalculationParameters params = adhan.CalculationMethod.muslim_world_league.getParameters();
    
    final adhan.PrayerTimes prayerTimes = adhan.PrayerTimes(
      coordinates,
      DateComponents.from(now),
      params,
    );
    
    final adhan.Prayer nextPrayer = prayerTimes.nextPrayer();
    final DateTime nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer)!;
    
    if (nextPrayer == adhan.Prayer.fajr && nextPrayerTime.isBefore(now)) {
      // إذا كانت صلاة الفجر في اليوم التالي
      final DateTime tomorrow = now.add(const Duration(days: 1));
      final adhan.PrayerTimes tomorrowPrayerTimes = adhan.PrayerTimes(
        coordinates,
        DateComponents.from(tomorrow),
        params,
      );
      
      return tomorrowPrayerTimes.fajr!;
    }
    
    return nextPrayerTime;
  }
  
  @override
  Future<PrayerName> getNextPrayer() async {
    final DateTime now = DateTime.now();
    final adhan.Coordinates coordinates = adhan.Coordinates(0, 0); // استبدل بإحداثيات المستخدم الفعلية
    final adhan.CalculationParameters params = adhan.CalculationMethod.muslim_world_league.getParameters();
    
    final adhan.PrayerTimes prayerTimes = adhan.PrayerTimes(
      coordinates,
      DateComponents.from(now),
      params,
    );
    
    return prayerTimes.nextPrayer() as PrayerName;
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
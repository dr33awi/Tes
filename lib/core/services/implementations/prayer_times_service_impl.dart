// lib/core/services/implementations/prayer_times_service_impl.dart
import 'package:adhan/adhan.dart' as adhan;
import '../../../features/prayers/domain/entities/prayer_times.dart';
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
    final adhan.CalculationParameters calculationParameters = params.toAdhanParams();
    
    final adhan.DateComponents dateComponents = adhan.DateComponents(date.year, date.month, date.day);
    
    final adhan.PrayerTimes prayerTimes = adhan.PrayerTimes(
      coordinates,
      dateComponents,
      calculationParameters,
    );
    
    return PrayerTimes.fromAdhan(prayerTimes);
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
    
    final adhan.DateComponents dateComponents = adhan.DateComponents(now.year, now.month, now.day);
    
    final adhan.PrayerTimes prayerTimes = adhan.PrayerTimes(
      coordinates,
      dateComponents,
      params,
    );
    
    final adhan.Prayer nextPrayer = prayerTimes.nextPrayer();
    final DateTime? nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
    
    if (nextPrayer == adhan.Prayer.fajr && (nextPrayerTime?.isBefore(now) ?? false)) {
      // إذا كانت صلاة الفجر في اليوم التالي
      final DateTime tomorrow = now.add(const Duration(days: 1));
      final adhan.DateComponents tomorrowComponents = adhan.DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
      
      final adhan.PrayerTimes tomorrowPrayerTimes = adhan.PrayerTimes(
        coordinates,
        tomorrowComponents,
        params,
      );
      
      return tomorrowPrayerTimes.fajr ?? now;
    }
    
    return nextPrayerTime ?? now;
  }
  
  @override
  Future<PrayerName> getNextPrayer() async {
    final DateTime now = DateTime.now();
    final adhan.Coordinates coordinates = adhan.Coordinates(0, 0); // استبدل بإحداثيات المستخدم الفعلية
    final adhan.CalculationParameters params = adhan.CalculationMethod.muslim_world_league.getParameters();
    
    final adhan.DateComponents dateComponents = adhan.DateComponents(now.year, now.month, now.day);
    
    final adhan.PrayerTimes prayerTimes = adhan.PrayerTimes(
      coordinates,
      dateComponents,
      params,
    );
    
    return prayerTimes.nextPrayer();
  }
  
  @override
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    final adhan.Coordinates coordinates = adhan.Coordinates(latitude, longitude);
    // استخدام طريقة الحساب الصحيحة في الإصدار الجديد من المكتبة
    return adhan.Qibla(coordinates).direction;
  }
}
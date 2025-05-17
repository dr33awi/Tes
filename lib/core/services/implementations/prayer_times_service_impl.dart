// lib/core/services/implementations/prayer_times_service_impl.dart
import 'dart:math';
import 'package:adhan/adhan.dart';
import '../interfaces/prayer_times_service.dart';

class PrayerTimesServiceImpl implements PrayerTimesService {
  @override
  Future<PrayerTimes> getPrayerTimes({
    required DateTime date,
    required PrayerTimesCalculationParams params,
  }) async {
    final coordinates = Coordinates(params.latitude, params.longitude);
    final calculationParameters = _getCalculationMethod(params.methodIndex);
    
    // تعيين طريقة حساب العصر
    if (params.asrMethodIndex == 0) {
      calculationParameters.madhab = Madhab.shafi;
    } else {
      calculationParameters.madhab = Madhab.hanafi;
    }
    
    // تعديل التاريخ حسب الحاجة
    final adjustedDate = date.add(Duration(days: params.adjustmentDays));
    
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(adjustedDate),
      calculationParameters,
    );
    
    // تحويل أوقات الصلاة إلى كائن PrayerTimes الخاص بنا
    return PrayerTimes(
      fajr: prayerTimes.fajr.toLocal(),
      sunrise: prayerTimes.sunrise.toLocal(),
      dhuhr: prayerTimes.dhuhr.toLocal(),
      asr: prayerTimes.asr.toLocal(),
      maghrib: prayerTimes.maghrib.toLocal(),
      isha: prayerTimes.isha.toLocal(),
      date: adjustedDate,
    );
  }

  @override
  Future<List<PrayerTimes>> getPrayerTimesForRange({
    required DateTime startDate,
    required DateTime endDate,
    required PrayerTimesCalculationParams params,
  }) async {
    final List<PrayerTimes> prayerTimesList = [];
    
    DateTime currentDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    
    final DateTime finalDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );
    
    while (currentDate.isBefore(finalDate) || currentDate.isAtSameMomentAs(finalDate)) {
      final prayerTimes = await getPrayerTimes(
        date: currentDate,
        params: params,
      );
      
      prayerTimesList.add(prayerTimes);
      
      // الانتقال لليوم التالي
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return prayerTimesList;
  }

  @override
  Future<DateTime> getNextPrayerTime({
    required PrayerTimesCalculationParams params,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // الحصول على مواقيت اليوم
    final todayPrayerTimes = await getPrayerTimes(
      date: today,
      params: params,
    );
    
    // التحقق من وقت الصلاة التالية
    final nextPrayer = todayPrayerTimes.getNextPrayer();
    final nextPrayerTime = todayPrayerTimes.getTimeForPrayer(nextPrayer);
    
    // إذا كانت جميع صلوات اليوم قد انتهت، ابحث عن صلاة الفجر للغد
    if (nextPrayer == Prayer.fajr && nextPrayerTime.isBefore(now)) {
      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowPrayerTimes = await getPrayerTimes(
        date: tomorrow,
        params: params,
      );
      
      return tomorrowPrayerTimes.fajr;
    }
    
    return nextPrayerTime;
  }

  @override
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    final coordinates = Coordinates(latitude, longitude);
    final qiblaDirection = Qibla(coordinates).direction;
    
    return qiblaDirection;
  }

  // الحصول على طريقة حساب مواقيت الصلاة
  CalculationParameters _getCalculationMethod(int methodIndex) {
    switch (methodIndex) {
      case 0:
        return CalculationMethod.karachi.getParameters();
      case 1:
        return CalculationMethod.northAmerica.getParameters();
      case 2:
        return CalculationMethod.muslimWorldLeague.getParameters();
      case 3:
        return CalculationMethod.egyptian.getParameters();
      case 4:
        return CalculationMethod.umm_al_qura.getParameters();
      case 5:
        return CalculationMethod.dubai.getParameters();
      case 6:
        return CalculationMethod.qatar.getParameters();
      case 7:
        return CalculationMethod.kuwait.getParameters();
      case 8:
        return CalculationMethod.singapore.getParameters();
      case 9:
        return CalculationMethod.turkey.getParameters();
      case 10:
        return CalculationMethod.tehran.getParameters();
      default:
        return CalculationMethod.other.getParameters();
    }
  }
}
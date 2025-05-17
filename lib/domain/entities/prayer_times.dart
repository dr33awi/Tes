// lib/domain/entities/prayer_times.dart
import 'package:adhan/adhan.dart' as adhan;

class PrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime date;
  
  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });
  
  // تحويل من كائن Adhan PrayerTimes إلى كائن مخصص
  factory PrayerTimes.fromAdhan(adhan.PrayerTimes prayerTimes) {
    return PrayerTimes(
      fajr: prayerTimes.fajr ?? DateTime.now(),
      sunrise: prayerTimes.sunrise ?? DateTime.now(),
      dhuhr: prayerTimes.dhuhr ?? DateTime.now(),
      asr: prayerTimes.asr ?? DateTime.now(),
      maghrib: prayerTimes.maghrib ?? DateTime.now(),
      isha: prayerTimes.isha ?? DateTime.now(),
      date: DateTime.now(),
    );
  }
  
  // الحصول على الصلاة الحالية
  adhan.Prayer getCurrentPrayer() {
    final now = DateTime.now();
    final prayers = [
      adhan.Prayer.fajr,
      adhan.Prayer.sunrise,
      adhan.Prayer.dhuhr,
      adhan.Prayer.asr,
      adhan.Prayer.maghrib,
      adhan.Prayer.isha,
    ];
    
    final times = [
      fajr,
      sunrise,
      dhuhr,
      asr,
      maghrib,
      isha,
    ];
    
    // إذا كان الوقت الحالي قبل صلاة الفجر أو بعد العشاء
    if (now.isBefore(fajr)) {
      return adhan.Prayer.isha; // العشاء (من اليوم السابق)
    }
    
    if (now.isAfter(isha)) {
      return adhan.Prayer.isha; // العشاء
    }
    
    // البحث عن أحدث صلاة مرّت
    for (int i = times.length - 1; i >= 0; i--) {
      if (now.isAfter(times[i])) {
        return prayers[i];
      }
    }
    
    return adhan.Prayer.none;
  }
  
  // الحصول على الصلاة التالية
  adhan.Prayer getNextPrayer() {
    final now = DateTime.now();
    final prayers = [
      adhan.Prayer.fajr,
      adhan.Prayer.sunrise,
      adhan.Prayer.dhuhr,
      adhan.Prayer.asr,
      adhan.Prayer.maghrib,
      adhan.Prayer.isha,
    ];
    
    final times = [
      fajr,
      sunrise,
      dhuhr,
      asr,
      maghrib,
      isha,
    ];
    
    // البحث عن الصلاة القادمة
    for (int i = 0; i < times.length; i++) {
      if (now.isBefore(times[i])) {
        return prayers[i];
      }
    }
    
    // إذا مرّت جميع الصلوات، نعتبر الفجر من اليوم التالي
    return adhan.Prayer.fajr;
  }
  
  // الحصول على وقت الصلاة بناءً على نوعها
  DateTime getTimeForPrayer(adhan.Prayer prayer) {
    switch (prayer) {
      case adhan.Prayer.fajr:
        return fajr;
      case adhan.Prayer.sunrise:
        return sunrise;
      case adhan.Prayer.dhuhr:
        return dhuhr;
      case adhan.Prayer.asr:
        return asr;
      case adhan.Prayer.maghrib:
        return maghrib;
      case adhan.Prayer.isha:
        return isha;
      default:
        return DateTime.now();
    }
  }
}
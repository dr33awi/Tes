// lib/core/services/interfaces/prayer_times_service.dart
import 'package:flutter/foundation.dart';

enum Prayer {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

class PrayerTimesCalculationParams {
  final double latitude;
  final double longitude;
  final double? altitude;
  final int methodIndex;
  final int asrMethodIndex;
  final int adjustmentDays;

  PrayerTimesCalculationParams({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.methodIndex = 4, // مؤشر الطريقة: 4 هي طريقة أم القرى
    this.asrMethodIndex = 0, // طريقة حساب العصر: 0 هي مذهب الشافعي (المعيار)
    this.adjustmentDays = 0, // تعديل عدد الأيام
  });
}

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

  Prayer? getCurrentPrayer() {
    final now = DateTime.now();
    
    if (now.isBefore(fajr)) {
      return null; // قبل الفجر
    } else if (now.isBefore(sunrise)) {
      return Prayer.fajr;
    } else if (now.isBefore(dhuhr)) {
      return Prayer.sunrise;
    } else if (now.isBefore(asr)) {
      return Prayer.dhuhr;
    } else if (now.isBefore(maghrib)) {
      return Prayer.asr;
    } else if (now.isBefore(isha)) {
      return Prayer.maghrib;
    } else {
      return Prayer.isha;
    }
  }

  Prayer getNextPrayer() {
    final now = DateTime.now();
    
    if (now.isBefore(fajr)) {
      return Prayer.fajr;
    } else if (now.isBefore(sunrise)) {
      return Prayer.sunrise;
    } else if (now.isBefore(dhuhr)) {
      return Prayer.dhuhr;
    } else if (now.isBefore(asr)) {
      return Prayer.asr;
    } else if (now.isBefore(maghrib)) {
      return Prayer.maghrib;
    } else if (now.isBefore(isha)) {
      return Prayer.isha;
    } else {
      return Prayer.fajr; // الفجر ليوم غد
    }
  }

  DateTime getTimeForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajr;
      case Prayer.sunrise:
        return sunrise;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
    }
  }

  Map<String, DateTime> toMap() {
    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'date': date,
    };
  }
}

abstract class PrayerTimesService {
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
  
  /// الحصول على وقت الصلاة التالية
  Future<DateTime> getNextPrayerTime({
    required PrayerTimesCalculationParams params,
  });
  
  /// الحصول على اتجاه القبلة
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
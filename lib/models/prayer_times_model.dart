// lib/models/prayer_times_model.dart
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

class PrayerTimeModel {
  final String name;
  final DateTime time;
  final IconData icon;
  final Color color;
  bool isNext;

  PrayerTimeModel({
    required this.name,
    required this.time,
    required this.icon,
    required this.color,
    this.isNext = false,
  });

  String get formattedTime {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }

  // لمعرفة إذا كان الوقت قد حان
  bool get isPassed => DateTime.now().isAfter(time);

  // لحساب الوقت المتبقي حتى الصلاة
  String get remainingTime {
    if (isPassed) return 'انتهى';
    
    final now = DateTime.now();
    final difference = time.difference(now);
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else {
      return '$minutes دقيقة';
    }
  }

  // تحويل أوقات صلاة Adhan إلى كائنات PrayerTimeModel
  static List<PrayerTimeModel> fromPrayerTimes(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final List<PrayerTimeModel> prayers = [
      PrayerTimeModel(
        name: 'الفجر',
        time: prayerTimes.fajr,
        icon: Icons.brightness_2,
        color: const Color(0xFF5B68D9),
      ),
      PrayerTimeModel(
        name: 'الشروق',
        time: prayerTimes.sunrise,
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFFF9E0D),
      ),
      PrayerTimeModel(
        name: 'الظهر',
        time: prayerTimes.dhuhr,
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFB746),
      ),
      PrayerTimeModel(
        name: 'العصر',
        time: prayerTimes.asr,
        icon: Icons.wb_twighlight,
        color: const Color(0xFFFF8A65),
      ),
      PrayerTimeModel(
        name: 'المغرب',
        time: prayerTimes.maghrib,
        icon: Icons.nights_stay_outlined,
        color: const Color(0xFF5C6BC0),
      ),
      PrayerTimeModel(
        name: 'العشاء',
        time: prayerTimes.isha,
        icon: Icons.nightlight_round,
        color: const Color(0xFF1A237E),
      ),
    ];

    // تحديد الصلاة التالية
    PrayerTimeModel? nextPrayer;
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
          nextPrayer = prayer;
        }
      }
    }

    if (nextPrayer != null) {
      final index = prayers.indexOf(nextPrayer);
      prayers[index] = PrayerTimeModel(
        name: nextPrayer.name,
        time: nextPrayer.time,
        icon: nextPrayer.icon,
        color: nextPrayer.color,
        isNext: true,
      );
    }

    return prayers;
  }
}
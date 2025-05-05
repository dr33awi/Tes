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
    final List<PrayerTimeModel> prayers = [];
    
    // تأكد من أن جميع الأوقات غير فارغة
    try {
      prayers.add(PrayerTimeModel(
        name: 'الفجر',
        time: prayerTimes.fajr,
        icon: Icons.brightness_2,
        color: const Color(0xFF5B68D9),
      ));
      
      prayers.add(PrayerTimeModel(
        name: 'الشروق',
        time: prayerTimes.sunrise,
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFFF9E0D),
      ));
      
      prayers.add(PrayerTimeModel(
        name: 'الظهر',
        time: prayerTimes.dhuhr,
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFB746),
      ));
      
      prayers.add(PrayerTimeModel(
        name: 'العصر',
        time: prayerTimes.asr,
        icon: Icons.wb_twighlight,
        color: const Color(0xFFFF8A65),
      ));
      
      prayers.add(PrayerTimeModel(
        name: 'المغرب',
        time: prayerTimes.maghrib,
        icon: Icons.nights_stay_outlined,
        color: const Color(0xFF5C6BC0),
      ));
      
      prayers.add(PrayerTimeModel(
        name: 'العشاء',
        time: prayerTimes.isha,
        icon: Icons.nightlight_round,
        color: const Color(0xFF1A237E),
      ));

      // تحديد الصلاة التالية
      PrayerTimeModel? nextPrayer;
      for (final prayer in prayers) {
        if (prayer.time.isAfter(now)) {
          if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
            nextPrayer = prayer;
          }
        }
      }

      // تحديث الصلاة التالية
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
    } catch (e) {
      debugPrint('خطأ في تحويل أوقات الصلاة: $e');
      
      // في حالة حدوث خطأ، نقوم بإنشاء أوقات افتراضية
      final defaultTimes = [
        DateTime(now.year, now.month, now.day, 5, 0),  // الفجر
        DateTime(now.year, now.month, now.day, 6, 15), // الشروق
        DateTime(now.year, now.month, now.day, 12, 0), // الظهر
        DateTime(now.year, now.month, now.day, 15, 30), // العصر
        DateTime(now.year, now.month, now.day, 18, 0), // المغرب
        DateTime(now.year, now.month, now.day, 19, 30), // العشاء
      ];
      
      final names = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
      final icons = [
        Icons.brightness_2,
        Icons.wb_sunny_outlined,
        Icons.wb_sunny,
        Icons.wb_twighlight,
        Icons.nights_stay_outlined,
        Icons.nightlight_round,
      ];
      final colors = [
        const Color(0xFF5B68D9),
        const Color(0xFFFF9E0D),
        const Color(0xFFFFB746),
        const Color(0xFFFF8A65),
        const Color(0xFF5C6BC0),
        const Color(0xFF1A237E),
      ];
      
      final defaultPrayers = <PrayerTimeModel>[];
      
      // إنشاء أوقات افتراضية
      for (int i = 0; i < names.length; i++) {
        defaultPrayers.add(PrayerTimeModel(
          name: names[i],
          time: defaultTimes[i],
          icon: icons[i],
          color: colors[i],
        ));
      }
      
      // تحديد الصلاة التالية من الأوقات الافتراضية
      PrayerTimeModel? nextDefaultPrayer;
      for (final prayer in defaultPrayers) {
        if (prayer.time.isAfter(now)) {
          if (nextDefaultPrayer == null || prayer.time.isBefore(nextDefaultPrayer.time)) {
            nextDefaultPrayer = prayer;
          }
        }
      }
      
      // تحديث الصلاة التالية
      if (nextDefaultPrayer != null) {
        final index = defaultPrayers.indexOf(nextDefaultPrayer);
        defaultPrayers[index] = PrayerTimeModel(
          name: nextDefaultPrayer.name,
          time: nextDefaultPrayer.time,
          icon: nextDefaultPrayer.icon,
          color: nextDefaultPrayer.color,
          isNext: true,
        );
      }
      
      return defaultPrayers;
    }
  }
}
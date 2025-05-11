// lib/prayer/models/prayer_time_model.dart
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';

class PrayerTimeModel {
  final String name;
  final DateTime time;
  final IconData icon;
  final Color color;
  final bool isNext;

  const PrayerTimeModel({
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
  
  bool get isPassed => DateTime.now().isAfter(time);

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
  
  String get englishName {
    switch (name) {
      case 'الفجر': return 'Fajr';
      case 'الشروق': return 'Sunrise';
      case 'الظهر': return 'Dhuhr';
      case 'العصر': return 'Asr';
      case 'المغرب': return 'Maghrib';
      case 'العشاء': return 'Isha';
      default: return name;
    }
  }
  
  PrayerTimeModel copyWith({
    String? name,
    DateTime? time,
    IconData? icon,
    Color? color,
    bool? isNext,
  }) {
    return PrayerTimeModel(
      name: name ?? this.name,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isNext: isNext ?? this.isNext,
    );
  }

  static List<PrayerTimeModel> fromPrayerTimes(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final List<PrayerTimeModel> prayers = [];
    
    // Use safe approach to avoid deep recursion
    final prayerDefinitions = [
      {
        'name': 'الفجر',
        'time': prayerTimes.fajr,
        'icon': Icons.brightness_2,
        'color': const Color(0xFF5B68D9),
      },
      {
        'name': 'الشروق',
        'time': prayerTimes.sunrise,
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFFF9E0D),
      },
      {
        'name': 'الظهر',
        'time': prayerTimes.dhuhr,
        'icon': Icons.wb_sunny,
        'color': const Color(0xFFFFB746),
      },
      {
        'name': 'العصر',
        'time': prayerTimes.asr,
        'icon': Icons.wb_twighlight,
        'color': const Color(0xFFFF8A65),
      },
      {
        'name': 'المغرب',
        'time': prayerTimes.maghrib,
        'icon': Icons.nights_stay_outlined,
        'color': const Color(0xFF5C6BC0),
      },
      {
        'name': 'العشاء',
        'time': prayerTimes.isha,
        'icon': Icons.nightlight_round,
        'color': const Color(0xFF1A237E),
      },
    ];
    
    // Simplified error handling to avoid nested try-catch
    for (final prayerDef in prayerDefinitions) {
      try {
        final time = prayerDef['time'] as DateTime;
        
        prayers.add(PrayerTimeModel(
          name: prayerDef['name'] as String,
          time: time,
          icon: prayerDef['icon'] as IconData,
          color: prayerDef['color'] as Color,
        ));
      } catch (e) {
        debugPrint('Error processing ${prayerDef['name']} time: $e');
      }
    }

    // Mark next prayer
    _markNextPrayer(prayers);

    return prayers;
  }
  
  static void _markNextPrayer(List<PrayerTimeModel> prayers) {
    final now = DateTime.now();
    
    PrayerTimeModel? nextPrayer;
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
          nextPrayer = prayer;
        }
      }
    }

    if (nextPrayer != null) {
      final index = prayers.indexWhere((p) => p.name == nextPrayer!.name);
      if (index != -1) {
        prayers[index] = prayers[index].copyWith(isNext: true);
      }
    }
  }
  
  static List<PrayerTimeModel> _createDefaultPrayerTimes(DateTime now) {
    final defaultPrayers = [
      PrayerTimeModel(
        name: 'الفجر',
        time: DateTime(now.year, now.month, now.day, 5, 0),
        icon: Icons.brightness_2,
        color: const Color(0xFF5B68D9),
      ),
      PrayerTimeModel(
        name: 'الشروق',
        time: DateTime(now.year, now.month, now.day, 6, 15),
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFFF9E0D),
      ),
      PrayerTimeModel(
        name: 'الظهر',
        time: DateTime(now.year, now.month, now.day, 12, 0),
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFB746),
      ),
      PrayerTimeModel(
        name: 'العصر',
        time: DateTime(now.year, now.month, now.day, 15, 30),
        icon: Icons.wb_twighlight,
        color: const Color(0xFFFF8A65),
      ),
      PrayerTimeModel(
        name: 'المغرب',
        time: DateTime(now.year, now.month, now.day, 18, 0),
        icon: Icons.nights_stay_outlined,
        color: const Color(0xFF5C6BC0),
      ),
      PrayerTimeModel(
        name: 'العشاء',
        time: DateTime(now.year, now.month, now.day, 19, 30),
        icon: Icons.nightlight_round,
        color: const Color(0xFF1A237E),
      ),
    ];
    
    _markNextPrayer(defaultPrayers);
    
    return defaultPrayers;
  }
  
  static int compareByTime(PrayerTimeModel a, PrayerTimeModel b) {
    return a.time.compareTo(b.time);
  }
}
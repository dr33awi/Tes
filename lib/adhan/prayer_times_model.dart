// lib/adhan/prayer_times_model.dart
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Model class for prayer time data
///
/// Represents a prayer time with name, time, icon, and other display properties.
/// Provides utility methods for formatting time and calculating remaining time.
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

  /// Format time in 12-hour format with AM/PM
  String get formattedTime {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }
  
  /// Format time using intl library
  String get formattedTimeWithIntl {
    try {
      final formatter = DateFormat.jm();
      return formatter.format(time);
    } catch (e) {
      // Fallback to basic formatting if intl formatting fails
      return formattedTime;
    }
  }

  /// Check if prayer time has already passed
  bool get isPassed => DateTime.now().isAfter(time);

  /// Calculate remaining time until prayer
  String get remainingTime {
    if (isPassed) return 'انتهى'; // Passed
    
    final now = DateTime.now();
    final difference = time.difference(now);
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة'; // hours and minutes
    } else {
      return '$minutes دقيقة'; // minutes only
    }
  }
  
  /// Get time in milliseconds since epoch
  int get timeInMillis => time.millisecondsSinceEpoch;
  
  /// Get prayer name in English for internal use
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
  
  /// Create a copy with modified properties
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

  /// Convert PrayerTimes from Adhan library to PrayerTimeModel list
  static List<PrayerTimeModel> fromPrayerTimes(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final List<PrayerTimeModel> prayers = [];
    
    try {
      // Map prayer definitions for simpler code
      final prayerDefinitions = [
        {
          'name': 'الفجر',
          'time': prayerTimes.fajr,
          'icon': Icons.brightness_2,
          'color': const Color(0xFF5B68D9),
          'defaultHour': 5,
          'defaultMinute': 0,
        },
        {
          'name': 'الشروق',
          'time': prayerTimes.sunrise,
          'icon': Icons.wb_sunny_outlined,
          'color': const Color(0xFFFF9E0D),
          'defaultHour': 6,
          'defaultMinute': 15,
        },
        {
          'name': 'الظهر',
          'time': prayerTimes.dhuhr,
          'icon': Icons.wb_sunny,
          'color': const Color(0xFFFFB746),
          'defaultHour': 12,
          'defaultMinute': 0,
        },
        {
          'name': 'العصر',
          'time': prayerTimes.asr,
          'icon': Icons.wb_twighlight,
          'color': const Color(0xFFFF8A65),
          'defaultHour': 15,
          'defaultMinute': 30,
        },
        {
          'name': 'المغرب',
          'time': prayerTimes.maghrib,
          'icon': Icons.nights_stay_outlined,
          'color': const Color(0xFF5C6BC0),
          'defaultHour': 18,
          'defaultMinute': 0,
        },
        {
          'name': 'العشاء',
          'time': prayerTimes.isha,
          'icon': Icons.nightlight_round,
          'color': const Color(0xFF1A237E),
          'defaultHour': 19,
          'defaultMinute': 30,
        },
      ];
      
      // Create prayer models with individual error handling
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
          
          // Use default time in case of error
          prayers.add(PrayerTimeModel(
            name: prayerDef['name'] as String,
            time: DateTime(
              now.year, 
              now.month, 
              now.day, 
              prayerDef['defaultHour'] as int, 
              prayerDef['defaultMinute'] as int
            ),
            icon: prayerDef['icon'] as IconData,
            color: prayerDef['color'] as Color,
          ));
        }
      }

      // Determine next prayer
      _markNextPrayer(prayers);

      return prayers;
    } catch (e) {
      debugPrint('General error processing prayer times: $e');
      return _createDefaultPrayerTimes(now);
    }
  }
  
  /// Mark the next upcoming prayer in the list
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

    // Update prayer marked as next
    if (nextPrayer != null) {
      final index = prayers.indexWhere((p) => p.name == nextPrayer!.name);
      if (index != -1) {
        prayers[index] = prayers[index].copyWith(isNext: true);
      }
    }
  }
  
  /// Create default prayer times
  static List<PrayerTimeModel> _createDefaultPrayerTimes(DateTime now) {
    final defaultDefinitions = [
      {
        'name': 'الفجر',
        'hour': 5,
        'minute': 0,
        'icon': Icons.brightness_2,
        'color': const Color(0xFF5B68D9),
      },
      {
        'name': 'الشروق',
        'hour': 6,
        'minute': 15,
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFFF9E0D),
      },
      {
        'name': 'الظهر',
        'hour': 12,
        'minute': 0,
        'icon': Icons.wb_sunny,
        'color': const Color(0xFFFFB746),
      },
      {
        'name': 'العصر',
        'hour': 15,
        'minute': 30,
        'icon': Icons.wb_twighlight,
        'color': const Color(0xFFFF8A65),
      },
      {
        'name': 'المغرب',
        'hour': 18,
        'minute': 0,
        'icon': Icons.nights_stay_outlined,
        'color': const Color(0xFF5C6BC0),
      },
      {
        'name': 'العشاء',
        'hour': 19,
        'minute': 30,
        'icon': Icons.nightlight_round,
        'color': const Color(0xFF1A237E),
      },
    ];
    
    final prayers = <PrayerTimeModel>[];
    
    for (final def in defaultDefinitions) {
      prayers.add(PrayerTimeModel(
        name: def['name'] as String,
        time: DateTime(
          now.year, 
          now.month, 
          now.day, 
          def['hour'] as int, 
          def['minute'] as int
        ),
        icon: def['icon'] as IconData,
        color: def['color'] as Color,
      ));
    }
    
    // Mark next prayer
    _markNextPrayer(prayers);
    
    return prayers;
  }
  
  /// Compare two PrayerTimeModel objects for sorting
  static int compareByTime(PrayerTimeModel a, PrayerTimeModel b) {
    return a.time.compareTo(b.time);
  }
  
  @override
  String toString() {
    return 'PrayerTimeModel(name: $name, time: $formattedTime, isNext: $isNext)';
  }
}
// lib/adhan/prayer_times_model.dart
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Formato de tiempo en formato 12 horas
  String get formattedTime {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }
  
  // Formato alternativo usando intl
  String get formattedTimeWithIntl {
    final formatter = DateFormat.jm();
    return formatter.format(time);
  }

  // Verificar si el tiempo ya pasó
  bool get isPassed => DateTime.now().isAfter(time);

  // Calcular tiempo restante hasta la oración
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
  
  // Crear una copia del modelo con modificaciones
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

  // Convertir tiempos de oración de Adhan a modelos PrayerTimeModel
  static List<PrayerTimeModel> fromPrayerTimes(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final List<PrayerTimeModel> prayers = [];
    
    try {
      // Mapa de definiciones de oración para simplificar el código
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
      
      // Crear modelos de oración con manejo de errores para cada uno individualmente
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
          debugPrint('Error al procesar tiempo de ${prayerDef['name']}: $e');
          
          // Usar tiempo por defecto en caso de error
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

      // Determinar la próxima oración
      PrayerTimeModel? nextPrayer;
      for (final prayer in prayers) {
        if (prayer.time.isAfter(now)) {
          if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
            nextPrayer = prayer;
          }
        }
      }

      // Actualizar oración marcada como siguiente
      if (nextPrayer != null) {
        final index = prayers.indexWhere((p) => p.name == nextPrayer!.name);
        if (index != -1) {
          prayers[index] = prayers[index].copyWith(isNext: true);
        }
      }
      
      return prayers;
    } catch (e) {
      debugPrint('Error general al procesar tiempos de oración: $e');
      return _createDefaultPrayerTimes(now);
    }
  }
  
  // Método privado para crear tiempos de oración predeterminados
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
    
    // Determinar la próxima oración
    PrayerTimeModel? nextPrayer;
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
          nextPrayer = prayer;
        }
      }
    }
    
    // Actualizar oración marcada como siguiente
    if (nextPrayer != null) {
      final index = prayers.indexWhere((p) => p.name == nextPrayer!.name);
      if (index != -1) {
        prayers[index] = prayers[index].copyWith(isNext: true);
      }
    }
    
    return prayers;
  }
}
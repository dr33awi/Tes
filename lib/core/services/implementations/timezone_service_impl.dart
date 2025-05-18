// lib/core/services/implementations/timezone_service_impl.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import '../interfaces/timezone_service.dart';

class TimezoneServiceImpl implements TimezoneService {
  bool _isInitialized = false;

  @override
  Future<void> initializeTimeZones() async {
    if (_isInitialized) return;
    
    // Inicializar las zonas horarias
    tz_data.initializeTimeZones();
    
    try {
      // Obtener la zona horaria local usando flutter_native_timezone_latest
      final String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
      
      debugPrint('Zona horaria detectada: $timeZoneName');
      
      // Establecer la zona horaria local
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error al configurar la zona horaria local: $e');
      // Fallback a detectar por offset si no se puede usar la biblioteca nativa
      try {
        final String timeZone = await _detectTimeZoneFromOffset();
        tz.setLocalLocation(tz.getLocation(timeZone));
      } catch (e2) {
        // Usar UTC como fallback final
        debugPrint('Error al detectar zona horaria por offset: $e2');
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      }
    }
    
    _isInitialized = true;
    debugPrint('TimezoneService inicializado. Zona horaria local: ${tz.local.name}');
  }

  @override
  Future<String> getLocalTimezone() async {
    try {
      // Intentar obtener la zona horaria con la biblioteca nativa
      return await FlutterNativeTimezoneLatest.getLocalTimezone();
    } catch (e) {
      debugPrint('Error al obtener zona horaria nativa: $e');
      return await _detectTimeZoneFromOffset();
    }
  }

  /// Método de respaldo para detectar la zona horaria basada en el offset
  Future<String> _detectTimeZoneFromOffset() async {
    final DateTime now = DateTime.now();
    final Duration offset = now.timeZoneOffset;
    
    // Mapa de offsets comunes a zonas horarias
    final Map<Duration, String> commonTimeZones = {
      const Duration(hours: 0): 'Etc/UTC',
      const Duration(hours: 1): 'Europe/Paris',
      const Duration(hours: 2): 'Europe/Cairo',
      const Duration(hours: 3): 'Asia/Riyadh',
      const Duration(hours: 4): 'Asia/Dubai',
      const Duration(hours: 5): 'Asia/Karachi',
      const Duration(hours: 5, minutes: 30): 'Asia/Kolkata',
      const Duration(hours: 6): 'Asia/Dhaka',
      const Duration(hours: 7): 'Asia/Bangkok',
      const Duration(hours: 8): 'Asia/Shanghai',
      const Duration(hours: 9): 'Asia/Tokyo',
      const Duration(hours: 10): 'Australia/Sydney',
      const Duration(hours: 11): 'Pacific/Noumea',
      const Duration(hours: 12): 'Pacific/Auckland',
      const Duration(hours: -1): 'Atlantic/Azores',
      const Duration(hours: -2): 'America/Noronha',
      const Duration(hours: -3): 'America/Sao_Paulo',
      const Duration(hours: -4): 'America/New_York',
      const Duration(hours: -5): 'America/Chicago',
      const Duration(hours: -6): 'America/Denver',
      const Duration(hours: -7): 'America/Los_Angeles',
      const Duration(hours: -8): 'Pacific/Honolulu',
      const Duration(hours: -9): 'Pacific/Marquesas',
      const Duration(hours: -10): 'Pacific/Samoa',
    };
    
    // Tratar de encontrar una coincidencia exacta
    if (commonTimeZones.containsKey(offset)) {
      return commonTimeZones[offset]!;
    }
    
    // Si no hay coincidencia exacta, buscar la más cercana
    var closestOffset = const Duration(hours: 0);
    var minDifference = const Duration(hours: 24);
    
    for (var tzOffset in commonTimeZones.keys) {
      final difference = Duration(
        microseconds: (offset.inMicroseconds - tzOffset.inMicroseconds).abs()
      );
      
      if (difference < minDifference) {
        minDifference = difference;
        closestOffset = tzOffset;
      }
    }
    
    return commonTimeZones[closestOffset] ?? 'Etc/UTC';
  }

  @override
  tz.TZDateTime getLocalTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  @override
  tz.TZDateTime nowLocal() {
    return tz.TZDateTime.now(tz.local);
  }

  @override
  tz.TZDateTime fromDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  @override
  tz.TZDateTime getNextDateTimeInstance(DateTime dateTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    if (scheduledDate.isBefore(now)) {
      // Si ya pasó, programar para el día siguiente
      if (dateTime.hour == 0 && dateTime.minute == 0) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else {
        final Duration difference = now.difference(scheduledDate);
        if (difference.inHours < 24) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        } else {
          final int daysToAdd = (difference.inHours / 24).ceil();
          scheduledDate = scheduledDate.add(Duration(days: daysToAdd));
        }
      }
    }

    return scheduledDate;
  }

  @override
  tz.TZDateTime getDateTimeInTimeZone(DateTime dateTime, String timeZoneId) {
    try {
      final location = tz.getLocation(timeZoneId);
      return tz.TZDateTime.from(dateTime, location);
    } catch (e) {
      debugPrint('Error al convertir a zona horaria $timeZoneId: $e');
      return getLocalTZDateTime(dateTime);
    }
  }
}
// lib/core/services/implementations/timezone_service_impl.dart
import 'dart:io';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../interfaces/timezone_service.dart';

class TimezoneServiceImpl implements TimezoneService {
  bool _isInitialized = false;

  @override
  Future<void> initializeTimeZones() async {
    if (!_isInitialized) {
      tz.initializeTimeZones();
      _isInitialized = true;
    }
  }

  @override
  Future<String> getLocalTimezone() async {
    try {
      // طريقة بسيطة للحصول على المنطقة الزمنية المحلية
      final String timezone = DateTime.now().timeZoneName;
      return timezone;
    } catch (e) {
      // في حالة حدوث خطأ، استخدم المنطقة الزمنية الافتراضية
      return 'UTC';
    }
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
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
// lib/core/services/implementations/timezone_service_impl.dart
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../interfaces/timezone_service.dart';

class TimezoneServiceImpl implements TimezoneService {
  bool _isInitialized = false;

  @override
  Future<void> initializeTimeZones() async {
    if (!_isInitialized) {
      tz_data.initializeTimeZones();
      _isInitialized = true;
    }
  }

  @override
  Future<String> getLocalTimezone() async {
    try {
      // محاولة الحصول على المنطقة الزمنية الحالية
      final String timezone = DateTime.now().timeZoneName;
      
      // التحقق مما إذا كانت المنطقة الزمنية معروفة في قائمة المناطق الزمنية المدعومة
      if (_isKnownTimeZone(timezone)) {
        return timezone;
      }
      
      // إذا لم تكن معروفة، محاولة استنتاج المنطقة الزمنية من فرق التوقيت
      final DateTime now = DateTime.now();
      final Duration offset = now.timeZoneOffset;
      
      // استنتاج المنطقة الزمنية من فرق التوقيت
      // مثال: إذا كان الفرق +3 ساعات، يمكن استنتاج أن المنطقة الزمنية هي 'Asia/Riyadh'
      final String inferredTimezone = _inferTimeZoneFromOffset(offset);
      return inferredTimezone;
    } catch (e) {
      // في حالة حدوث خطأ، استخدم المنطقة الزمنية الافتراضية
      return 'Etc/UTC';
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
      if (dateTime.hour == 0 && dateTime.minute == 0) {
        // إذا كان الوقت في منتصف الليل، أضف يومًا كاملًا
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else {
        // حساب ما إذا كان الفرق أقل من يوم (قد يكون بسبب تغيير التوقيت الصيفي)
        final Duration difference = now.difference(scheduledDate);
        if (difference.inHours < 24) {
          // إضافة يوم واحد
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        } else {
          // حساب عدد الأيام اللازمة للإضافة
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
      // إذا كانت المنطقة الزمنية غير معروفة، استخدم المنطقة الزمنية المحلية
      return getLocalTZDateTime(dateTime);
    }
  }

  // طريقة للتحقق مما إذا كانت المنطقة الزمنية معروفة
  bool _isKnownTimeZone(String timezone) {
    try {
      tz.getLocation(timezone);
      return true;
    } catch (e) {
      return false;
    }
  }

  // طريقة لاستنتاج المنطقة الزمنية من فرق التوقيت
  String _inferTimeZoneFromOffset(Duration offset) {
    // قائمة مختصرة من المناطق الزمنية المعروفة وفروق التوقيت الخاصة بها
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
    
    return commonTimeZones[offset] ?? 'Etc/UTC';
  }
}
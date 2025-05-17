// lib/core/services/interfaces/timezone_service.dart
import 'package:timezone/timezone.dart' as tz;

abstract class TimezoneService {
  /// تهيئة بيانات المناطق الزمنية
  Future<void> initializeTimeZones();
  
  /// الحصول على المنطقة الزمنية المحلية
  Future<String> getLocalTimezone();
  
  /// تحويل DateTime إلى TZDateTime في المنطقة الزمنية المحلية
  tz.TZDateTime getLocalTZDateTime(DateTime dateTime);
  
  /// الحصول على الوقت الحالي في المنطقة الزمنية المحلية
  tz.TZDateTime nowLocal();
  
  /// تحويل DateTime إلى TZDateTime
  tz.TZDateTime fromDateTime(DateTime dateTime);
  
  /// الحصول على الوقت التالي للجدولة مع مراعاة المنطقة الزمنية
  tz.TZDateTime getNextDateTimeInstance(DateTime dateTime);
  
  /// تحويل DateTime إلى TZDateTime في منطقة زمنية محددة
  tz.TZDateTime getDateTimeInTimeZone(DateTime dateTime, String timeZoneId);
}
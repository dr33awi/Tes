// lib/core/error/exceptions.dart
/// استثناء حدوث خطأ عام
class AppException implements Exception {
  final String message;
  
  AppException(this.message);
  
  @override
  String toString() => message;
}

/// استثناء فشل تحميل البيانات
class DataLoadException extends AppException {
  DataLoadException(String message) : super(message);
}

/// استثناء فشل تحديث البيانات
class DataUpdateException extends AppException {
  DataUpdateException(String message) : super(message);
}

/// استثناء البيانات غير موجودة
class DataNotFoundException extends AppException {
  DataNotFoundException(String message) : super(message);
}

/// استثناء فشل تحديد الموقع
class LocationException extends AppException {
  LocationException(String message) : super(message);
}

/// استثناء فشل خدمة الإشعارات
class NotificationException extends AppException {
  NotificationException(String message) : super(message);
}

/// استثناء فشل حساب مواقيت الصلاة
class PrayerTimesException extends AppException {
  PrayerTimesException(String message) : super(message);
}

/// استثناء فشل حساب اتجاه القبلة
class QiblaException extends AppException {
  QiblaException(String message) : super(message);
}

/// استثناء فشل خدمة التخزين المحلي
class StorageException extends AppException {
  StorageException(String message) : super(message);
}
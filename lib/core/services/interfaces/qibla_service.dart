
// lib/core/services/interfaces/qibla_service.dart
import 'dart:async';

abstract class QiblaService {
  /// الحصول على اتجاه القبلة بالدرجات (من 0 إلى 360)
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  });
  
  /// الحصول على تدفق البيانات لقراءات البوصلة
  Stream<double> getCompassStream();
  
  /// الحصول على زاوية اتجاه الجهاز الحالي نسبة للقبلة
  Stream<double> getQiblaDirectionStream({
    required double latitude,
    required double longitude,
  });
  
  /// تحديث موقع المستخدم
  Future<void> updateUserLocation(double latitude, double longitude);
  
  /// التحقق من توفر البوصلة على الجهاز
  Future<bool> isCompassAvailable();
  
  /// إلغاء الاشتراكات وتنظيف الموارد
  void dispose();
}
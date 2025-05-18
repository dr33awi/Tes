// lib/core/services/implementations/qibla_service_impl.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../interfaces/qibla_service.dart';

class QiblaServiceImpl implements QiblaService {
  static const double KAABA_LATITUDE = 21.422487;
  static const double KAABA_LONGITUDE = 39.826206;
  
  // استخدام متغيرات للتحكم في حالة الاشتراكات
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamController<double>? _qiblaStreamController;
  StreamController<double>? _compassStreamController;
  
  double _userLatitude = 0;
  double _userLongitude = 0;
  double _qiblaAngle = 0;
  bool _isDisposed = false;
  
  @override
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    _userLatitude = latitude;
    _userLongitude = longitude;
    
    final adhan.Coordinates coordinates = adhan.Coordinates(latitude, longitude);
    // استخدام الطريقة الصحيحة في الإصدار الجديد من المكتبة
    return adhan.Qibla(coordinates).direction;
  }
  
  @override
  Stream<double> getCompassStream() {
    if (_compassStreamController == null || _compassStreamController!.isClosed) {
      _compassStreamController = StreamController<double>.broadcast();
      
      // تعديل لاستخدام null safety
      if (FlutterCompass.events != null) {
        FlutterCompass.events!.listen((event) {
          if (!_isDisposed && event.heading != null) {
            _compassStreamController?.add(event.heading!);
          }
        }, onError: (e) {
          debugPrint('Error in compass stream: $e');
        }, cancelOnError: false);
      } else {
        // إضافة قيمة افتراضية إذا لم تكن البوصلة متوفرة
        _compassStreamController?.addError(Exception('Compass not available'));
      }
    }
    
    return _compassStreamController!.stream;
  }
  
  @override
  Stream<double> getQiblaDirectionStream({
    required double latitude,
    required double longitude,
  }) {
    if (_qiblaStreamController == null || _qiblaStreamController!.isClosed) {
      _qiblaStreamController = StreamController<double>.broadcast();
      
      // تحديث موقع المستخدم
      _userLatitude = latitude;
      _userLongitude = longitude;
      _calculateQiblaAngle();
      
      // استخدم تعريف متغير Stream ليتوافق مع نوع الاشتراك
      final Stream<CompassEvent>? compassStream = FlutterCompass.events;
      if (compassStream != null) {
        _compassSubscription = compassStream.listen((event) {
          if (!_isDisposed && event.heading != null) {
            double qiblaDirection = (_qiblaAngle - (event.heading ?? 0) + 360) % 360;
            _qiblaStreamController?.add(qiblaDirection);
          }
        }, onError: (e) {
          debugPrint('Error in qibla direction stream: $e');
          _qiblaStreamController?.addError(e);
        }, cancelOnError: false);
      } else {
        // إضافة قيمة افتراضية إذا لم تكن البوصلة متوفرة
        _qiblaStreamController?.addError(Exception('Compass not available'));
      }
    }
    
    return _qiblaStreamController!.stream;
  }
  
  void _calculateQiblaAngle() {
    _qiblaAngle = _calculateQiblaDirection(_userLatitude, _userLongitude, KAABA_LATITUDE, KAABA_LONGITUDE);
  }
  
  double _calculateQiblaDirection(double latitude, double longitude, double targetLatitude, double targetLongitude) {
    // استخدام مكتبة adhan لحساب اتجاه القبلة
    final adhan.Coordinates coordinates = adhan.Coordinates(latitude, longitude);
    // استخدام الطريقة الصحيحة في الإصدار الجديد من المكتبة
    return adhan.Qibla(coordinates).direction;
  }
  
  @override
  Future<bool> isCompassAvailable() async {
    try {
      // التحقق من توفر البوصلة بشكل فعلي
      final events = FlutterCompass.events;
      if (events == null) return false;
      
      // محاولة الحصول على قراءة واحدة خلال مهلة زمنية
      return await events.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Compass reading timed out'),
      ).then((_) => true).catchError((e) {
        debugPrint('Error checking compass: $e');
        return false;
      });
    } catch (e) {
      debugPrint('Error checking compass: $e');
      return false;
    }
  }
  
  // طريقة للتحديث إحداثيات المستخدم
  @override
  Future<void> updateUserLocation(double latitude, double longitude) async {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _calculateQiblaAngle();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    // إلغاء الاشتراك بالبوصلة وإغلاق جميع التدفقات
    _compassSubscription?.cancel();
    _compassSubscription = null;
    
    // إغلاق تدفقات البيانات
    if (_qiblaStreamController != null) {
      _qiblaStreamController!.close();
      _qiblaStreamController = null;
    }
    
    if (_compassStreamController != null) {
      _compassStreamController!.close();
      _compassStreamController = null;
    }
    
    debugPrint('QiblaService disposed');
  }
}
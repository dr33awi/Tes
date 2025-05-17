// lib/core/services/implementations/qibla_service_impl.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../interfaces/qibla_service.dart';

class QiblaServiceImpl implements QiblaService {
  static const double KAABA_LATITUDE = 21.422487;
  static const double KAABA_LONGITUDE = 39.826206;
  
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamController<double>? _qiblaStreamController;
  StreamController<double>? _compassStreamController;
  
  double _userLatitude = 0;
  double _userLongitude = 0;
  double _qiblaAngle = 0;
  
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
    if (_compassStreamController == null) {
      _compassStreamController = StreamController<double>.broadcast();
      
      // تعديل لاستخدام null safety
      if (FlutterCompass.events != null) {
        FlutterCompass.events!.listen((event) {
          if (event.heading != null) {
            _compassStreamController?.add(event.heading!);
          }
        });
      }
    }
    
    return _compassStreamController!.stream;
  }
  
  @override
  Stream<double> getQiblaDirectionStream({
    required double latitude,
    required double longitude,
  }) {
    if (_qiblaStreamController == null) {
      _qiblaStreamController = StreamController<double>.broadcast();
      
      // تحديث موقع المستخدم
      _userLatitude = latitude;
      _userLongitude = longitude;
      _calculateQiblaAngle();
      
      // استخدم تعريف متغير Stream ليتوافق مع نوع الاشتراك
      final Stream<CompassEvent>? compassStream = FlutterCompass.events;
      if (compassStream != null) {
        _compassSubscription = compassStream.listen((event) {
          if (event.heading != null) {
            double qiblaDirection = (_qiblaAngle - (event.heading ?? 0) + 360) % 360;
            _qiblaStreamController?.add(qiblaDirection);
          }
        });
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
    // استخدم null safety للتحقق من توفر البوصلة
    try {
      return await FlutterCompass.events?.first.then((_) => true) ?? false;
    } catch (_) {
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
    _compassSubscription?.cancel();
    _qiblaStreamController?.close();
    _qiblaStreamController = null;
    _compassStreamController?.close();
    _compassStreamController = null;
  }
}
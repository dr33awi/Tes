// lib/core/services/implementations/qibla_service_impl.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:vector_math/vector_math.dart';
import '../interfaces/qibla_service.dart';

class QiblaServiceImpl implements QiblaService {
  StreamController<double>? _qiblaStreamController;
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  @override
  Future<double> getQiblaDirection({
    required double latitude,
    required double longitude,
  }) async {
    final coordinates = Coordinates(latitude, longitude);
    final qiblaDirection = Qibla(coordinates).direction;
    
    return qiblaDirection;
  }
  
  @override
  Stream<double> getCompassStream() {
    if (!FlutterCompass.events.isBroadcast) {
      return FlutterCompass.events
          .where((event) => event.heading != null)
          .map((event) => event.heading!);
    } else {
      return FlutterCompass.events
          .asBroadcastStream()
          .where((event) => event.heading != null)
          .map((event) => event.heading!);
    }
  }
  
  @override
  Stream<double> getQiblaDirectionStream({
    required double latitude,
    required double longitude,
  }) {
    // إلغاء الاشتراك الحالي إذا كان موجوداً
    _disposeQiblaStream();
    
    // إنشاء تدفق بيانات جديد
    _qiblaStreamController = StreamController<double>.broadcast();
    
    // الحصول على اتجاه القبلة
    getQiblaDirection(latitude: latitude, longitude: longitude).then((qiblaAngle) {
      // الاشتراك في تدفق بيانات البوصلة
      _compassSubscription = getCompassStream().listen((compassAngle) {
        // حساب الفرق بين اتجاه البوصلة واتجاه القبلة
        final double angle = (qiblaAngle - compassAngle) % 360;
        
        // إرسال الزاوية المحسوبة إلى تدفق البيانات
        _qiblaStreamController?.add(angle);
      });
    });
    
    return _qiblaStreamController!.stream;
  }
  
  @override
  Future<bool> isCompassAvailable() async {
    return await FlutterCompass.events.first.then((_) => true).catchError((_) => false);
  }
  
  void _disposeQiblaStream() {
    _compassSubscription?.cancel();
    _qiblaStreamController?.close();
    _compassSubscription = null;
    _qiblaStreamController = null;
  }
}
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import '../interfaces/qibla_service.dart';

class QiblaServiceImpl implements QiblaService {
  static const double KAABA_LATITUDE = 21.422487;
  static const double KAABA_LONGITUDE = 39.826206;
  
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamController<double>? _qiblaStreamController;
  
  double _userLatitude = 0;
  double _userLongitude = 0;
  double _qiblaAngle = 0;
  
  @override
  Stream<double> getQiblaStream() {
    if (_qiblaStreamController == null) {
      _qiblaStreamController = StreamController<double>.broadcast();
      
      // تعديل لاستخدام null safety
      if (FlutterCompass.events?.isBroadcast != true) {
        FlutterCompass.events
            ?.where((event) => event.heading != null)
            .map((event) => event.heading!)
            .asBroadcastStream();
      }
      
      _startQiblaCalculation();
    }
    
    return _qiblaStreamController!.stream;
  }
  
  @override
  Future<void> updateUserLocation(double latitude, double longitude) async {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _calculateQiblaAngle();
  }
  
  void _startQiblaCalculation() {
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
  
  void _calculateQiblaAngle() {
    _qiblaAngle = _calculateQiblaDirection(_userLatitude, _userLongitude, KAABA_LATITUDE, KAABA_LONGITUDE);
  }
  
  double _calculateQiblaDirection(double latitude, double longitude, double targetLatitude, double targetLongitude) {
    // تحويل من درجات إلى راديان
    final double latRad = _degreesToRadians(latitude);
    final double longRad = _degreesToRadians(longitude);
    final double targetLatRad = _degreesToRadians(targetLatitude);
    final double targetLongRad = _degreesToRadians(targetLongitude);
    
    // صيغة حساب اتجاه القبلة
    final double y = math.sin(targetLongRad - longRad);
    final double x = math.cos(latRad) * math.tan(targetLatRad) - 
                     math.sin(latRad) * math.cos(targetLongRad - longRad);
    
    // تحويل من راديان إلى درجات
    double angle = _radiansToDegrees(math.atan2(y, x));
    
    // التأكد من أن الزاوية بين 0 و 360 درجة
    return (angle + 360) % 360;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  double _radiansToDegrees(double radians) {
    return radians * (180 / math.pi);
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
  
  @override
  void dispose() {
    _compassSubscription?.cancel();
    _qiblaStreamController?.close();
    _qiblaStreamController = null;
  }
}
// lib/presentation/blocs/prayers/prayer_times_provider.dart
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../../core/services/interfaces/prayer_times_service.dart';
import '../../../domain/entities/prayer_times.dart';
import '../../../domain/entities/settings.dart';
import '../../../domain/usecases/prayers/get_prayer_times.dart';
import '../../../domain/usecases/prayers/get_qibla_direction.dart';

class PrayerTimesProvider extends ChangeNotifier {
  final GetPrayerTimes _getPrayerTimes;
  final GetQiblaDirection _getQiblaDirection;
  
  PrayerTimes? _todayPrayerTimes;
  List<PrayerTimes>? _weekPrayerTimes;
  double? _qiblaDirection;
  
  bool _isLoading = false;
  String? _error;
  
  // موقع المستخدم
  double? _latitude;
  double? _longitude;
  
  PrayerTimesProvider({
    required GetPrayerTimes getPrayerTimes,
    required GetQiblaDirection getQiblaDirection,
  })  : _getPrayerTimes = getPrayerTimes,
        _getQiblaDirection = getQiblaDirection;
  
  // الحالة الحالية
  PrayerTimes? get todayPrayerTimes => _todayPrayerTimes;
  List<PrayerTimes>? get weekPrayerTimes => _weekPrayerTimes;
  double? get qiblaDirection => _qiblaDirection;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasLocation => _latitude != null && _longitude != null;
  
  // تعيين موقع المستخدم
  void setLocation({required double latitude, required double longitude}) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }
  
  // تحميل مواقيت الصلاة لليوم الحالي
  Future<void> loadTodayPrayerTimes(Settings settings) async {
    if (!hasLocation) {
      _error = 'Location not available';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // إنشاء معلمات حساب مواقيت الصلاة
      final params = PrayerTimesCalculationParams(
        calculationMethod: _getCalculationMethodName(settings.calculationMethod),
        adjustmentMinutes: 0,
        asrMethodIndex: settings.asrMethod,
      );
      
      // تحميل مواقيت اليوم
      _todayPrayerTimes = await _getPrayerTimes.getTodayPrayerTimes(
        params,
        latitude: _latitude!,
        longitude: _longitude!,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // تحميل مواقيت الصلاة للأسبوع الحالي
  Future<void> loadWeekPrayerTimes(Settings settings) async {
    if (!hasLocation) {
      _error = 'Location not available';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // إنشاء معلمات حساب مواقيت الصلاة
      final params = PrayerTimesCalculationParams(
        calculationMethod: _getCalculationMethodName(settings.calculationMethod),
        adjustmentMinutes: 0,
        asrMethodIndex: settings.asrMethod,
      );
      
      // إنشاء تاريخ بداية ونهاية الأسبوع
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 6));
      
      // تحميل مواقيت الأسبوع
      _weekPrayerTimes = await _getPrayerTimes.getPrayerTimesForRange(
        params: params,
        startDate: startDate,
        endDate: endDate,
        latitude: _latitude!,
        longitude: _longitude!,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // تحميل اتجاه القبلة
  Future<void> loadQiblaDirection() async {
    if (!hasLocation) {
      _error = 'Location not available';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _qiblaDirection = await _getQiblaDirection(
        latitude: _latitude!,
        longitude: _longitude!,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // إعادة تحميل البيانات
  Future<void> refreshData(Settings settings) async {
    await loadTodayPrayerTimes(settings);
    await loadWeekPrayerTimes(settings);
    await loadQiblaDirection();
  }
  
  // تحويل رقم طريقة الحساب إلى اسم الطريقة
  String _getCalculationMethodName(int methodIndex) {
    switch (methodIndex) {
      case 0:
        return 'karachi';
      case 1:
        return 'north_america';
      case 2:
        return 'muslim_world_league';
      case 3:
        return 'egyptian';
      case 4:
        return 'umm_al_qura';
      case 5:
        return 'dubai';
      case 6:
        return 'qatar';
      case 7:
        return 'kuwait';
      case 8:
        return 'singapore';
      case 9:
        return 'turkey';
      case 10:
        return 'tehran';
      default:
        return 'muslim_world_league';
    }
  }
}
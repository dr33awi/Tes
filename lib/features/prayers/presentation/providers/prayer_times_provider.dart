// lib/presentation/blocs/prayers/prayer_times_provider.dart
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../../../../core/services/interfaces/prayer_times_service.dart';
import '../../domain/entities/prayer_times.dart';
import '../../../settings/domain/entities/settings.dart';
import '../../domain/usecases/get_prayer_times.dart';
import '../../domain/usecases/get_qibla_direction.dart';

class PrayerTimesProvider extends ChangeNotifier {
  final GetPrayerTimes _getPrayerTimes;
  final GetQiblaDirection _getQiblaDirection;
  
  PrayerTimes? _todayPrayerTimes;
  List<PrayerTimes>? _weekPrayerTimes;
  double? _qiblaDirection;
  
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;
  
  // موقع المستخدم
  double? _latitude;
  double? _longitude;
  
  // خرائط لتتبع حالة التحميل
  final Map<String, bool> _loadingStatus = {};
  
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
  
  bool isOperationLoading(String operation) => _loadingStatus[operation] ?? false;
  
  // تعيين موقع المستخدم
  void setLocation({required double latitude, required double longitude}) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }
  
  // تحميل مواقيت الصلاة لليوم الحالي
  Future<void> loadTodayPrayerTimes(Settings settings) async {
    // التحقق من توفر الموقع ومنع التحميل المتكرر
    if (!hasLocation || isOperationLoading('todayPrayers') || _isDisposed) {
      if (!hasLocation) {
        _error = 'Location not available';
        notifyListeners();
      }
      return;
    }
    
    _loadingStatus['todayPrayers'] = true;
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
      
      // إضافة مهلة زمنية للعملية
      _todayPrayerTimes = await _getPrayerTimes.getTodayPrayerTimes(
        params,
        latitude: _latitude!,
        longitude: _longitude!,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Operation timed out'),
      );
      
      _loadingStatus['todayPrayers'] = false;
      _isLoading = _loadingStatus.values.any((isLoading) => isLoading);
      
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      _loadingStatus['todayPrayers'] = false;
      _isLoading = _loadingStatus.values.any((isLoading) => isLoading);
      _error = e.toString();
      
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
  
  // تحميل مواقيت الصلاة للأسبوع الحالي
  Future<void> loadWeekPrayerTimes(Settings settings) async {
    // التحقق من توفر الموقع ومنع التحميل المتكرر
    if (!hasLocation || isOperationLoading('weekPrayers') || _isDisposed) {
      if (!hasLocation) {
        _error = 'Location not available';
        notifyListeners();
      }
      return;
    }
    
    _loadingStatus['weekPrayers'] = true;
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
      
      // إضافة مهلة زمنية للعملية
      _weekPrayerTimes = await _getPrayerTimes.getPrayerTimesForRange(
        params: params,
        startDate: startDate,
        endDate: endDate,
        latitude: _latitude!,
        longitude: _longitude!,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Operation timed out'),
      );
      
      _loadingStatus['weekPrayers'] = false;
      _isLoading = _loadingStatus.values.any((isLoading) => isLoading);
      
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      _loadingStatus['weekPrayers'] = false;
      _isLoading = _loadingStatus.values.any((isLoading) => isLoading);
      _error = e.toString();
      
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
  
  // تحميل اتجاه القبلة
  Future<void> loadQiblaDirection() async {
    // التحقق من توفر الموقع ومنع التحميل المتكرر
    if (!hasLocation || isOperationLoading('qibla') || _isDisposed) {
      if (!hasLocation) {
        _error = 'Location not available';
        notifyListeners();
      }
      return;
    }
    
    _loadingStatus['qibla'] = true;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // إضافة مهلة زمنية للعملية
      _qiblaDirection = await _getQiblaDirection(
        latitude: _latitude!,
        longitude: _longitude!,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Operation timed out'),
      );
      
      _loadingStatus['qibla'] = false;
      _isLoading = _loadingStatus.values.any((isLoading) => isLoading);
      
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      _loadingStatus['qibla'] = false;
      _isLoading = _loadingStatus.values.any((isLoading) => isLoading);
      _error = e.toString();
      
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }
  
  // إعادة تحميل البيانات
  Future<void> refreshData(Settings settings) async {
    // إعادة تعيين حالة الخطأ
    _error = null;
    
    // تحميل جميع البيانات بشكل متوازٍ
    final futures = [
      loadTodayPrayerTimes(settings),
      loadWeekPrayerTimes(settings),
      loadQiblaDirection(),
    ];
    
    // الانتظار حتى اكتمال جميع العمليات
    await Future.wait(futures);
  }
  
  // التحميل الأولي (يُستخدم عند بدء التطبيق)
  Future<void> initialLoad(Settings settings) async {
    if (!hasLocation) return;
    
    // تحميل بيانات اليوم أولاً
    await loadTodayPrayerTimes(settings);
    
    // ثم تحميل باقي البيانات في الخلفية
    if (!_isDisposed) {
      // استخدام microtask لتجنب تعطيل واجهة المستخدم
      Future.microtask(() {
        loadQiblaDirection();
        loadWeekPrayerTimes(settings);
      });
    }
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
  
  // تنظيف الموارد عند التخلص من Provider
  @override
  void dispose() {
    _isDisposed = true;
    _loadingStatus.clear();
    super.dispose();
  }
}

// إضافة استثناء مخصص للمهلة الزمنية
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}
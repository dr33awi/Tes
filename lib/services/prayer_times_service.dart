// lib/services/prayer_times_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_times_model.dart';
import 'package:adhan/adhan.dart';

class PrayerTimesService {
  // Singleton pattern
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  // حفظ الإحداثيات والإعدادات
  double? _latitude;
  double? _longitude;
  String? _locationName;
  List<PrayerTimeModel>? _currentPrayerTimes;
  
  // إعدادات المستخدم
  String _calculationMethod = 'Umm al-Qura'; // القيمة الافتراضية
  String _madhab = 'Shafi'; // القيمة الافتراضية
  Map<String, int> _adjustments = {}; // للتعديلات اليدوية
  
  // مفاتيح مشتركة للتخزين المحلي
  static const String _calcMethodKey = 'prayer_calc_method';
  static const String _madhabKey = 'prayer_madhab';
  static const String _adjustmentsKey = 'prayer_adjustments';

  // تهيئة الخدمة وتحميل الإعدادات المحفوظة
  Future<void> initialize() async {
    await _loadSettings();
  }
  
  // تحميل الإعدادات من التخزين المحلي
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _calculationMethod = prefs.getString(_calcMethodKey) ?? 'Umm al-Qura';
      _madhab = prefs.getString(_madhabKey) ?? 'Shafi';
      
      final String? adjustmentsJson = prefs.getString(_adjustmentsKey);
      if (adjustmentsJson != null) {
        final Map<String, dynamic> decoded = json.decode(adjustmentsJson);
        _adjustments = decoded.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('Error loading prayer settings: $e');
      // استخدام القيم الافتراضية
      _calculationMethod = 'Umm al-Qura';
      _madhab = 'Shafi';
      _adjustments = {};
    }
  }

  // الحصول على مواقيت الصلاة من واجهة برمجة AlAdhan
  Future<List<PrayerTimeModel>> getPrayerTimesFromAPI({
    double? latitude,
    double? longitude,
    DateTime? date,
  }) async {
    try {
      // استخدام الإحداثيات المحفوظة إذا لم يتم توفير إحداثيات جديدة
      latitude = latitude ?? _latitude;
      longitude = longitude ?? _longitude;
      date = date ?? DateTime.now();

      // إذا لم تتوفر إحداثيات، حاول الحصول عليها
      if (latitude == null || longitude == null) {
        final position = await getCurrentLocation();
        if (position == null) {
          throw Exception('لا يمكن الحصول على الموقع');
        }
        latitude = position.latitude;
        longitude = position.longitude;
      }

      // حفظ الإحداثيات للاستخدام المستقبلي
      _latitude = latitude;
      _longitude = longitude;

      // تنسيق التاريخ للواجهة البرمجية
      final formattedDate = "${date.day}-${date.month}-${date.year}";
      
      // تحويل اسم طريقة الحساب إلى رقم للواجهة البرمجية
      int methodNumber = _getMethodNumber(_calculationMethod);
      
      // تحويل اسم المذهب إلى رقم للواجهة البرمجية
      int madhabNumber = _madhab == 'Hanafi' ? 1 : 0;
      
      // بناء عنوان الطلب (URL)
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$formattedDate?latitude=$latitude&longitude=$longitude&method=$methodNumber&school=$madhabNumber'
      );

      debugPrint('Requesting prayer times from: $url');

      // إرسال الطلب
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        // تحليل البيانات المستلمة
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> timings = data['data']['timings'];
        final Map<String, dynamic> meta = data['data']['meta'];
        
        // الحصول على اسم الموقع من البيانات الجغرافية إن وجدت
        if (data['data'].containsKey('meta') && 
            meta.containsKey('timezone')) {
          _locationName = meta['timezone'];
        } else {
          _locationName = 'موقعك الحالي';
        }
        
        // تحويل البيانات إلى قائمة من PrayerTimeModel
        final List<PrayerTimeModel> prayerTimes = _convertTimingsToPrayerModels(timings);
        
        // تطبيق التعديلات اليدوية إن وجدت
        _applyManualAdjustments(prayerTimes);
        
        // حفظ المواقيت الحالية
        _currentPrayerTimes = prayerTimes;
        return prayerTimes;
      } else {
        // في حالة فشل الطلب، استخدم الحساب المحلي كنسخة احتياطية
        debugPrint('فشل في الحصول على المواقيت من الواجهة البرمجية: ${response.statusCode}');
        return getPrayerTimesLocally(latitude: latitude, longitude: longitude, date: date);
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على المواقيت من الواجهة البرمجية: $e');
      // في حالة حدوث خطأ، استخدم الحساب المحلي كنسخة احتياطية
      return getPrayerTimesLocally(latitude: latitude, longitude: longitude, date: date);
    }
  }
  
  // تحويل اسم طريقة الحساب إلى رقم للواجهة البرمجية
  int _getMethodNumber(String methodName) {
    switch (methodName) {
      case 'Muslim World League':
        return 3;
      case 'Egyptian':
        return 5;
      case 'Karachi':
        return 1;
      case 'Umm al-Qura':
        return 4;
      case 'Dubai':
        return 8;
      case 'Qatar':
        return 9;
      case 'Kuwait':
        return 10;
      case 'Singapore':
        return 11;
      case 'North America':
        return 2;
      default:
        return 4; // Umm al-Qura كقيمة افتراضية
    }
  }

  // تحويل بيانات المواقيت من API إلى قائمة من PrayerTimeModel
  List<PrayerTimeModel> _convertTimingsToPrayerModels(Map<String, dynamic> timings) {
    // تحويل التنسيق من "HH:MM" إلى كائن DateTime
    DateTime _parseTime(String timeStr) {
      final now = DateTime.now();
      final parts = timeStr.split(':');
      return DateTime(
        now.year, 
        now.month, 
        now.day, 
        int.parse(parts[0]), 
        int.parse(parts[1])
      );
    }
    
    // إنشاء قائمة بالمواقيت
    final List<PrayerTimeModel> prayers = [
      PrayerTimeModel(
        name: 'الفجر',
        time: _parseTime(timings['Fajr']),
        icon: Icons.brightness_2,
        color: const Color(0xFF5B68D9),
      ),
      PrayerTimeModel(
        name: 'الشروق',
        time: _parseTime(timings['Sunrise']),
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFFF9E0D),
      ),
      PrayerTimeModel(
        name: 'الظهر',
        time: _parseTime(timings['Dhuhr']),
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFB746),
      ),
      PrayerTimeModel(
        name: 'العصر',
        time: _parseTime(timings['Asr']),
        icon: Icons.wb_twighlight,
        color: const Color(0xFFFF8A65),
      ),
      PrayerTimeModel(
        name: 'المغرب',
        time: _parseTime(timings['Maghrib']),
        icon: Icons.nights_stay_outlined,
        color: const Color(0xFF5C6BC0),
      ),
      PrayerTimeModel(
        name: 'العشاء',
        time: _parseTime(timings['Isha']),
        icon: Icons.nightlight_round,
        color: const Color(0xFF1A237E),
      ),
    ];

    // تحديد الصلاة التالية
    final now = DateTime.now();
    PrayerTimeModel? nextPrayer;
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
          nextPrayer = prayer;
        }
      }
    }

    if (nextPrayer != null) {
      final index = prayers.indexOf(nextPrayer);
      prayers[index] = PrayerTimeModel(
        name: nextPrayer.name,
        time: nextPrayer.time,
        icon: nextPrayer.icon,
        color: nextPrayer.color,
        isNext: true,
      );
    }

    return prayers;
  }

  // تطبيق التعديلات اليدوية
  void _applyManualAdjustments(List<PrayerTimeModel> prayerTimes) {
    if (_adjustments.isEmpty) return;
    
    for (int i = 0; i < prayerTimes.length; i++) {
      final prayer = prayerTimes[i];
      if (_adjustments.containsKey(prayer.name)) {
        final adjustment = _adjustments[prayer.name]!;
        final adjustedTime = prayer.time.add(Duration(minutes: adjustment));
        
        prayerTimes[i] = PrayerTimeModel(
          name: prayer.name,
          time: adjustedTime,
          icon: prayer.icon,
          color: prayer.color,
          isNext: prayer.isNext,
        );
      }
    }
  }

  // النسخة الاحتياطية: الحصول على أوقات الصلاة محلياً باستخدام مكتبة Adhan
  Future<List<PrayerTimeModel>> getPrayerTimesLocally({
    double? latitude,
    double? longitude,
    DateTime? date,
  }) async {
    try {
      // استخدام الإحداثيات المحفوظة إذا لم يتم توفير إحداثيات جديدة
      latitude = latitude ?? _latitude;
      longitude = longitude ?? _longitude;
      date = date ?? DateTime.now();

      // إذا لم تتوفر إحداثيات، حاول الحصول عليها
      if (latitude == null || longitude == null) {
        final position = await getCurrentLocation();
        if (position == null) {
          throw Exception('لا يمكن الحصول على الموقع');
        }
        latitude = position.latitude;
        longitude = position.longitude;
      }

      // إعداد المعلمات لحساب أوقات الصلاة
      final coordinates = Coordinates(latitude, longitude);
      
      // اختيار طريقة الحساب بناءً على إعدادات المستخدم
      CalculationParameters params;
      switch (_calculationMethod) {
        case 'Muslim World League':
          params = CalculationMethod.muslim_world_league.getParameters();
          break;
        case 'Egyptian':
          params = CalculationMethod.egyptian.getParameters();
          break;
        case 'Karachi':
          params = CalculationMethod.karachi.getParameters();
          break;
        case 'Umm al-Qura':
          params = CalculationMethod.umm_al_qura.getParameters();
          break;
        case 'Dubai':
          params = CalculationMethod.dubai.getParameters();
          break;
        case 'Qatar':
          params = CalculationMethod.qatar.getParameters();
          break;
        case 'Kuwait':
          params = CalculationMethod.kuwait.getParameters();
          break;
        case 'Singapore':
          params = CalculationMethod.singapore.getParameters();
          break;
        case 'North America':
          params = CalculationMethod.north_america.getParameters();
          break;
        default:
          params = CalculationMethod.other.getParameters();
          break;
      }
      
      // اختيار المذهب
      if (_madhab == 'Hanafi') {
        params.madhab = Madhab.hanafi;
      } else {
        params.madhab = Madhab.shafi;
      }
      
      final prayerTimes = PrayerTimes(
        coordinates,
        DateComponents.from(date),
        params,
      );

      // تحويل النتائج إلى نموذج PrayerTimeModel
      _currentPrayerTimes = PrayerTimeModel.fromPrayerTimes(prayerTimes);
      
      // تطبيق التعديلات اليدوية
      _applyManualAdjustments(_currentPrayerTimes!);
      
      return _currentPrayerTimes!;
    } catch (e) {
      debugPrint('خطأ في حساب أوقات الصلاة محلياً: $e');
      throw Exception('لا يمكن حساب مواقيت الصلاة: $e');
    }
  }

  // الحصول على الموقع الحالي - مع تحسينات لحل مشاكل الموقع
  Future<Position?> getCurrentLocation() async {
    try {
      // التحقق مما إذا كانت خدمات الموقع مفعلة
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // إذا كانت خدمات الموقع غير مفعلة، نحاول فتح الإعدادات
        await Geolocator.openLocationSettings();
        // انتظار فترة قصيرة لمنح المستخدم وقتًا لتفعيل الخدمة
        await Future.delayed(const Duration(seconds: 3));
        // نتحقق مرة أخرى
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('خدمات الموقع غير مفعلة');
          throw Exception('خدمات الموقع غير مفعلة، يرجى تفعيلها من إعدادات الجهاز');
        }
      }

      // التحقق من حالة الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // طلب الإذن إذا كان مرفوضاً
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('تم رفض إذن الوصول إلى الموقع');
          throw Exception('تم رفض إذن الوصول إلى الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // إذا كان الإذن مرفوضاً بشكل دائم، نخبر المستخدم بأنه يجب عليه تغيير الإعدادات يدوياً
        debugPrint('تم رفض إذن الوصول إلى الموقع بشكل دائم');
        await Geolocator.openAppSettings();
        throw Exception('تم رفض إذن الوصول إلى الموقع بشكل دائم. يرجى تمكينه من إعدادات التطبيق في هاتفك');
      }

      // محاولة الحصول على الموقع الحالي مع زيادة الدقة والوقت المسموح به
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationName = 'موقعك الحالي';
      
      debugPrint('تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('خطأ في الحصول على الموقع: $e');
      throw Exception('لا يمكن الحصول على الموقع: $e');
    }
  }

  // التحقق من حالة أذونات الموقع
  Future<bool> checkLocationPermission() async {
    try {
      // التحقق من حالة خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
      
      // التحقق من حالة الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('خطأ في التحقق من أذونات الموقع: $e');
      return false;
    }
  }

  // طلب أذونات الموقع بطريقة محسنة
  Future<bool> requestLocationPermission() async {
    try {
      // التحقق من حالة خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // محاولة فتح إعدادات الموقع
        await Geolocator.openLocationSettings();
        
        // انتظار قليلاً لمنح المستخدم وقتاً لتفعيل الخدمة
        await Future.delayed(const Duration(seconds: 3));
        
        // التحقق مرة أخرى
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return false;
        }
      }
      
      // التحقق من حالة الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // طلب الإذن
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // محاولة فتح إعدادات التطبيق
        await Geolocator.openAppSettings();
        return false;
      }
      
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('خطأ في طلب إذن الموقع: $e');
      return false;
    }
  }

  // تحديث طريقة الحساب
  void updateCalculationMethod(String method) {
    _calculationMethod = method;
  }
  
  // تحديث المذهب
  void updateMadhab(String madhab) {
    _madhab = madhab;
  }
  
  // إضافة تعديل يدوي لوقت صلاة
  void setAdjustment(String prayerName, int minutes) {
    _adjustments[prayerName] = minutes;
  }
  
  // مسح جميع التعديلات
  void clearAdjustments() {
    _adjustments.clear();
  }
  
  // الحصول على إعدادات المستخدم الحالية
  Map<String, dynamic> getUserSettings() {
    return {
      'calculationMethod': _calculationMethod,
      'madhab': _madhab,
      'adjustments': Map<String, int>.from(_adjustments),
    };
  }
  
  // حفظ الإعدادات
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_calcMethodKey, _calculationMethod);
      await prefs.setString(_madhabKey, _madhab);
      
      // تحويل التعديلات إلى JSON وحفظها
      final String adjustmentsJson = json.encode(_adjustments);
      await prefs.setString(_adjustmentsKey, adjustmentsJson);
      
      debugPrint('تم حفظ إعدادات مواقيت الصلاة بنجاح');
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات مواقيت الصلاة: $e');
    }
  }

  // الحصول على قائمة بطرق الحساب المتاحة
  List<String> getAvailableCalculationMethods() {
    return [
      'Muslim World League',
      'Egyptian',
      'Karachi',
      'Umm al-Qura',
      'Dubai',
      'Qatar',
      'Kuwait',
      'Singapore',
      'North America',
    ];
  }
  
  // الحصول على قائمة بالمذاهب المتاحة
  List<String> getAvailableMadhabs() {
    return ['Shafi', 'Hanafi'];
  }
  
  // الدالات الحالية  
  List<PrayerTimeModel>? get currentPrayerTimes => _currentPrayerTimes;
  String? get locationName => _locationName;
}
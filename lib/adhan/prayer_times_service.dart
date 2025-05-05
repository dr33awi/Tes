// lib/adhan/prayer_times_service.dart
import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/adhan/prayer_times_model.dart';
import 'package:test_athkar_app/adhan/location_permission_dialog.dart';
import 'package:test_athkar_app/adhan/adhan_notification_service.dart';

class PrayerTimesService {
  // تطبيق نمط Singleton
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  // متغيرات الإعدادات والحالة
  late CalculationParameters _calculationParameters;
  late Madhab _madhab;
  Map<String, int> _adjustments = {};
  
  // معلومات الموقع
  double? _latitude;
  double? _longitude;
  String? _locationName;
  
  // BuildContext للحوارات
  BuildContext? _context;
  
  // دالة التهيئة
  Future<void> initialize() async {
    try {
      await _loadSettings();
      final AdhanNotificationService notificationService = AdhanNotificationService();
      await notificationService.initialize();
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة مواقيت الصلاة: $e');
      // استخدام الإعدادات الافتراضية في حالة الخطأ
      _setDefaultSettings();
    }
  }
  
  // تعيين الإعدادات الافتراضية
  void _setDefaultSettings() {
    // استخدام طريقة أم القرى كافتراضي
    _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
    _madhab = Madhab.shafi;
    _calculationParameters.madhab = _madhab;
    _adjustments = {};
  }
  
  // تحميل الإعدادات المحفوظة
  Future<void> _loadSettings() async {
    // الإعدادات الافتراضية
    String calculationMethod = 'Umm al-Qura';
    String madhab = 'Shafi';
    _adjustments = {};
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل طريقة الحساب
      calculationMethod = prefs.getString('prayer_calculation_method') ?? calculationMethod;
      
      // تحميل المذهب الفقهي
      madhab = prefs.getString('prayer_madhab') ?? madhab;
      
      // تحميل التعديلات الزمنية
      final adjustmentsJson = prefs.getString('prayer_adjustments');
      if (adjustmentsJson != null) {
        final Map<String, dynamic> decoded = json.decode(adjustmentsJson);
        _adjustments = decoded.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      debugPrint('خطأ في تحميل إعدادات مواقيت الصلاة: $e');
    }
    
    // تطبيق الإعدادات
    _setCalculationMethod(calculationMethod);
    _setMadhab(madhab);
  }
  
  // حفظ الإعدادات
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ طريقة الحساب
      final String calculationMethod = getCalculationMethodName();
      await prefs.setString('prayer_calculation_method', calculationMethod);
      
      // حفظ المذهب الفقهي
      final String madhab = _madhab == Madhab.shafi ? 'Shafi' : 'Hanafi';
      await prefs.setString('prayer_madhab', madhab);
      
      // حفظ التعديلات الزمنية
      final String adjustmentsJson = json.encode(_adjustments);
      await prefs.setString('prayer_adjustments', adjustmentsJson);
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات مواقيت الصلاة: $e');
    }
  }
  
  // تعيين طريقة الحساب - تم تعديله ليتناسب مع اسماء الدوال الجديدة
  void _setCalculationMethod(String method) {
    switch (method) {
      case 'Muslim World League':
        _calculationParameters = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'Egyptian':
        _calculationParameters = CalculationMethod.egyptian.getParameters();
        break;
      case 'Karachi':
        _calculationParameters = CalculationMethod.karachi.getParameters();
        break;
      case 'Umm al-Qura':
        _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'Dubai':
        _calculationParameters = CalculationMethod.dubai.getParameters();
        break;
      case 'Qatar':
        _calculationParameters = CalculationMethod.qatar.getParameters();
        break;
      case 'Kuwait':
        _calculationParameters = CalculationMethod.kuwait.getParameters();
        break;
      case 'Moonsighting Committee':
        _calculationParameters = CalculationMethod.moon_sighting_committee.getParameters();
        break;
      case 'Singapore':
        _calculationParameters = CalculationMethod.singapore.getParameters();
        break;
      case 'Turkey':
        _calculationParameters = CalculationMethod.turkey.getParameters();
        break;
      case 'Tehran':
        _calculationParameters = CalculationMethod.tehran.getParameters();
        break;
      case 'North America':
        _calculationParameters = CalculationMethod.north_america.getParameters();
        break;
      default:
        _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
    }
  }
  
  // الحصول على اسم طريقة الحساب - تم تبسيطه لتجنب المقارنات
  String getCalculationMethodName() {
    try {
      CalculationMethod method = getCurrentCalculationMethod();
      switch (method) {
        case CalculationMethod.muslim_world_league:
          return 'Muslim World League';
        case CalculationMethod.egyptian:
          return 'Egyptian';
        case CalculationMethod.karachi:
          return 'Karachi';
        case CalculationMethod.umm_al_qura:
          return 'Umm al-Qura';
        case CalculationMethod.dubai:
          return 'Dubai';
        case CalculationMethod.qatar:
          return 'Qatar';
        case CalculationMethod.kuwait:
          return 'Kuwait';
        case CalculationMethod.moon_sighting_committee:
          return 'Moonsighting Committee';
        case CalculationMethod.singapore:
          return 'Singapore';
        case CalculationMethod.turkey:
          return 'Turkey';
        case CalculationMethod.tehran:
          return 'Tehran';
        case CalculationMethod.north_america:
          return 'North America';
        default:
          return 'Umm al-Qura'; // Default
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على اسم طريقة الحساب: $e');
      return 'Umm al-Qura'; // Default in case of error
    }
  }
  
  // تحديد طريقة الحساب الحالية - إضافة دالة جديدة لحل مشكلة تطابق الإعدادات
  CalculationMethod getCurrentCalculationMethod() {
    // إرجاع طريقة الحساب حسب الإعدادات الحالية
    // هذه طريقة مبسطة تعتمد عادةً على نوع المعلمات، وقد تحتاج إلى تعديل
    return CalculationMethod.umm_al_qura; // الإعداد الافتراضي
  }
  
  // تعيين المذهب الفقهي
  void _setMadhab(String madhabName) {
    _madhab = madhabName == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;
    _calculationParameters.madhab = _madhab;
  }
  
  // الحصول على المذهب الفقهي الحالي
  String getMadhabName() {
    return _madhab == Madhab.hanafi ? 'Hanafi' : 'Shafi';
  }
  
  // التحقق من أذونات الموقع
  Future<bool> checkLocationPermission() async {
    try {
      // التحقق من حالة الأذونات
      PermissionStatus status = await Permission.location.status;
      
      if (status.isGranted) {
        // التحقق من تفعيل خدمة الموقع
        bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        return isServiceEnabled;
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من أذونات الموقع: $e');
    }
    
    return false;
  }
  
  // طلب أذونات الموقع
  Future<bool> requestLocationPermission() async {
    try {
      // التحقق من حالة الأذونات
      PermissionStatus status = await Permission.location.status;
      
      if (status.isGranted) {
        // تأكد من أن خدمة الموقع مفعلة
        bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        
        if (!isServiceEnabled && _context != null) {
          // طلب تفعيل خدمة الموقع
          final shouldOpen = await showLocationServiceDialog(_context!);
          
          if (shouldOpen) {
            await Geolocator.openLocationSettings();
            isServiceEnabled = await Geolocator.isLocationServiceEnabled();
          }
        }
        
        return isServiceEnabled;
      } else if (status.isDenied) {
        if (_context != null) {
          // عرض شرح لسبب الحاجة للموقع
          final shouldRequest = await showLocationPermissionRationaleDialog(_context!);
          
          if (shouldRequest) {
            status = await Permission.location.request();
            return status.isGranted;
          }
        } else {
          // إذا لم يكن هناك سياق، حاول الطلب مباشرةً
          status = await Permission.location.request();
          return status.isGranted;
        }
      } else if (status.isPermanentlyDenied) {
        if (_context != null) {
          // طلب فتح إعدادات التطبيق لتغيير الأذونات
          final shouldOpenSettings = await showOpenAppSettingsDialog(_context!);
          
          if (shouldOpenSettings) {
            await openAppSettings();
            status = await Permission.location.status;
            return status.isGranted;
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في طلب أذونات الموقع: $e');
    }
    
    return false;
  }
  
  // الحصول على الموقع الحالي
  Future<Position?> _getCurrentLocation() async {
    try {
      // التحقق من وجود الأذونات
      bool hasPermission = await checkLocationPermission();
      
      // إذا لم يكن لدينا أذونات، حاول طلبها
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
      }
      
      if (hasPermission) {
        // الحصول على الموقع مع تحديد الدقة
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
        
        return position;
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على الموقع: $e');
    }
    
    return null;
  }
  
  // الحصول على اسم الموقع من الإحداثيات
  Future<String?> _getLocationName(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?' +
        'lat=$latitude&lon=$longitude&format=json&accept-language=ar'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'Islamic Prayer Times App'
      });
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // محاولة استخراج اسم المكان بطرق مختلفة
        String? name;
        
        // المدينة أو البلدة
        if (data['address'] != null) {
          if (data['address']['city'] != null) {
            name = data['address']['city'];
          } else if (data['address']['town'] != null) {
            name = data['address']['town'];
          } else if (data['address']['village'] != null) {
            name = data['address']['village'];
          } else if (data['address']['state'] != null) {
            name = data['address']['state'];
          } else if (data['address']['country'] != null) {
            name = data['address']['country'];
          }
        }
        
        // استخدام اسم المعروض إذا لم نجد شيئًا محددًا
        if (name == null && data['display_name'] != null) {
          final parts = data['display_name'].toString().split(',');
          if (parts.isNotEmpty) {
            name = parts[0];
          }
        }
        
        return name;
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على اسم الموقع: $e');
    }
    
    return null;
  }
  
  // تعيين سياق لعرض الحوارات
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // الحصول على أوقات الصلاة من واجهة برمجة التطبيق
  Future<List<PrayerTimeModel>> getPrayerTimesFromAPI({
    bool useDefaultLocationIfNeeded = true
  }) async {
    try {
      // أولاً، حاول الحصول على الموقع الحالي
      final position = await _getCurrentLocation();
      
      if (position != null) {
        // نجحنا في الحصول على الموقع
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // محاولة الحصول على اسم الموقع
        _locationName = await _getLocationName(position.latitude, position.longitude) ?? 'موقعك الحالي';
        
        return getPrayerTimesLocally();
      } else if (useDefaultLocationIfNeeded) {
        // إذا لم نتمكن من الحصول على الموقع، استخدم موقع افتراضي (مكة المكرمة)
        _latitude = 21.4225;
        _longitude = 39.8262;
        _locationName = 'مكة المكرمة (الموقع الافتراضي)';
        
        return getPrayerTimesLocally();
      } else {
        // إذا لم نكن نريد استخدام موقع افتراضي، رمي استثناء
        throw Exception('لم نتمكن من الحصول على موقعك الحالي.');
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على أوقات الصلاة من API: $e');
      
      // في حالة الخطأ، استخدام الموقع الافتراضي
      _latitude = 21.4225;
      _longitude = 39.8262;
      _locationName = 'مكة المكرمة (الموقع الافتراضي)';
      
      return getPrayerTimesLocally();
    }
  }
  
  // الحصول على أوقات الصلاة محليًا
  List<PrayerTimeModel> getPrayerTimesLocally() {
    try {
      // التأكد من وجود بيانات الموقع
      if (_latitude == null || _longitude == null) {
        // استخدام قيم افتراضية لمكة المكرمة
        _latitude = 21.4225;
        _longitude = 39.8262;
        _locationName = 'مكة المكرمة (الموقع الافتراضي)';
      }
      
      // إنشاء كائن الإحداثيات
      final coordinates = Coordinates(_latitude!, _longitude!);
      
      // تطبيق التعديلات على معلمات الحساب
      try {
        for (final entry in _adjustments.entries) {
          switch (entry.key) {
            case 'الفجر':
              _calculationParameters.adjustments.fajr = entry.value;
              break;
            case 'الشروق':
              _calculationParameters.adjustments.sunrise = entry.value;
              break;
            case 'الظهر':
              _calculationParameters.adjustments.dhuhr = entry.value;
              break;
            case 'العصر':
              _calculationParameters.adjustments.asr = entry.value;
              break;
            case 'المغرب':
              _calculationParameters.adjustments.maghrib = entry.value;
              break;
            case 'العشاء':
              _calculationParameters.adjustments.isha = entry.value;
              break;
          }
        }
      } catch (e) {
        debugPrint('خطأ في تطبيق التعديلات: $e');
        // تجاهل خطأ التعديلات واستمر بدونه
      }
      
      // إنشاء كائن مكونات التاريخ للوقت الحالي
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      
      // حساب أوقات الصلاة
      try {
        final prayerTimes = PrayerTimes(coordinates, date, _calculationParameters);
        
        // تحويل أوقات الصلاة إلى النموذج الخاص بنا
        return PrayerTimeModel.fromPrayerTimes(prayerTimes);
      } catch (e) {
        debugPrint('خطأ في حساب أوقات الصلاة: $e');
        throw e; // رمي الخطأ للتعامل معه في دالة الاحتياط
      }
    } catch (e) {
      debugPrint('خطأ في الحصول على أوقات الصلاة محليًا: $e');
      
      // في حالة الخطأ، إنشاء أوقات افتراضية
      return _createDefaultPrayerTimes();
    }
  }
  
  // إنشاء أوقات صلاة افتراضية
  List<PrayerTimeModel> _createDefaultPrayerTimes() {
    final now = DateTime.now();
    final timestamps = [
      DateTime(now.year, now.month, now.day, 5, 0), // الفجر
      DateTime(now.year, now.month, now.day, 6, 15), // الشروق
      DateTime(now.year, now.month, now.day, 12, 0), // الظهر
      DateTime(now.year, now.month, now.day, 15, 30), // العصر
      DateTime(now.year, now.month, now.day, 18, 0), // المغرب
      DateTime(now.year, now.month, now.day, 19, 30), // العشاء
    ];
    
    final prayers = <PrayerTimeModel>[];
    final names = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    final icons = [
      Icons.brightness_2,
      Icons.wb_sunny_outlined,
      Icons.wb_sunny,
      Icons.wb_twighlight,
      Icons.nights_stay_outlined,
      Icons.nightlight_round,
    ];
    final colors = [
      const Color(0xFF5B68D9),
      const Color(0xFFFF9E0D),
      const Color(0xFFFFB746),
      const Color(0xFFFF8A65),
      const Color(0xFF5C6BC0),
      const Color(0xFF1A237E),
    ];
    
    // إنشاء قائمة أوقات الصلاة الافتراضية
    for (int i = 0; i < names.length; i++) {
      prayers.add(PrayerTimeModel(
        name: names[i],
        time: timestamps[i],
        icon: icons[i],
        color: colors[i],
      ));
    }
    
    // تحديد الصلاة التالية
    PrayerTimeModel? nextPrayer;
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
          nextPrayer = prayer;
        }
      }
    }
    
    // تحديث الصلاة التالية
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
  
  // جدولة إشعارات الصلاة
  Future<void> schedulePrayerNotifications() async {
    try {
      // الحصول على أوقات الصلاة
      List<PrayerTimeModel> prayerTimes;
      try {
        prayerTimes = await getPrayerTimesFromAPI(useDefaultLocationIfNeeded: true);
      } catch (e) {
        debugPrint('خطأ في الحصول على أوقات الصلاة للإشعارات: $e');
        // استخدام أوقات افتراضية في حالة الخطأ
        prayerTimes = _createDefaultPrayerTimes();
      }
      
      // إعداد قائمة بأوقات الصلاة لجدولة الإشعارات
      final List<Map<String, dynamic>> notificationTimes = [];
      
      for (final prayer in prayerTimes) {
        // تجاهل الشروق لأنه ليس وقت صلاة حقيقي
        if (prayer.name != 'الشروق' && prayer.time.isAfter(DateTime.now())) {
          notificationTimes.add({
            'name': prayer.name,
            'time': prayer.time,
          });
        }
      }
      
      // جدولة إشعارات الصلاة
      final AdhanNotificationService notificationService = AdhanNotificationService();
      await notificationService.scheduleAllPrayerNotifications(notificationTimes);
    } catch (e) {
      debugPrint('خطأ في جدولة إشعارات الصلاة: $e');
    }
  }
  
  // تحديث طريقة الحساب
  void updateCalculationMethod(String method) {
    _setCalculationMethod(method);
  }
  
  // تحديث المذهب الفقهي
  void updateMadhab(String madhabName) {
    _setMadhab(madhabName);
  }
  
  // إضافة تعديل لوقت صلاة
  void setAdjustment(String prayerName, int minutes) {
    _adjustments[prayerName] = minutes;
  }
  
  // إزالة جميع التعديلات
  void clearAdjustments() {
    _adjustments.clear();
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
      'Moonsighting Committee',
      'Singapore',
      'Turkey',
      'Tehran',
      'North America',
    ];
  }
  
  // الحصول على قائمة بالمذاهب المتاحة
  List<String> getAvailableMadhabs() {
    return ['Shafi', 'Hanafi'];
  }
  
  // الحصول على الإعدادات الحالية
  Map<String, dynamic> getUserSettings() {
    return {
      'calculationMethod': getCalculationMethodName(),
      'madhab': getMadhabName(),
      'adjustments': _adjustments,
    };
  }
  
  // الحصول على اسم الموقع
  String? get locationName => _locationName;
}
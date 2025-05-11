// lib/services/battery_optimization_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// خدمة لإدارة إعدادات تحسين البطارية التي قد تؤثر على الإشعارات
class BatteryOptimizationService {
  // تنفيذ نمط Singleton مع التبعية المعكوسة
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  
  factory BatteryOptimizationService({
    ErrorLoggingService? errorLoggingService,
  }) {
    _instance._errorLoggingService = errorLoggingService ?? ErrorLoggingService();
    return _instance;
  }
  
  BatteryOptimizationService._internal();
  
  // التبعية المعكوسة
  late ErrorLoggingService _errorLoggingService;
  
  // مفاتيح التخزين المحلي
  static const String _keyBatteryOptimizationChecked = 'battery_optimization_checked';
  static const String _keyNeedsBatteryOptimization = 'needs_battery_optimization';
  static const String _keyLastCheckTime = 'battery_optimization_last_check';
  
  // قناة الطريقة للكود المخصص للمنصة
  static const platform = MethodChannel('com.athkar.app/battery_optimization');
  
  // كائن البطارية
  final Battery _battery = Battery();

  /// التحقق مما إذا كان تحسين البطارية مفعلًا للتطبيق
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // محاولة استخدام قناة الطريقة أولاً
      try {
        final bool? result = await platform.invokeMethod<bool>('isBatteryOptimizationEnabled');
        if (result != null) return result;
      } catch (e) {
        print('خطأ في قناة الطريقة: $e');
        // الرجوع إلى طرق أخرى
        await _errorLoggingService.logError(
          'BatteryOptimizationService', 
          'خطأ في التحقق من تحسين البطارية باستخدام قناة الطريقة', 
          e
        );
      }
      
      // التحقق مما إذا كان يمكننا اكتشاف وضع توفير الطاقة كبديل
      final isLowPowerMode = await _battery.isInBatterySaveMode;
      
      // هذا ليس مثاليًا، ولكن قد يعطي بعض المؤشرات
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ ما وجدناه
      await prefs.setBool(_keyNeedsBatteryOptimization, isLowPowerMode ?? false);
      
      return isLowPowerMode ?? false;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في التحقق من تحسين البطارية', 
        e
      );
      return false;
    }
  }

  /// طلب تعطيل تحسين البطارية
  Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // محاولة استخدام قناة الطريقة أولاً
      try {
        final bool? result = await platform.invokeMethod<bool>('requestBatteryOptimizationDisable');
        if (result != null) return result;
      } catch (e) {
        print('خطأ في قناة الطريقة: $e');
        // الرجوع إلى إعدادات التطبيق
        await _errorLoggingService.logError(
          'BatteryOptimizationService', 
          'خطأ في طلب تعطيل تحسين البطارية باستخدام قناة الطريقة', 
          e
        );
      }
      
      // فتح إعدادات تحسين البطارية - تم التصحيح هنا
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
      await _saveLastCheckTime();
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في طلب تعطيل تحسين البطارية', 
        e
      );
      return false;
    }
  }
  
  /// التحقق وفتح إعدادات البطارية إذا لزم الأمر
  Future<void> checkAndRequestBatteryOptimization(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      // التحقق فقط بشكل دوري
      if (!await shouldCheckBatteryOptimization()) {
        return;
      }
      
      final bool needsOptimization = await isBatteryOptimizationEnabled();
      if (needsOptimization) {
        showBatteryOptimizationDialog(context);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في checkAndRequestBatteryOptimization', 
        e
      );
    }
  }
  
  /// عرض حوار حول تحسين البطارية
  void showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحسين أداء الإشعارات'),
        content: const Text(
          'لضمان وصول إشعارات الأذكار بشكل منتظم، يرجى تعطيل وضع توفير البطارية للتطبيق.\n\n'
          'سيتم توجيهك إلى إعدادات البطارية، ثم اختر تطبيق الأذكار وحدد "عدم تحسين" أو "السماح في الخلفية".',
        ),
        actions: [
          TextButton(
            child: const Text('لاحقاً'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('فتح الإعدادات'),
            onPressed: () {
              Navigator.of(context).pop();
              _openBatterySettings();
            },
          ),
        ],
      ),
    );
  }
  
  /// فتح إعدادات البطارية مباشرة
  Future<void> _openBatterySettings() async {
    try {
      await requestDisableBatteryOptimization();
      await _saveLastCheckTime();
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في فتح إعدادات البطارية', 
        e
      );
      // الرجوع إلى إعدادات التطبيق
      AppSettings.openAppSettings();
    }
  }
  
  /// حفظ وقت آخر تحقق
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في حفظ وقت آخر تحقق من البطارية', 
        e
      );
    }
  }
  
  /// التحقق مما إذا كنا بحاجة لمطالبة المستخدم مرة أخرى (ليس بشكل متكرر جدًا)
  Future<bool> shouldCheckBatteryOptimization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_keyLastCheckTime) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // التحقق مرة واحدة فقط في الأسبوع (604800000 مللي ثانية)
      return (now - lastCheckTime) > 604800000;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في التحقق مما إذا كان يجب مطالبة تحسين البطارية', 
        e
      );
      return false;
    }
  }
  
  /// التحقق من قيود البطارية الإضافية التي قد تؤثر على الإشعارات
  Future<void> checkForAdditionalBatteryRestrictions(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      final manufacturer = await _getDeviceManufacturer();
      if (_isManufacturerWithSpecialRestrictions(manufacturer)) {
        _showManufacturerSpecificBatteryDialog(context, manufacturer);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في التحقق من قيود البطارية الإضافية', 
        e
      );
    }
  }
  
  /// الحصول على مصنع الجهاز (مبسط)
  Future<String> _getDeviceManufacturer() async {
    try {
      // deviceInfo غير متوفر في battery_plus، استخدم قناة platform أو الافتراضي "unknown"
      // يمكن تحسين هذا باستخدام device_info_plus package
      return "unknown";
    } catch (e) {
      return "unknown";
    }
  }
  
  /// التحقق مما إذا كان المصنع لديه قيود بطارية خاصة
  bool _isManufacturerWithSpecialRestrictions(String manufacturer) {
    final restrictiveManufacturers = [
      "xiaomi", "redmi", "poco", "huawei", "honor", "oppo", "vivo", "oneplus", "realme", "samsung"
    ];
    
    return restrictiveManufacturers.any(
      (brand) => manufacturer.toLowerCase().contains(brand)
    );
  }
  
  /// عرض حوار بتعليمات خاصة بالمصنع
  void _showManufacturerSpecificBatteryDialog(BuildContext context, String manufacturer) {
    String instructions = _getManufacturerSpecificInstructions(manufacturer);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات إضافية مطلوبة'),
        content: Text(instructions),
        actions: [
          TextButton(
            child: const Text('لاحقاً'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('فتح الإعدادات'),
            onPressed: () {
              Navigator.of(context).pop();
              AppSettings.openAppSettings();
            },
          ),
        ],
      ),
    );
  }
  
  /// الحصول على تعليمات خاصة بالمصنع
  String _getManufacturerSpecificInstructions(String manufacturer) {
    if (manufacturer.toLowerCase().contains("xiaomi") || 
        manufacturer.toLowerCase().contains("redmi") || 
        manufacturer.toLowerCase().contains("poco")) {
      return 'أجهزة شاومي/ريدمي/بوكو لديها إعدادات بطارية خاصة:\n\n'
             '1. افتح "الإعدادات" ثم "البطارية والأداء"\n'
             '2. اختر "توفير البطارية للتطبيقات"\n'
             '3. ابحث عن تطبيق الأذكار\n'
             '4. اختر "لا قيود" وفعّل "السماح بالتشغيل في الخلفية"';
    } else if (manufacturer.toLowerCase().contains("samsung")) {
      return 'أجهزة سامسونج لديها إعدادات بطارية خاصة:\n\n'
             '1. افتح "الإعدادات" ثم "الرعاية المتقدمة" أو "تحسين البطارية"\n'
             '2. اختر "البطارية" ثم "حدود استخدام البطارية في الخلفية"\n'
             '3. ابحث عن تطبيق الأذكار\n'
             '4. اختر "السماح بالاستخدام في الخلفية"';
    } else if (manufacturer.toLowerCase().contains("huawei") || 
               manufacturer.toLowerCase().contains("honor")) {
      return 'أجهزة هواوي/أونور لديها إعدادات بطارية خاصة:\n\n'
             '1. افتح "الإعدادات" ثم "البطارية"\n'
             '2. اختر "إدارة تشغيل التطبيقات" أو "التشغيل التلقائي"\n'
             '3. ابحث عن تطبيق الأذكار\n'
             '4. فعّل "التشغيل التلقائي" و"تشغيل في الخلفية"';
    } else if (manufacturer.toLowerCase().contains("oppo") || 
               manufacturer.toLowerCase().contains("realme") || 
               manufacturer.toLowerCase().contains("vivo") ||
               manufacturer.toLowerCase().contains("oneplus")) {
      return 'أجهزة أوبو/ريلمي/فيفو/ون بلس لديها إعدادات بطارية خاصة:\n\n'
             '1. افتح "الإعدادات" ثم "البطارية"\n'
             '2. اختر "تحسين البطارية" أو "توفير الطاقة للتطبيقات"\n'
             '3. ابحث عن تطبيق الأذكار\n'
             '4. اختر "لا تحسين" و"السماح بالتشغيل في الخلفية"';
    } else {
      return 'بعض أجهزة الأندرويد لديها إعدادات بطارية خاصة قد تؤثر على الإشعارات.\n\n'
             'يرجى التأكد من:\n'
             '1. تعطيل "توفير البطارية" للتطبيق\n'
             '2. السماح بتشغيل التطبيق في الخلفية\n'
             '3. السماح بالبدء التلقائي للتطبيق (إن وجد)';
    }
  }
}
// lib/services/battery_optimization_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// فئة بيانات لتعليمات الشركة المصنعة
class ManufacturerInstructions {
  final String name;
  final String instructions;
  final List<String> keywords;
  final String settingsPath;
  
  const ManufacturerInstructions({
    required this.name,
    required this.instructions,
    required this.keywords,
    required this.settingsPath,
  });
}

/// خدمة لإدارة إعدادات تحسين البطارية
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
  
  // التبعيات
  late ErrorLoggingService _errorLoggingService;
  
  // الثوابت لتخزين البيانات محلياً
  static const String _keyBatteryOptimizationChecked = 'battery_optimization_checked';
  static const String _keyNeedsBatteryOptimization = 'needs_battery_optimization';
  static const String _keyLastCheckTime = 'battery_optimization_last_check';
  static const String _keyDeviceManufacturer = 'device_manufacturer';
  static const String _keyDeviceModel = 'device_model';
  static const String _keyUserDismissed = 'battery_optimization_dismissed';
  
  // قناة الاتصال مع الكود الأصلي
  static const platform = MethodChannel('com.athkar.app/battery_optimization');
  
  // كائن البطارية
  final Battery _battery = Battery();
  
  // كائن معلومات الجهاز للكشف الأفضل عن الجهاز
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // اسم التطبيق للتنبيهات
  String _appName = "Athkar App";
  
  // قائمة الشركات المصنعة المعروفة وتعليماتها
  final List<ManufacturerInstructions> _manufacturers = [
    ManufacturerInstructions(
      name: "Xiaomi",
      keywords: ["xiaomi", "redmi", "poco"],
      instructions: 
        '1. افتح "الإعدادات" > "البطارية والأداء"\n'
        '2. اختر "توفير البطارية للتطبيقات"\n'
        '3. ابحث عن {APP_NAME}\n'
        '4. اختر "بدون قيود" وفعّل "التشغيل في الخلفية"',
      settingsPath: "الإعدادات > البطارية والأداء > توفير البطارية للتطبيقات",
    ),
    ManufacturerInstructions(
      name: "Samsung",
      keywords: ["samsung"],
      instructions: 
        '1. افتح "الإعدادات" > "البطارية"\n'
        '2. اختر "استخدام البطارية" أو "وضع توفير الطاقة"\n'
        '3. ابحث عن {APP_NAME}\n'
        '4. اختر "غير مقيد" تحت التشغيل في الخلفية',
      settingsPath: "الإعدادات > البطارية > استخدام البطارية",
    ),
    ManufacturerInstructions(
      name: "Huawei",
      keywords: ["huawei", "honor"],
      instructions: 
        '1. افتح "الإعدادات" > "البطارية"\n'
        '2. اختر "تشغيل التطبيقات" أو "التطبيقات المحمية"\n'
        '3. ابحث عن {APP_NAME}\n'
        '4. فعّل كلاً من "التشغيل التلقائي" و"التشغيل في الخلفية"',
      settingsPath: "الإعدادات > البطارية > تشغيل التطبيقات",
    ),
    ManufacturerInstructions(
      name: "Oppo/Realme/Vivo/OnePlus",
      keywords: ["oppo", "realme", "vivo", "oneplus"],
      instructions: 
        '1. افتح "الإعدادات" > "البطارية"\n'
        '2. اختر "تحسين البطارية" أو "الأنشطة في الخلفية"\n'
        '3. ابحث عن {APP_NAME}\n'
        '4. اختر "بدون تحسين" و"السماح بالتشغيل في الخلفية"',
      settingsPath: "الإعدادات > البطارية > تحسين البطارية",
    ),
  ];
  
  /// تهيئة الخدمة
  Future<void> initialize() async {
    try {
      // تحميل معلومات التطبيق
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      
      // حفظ معلومات الجهاز
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyDeviceManufacturer, androidInfo.manufacturer.toLowerCase());
        await prefs.setString(_keyDeviceModel, androidInfo.model.toLowerCase());
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService',
        'خطأ في التهيئة',
        e
      );
    }
  }

  /// فحص ما إذا كانت تحسينات البطارية مفعلة للتطبيق
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // محاولة استخدام قناة الاتصال أولاً
      try {
        final bool? result = await platform.invokeMethod<bool>('isBatteryOptimizationEnabled');
        if (result != null) return result;
      } catch (e) {
        print('خطأ في قناة الاتصال: $e');
        await _errorLoggingService.logError(
          'BatteryOptimizationService', 
          'خطأ في التحقق من تحسين البطارية عبر قناة الاتصال', 
          e
        );
      }
      
      // فحص ما إذا كان وضع توفير الطاقة مفعلاً كبديل
      final isLowPowerMode = await _battery.isInBatterySaveMode;
      
      // هذا ليس مثالياً ولكن يمكن أن يعطي مؤشرات
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ النتيجة
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

  /// طلب من المستخدم تعطيل تحسينات البطارية
  Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // محاولة استخدام قناة الاتصال أولاً
      try {
        final bool? result = await platform.invokeMethod<bool>('requestBatteryOptimizationDisable');
        if (result != null) return result;
      } catch (e) {
        print('خطأ في قناة الاتصال: $e');
        await _errorLoggingService.logError(
          'BatteryOptimizationService', 
          'خطأ في إلغاء تفعيل تحسين البطارية عبر قناة الاتصال', 
          e
        );
      }
      
      // فتح إعدادات البطارية
      await AppSettings.openAppSettings();
      await _saveLastCheckTime();
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في طلب إلغاء تحسين البطارية', 
        e
      );
      return false;
    }
  }
  
  /// فحص وطلب تحسينات البطارية إذا لزم الأمر
  Future<void> checkAndRequestBatteryOptimization(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      // فحص دوري فقط
      if (!await shouldCheckBatteryOptimization()) {
        return;
      }
      
      // فحص ما إذا كان المستخدم قد رفض هذا التحذير بالفعل
      final prefs = await SharedPreferences.getInstance();
      final userDismissed = prefs.getBool(_keyUserDismissed) ?? false;
      
      if (userDismissed) {
        // إذا رفض المستخدم التحذير، فحص نادر فقط (مرة في الشهر)
        final lastCheckTime = prefs.getInt(_keyLastCheckTime) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // 30 يوماً (بالميلي ثانية) 
        if (now - lastCheckTime < 30 * 24 * 60 * 60 * 1000) {
          return;
        }
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
  
  /// عرض نافذة حوار تحسينات البطارية
  void showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text('تحسين الإشعارات')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'للحصول على إشعارات موثوقة للأذكار، يُنصح بإلغاء تفعيل وضع توفير البطارية لهذا التطبيق.\n\n'
              'سيتم توجيهك إلى إعدادات البطارية. اختر "$_appName" وألغِ تفعيل تحسين البطارية.',
            ),
            SizedBox(height: 12),
            _buildManufacturerSpecificNote(),
          ],
        ),
        actions: [
          TextButton(
            child: Text('ليس الآن'),
            onPressed: () {
              _markUserDismissed();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('عدم الإظهار مجدداً'),
            onPressed: () {
              _markUserDismissedPermanently();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('فتح الإعدادات'),
            onPressed: () {
              Navigator.of(context).pop();
              _openBatterySettings();
            },
          ),
        ],
      ),
    );
  }
  
  /// إنشاء ملاحظة خاصة بالشركة المصنعة
  Widget _buildManufacturerSpecificNote() {
    return FutureBuilder<String>(
      future: _getDeviceManufacturer(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final manufacturer = snapshot.data!;
          final matchingInstructions = _getManufacturerInstructions(manufacturer);
          
          if (matchingInstructions != null) {
            final instructions = matchingInstructions.instructions.replaceAll('{APP_NAME}', _appName);
            
            return Card(
              margin: EdgeInsets.only(top: 16),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لأجهزة ${matchingInstructions.name}:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(instructions),
                  ],
                ),
              ),
            );
          }
        }
        
        return SizedBox.shrink();
      },
    );
  }
  
  /// وضع علامة على أن المستخدم رفض الحوار
  Future<void> _markUserDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserDismissed, true);
      await _saveLastCheckTime();
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في تسجيل رفض المستخدم', 
        e
      );
    }
  }
  
  /// وضع علامة على أن المستخدم رفض الحوار بشكل دائم
  Future<void> _markUserDismissedPermanently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserDismissed, true);
      
      // تعيين وقت الفحص الأخير لتاريخ بعيد جداً في المستقبل
      final farFuture = DateTime.now().add(Duration(days: 365)).millisecondsSinceEpoch;
      await prefs.setInt(_keyLastCheckTime, farFuture);
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في تسجيل الرفض الدائم للمستخدم', 
        e
      );
    }
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
      // البديل هو فتح إعدادات التطبيق
      AppSettings.openAppSettings();
    }
  }
  
  /// حفظ وقت آخر فحص
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في حفظ وقت الفحص الأخير', 
        e
      );
    }
  }
  
  /// فحص ما إذا كان يجب أن نسأل المستخدم مرة أخرى (ليس بشكل متكرر جداً)
  Future<bool> shouldCheckBatteryOptimization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_keyLastCheckTime) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // فحص مرة واحدة فقط كل أسبوع (604800000 ميلي ثانية)
      return (now - lastCheckTime) > 604800000;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في التحقق من ضرورة فحص تحسين البطارية', 
        e
      );
      return false;
    }
  }
  
  /// فحص القيود الإضافية للبطارية التي قد تؤثر على الإشعارات
  Future<void> checkForAdditionalBatteryRestrictions(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      // فحص دوري فقط
      if (!await shouldCheckBatteryOptimization()) {
        return;
      }
      
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
  
  /// تحديد الشركة المصنعة للجهاز بدقة أكبر
  Future<String> _getDeviceManufacturer() async {
    try {
      // استرجاع من البيانات المحفوظة
      final prefs = await SharedPreferences.getInstance();
      final manufacturer = prefs.getString(_keyDeviceManufacturer);
      
      if (manufacturer != null && manufacturer.isNotEmpty) {
        return manufacturer;
      }
      
      // البديل: استرجاع جديد
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final newManufacturer = androidInfo.manufacturer.toLowerCase();
        
        // حفظ للاستخدام المستقبلي
        await prefs.setString(_keyDeviceManufacturer, newManufacturer);
        
        return newManufacturer;
      }
      
      return "unknown";
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في تحديد مُصنِّع الجهاز', 
        e
      );
      return "unknown";
    }
  }
  
  /// فحص ما إذا كانت الشركة المصنعة لديها قيود خاصة
  bool _isManufacturerWithSpecialRestrictions(String manufacturer) {
    return _manufacturers.any(
      (m) => m.keywords.any((keyword) => manufacturer.toLowerCase().contains(keyword))
    );
  }
  
  /// الحصول على تعليمات خاصة بالشركة المصنعة
  ManufacturerInstructions? _getManufacturerInstructions(String manufacturer) {
    for (var m in _manufacturers) {
      if (m.keywords.any((keyword) => manufacturer.toLowerCase().contains(keyword))) {
        return m;
      }
    }
    return null;
  }
  
  /// عرض حوار خاص بالشركة المصنعة
  void _showManufacturerSpecificBatteryDialog(BuildContext context, String manufacturer) {
    final instructions = _getManufacturerInstructions(manufacturer);
    
    if (instructions == null) return;
    
    final displayInstructions = instructions.instructions.replaceAll('{APP_NAME}', _appName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 10),
            Expanded(child: Text('إعدادات إضافية مطلوبة')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لأجهزة ${instructions.name}:'),
            SizedBox(height: 8),
            Text(displayInstructions),
            SizedBox(height: 16),
            Text(
              'هذه الإعدادات مهمة لضمان وصول الإشعارات بشكل موثوق.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('لاحقاً'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('فتح الإعدادات'),
            onPressed: () {
              Navigator.of(context).pop();
              _openManufacturerSpecificSettings(manufacturer);
            },
          ),
        ],
      ),
    );
  }
  
  /// فتح إعدادات خاصة بالشركة المصنعة
  Future<void> _openManufacturerSpecificSettings(String manufacturer) async {
    try {
      // محاولة فتح شاشات إعدادات محددة
      // هذا يتطلب تنفيذاً أصلياً إضافياً
      
      try {
        final result = await platform.invokeMethod<bool>(
          'openManufacturerSpecificSettings',
          {'manufacturer': manufacturer}
        );
        
        if (result == true) {
          // تم الفتح بنجاح
          await _saveLastCheckTime();
          return;
        }
      } catch (e) {
        print('خطأ في قناة الاتصال: $e');
      }
      
      // البديل: فتح إعدادات البطارية
      await AppSettings.openAppSettings();
      await _saveLastCheckTime();
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'خطأ في فتح إعدادات الشركة المصنعة', 
        e
      );
      // البديل هو إعدادات التطبيق العامة
      AppSettings.openAppSettings();
    }
  }
}
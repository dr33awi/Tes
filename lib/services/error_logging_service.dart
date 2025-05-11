// lib/services/error_logging_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// خدمة للتعامل مع تسجيل الأخطاء وتتبعها
class ErrorLoggingService {
  // تنفيذ نمط Singleton
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  // مفاتيح التخزين المحلي
  static const String _keyErrorLog = 'error_log';
  static const String _keyErrorStats = 'error_stats';
  static const int _maxErrors = 100; // الحد الأقصى لعدد الأخطاء للتخزين
  
  // كائنات هامة
  late Logger _logger;
  late FlutterSecureStorage _secureStorage;
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _deviceInfo;
  
  // معلومات التطبيق والجهاز
  String get appVersion => _packageInfo?.version ?? 'unknown';
  String get appBuildNumber => _packageInfo?.buildNumber ?? 'unknown';
  
  /// تهيئة خدمة تسجيل الأخطاء
  Future<void> initialize() async {
    _initLogger();
    _secureStorage = const FlutterSecureStorage();
    
    await _initPackageInfo();
    await _initDeviceInfo();
  }
  
  // تهيئة Logger
  void _initLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: Level.debug,
    );
  }
  
  // تهيئة معلومات التطبيق
  Future<void> _initPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      print('خطأ في تهيئة معلومات التطبيق: $e');
    }
  }
  
  // تهيئة معلومات الجهاز
  Future<void> _initDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      _deviceInfo = {};
      
      if (Theme.of(GlobalKey<NavigatorState>().currentContext!).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceInfo = {
          'device': androidInfo.device,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Theme.of(GlobalKey<NavigatorState>().currentContext!).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceInfo = {
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }
    } catch (e) {
      print('خطأ في تهيئة معلومات الجهاز: $e');
    }
  }
  
  /// تسجيل خطأ مع السياق
  Future<void> logError(
    String source,
    String message,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    stackTrace = stackTrace ?? StackTrace.current;
    
    // الطباعة في وحدة التحكم
    _logger.e("$source: $message\nError: $error\nStackTrace: $stackTrace");
    
    try {
      // تحسين فئة شدة الخطأ بناءً على السياق
      final ErrorSeverity severity = _determineSeverity(source, message, error);
      
      // إنشاء كائن الخطأ المحسّن
      final errorObj = {
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
        'message': message,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
        'severity': severity.toString(),
        'appVersion': appVersion,
        'buildNumber': appBuildNumber,
        'deviceInfo': _deviceInfo,
        'additionalData': additionalData,
      };
      
      // الحفظ بطريقة آمنة
      await _securelyStoreError(errorObj);
      
      // تحديث إحصائيات الأخطاء
      await _updateErrorStats(source, severity);
      
      // إرسال الخطأ للخدمة السحابية إذا كان خطيرًا
      if (severity == ErrorSeverity.critical || severity == ErrorSeverity.fatal) {
        await _syncErrorsToCloud();
      }
    } catch (e) {
      // إذا فشل تسجيل الأخطاء، على الأقل الطباعة في وحدة التحكم
      print('فشل تسجيل الأخطاء: $e');
    }
  }
  
  /// تحديد شدة الخطأ بناءً على السياق
  ErrorSeverity _determineSeverity(String source, String message, dynamic error) {
    // الأخطاء المتعلقة بالإشعارات حرجة لأنها تؤثر على وظيفة التطبيق الأساسية
    if (source.toLowerCase().contains('notification') || 
        message.toLowerCase().contains('notification')) {
      return ErrorSeverity.critical;
    }
    
    // أخطاء التهيئة خطيرة ولكن قد لا تكون مميتة
    if (source.toLowerCase().contains('initializer') || 
        message.toLowerCase().contains('initialize')) {
      return ErrorSeverity.high;
    }
    
    // الأخطاء الجذرية حسب النوع
    if (error is TypeError || error is ArgumentError) {
      return ErrorSeverity.high;
    } else if (error is NetworkException) {
      return ErrorSeverity.medium;
    }
    
    // الافتراضي
    return ErrorSeverity.low;
  }
  
  /// حفظ الخطأ بطريقة آمنة
  Future<void> _securelyStoreError(Map<String, dynamic> errorObj) async {
    try {
      // الحصول على الأخطاء الموجودة
      List<dynamic> errors = [];
      final String? storedErrors = await _secureStorage.read(key: _keyErrorLog);
      
      if (storedErrors != null) {
        errors = jsonDecode(storedErrors);
      }
      
      // إضافة خطأ جديد وتحديد عدد الأخطاء المخزنة
      errors.add(errorObj);
      if (errors.length > _maxErrors) {
        errors = errors.sublist(errors.length - _maxErrors);
      }
      
      // الحفظ في التخزين الآمن
      await _secureStorage.write(
        key: _keyErrorLog,
        value: jsonEncode(errors),
      );
    } catch (e) {
      print('خطأ في حفظ سجل الأخطاء بطريقة آمنة: $e');
      
      // الرجوع إلى SharedPreferences في حالة الفشل
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // الحصول على الأخطاء الموجودة
        List<dynamic> errors = [];
        final String? storedErrors = prefs.getString(_keyErrorLog);
        
        if (storedErrors != null) {
          errors = jsonDecode(storedErrors);
        }
        
        // إضافة خطأ جديد وتحديد عدد الأخطاء المخزنة
        errors.add(errorObj);
        if (errors.length > _maxErrors) {
          errors = errors.sublist(errors.length - _maxErrors);
        }
        
        // الحفظ في SharedPreferences
        await prefs.setString(_keyErrorLog, jsonEncode(errors));
      } catch (e2) {
        print('خطأ في الرجوع إلى SharedPreferences: $e2');
      }
    }
  }
  
  /// تحديث إحصائيات الأخطاء مع مراعاة الشدة
  Future<void> _updateErrorStats(String source, ErrorSeverity severity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // الحصول على الإحصائيات الموجودة
      Map<String, dynamic> stats = {};
      final String? storedStats = prefs.getString(_keyErrorStats);
      
      if (storedStats != null) {
        stats = jsonDecode(storedStats);
      }
      
      // تحديث الإحصائيات لهذا المصدر
      if (!stats.containsKey(source)) {
        stats[source] = {
          'count': 1,
          'byLevel': {
            'low': severity == ErrorSeverity.low ? 1 : 0,
            'medium': severity == ErrorSeverity.medium ? 1 : 0,
            'high': severity == ErrorSeverity.high ? 1 : 0,
            'critical': severity == ErrorSeverity.critical ? 1 : 0,
            'fatal': severity == ErrorSeverity.fatal ? 1 : 0,
          },
          'firstSeen': DateTime.now().toIso8601String(),
          'lastSeen': DateTime.now().toIso8601String(),
        };
      } else {
        stats[source]['count'] = (stats[source]['count'] as int) + 1;
        stats[source]['lastSeen'] = DateTime.now().toIso8601String();
        
        // تحديث عدد الأخطاء حسب المستوى
        if (!stats[source].containsKey('byLevel')) {
          stats[source]['byLevel'] = {
            'low': 0,
            'medium': 0,
            'high': 0,
            'critical': 0,
            'fatal': 0,
          };
        }
        
        final levelKey = severity.toString().split('.').last.toLowerCase();
        stats[source]['byLevel'][levelKey] = (stats[source]['byLevel'][levelKey] as int) + 1;
      }
      
      // الحفظ في SharedPreferences
      await prefs.setString(_keyErrorStats, jsonEncode(stats));
    } catch (e) {
      print('خطأ في تحديث إحصائيات الأخطاء: $e');
    }
  }
  
  /// مزامنة الأخطاء الخطيرة إلى السحابة
  Future<void> _syncErrorsToCloud() async {
    // هذه الدالة يمكن تنفيذها لإرسال الأخطاء إلى خدمة مثل Firebase Crashlytics
    // أو أي نظام تتبع أخطاء آخر
    
    // كمثال:
    // try {
    //   final List<Map<String, dynamic>> criticalErrors = await getCriticalErrors();
    //   for (final error in criticalErrors) {
    //     await FirebaseCrashlytics.instance.recordError(
    //       error['error'],
    //       StackTrace.fromString(error['stackTrace']),
    //       reason: error['message'],
    //       information: [
    //         'Source: ${error['source']}',
    //         'Timestamp: ${error['timestamp']}',
    //       ],
    //     );
    //   }
    // } catch (e) {
    //   print('خطأ في مزامنة الأخطاء إلى السحابة: $e');
    // }
  }
  
  /// الحصول على جميع الأخطاء المسجلة
  Future<List<Map<String, dynamic>>> getErrors() async {
    try {
      // محاولة قراءة من التخزين الآمن أولاً
      String? storedErrors = await _secureStorage.read(key: _keyErrorLog);
      
      // إذا لم يكن هناك بيانات في التخزين الآمن، جرب SharedPreferences
      if (storedErrors == null) {
        final prefs = await SharedPreferences.getInstance();
        storedErrors = prefs.getString(_keyErrorLog);
      }
      
      if (storedErrors != null) {
        final List<dynamic> errors = jsonDecode(storedErrors);
        return errors.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      return [];
    } catch (e) {
      print('خطأ في الحصول على الأخطاء: $e');
      return [];
    }
  }
  
  /// الحصول على الأخطاء الخطيرة فقط
  Future<List<Map<String, dynamic>>> getCriticalErrors() async {
    try {
      final errors = await getErrors();
      return errors.where((error) {
        final severity = error['severity'] ?? 'low';
        return severity == 'critical' || severity == 'fatal';
      }).toList();
    } catch (e) {
      print('خطأ في الحصول على الأخطاء الخطيرة: $e');
      return [];
    }
  }
  
  /// الحصول على إحصائيات الأخطاء
  Future<Map<String, dynamic>> getErrorStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedStats = prefs.getString(_keyErrorStats);
      
      if (storedStats != null) {
        return jsonDecode(storedStats);
      }
      
      return {};
    } catch (e) {
      print('خطأ في الحصول على إحصائيات الأخطاء: $e');
      return {};
    }
  }
  
  /// مسح جميع سجلات الأخطاء
  Future<void> clearErrors() async {
    try {
      await _secureStorage.delete(key: _keyErrorLog);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyErrorLog);
    } catch (e) {
      print('خطأ في مسح الأخطاء: $e');
    }
  }
  
  /// الحصول على تقرير تشخيصي محسّن
  Future<String> getDiagnosticReport() async {
    try {
      final errors = await getErrors();
      final stats = await getErrorStats();
      
      // إنشاء تقرير
      StringBuffer report = StringBuffer();
      report.writeln('===== تقرير تشخيص التطبيق =====');
      report.writeln('وقت التقرير: ${DateTime.now().toIso8601String()}');
      report.writeln('إصدار التطبيق: $appVersion (${appBuildNumber})');
      
      if (_deviceInfo != null) {
        report.writeln('\n=== معلومات الجهاز ===');
        _deviceInfo!.forEach((key, value) {
          report.writeln('$key: $value');
        });
      }
      
      report.writeln('\n=== إحصائيات الأخطاء ===');
      
      // ترتيب الإحصائيات حسب العدد
      final sortedStats = stats.entries.toList()
        ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));
      
      for (var entry in sortedStats) {
        final source = entry.key;
        final data = entry.value;
        report.writeln('مصدر: $source');
        report.writeln('عدد الأخطاء: ${data['count']}');
        
        // إضافة تفاصيل حسب المستوى إذا كانت متوفرة
        if (data.containsKey('byLevel')) {
          report.writeln('توزيع حسب الشدة:');
          data['byLevel'].forEach((level, count) {
            if (count > 0) {
              report.writeln('  - $level: $count');
            }
          });
        }
        
        report.writeln('أول ظهور: ${data['firstSeen']}');
        report.writeln('آخر ظهور: ${data['lastSeen']}');
        report.writeln('---');
      }
      
      report.writeln('\n=== آخر 10 أخطاء ===');
      final recentErrors = errors.length > 10 ? errors.sublist(errors.length - 10) : errors;
      
      for (var error in recentErrors.reversed) {
        final severity = error['severity'] ?? 'غير محدد';
        report.writeln('${error['timestamp']} - ${error['source']} [${severity}]: ${error['message']}');
        report.writeln('الخطأ: ${error['error']}');
        
        // إضافة بيانات إضافية إذا كانت متوفرة
        if (error.containsKey('additionalData') && error['additionalData'] != null) {
          report.writeln('بيانات إضافية:');
          (error['additionalData'] as Map<String, dynamic>).forEach((key, value) {
            report.writeln('  $key: $value');
          });
        }
        
        report.writeln('---');
      }
      
      return report.toString();
    } catch (e) {
      print('خطأ في إنشاء تقرير تشخيصي: $e');
      return 'حدث خطأ أثناء إنشاء التقرير: $e';
    }
  }
  
  /// عرض حوار خطأ محسّن مع خيارات الاسترداد
  void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onReport,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    // تحديد لون الخطأ حسب الشدة
    Color errorColor;
    switch (severity) {
      case ErrorSeverity.fatal:
      case ErrorSeverity.critical:
        errorColor = Colors.red;
        break;
      case ErrorSeverity.high:
        errorColor = Colors.orange;
        break;
      case ErrorSeverity.medium:
        errorColor = Colors.amber;
        break;
      case ErrorSeverity.low:
      default:
        errorColor = Colors.blue;
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: errorColor),
            SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              SizedBox(height: 16),
              Text(
                'إذا استمرت المشكلة، يرجى محاولة إعادة تشغيل التطبيق أو التحقق من إعدادات الجهاز.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
          if (onReport != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onReport();
              },
              child: Text('إرسال تقرير'),
            ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// فئة لاستثناءات الشبكة
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  
  NetworkException(this.message, {this.statusCode});
  
  @override
  String toString() => 'NetworkException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// تعداد لشدة الخطأ
enum ErrorSeverity {
  low,      // أخطاء بسيطة لا تؤثر على وظائف التطبيق
  medium,   // أخطاء متوسطة قد تعطل بعض الوظائف
  high,     // أخطاء خطيرة تعطل وظائف أساسية
  critical, // أخطاء حرجة تمنع استخدام الميزات الرئيسية
  fatal     // أخطاء قاتلة تتسبب في توقف التطبيق
}
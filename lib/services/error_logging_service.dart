// lib/services/error_logging_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// خدمة للتعامل مع تسجيل الأخطاء وتتبعها
class ErrorLoggingService {
  // تنفيذ نمط Singleton
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal() {
    _initLogger();
  }

  // مفاتيح SharedPreferences
  static const String _keyErrorLog = 'error_log';
  static const String _keyErrorStats = 'error_stats';
  static const int _maxErrors = 100; // الحد الأقصى لعدد الأخطاء للتخزين
  
  // كائن Logger
  late Logger _logger;
  
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
  
  /// تسجيل خطأ مع السياق
  Future<void> logError(String source, String message, dynamic error, {StackTrace? stackTrace}) async {
    // الطباعة في وحدة التحكم
    _logger.e("$source: $message\nError: $error\nStackTrace: ${stackTrace ?? 'لا توجد آثار المكدس'}");
    
    try {
      // إنشاء كائن الخطأ
      final errorObj = {
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
        'message': message,
        'error': error.toString(),
        'stackTrace': stackTrace?.toString() ?? 'لا توجد آثار المكدس',
      };
      
      // الحفظ في SharedPreferences
      await _saveError(errorObj);
      
      // تحديث إحصائيات الأخطاء
      await _updateErrorStats(source);
    } catch (e) {
      // إذا فشل تسجيل الأخطاء، على الأقل الطباعة في وحدة التحكم
      print('فشل تسجيل الأخطاء: $e');
    }
  }
  
  /// حفظ الخطأ في التخزين الدائم
  Future<void> _saveError(Map<String, dynamic> errorObj) async {
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
    } catch (e) {
      print('خطأ في حفظ سجل الأخطاء: $e');
    }
  }
  
  /// تحديث إحصائيات الأخطاء
  Future<void> _updateErrorStats(String source) async {
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
          'firstSeen': DateTime.now().toIso8601String(),
          'lastSeen': DateTime.now().toIso8601String(),
        };
      } else {
        stats[source]['count'] = (stats[source]['count'] as int) + 1;
        stats[source]['lastSeen'] = DateTime.now().toIso8601String();
      }
      
      // الحفظ في SharedPreferences
      await prefs.setString(_keyErrorStats, jsonEncode(stats));
    } catch (e) {
      print('خطأ في تحديث إحصائيات الأخطاء: $e');
    }
  }
  
  /// الحصول على جميع الأخطاء المسجلة
  Future<List<Map<String, dynamic>>> getErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedErrors = prefs.getString(_keyErrorLog);
      
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyErrorLog);
    } catch (e) {
      print('خطأ في مسح الأخطاء: $e');
    }
  }
  
  /// التحقق مما إذا كانت هناك أي أخطاء حرجة
  Future<bool> hasCriticalErrors() async {
    try {
      final errors = await getErrors();
      final criticalSources = ['notification', 'schedule', 'alarm'];
      
      return errors.any((error) {
        final source = error['source'] as String? ?? '';
        return criticalSources.any((criticalSource) => 
          source.toLowerCase().contains(criticalSource.toLowerCase()));
      });
    } catch (e) {
      print('خطأ في التحقق من الأخطاء الحرجة: $e');
      return false;
    }
  }
  
  /// الحصول على تقرير تشخيصي
  Future<String> getDiagnosticReport() async {
    try {
      final errors = await getErrors();
      final stats = await getErrorStats();
      
      // إنشاء تقرير
      StringBuffer report = StringBuffer();
      report.writeln('===== تقرير تشخيص التطبيق =====');
      report.writeln('وقت التقرير: ${DateTime.now().toIso8601String()}');
      report.writeln('\n=== إحصائيات الأخطاء ===');
      
      stats.forEach((source, data) {
        report.writeln('مصدر: $source');
        report.writeln('عدد الأخطاء: ${data['count']}');
        report.writeln('أول ظهور: ${data['firstSeen']}');
        report.writeln('آخر ظهور: ${data['lastSeen']}');
        report.writeln('---');
      });
      
      report.writeln('\n=== آخر 10 أخطاء ===');
      final recentErrors = errors.length > 10 ? errors.sublist(errors.length - 10) : errors;
      
      for (var error in recentErrors.reversed) {
        report.writeln('${error['timestamp']} - ${error['source']}: ${error['message']}');
        report.writeln('الخطأ: ${error['error']}');
        report.writeln('---');
      }
      
      return report.toString();
    } catch (e) {
      print('خطأ في إنشاء تقرير تشخيصي: $e');
      return 'حدث خطأ أثناء إنشاء التقرير: $e';
    }
  }
  
  /// عرض حوار خطأ مع خيارات الاسترداد
  void showErrorDialog(BuildContext context, String title, String message, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text('إعادة المحاولة'),
            ),
        ],
      ),
    );
  }
}
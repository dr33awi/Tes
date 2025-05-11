// lib/screens/athkarscreen/services/error_logging_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Service to handle error logging and tracking
class ErrorLoggingService {
  // Singleton implementation
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal() {
    _initLogger();
  }

  // Keys for SharedPreferences
  static const String _keyErrorLog = 'error_log';
  static const String _keyErrorStats = 'error_stats';
  static const int _maxErrors = 100; // Maximum number of errors to store
  
  // Logger instance
  late Logger _logger;
  
  // Initialize logger
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
  
  // Log an error with context
// Log an error with context
  Future<void> logError(String source, String message, dynamic error, {StackTrace? stackTrace}) async {
    // Print to console - fix the _logger.e call
    _logger.e("$source: $message\nError: $error\nStackTrace: ${stackTrace ?? 'No stack trace'}");
    
    try {
      // Create error object
      final errorObj = {
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
        'message': message,
        'error': error.toString(),
        'stackTrace': stackTrace?.toString() ?? 'No stack trace',
      };
      
      // Save to SharedPreferences
      await _saveError(errorObj);
      
      // Update error statistics
      await _updateErrorStats(source);
    } catch (e) {
      // If error logging fails, at least print to console
      print('Error logging failed: $e');
    }
  }
  
  // Save error to persistent storage
  Future<void> _saveError(Map<String, dynamic> errorObj) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing errors
      List<dynamic> errors = [];
      final String? storedErrors = prefs.getString(_keyErrorLog);
      
      if (storedErrors != null) {
        errors = jsonDecode(storedErrors);
      }
      
      // Add new error and limit the number of stored errors
      errors.add(errorObj);
      if (errors.length > _maxErrors) {
        errors = errors.sublist(errors.length - _maxErrors);
      }
      
      // Save back to SharedPreferences
      await prefs.setString(_keyErrorLog, jsonEncode(errors));
    } catch (e) {
      print('Error saving error log: $e');
    }
  }
  
  // Update error statistics
  Future<void> _updateErrorStats(String source) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing stats
      Map<String, dynamic> stats = {};
      final String? storedStats = prefs.getString(_keyErrorStats);
      
      if (storedStats != null) {
        stats = jsonDecode(storedStats);
      }
      
      // Update stats for this source
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
      
      // Save back to SharedPreferences
      await prefs.setString(_keyErrorStats, jsonEncode(stats));
    } catch (e) {
      print('Error updating error stats: $e');
    }
  }
  
  // Get all logged errors
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
      print('Error getting errors: $e');
      return [];
    }
  }
  
  // Get error statistics
  Future<Map<String, dynamic>> getErrorStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedStats = prefs.getString(_keyErrorStats);
      
      if (storedStats != null) {
        return jsonDecode(storedStats);
      }
      
      return {};
    } catch (e) {
      print('Error getting error stats: $e');
      return {};
    }
  }
  
  // Clear all error logs
  Future<void> clearErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyErrorLog);
    } catch (e) {
      print('Error clearing errors: $e');
    }
  }
  
  // Check if there are any critical errors
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
      print('Error checking for critical errors: $e');
      return false;
    }
  }
  
  // Get a diagnostic report
  Future<String> getDiagnosticReport() async {
    try {
      final errors = await getErrors();
      final stats = await getErrorStats();
      
      // Generate a report
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
      print('Error generating diagnostic report: $e');
      return 'حدث خطأ أثناء إنشاء التقرير: $e';
    }
  }
  
  // Show error dialog with recovery options
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
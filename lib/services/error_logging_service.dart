// lib/services/error_logging_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// خدمة بسيطة لتسجيل الأخطاء
class ErrorLoggingService {
  // تنفيذ نمط Singleton
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  // مفاتيح التخزين المحلي
  static const String _keyErrorLog = 'error_log';
  static const int _maxErrors = 50; // الحد الأقصى لعدد الأخطاء للتخزين
  
  // Logger
  late Logger _logger;
  
  /// تهيئة خدمة تسجيل الأخطاء
  Future<void> initialize() async {
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
  
  /// تسجيل خطأ
  Future<void> logError(
    String source,
    String message,
    dynamic error, {
    StackTrace? stackTrace,
  }) async {
    // الطباعة في وحدة التحكم
    _logger.e("$source: $message\nError: $error\nStackTrace: $stackTrace");
    
    try {
      // إنشاء كائن الخطأ
      final errorObj = {
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
        'message': message,
        'error': error.toString(),
        'stackTrace': stackTrace?.toString() ?? '',
      };
      
      // الحفظ في التخزين المحلي
      await _storeError(errorObj);
    } catch (e) {
      print('فشل تسجيل الأخطاء: $e');
    }
  }
  
  /// حفظ الخطأ في التخزين المحلي
  Future<void> _storeError(Map<String, dynamic> errorObj) async {
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
  
  /// الحصول على الأخطاء الأخيرة
  Future<List<Map<String, dynamic>>> getRecentErrors({int limit = 20}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedErrors = prefs.getString(_keyErrorLog);
      
      if (storedErrors != null) {
        final List<dynamic> errors = jsonDecode(storedErrors);
        final recentErrors = errors.reversed.take(limit).toList();
        return recentErrors.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      return [];
    } catch (e) {
      print('خطأ في الحصول على الأخطاء: $e');
      return [];
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
  
  /// عرض حوار خطأ بسيط
  void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
          if (onRetry != null)
            ElevatedButton(
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
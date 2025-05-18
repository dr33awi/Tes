import 'package:flutter/foundation.dart';
import '../interfaces/logger_service.dart';

class LoggerServiceImpl implements LoggerService {
  @override
  void debug({required String message, dynamic data}) {
    if (kDebugMode) {
      print('📘 DEBUG: $message');
      if (data != null) print('Data: $data');
    }
  }

  @override
  void info({required String message, dynamic data}) {
    if (kDebugMode) {
      print('📗 INFO: $message');
      if (data != null) print('Data: $data');
    }
  }

  @override
  void warning({required String message, dynamic data}) {
    if (kDebugMode) {
      print('📙 WARNING: $message');
      if (data != null) print('Data: $data');
    }
  }

  @override
  void error({required String message, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('📕 ERROR: $message');
      print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
    
    // هنا يمكن إضافة منطق لتسجيل الأخطاء في خدمة مثل Firebase Crashlytics
  }
}
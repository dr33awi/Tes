import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../error/exceptions.dart';
import '../services/interfaces/logger_service.dart';

// سجل عام للأخطاء
class AppErrorHandler {
  final LoggerService _logger;
  
  AppErrorHandler(this._logger);
  
  // معالجة أي نوع من الأخطاء
  Future<T?> handleError<T>(
    Future<T> Function() operation, {
    String? operationName,
    Function(String)? onError,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final errorMessage = _getReadableErrorMessage(e);
      _logError(operationName ?? 'unknown_operation', e, stackTrace);
      
      if (onError != null) {
        onError(errorMessage);
      }
      
      return defaultValue;
    }
  }
  
  // الحصول على رسالة خطأ مقروءة
  String _getReadableErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'لا يمكن الاتصال بالإنترنت، يرجى التحقق من اتصالك والمحاولة مرة أخرى';
    } else if (error is TimeoutException) {
      return 'استغرقت العملية وقتًا طويلاً، يرجى المحاولة مرة أخرى';
    } else if (error is DataLoadException) {
      return 'حدث خطأ أثناء تحميل البيانات: ${error.message}';
    } else if (error is DataUpdateException) {
      return 'حدث خطأ أثناء تحديث البيانات: ${error.message}';
    } else if (error is DataNotFoundException) {
      return 'البيانات المطلوبة غير موجودة: ${error.message}';
    } else if (error is LocationException) {
      return 'حدث خطأ أثناء تحديد الموقع: ${error.message}';
    } else if (error is NotificationException) {
      return 'حدث خطأ في نظام الإشعارات: ${error.message}';
    } else if (error is PrayerTimesException) {
      return 'حدث خطأ أثناء حساب مواقيت الصلاة: ${error.message}';
    } else if (error is QiblaException) {
      return 'حدث خطأ أثناء تحديد اتجاه القبلة: ${error.message}';
    } else if (error is StorageException) {
      return 'حدث خطأ في التخزين المحلي: ${error.message}';
    }
    
    return 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
  }
  
  // تسجيل الخطأ
  void _logError(String operation, dynamic error, StackTrace stackTrace) {
    _logger.error(
      message: 'خطأ في عملية: $operation',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  // عرض رسالة خطأ للمستخدم
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  // عرض الخطأ مع خيارات
  static Future<bool> showErrorDialog(
    BuildContext context, 
    String title, 
    String message, {
    String? retryLabel,
    VoidCallback? onRetry,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          if (retryLabel != null && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
                onRetry();
              },
              child: Text(retryLabel),
            ),
        ],
      ),
    ) ?? false;
  }
}
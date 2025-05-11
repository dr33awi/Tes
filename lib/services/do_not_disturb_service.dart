// lib/services/do_not_disturb_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// خدمة للتعامل مع وضع عدم الإزعاج وضمان وصول الإشعارات
class DoNotDisturbService {
  // تنفيذ نمط Singleton مع التبعية المعكوسة
  static final DoNotDisturbService _instance = DoNotDisturbService._internal();
  
  factory DoNotDisturbService({
    ErrorLoggingService? errorLoggingService,
  }) {
    _instance._errorLoggingService = errorLoggingService ?? ErrorLoggingService();
    return _instance;
  }
  
  DoNotDisturbService._internal();
  
  // التبعية المعكوسة
  late ErrorLoggingService _errorLoggingService;
  
  // قناة الطريقة للتواصل مع كود خاص بالمنصة
  static const MethodChannel _channel = MethodChannel('com.athkar.app/do_not_disturb');
  
  /// التحقق مما إذا كان الجهاز حاليًا في وضع عدم الإزعاج
  Future<bool> isInDoNotDisturbMode() async {
    try {
      if (Platform.isAndroid) {
        final bool? result = await _channel.invokeMethod<bool>('isInDoNotDisturbMode');
        return result ?? false;
      } else if (Platform.isIOS) {
        // iOS لا توفر واجهة برمجة تطبيقات مباشرة للتحقق من هذا
        // يمكننا التحقق من إعدادات الإشعارات بدلاً من ذلك
        return false;
      }
      return false;
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'خطأ في التحقق من وضع عدم الإزعاج', 
        e
      );
      return false;
    }
  }
  
  /// التحقق مما إذا كان التطبيق لديه إذن لتجاوز وضع عدم الإزعاج
  Future<bool> canBypassDoNotDisturb() async {
    try {
      if (Platform.isAndroid) {
        final bool? result = await _channel.invokeMethod<bool>('canBypassDoNotDisturb');
        return result ?? false;
      } else if (Platform.isIOS) {
        // iOS تستخدم التنبيهات الحرجة لهذا الغرض
        final bool? result = await _channel.invokeMethod<bool>('hasCriticalAlertPermission');
        return result ?? false;
      }
      return false;
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'خطأ في التحقق من إذن التجاوز', 
        e
      );
      return false;
    }
  }
  
  /// فتح إعدادات عدم الإزعاج للمستخدم لتكوينها
  Future<void> openDoNotDisturbSettings() async {
    try {
      if (Platform.isAndroid) {
        // استخدام الطريقة الصحيحة من حزمة AppSettings
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
      } else if (Platform.isIOS) {
        await AppSettings.openAppSettings();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'خطأ في فتح إعدادات عدم الإزعاج', 
        e
      );
    }
  }
  
  /// التحقق مما إذا كان يجب مطالبة المستخدم بإعدادات وضع عدم الإزعاج
  Future<bool> shouldPromptAboutDoNotDisturb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // التحقق مما إذا كنا قد طالبنا المستخدم بالفعل
      final bool hasPrompted = prefs.getBool('dnd_prompted') ?? false;
      if (hasPrompted) {
        // لا تطالب مرة أخرى إذا كنا قد فعلنا ذلك في الأسبوع الماضي
        final int lastPromptTime = prefs.getInt('dnd_prompt_time') ?? 0;
        final int now = DateTime.now().millisecondsSinceEpoch;
        
        // التحقق مما إذا كان قد مر أسبوع منذ آخر مرة طالبناه
        if (now - lastPromptTime < 7 * 24 * 60 * 60 * 1000) {
          return false;
        }
      }
      
      // التحقق مما إذا كان الجهاز في وضع عدم الإزعاج
      final bool isDndActive = await isInDoNotDisturbMode();
      if (!isDndActive) {
        return false; // لا حاجة للمطالبة إذا لم يكن DND نشطًا
      }
      
      // التحقق مما إذا كان التطبيق يمكنه بالفعل تجاوز DND
      final bool canBypass = await canBypassDoNotDisturb();
      return !canBypass; // فقط مطالبة إذا لم نتمكن من تجاوز DND
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'خطأ في التحقق مما إذا كان ينبغي المطالبة بشأن DND', 
        e
      );
      return false;
    }
  }
  
  /// تسجيل أننا طالبنا المستخدم بإعدادات وضع عدم الإزعاج
  Future<void> recordDoNotDisturbPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dnd_prompted', true);
      await prefs.setInt('dnd_prompt_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'خطأ في تسجيل مطالبة DND', 
        e
      );
    }
  }
  
  /// عرض حوار حول إعدادات وضع عدم الإزعاج
  Future<void> showDoNotDisturbDialog(BuildContext context) async {
    try {
      final isDndActive = await isInDoNotDisturbMode();
      final canBypass = await canBypassDoNotDisturb();
      
      if (isDndActive && !canBypass) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('وضع عدم الإزعاج'),
            content: Text(
              'تم تفعيل وضع "عدم الإزعاج" على جهازك. لضمان وصول إشعارات الأذكار المهمة، يرجى السماح للتطبيق بتجاوز وضع عدم الإزعاج.\n\n'
              'سيتم توجيهك إلى إعدادات الجهاز لتفعيل هذه الميزة.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('لاحقاً'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openDoNotDisturbSettings();
                },
                child: Text('فتح الإعدادات'),
              ),
            ],
          ),
        );
        
        // تسجيل أننا طالبنا المستخدم
        await recordDoNotDisturbPrompt();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'خطأ في عرض حوار عدم الإزعاج', 
        e
      );
    }
  }
  
  /// تكوين قنوات الإشعارات لتجاوز وضع عدم الإزعاج (Android فقط)
  Future<void> configureNotificationChannelsForDoNotDisturb() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('configureNotificationChannelsForDoNotDisturb');
      }
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'خطأ في تكوين قنوات الإشعارات', 
        e
      );
    }
  }
}
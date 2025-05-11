// lib/screens/athkarscreen/services/do_not_disturb_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// Service to handle Do Not Disturb mode and ensure notifications get through
class DoNotDisturbService {
  // Singleton pattern implementation
  static final DoNotDisturbService _instance = DoNotDisturbService._internal();
  factory DoNotDisturbService() => _instance;
  DoNotDisturbService._internal();
  
  // Error logging service
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  // Method channel for communicating with platform-specific code
  static const MethodChannel _channel = MethodChannel('com.athkar.app/do_not_disturb');
  
  // Check if the device is currently in Do Not Disturb mode
  Future<bool> isInDoNotDisturbMode() async {
    try {
      if (Platform.isAndroid) {
        final bool? result = await _channel.invokeMethod<bool>('isInDoNotDisturbMode');
        return result ?? false;
      } else if (Platform.isIOS) {
        // iOS doesn't provide direct API to check this
        // We could check notification settings instead
        return false;
      }
      return false;
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'Error checking Do Not Disturb mode', 
        e
      );
      return false;
    }
  }
  
  // Check if the app has permission to bypass Do Not Disturb
  Future<bool> canBypassDoNotDisturb() async {
    try {
      if (Platform.isAndroid) {
        final bool? result = await _channel.invokeMethod<bool>('canBypassDoNotDisturb');
        return result ?? false;
      } else if (Platform.isIOS) {
        // iOS uses critical alerts for this purpose
        final bool? result = await _channel.invokeMethod<bool>('hasCriticalAlertPermission');
        return result ?? false;
      }
      return false;
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'Error checking bypass permission', 
        e
      );
      return false;
    }
  }
  
  // Open Do Not Disturb settings for the user to configure
  Future<void> openDoNotDisturbSettings() async {
  try {
    if (Platform.isAndroid) {
      // استخدم الطريقة الصحيحة من حزمة AppSettings
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      // أو استخدم هذا إذا كان الإصدار القديم:
      // await AppSettings.openSettings(AppSettingsType.NOTIFICATION);
    } else if (Platform.isIOS) {
      await AppSettings.openAppSettings();
    }
  } catch (e) {
    _errorLoggingService.logError(
      'DoNotDisturbService', 
      'Error opening Do Not Disturb settings', 
      e
    );
  }
}
  // Check if the app should prompt the user about Do Not Disturb settings
  Future<bool> shouldPromptAboutDoNotDisturb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we've already prompted the user
      final bool hasPrompted = prefs.getBool('dnd_prompted') ?? false;
      if (hasPrompted) {
        // Don't prompt again if we've already done so in the last week
        final int lastPromptTime = prefs.getInt('dnd_prompt_time') ?? 0;
        final int now = DateTime.now().millisecondsSinceEpoch;
        
        // Check if a week has passed since we last prompted
        if (now - lastPromptTime < 7 * 24 * 60 * 60 * 1000) {
          return false;
        }
      }
      
      // Check if the device is in Do Not Disturb mode
      final bool isDndActive = await isInDoNotDisturbMode();
      if (!isDndActive) {
        return false; // No need to prompt if DND is not active
      }
      
      // Check if the app can already bypass DND
      final bool canBypass = await canBypassDoNotDisturb();
      return !canBypass; // Only prompt if we can't bypass DND
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'Error checking if should prompt about DND', 
        e
      );
      return false;
    }
  }
  
  // Record that we've prompted the user about Do Not Disturb settings
  Future<void> recordDoNotDisturbPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dnd_prompted', true);
      await prefs.setInt('dnd_prompt_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'Error recording DND prompt', 
        e
      );
    }
  }
  
  // Show dialog about Do Not Disturb settings
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
        
        // Record that we've prompted the user
        await recordDoNotDisturbPrompt();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'Error showing Do Not Disturb dialog', 
        e
      );
    }
  }
  
  // Configure notification channels to bypass Do Not Disturb (Android only)
  Future<void> configureNotificationChannelsForDoNotDisturb() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('configureNotificationChannelsForDoNotDisturb');
      }
    } catch (e) {
      _errorLoggingService.logError(
        'DoNotDisturbService', 
        'Error configuring notification channels', 
        e
      );
    }
  }
}
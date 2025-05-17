// lib/core/services/utils/permission_utils.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

class AppPermissionUtils {
  /// طلب إذن الموقع
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  /// التحقق من حالة إذن الموقع
  static Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }
  
  /// طلب إذن الإشعارات
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  
  /// التحقق من حالة إذن الإشعارات
  static Future<bool> checkNotificationPermission() async {
    return await Permission.notification.isGranted;
  }
  
  /// فتح إعدادات التطبيق
  static Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }
  
  /// فتح إعدادات الموقع
  static Future<void> openLocationSettings() async {
    await AppSettings.openLocationSettings();
  }
  
  /// فتح إعدادات الإشعارات
  static Future<void> openNotificationSettings() async {
    await AppSettings.openNotificationSettings();
  }
  
  /// عرض حوار طلب الإذن مع شرح السبب
  static Future<bool> showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Function() onOpenSettings,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              onOpenSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}
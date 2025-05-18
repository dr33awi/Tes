// lib/core/services/utils/permission_helper.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// فئة مساعدة للتعامل مع الأذونات بطريقة بسيطة
class PermissionHelper {
  /// طلب إذن الإشعارات مع عرض مربع حوار توضيحي
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    // التحقق مما إذا كان لدينا الإذن بالفعل
    PermissionStatus status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }
    
    // عرض مربع حوار توضيحي
    bool shouldRequest = await _showPermissionDialog(
      context,
      title: 'إذن الإشعارات',
      message: 'يحتاج التطبيق إلى إذن الإشعارات لإرسال تنبيهات بأوقات الصلاة والأذكار.',
      importance: 'بدون هذا الإذن، لن تتلقى تذكيرات بمواعيد الصلاة والأذكار اليومية.',
    );
    
    if (!shouldRequest) {
      return false;
    }
    
    // طلب الإذن
    status = await Permission.notification.request();
    return status.isGranted;
  }

  /// طلب إذن الموقع مع عرض مربع حوار توضيحي
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // التحقق مما إذا كان لدينا الإذن بالفعل
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }
    
    // عرض مربع حوار توضيحي
    bool shouldRequest = await _showPermissionDialog(
      context,
      title: 'إذن الموقع',
      message: 'يحتاج التطبيق إلى إذن الموقع لتحديد اتجاه القبلة ومواقيت الصلاة بدقة.',
      importance: 'بدون هذا الإذن، سيتم استخدام موقع افتراضي أقل دقة.',
    );
    
    if (!shouldRequest) {
      return false;
    }
    
    // طلب الإذن
    status = await Permission.location.request();
    return status.isGranted;
  }
  
  /// طلب إذن استثناء تحسينات البطارية
  static Future<bool> requestBatteryOptimizationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) {
      return true;
    }
    
    bool shouldRequest = await _showPermissionDialog(
      context,
      title: 'استثناء تحسينات البطارية',
      message: 'يحتاج التطبيق إلى استثناء من تحسينات البطارية لضمان وصول الإشعارات في الوقت المناسب.',
      importance: 'بدون هذا الإذن، قد لا تصلك الإشعارات عند تفعيل وضع توفير البطارية.',
    );
    
    if (!shouldRequest) {
      return false;
    }
    
    status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }
  
  /// طلب إذن وضع عدم الإزعاج
  static Future<bool> requestDoNotDisturbPermission(BuildContext context) async {
    PermissionStatus status = await Permission.accessNotificationPolicy.status;
    if (status.isGranted) {
      return true;
    }
    
    bool shouldRequest = await _showPermissionDialog(
      context,
      title: 'إذن وضع عدم الإزعاج',
      message: 'يحتاج التطبيق إلى إذن التحكم في وضع عدم الإزعاج لضمان وصول إشعارات الصلاة المهمة.',
      importance: 'بدون هذا الإذن، لن تتلقى إشعارات الصلاة عندما يكون وضع عدم الإزعاج مفعلاً.',
    );
    
    if (!shouldRequest) {
      return false;
    }
    
    status = await Permission.accessNotificationPolicy.request();
    return status.isGranted;
  }
  
  /// التحقق من حالة إذن محدد
  static Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }
  
  /// فتح إعدادات التطبيق للأذونات
  static Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }
  
  /// فتح إعدادات الموقع
  static Future<void> openLocationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.location);
  }
  
  /// فتح إعدادات الإشعارات
  static Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }
  
  /// فتح إعدادات البطارية
  static Future<void> openBatterySettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.battery);
  }
  
  /// عرض مربع حوار يشرح سبب الحاجة إلى إذن
  static Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String importance,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text(
              importance,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('السماح'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// التحقق من حالة جميع الأذونات المهمة
  static Future<Map<String, PermissionStatus>> checkAllPermissions() async {
    return {
      'notification': await Permission.notification.status,
      'location': await Permission.location.status,
      'battery': await Permission.ignoreBatteryOptimizations.status,
      'doNotDisturb': await Permission.accessNotificationPolicy.status,
    };
  }
  
  /// التحقق من عدة أذونات دفعة واحدة
  static Future<bool> requestMultiplePermissions(BuildContext context, List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = true;
    for (var entry in statuses.entries) {
      if (!entry.value.isGranted) {
        allGranted = false;
        break;
      }
    }
    
    return allGranted;
  }
  
  /// إظهار مربع حوار إذا كان الإذن مرفوضًا بشكل دائم
  static Future<void> showPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
    Function onOpenSettings,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إذن $permissionName مرفوض'),
        content: Text(
          'تم رفض إذن $permissionName بشكل دائم. لاستخدام هذه الميزة، يرجى تفعيل الإذن من إعدادات التطبيق.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
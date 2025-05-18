import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType {
  location,
  notification,
  doNotDisturb,
  batteryOptimization,
}

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

abstract class PermissionService {
  /// التحقق وطلب إذن الموقع
  Future<bool> requestLocationPermission();
  
  /// التحقق وطلب إذن الإشعارات
  Future<bool> requestNotificationPermission();
  
  /// التحقق وطلب إذن "عدم الإزعاج"
  Future<bool> requestDoNotDisturbPermission();
  
  /// التحقق وطلب إذن البطارية
  Future<bool> requestBatteryOptimizationPermission();
  
  /// التحقق من حالة الأذونات
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions();
  
  /// فتح إعدادات التطبيق أو إعدادات محددة
  Future<void> openAppSettings([AppSettingsType? type]);
}

/// أنواع الإعدادات التي يمكن فتحها
enum AppSettingsType {
  app,
  location,
  notification,
  battery,
}
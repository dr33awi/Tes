// lib/core/services/implementations/permission_service_impl.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../interfaces/permission_service.dart';

class PermissionServiceImpl implements PermissionService {
  // تخزين سجل طلبات الأذونات
  final Map<AppPermissionType, int> _permissionAttempts = {};
  
  @override
  Future<bool> requestLocationPermission() async {
    // تسجيل محاولة طلب الإذن
    _permissionAttempts[AppPermissionType.location] = 
        (_permissionAttempts[AppPermissionType.location] ?? 0) + 1;
        
    // التحقق من الإذن وطلبه
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  @override
  Future<bool> requestNotificationPermission() async {
    // تسجيل محاولة طلب الإذن
    _permissionAttempts[AppPermissionType.notification] = 
        (_permissionAttempts[AppPermissionType.notification] ?? 0) + 1;
        
    // التحقق من الإذن وطلبه
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  
  @override
  Future<bool> requestDoNotDisturbPermission() async {
    // تنفيذ طلب إذن وضع عدم الإزعاج
    try {
      final status = await Permission.accessNotificationPolicy.request();
      return status.isGranted;
    } catch (e) {
      // إذا لم يكن الإذن متاحًا في نظام التشغيل الحالي
      return false;
    }
  }
  
  @override
  Future<bool> requestBatteryOptimizationPermission() async {
    // طلب استثناء من تحسينات البطارية (خاص بنظام Android)
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      // قد لا يكون متاحًا في جميع الأنظمة
      return false;
    }
  }
  
  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    // التحقق من جميع الأذونات المطلوبة للتطبيق
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;
    final dndStatus = await Permission.accessNotificationPolicy.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    
    return {
      AppPermissionType.location: _mapToPermissionStatus(locationStatus),
      AppPermissionType.notification: _mapToPermissionStatus(notificationStatus),
      AppPermissionType.doNotDisturb: _mapToPermissionStatus(dndStatus),
      AppPermissionType.batteryOptimization: _mapToPermissionStatus(batteryStatus),
    };
  }
  
  @override
  Future<void> openAppSettings([AppSettingsType? type]) async {
    switch (type) {
      case AppSettingsType.location:
        await AppSettings.openLocationSettings();
        break;
      case AppSettingsType.notification:
        await AppSettings.openNotificationSettings();
        break;
      case AppSettingsType.battery:
        await AppSettings.openBatteryOptimizationSettings();
        break;
      default:
        await AppSettings.openAppSettings();
    }
  }
  
  // طرق مساعدة خاصة
  AppPermissionStatus _mapToPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    if (status.isLimited) return AppPermissionStatus.limited;
    return AppPermissionStatus.denied;
  }
  
  bool _isDeniedPermanently(AppPermissionType type) {
    // التحقق من عدد المحاولات السابقة لطلب الإذن
    return (_permissionAttempts[type] ?? 0) >= 2;
  }
}
  
  @override
  Future<void> openAppSettings({SettingsType? type}) async {
    if (type == null) {
      await AppSettings.openAppSettings();
      return;
    }
    
    switch (type) {
      case SettingsType.location:
        await AppSettings.openLocationSettings();
        break;
      case SettingsType.notification:
        await AppSettings.openNotificationSettings();
        break;
      case SettingsType.battery:
        await AppSettings.openBatteryOptimizationSettings();
        break;
      default:
        await AppSettings.openAppSettings();
    }
  }
  
  // طرق مساعدة خاصة
  
  PermissionStatus _mapToPermissionStatus(Permission.PermissionStatus status) {
    if (status.isGranted) return PermissionStatus.granted;
    if (status.isPermanentlyDenied) return PermissionStatus.permanentlyDenied;
    if (status.isRestricted) return PermissionStatus.restricted;
    if (status.isLimited) return PermissionStatus.limited;
    return PermissionStatus.denied;
  }
  
  String _getPermissionTitle(PermissionType type) {
    switch (type) {
      case PermissionType.location:
        return 'إذن الموقع';
      case PermissionType.notification:
        return 'إذن الإشعارات';
      case PermissionType.doNotDisturb:
        return 'إذن وضع عدم الإزعاج';
      case PermissionType.batteryOptimization:
        return 'استثناء من تحسينات البطارية';
    }
  }
  
  bool _isDeniedPermanently(PermissionType type) {
    // التحقق من عدد المحاولات السابقة لطلب الإذن
    return (_permissionAttempts[type] ?? 0) >= 2;
  }
}

enum SettingsType {
  location,
  notification,
  battery,
}
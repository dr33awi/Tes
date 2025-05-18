import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as app_settings;
import '../interfaces/permission_service.dart';

class PermissionServiceImpl implements PermissionService {
  final Map<AppPermissionType, int> _permissionAttempts = {};

  @override
  Future<bool> requestLocationPermission() async {
    _permissionAttempts[AppPermissionType.location] = 
        (_permissionAttempts[AppPermissionType.location] ?? 0) + 1;
    
    final status = await Permission.location.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    _permissionAttempts[AppPermissionType.notification] = 
        (_permissionAttempts[AppPermissionType.notification] ?? 0) + 1;
    
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  @override
  Future<bool> requestDoNotDisturbPermission() async {
    try {
      _permissionAttempts[AppPermissionType.doNotDisturb] = 
          (_permissionAttempts[AppPermissionType.doNotDisturb] ?? 0) + 1;
      
      final status = await Permission.accessNotificationPolicy.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestBatteryOptimizationPermission() async {
    try {
      _permissionAttempts[AppPermissionType.batteryOptimization] = 
          (_permissionAttempts[AppPermissionType.batteryOptimization] ?? 0) + 1;
          
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    return {
      AppPermissionType.location: _mapToPermissionStatus(await Permission.location.status),
      AppPermissionType.notification: _mapToPermissionStatus(await Permission.notification.status),
      AppPermissionType.doNotDisturb: _mapToPermissionStatus(await Permission.accessNotificationPolicy.status),
      AppPermissionType.batteryOptimization: _mapToPermissionStatus(await Permission.ignoreBatteryOptimizations.status),
    };
  }

  @override
  Future<void> openAppSettings([AppSettingsType? type]) async {
    switch (type) {
      case AppSettingsType.location:
        await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.location);
        break;
      case AppSettingsType.notification:
        await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.notification);
        break;
      case AppSettingsType.battery:
        await app_settings.AppSettings.openAppSettings(type: app_settings.AppSettingsType.batteryOptimization);
        break;
      default:
        await app_settings.AppSettings.openAppSettings();
    }
  }

  AppPermissionStatus _mapToPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return AppPermissionStatus.restricted;
    if (status.isLimited) return AppPermissionStatus.limited;
    return AppPermissionStatus.denied;
  }
}
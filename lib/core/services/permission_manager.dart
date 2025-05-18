// lib/core/services/permission_manager.dart
import 'package:flutter/material.dart';
import './interfaces/permission_service.dart';

class PermissionManager {
  final PermissionService _permissionService;

  PermissionManager(this._permissionService);

  // Check status of all permissions
  Future<Map<AppPermissionType, AppPermissionStatus>> checkPermissions() async {
    return await _permissionService.checkAllPermissions();
  }

  // Request essential permissions (notification and location)
  Future<Map<AppPermissionType, bool>> requestEssentialPermissions(BuildContext context) async {
    Map<AppPermissionType, bool> results = {};
    
    // Request notification permission
    final notificationGranted = await _permissionService.requestNotificationPermission();
    results[AppPermissionType.notification] = notificationGranted;
    
    // Request location permission
    final locationGranted = await _permissionService.requestLocationPermission();
    results[AppPermissionType.location] = locationGranted;
    
    return results;
  }

  // Request optional permissions (battery optimization and DND)
  Future<Map<AppPermissionType, bool>> requestOptionalPermissions(BuildContext context) async {
    Map<AppPermissionType, bool> results = {};
    
    // Request battery optimization permission
    final batteryOptGranted = await _permissionService.requestBatteryOptimizationPermission();
    results[AppPermissionType.batteryOptimization] = batteryOptGranted;
    
    // Request DND permission
    final dndGranted = await _permissionService.requestDoNotDisturbPermission();
    results[AppPermissionType.doNotDisturb] = dndGranted;
    
    return results;
  }

  // Request location permission specifically
  Future<bool> requestLocationPermission(BuildContext context) async {
    return await _permissionService.requestLocationPermission();
  }
  
  // Open app settings for a specific permission type
  Future<void> openPermissionSettings(AppPermissionType type) async {
    AppSettingsType? settingsType;
    
    switch (type) {
      case AppPermissionType.location:
        settingsType = AppSettingsType.location;
        break;
      case AppPermissionType.notification:
        settingsType = AppSettingsType.notification;
        break;
      case AppPermissionType.batteryOptimization:
        settingsType = AppSettingsType.battery;
        break;
      case AppPermissionType.doNotDisturb:
        settingsType = AppSettingsType.app;
        break;
    }
    
    await _permissionService.openAppSettings(settingsType);
  }
}
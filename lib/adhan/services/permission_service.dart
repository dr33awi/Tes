// lib/adhan/permission_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

/// Service for managing app permissions
///
/// Handles requesting and checking permissions for notifications,
/// location, and exact alarms required for the prayer times app.
class PermissionService {
  // Singleton implementation
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();
  
  // Method channel for platform-specific operations
  static const platform = MethodChannel('com.example.test_athkar_app/permissions');
  
  // Cache permission results to avoid frequent checks
  Map<Permission, PermissionStatus> _permissionCache = {};
  DateTime? _permissionCacheTime;
  
  // Constants
  static const Duration _cacheDuration = Duration(minutes: 1);
  
  /// Request notification permission
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      
      // Update cache
      _updatePermissionCache(Permission.notification, status);
      
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }
  
  /// Check notification permission status
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkNotificationPermission() async {
    try {
      // Check cache first
      if (_isPermissionCacheValid(Permission.notification)) {
        return _permissionCache[Permission.notification]!.isGranted;
      }
      
      final status = await Permission.notification.status;
      
      // Update cache
      _updatePermissionCache(Permission.notification, status);
      
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }
  
  /// Request location permission
  ///
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestLocationPermission() async {
    try {
      // Request permission
      final status = await Permission.location.request();
      
      // Update cache
      _updatePermissionCache(Permission.location, status);
      
      // If permission granted, check if location service is enabled
      if (status.isGranted) {
        return await Geolocator.isLocationServiceEnabled();
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }
  
  /// Check location permission status
  /// 
  /// Returns true if permission is granted AND location service is enabled
  Future<bool> checkLocationPermission() async {
    try {
      // Check cache first
      if (_isPermissionCacheValid(Permission.location)) {
        if (_permissionCache[Permission.location]!.isGranted) {
          return await Geolocator.isLocationServiceEnabled();
        }
        return false;
      }
      
      final status = await Permission.location.status;
      
      // Update cache
      _updatePermissionCache(Permission.location, status);
      
      // If permission granted, check if location service is enabled
      if (status.isGranted) {
        return await Geolocator.isLocationServiceEnabled();
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }
  
  /// Request exact alarm permission (Android only)
  ///
  /// On Android 12+, exact alarms require special permission.
  /// This method requests that permission through platform channels.
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return true;  // iOS doesn't need this permission
    }
    
    try {
      // Check Android version
      final androidInfo = await _getAndroidVersion();
      final androidVersion = androidInfo['version'] ?? 0;
      
      // Only Android 12+ (API level 31+) requires this permission
      if (androidVersion < 31) {
        return true;
      }
      
      if (await platform.invokeMethod('checkExactAlarmPermission')) {
        return true;  // Permission already granted
      }
      
      // Open settings to request permission
      if (await platform.invokeMethod('openAlarmSettings')) {
        // We can't programmatically know the result, check again after
        await Future.delayed(const Duration(seconds: 1));
        return await platform.invokeMethod('checkExactAlarmPermission') ?? false;
      }
      
      return false;
    } on PlatformException catch (e) {
      debugPrint("Failed to request exact alarm permission: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("Error requesting exact alarm permission: $e");
      return false;
    }
  }
  
  /// Check exact alarm permission status (Android only)
  Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return true;  // iOS doesn't need this permission
    }
    
    try {
      // Check Android version
      final androidInfo = await _getAndroidVersion();
      final androidVersion = androidInfo['version'] ?? 0;
      
      // Only Android 12+ (API level 31+) requires this permission
      if (androidVersion < 31) {
        return true;
      }
      
      return await platform.invokeMethod('checkExactAlarmPermission') ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check exact alarm permission: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("Error checking exact alarm permission: $e");
      return false;
    }
  }
  
  /// Request all required permissions
  ///
  /// Requests location, notification, and exact alarm permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    // Request location permission
    results['location'] = await requestLocationPermission();
    
    // Request notification permission
    results['notification'] = await requestNotificationPermission();
    
    // Request exact alarm permission (Android only)
    results['exactAlarm'] = await requestExactAlarmPermission();
    
    // Return all results
    return results;
  }
  
  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }
  
  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
      return true;
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }
  
  /// Private method to get Android version
  Future<Map<String, dynamic>> _getAndroidVersion() async {
    if (!Platform.isAndroid) {
      return {'version': 0, 'sdkInt': 0};
    }
    
    try {
      final result = await platform.invokeMethod('getAndroidVersion');
      return Map<String, dynamic>.from(result ?? {'version': 0, 'sdkInt': 0});
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      return {'version': 0, 'sdkInt': 0};
    }
  }
  
  /// Update permission cache
  void _updatePermissionCache(Permission permission, PermissionStatus status) {
    _permissionCache[permission] = status;
    _permissionCacheTime = DateTime.now();
  }
  
  /// Check if permission cache is valid
  bool _isPermissionCacheValid(Permission permission) {
    if (_permissionCacheTime == null || _permissionCache[permission] == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_permissionCacheTime!) < _cacheDuration && 
           _permissionCache.containsKey(permission);
  }
  
  /// Clear permission cache
  void clearPermissionCache() {
    _permissionCache.clear();
    _permissionCacheTime = null;
  }
}
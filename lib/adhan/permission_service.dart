// lib/services/permission_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();
  
  static const platform = MethodChannel('com.example.test_athkar_app/permissions');
  
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  Future<bool> requestExactAlarmPermission() async {
    try {
      if (await platform.invokeMethod('openAlarmSettings')) {
        // We can't programmatically know the result, so assume success
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint("Failed to invoke method: ${e.message}");
      return false;
    }
  }
  
  Future<bool> requestAllPermissions() async {
    bool locationGranted = await requestLocationPermission();
    bool notificationGranted = await requestNotificationPermission();
    bool alarmGranted = await requestExactAlarmPermission();
    
    return locationGranted && notificationGranted && alarmGranted;
  }
}
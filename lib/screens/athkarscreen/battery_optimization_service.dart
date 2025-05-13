// lib/screens/athkarscreen/services/battery_optimization_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  // Singleton implementation
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  // Keys for shared preferences
  static const String _keyBatteryOptimizationChecked = 'battery_optimization_checked';
  static const String _keyNeedsBatteryOptimization = 'needs_battery_optimization';
  static const String _keyLastCheckTime = 'battery_optimization_last_check';
  
  // Method channel for custom platform code
  static const platform = MethodChannel('com.athkar.app/battery_optimization');
  
  // Battery instance
  final Battery _battery = Battery();

  // Check if battery optimization is enabled for the app
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Try to use method channel first
      try {
        final bool? result = await platform.invokeMethod<bool>('isBatteryOptimizationEnabled');
        if (result != null) return result;
      } catch (e) {
        print('Method channel error: $e');
        // Fall back to other methods
      }
      
      // Check if we can detect power save mode as a fallback
      // Note: getBatteryState() doesn't exist, using BatteryState.full as a default value
      final isLowPowerMode = await _battery.isInBatterySaveMode;
      
      // This is not perfect, but might give some indication
      final prefs = await SharedPreferences.getInstance();
      
      // Save what we found
      await prefs.setBool(_keyNeedsBatteryOptimization, isLowPowerMode ?? false);
      
      return isLowPowerMode ?? false;
    } catch (e) {
      print('Error checking battery optimization: $e');
      return false;
    }
  }

  // Request to disable battery optimization
  Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // Try to use method channel first
      try {
        final bool? result = await platform.invokeMethod<bool>('requestBatteryOptimizationDisable');
        if (result != null) return result;
      } catch (e) {
        print('Method channel error: $e');
        // Fall back to app settings
      }
      
      // Open battery optimization settings - using AppSettings.openAppSettings() instead
      await AppSettings.openAppSettings();
      await _saveLastCheckTime();
      
      return true;
    } catch (e) {
      print('Error requesting battery optimization: $e');
      return false;
    }
  }
  
  // Check and open battery settings if needed
  Future<void> checkAndRequestBatteryOptimization(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      // Only check periodically
      if (!await shouldCheckBatteryOptimization()) {
        return;
      }
      
      final bool needsOptimization = await isBatteryOptimizationEnabled();
      if (needsOptimization) {
        showBatteryOptimizationDialog(context);
      }
    } catch (e) {
      print('Error in checkAndRequestBatteryOptimization: $e');
    }
  }
  
  // Show dialog about battery optimization
  void showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحسين أداء الإشعارات'),
        content: const Text(
          'لضمان وصول إشعارات الأذكار بشكل منتظم، يرجى تعطيل وضع توفير البطارية للتطبيق.\n\n'
          'سيتم توجيهك إلى إعدادات البطارية، ثم اختر تطبيق الأذكار وحدد "عدم تحسين" أو "السماح في الخلفية".',
        ),
        actions: [
          TextButton(
            child: const Text('لاحقاً'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('فتح الإعدادات'),
            onPressed: () {
              Navigator.of(context).pop();
              _openBatterySettings();
            },
          ),
        ],
      ),
    );
  }
  
  // Open battery settings directly
  Future<void> _openBatterySettings() async {
    try {
      await requestDisableBatteryOptimization();
      await _saveLastCheckTime();
    } catch (e) {
      print('Error opening battery settings: $e');
      // Fallback to app settings
      AppSettings.openAppSettings();
    }
  }
  
  // Save when the last check was done
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving last battery check time: $e');
    }
  }
  
  // Check if we need to prompt user again (not too frequent)
  Future<bool> shouldCheckBatteryOptimization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_keyLastCheckTime) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Only check once per week (604800000 ms)
      return (now - lastCheckTime) > 604800000;
    } catch (e) {
      print('Error checking if should prompt battery optimization: $e');
      return false;
    }
  }
  
  // Check additional battery restrictions that might affect notifications
  Future<void> checkForAdditionalBatteryRestrictions(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      final manufacturer = await _getDeviceManufacturer();
      if (_isManufacturerWithSpecialRestrictions(manufacturer)) {
        _showManufacturerSpecificBatteryDialog(context, manufacturer);
      }
    } catch (e) {
      print('Error checking for additional battery restrictions: $e');
    }
  }
  
  // Get device manufacturer (simplified)
  Future<String> _getDeviceManufacturer() async {
    try {
      // deviceInfo is not available in battery_plus, use platform channel or default to "unknown"
      return "unknown";
    } catch (e) {
      return "unknown";
    }
  }
  
  // Check if manufacturer has special battery restrictions
  bool _isManufacturerWithSpecialRestrictions(String manufacturer) {
    final restrictiveManufacturers = [
      "xiaomi", "redmi", "poco", "huawei", "honor", "oppo", "vivo", "oneplus", "realme", "samsung"
    ];
    
    return restrictiveManufacturers.any(
      (brand) => manufacturer.toLowerCase().contains(brand)
    );
  }
  
  // Show dialog with manufacturer-specific instructions
  void _showManufacturerSpecificBatteryDialog(BuildContext context, String manufacturer) {
    String instructions = _getManufacturerSpecificInstructions(manufacturer);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات إضافية مطلوبة'),
        content: Text(instructions),
        actions: [
          TextButton(
            child: const Text('لاحقاً'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('فتح الإعدادات'),
            onPressed: () {
              Navigator.of(context).pop();
              AppSettings.openAppSettings();
            },
          ),
        ],
      ),
    );
  }
  
  // Get manufacturer-specific instructions
  String _getManufacturerSpecificInstructions(String manufacturer) {
    if (manufacturer.toLowerCase().contains("xiaomi") || 
        manufacturer.toLowerCase().contains("redmi") || 
        manufacturer.toLowerCase().contains("poco")) {
      return 'أجهزة شاومي/ريدمي/بوكو لديها إعدادات بطارية خاصة:\n\n'
             '1. افتح "الإعدادات" ثم "البطارية والأداء"\n'
             '2. اختر "توفير البطارية للتطبيقات"\n'
             '3. ابحث عن تطبيق الأذكار\n'
             '4. اختر "لا قيود" وفعّل "السماح بالتشغيل في الخلفية"';
    } else if (manufacturer.toLowerCase().contains("samsung")) {
      return 'أجهزة سامسونج لديها إعدادات بطارية خاصة:\n\n'
             '1. افتح "الإعدادات" ثم "الرعاية المتقدمة" أو "تحسين البطارية"\n'
             '2. اختر "البطارية" ثم "حدود استخدام البطارية في الخلفية"\n'
             '3. ابحث عن تطبيق الأذكار\n'
             '4. اختر "السماح بالاستخدام في الخلفية"';
    } else {
      return 'بعض أجهزة الأندرويد لديها إعدادات بطارية خاصة قد تؤثر على الإشعارات.\n\n'
             'يرجى التأكد من:\n'
             '1. تعطيل "توفير البطارية" للتطبيق\n'
             '2. السماح بتشغيل التطبيق في الخلفية\n'
             '3. السماح بالبدء التلقائي للتطبيق (إن وجد)';
    }
  }
}
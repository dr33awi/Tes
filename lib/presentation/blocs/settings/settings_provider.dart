// lib/presentation/blocs/settings/settings_provider.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/settings.dart';
import '../../../domain/usecases/settings/get_settings.dart';
import '../../../domain/usecases/settings/update_settings.dart';
import '../../../core/services/interfaces/notification_service.dart';
import '../../../app/di/service_locator.dart';

class SettingsProvider extends ChangeNotifier {
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;
  final NotificationService _notificationService = getIt<NotificationService>();
  
  Settings? _settings;
  bool _isLoading = false;
  String? _error;
  
  SettingsProvider({
    required GetSettings getSettings,
    required UpdateSettings updateSettings,
  })  : _getSettings = getSettings,
        _updateSettings = updateSettings;
  
  // الحالة الحالية
  Settings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  
  // تحميل الإعدادات
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _settings = await _getSettings();
      
      // تحديث إعدادات خدمة الإشعارات
      await _updateNotificationServiceSettings();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // تحديث الإعدادات
  Future<bool> updateSettings(Settings newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _updateSettings(newSettings);
      if (success) {
        _settings = newSettings;
        
        // تحديث إعدادات خدمة الإشعارات
        await _updateNotificationServiceSettings();
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return false;
    }
  }
  
  // تحديث إعداد محدد
  Future<bool> updateSetting({required String key, required dynamic value}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _updateSettings.updateSetting(key: key, value: value);
      if (success && _settings != null) {
        // تحديث الإعدادات المحلية
        switch (key) {
          case 'enableNotifications':
            _settings = _settings!.copyWith(enableNotifications: value as bool);
            break;
          case 'enablePrayerTimesNotifications':
            _settings = _settings!.copyWith(enablePrayerTimesNotifications: value as bool);
            break;
          case 'enableAthkarNotifications':
            _settings = _settings!.copyWith(enableAthkarNotifications: value as bool);
            break;
          case 'enableDarkMode':
            _settings = _settings!.copyWith(enableDarkMode: value as bool);
            break;
          case 'language':
            _settings = _settings!.copyWith(language: value as String);
            break;
          case 'calculationMethod':
            _settings = _settings!.copyWith(calculationMethod: value as int);
            break;
          case 'asrMethod':
            _settings = _settings!.copyWith(asrMethod: value as int);
            break;
          case 'respectBatteryOptimizations':
            _settings = _settings!.copyWith(respectBatteryOptimizations: value as bool);
            break;
          case 'respectDoNotDisturb':
            _settings = _settings!.copyWith(respectDoNotDisturb: value as bool);
            break;
          case 'enableHighPriorityForPrayers':
            _settings = _settings!.copyWith(enableHighPriorityForPrayers: value as bool);
            break;
          case 'enableSilentMode':
            _settings = _settings!.copyWith(enableSilentMode: value as bool);
            break;
          case 'lowBatteryThreshold':
            _settings = _settings!.copyWith(lowBatteryThreshold: value as int);
            break;
          case 'showAthkarReminders':
            _settings = _settings!.copyWith(showAthkarReminders: value as bool);
            break;
          case 'morningAthkarTime':
            _settings = _settings!.copyWith(morningAthkarTime: value as List<int>);
            break;
          case 'eveningAthkarTime':
            _settings = _settings!.copyWith(eveningAthkarTime: value as List<int>);
            break;
        }
        
        // تحديث إعدادات خدمة الإشعارات
        await _updateNotificationServiceSettings();
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return false;
    }
  }
  
  // تحديث إعدادات خدمة الإشعارات
  Future<void> _updateNotificationServiceSettings() async {
    if (_settings == null) return;
    
    // تحديث إعدادات احترام البطارية ووضع عدم الإزعاج
    await _notificationService.setRespectBatteryOptimizations(_settings!.respectBatteryOptimizations);
    await _notificationService.setRespectDoNotDisturb(_settings!.respectDoNotDisturb);
  }
}
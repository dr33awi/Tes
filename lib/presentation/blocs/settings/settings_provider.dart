// lib/presentation/blocs/settings/settings_provider.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/settings.dart';
import '../../../domain/usecases/settings/get_settings.dart';
import '../../../domain/usecases/settings/update_settings.dart';

class SettingsProvider extends ChangeNotifier {
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;
  
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
        }
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
}
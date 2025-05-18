// lib/data/datasources/local/settings_local_data_source.dart
import '../../../../core/services/interfaces/storage_service.dart';
import '../models/settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<Map<String, dynamic>> getSettings();
  Future<bool> updateSettings(Map<String, dynamic> settings);
  Future<bool> updateSetting({required String key, required dynamic value});
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final StorageService _storageService;
  final String _settingsKey = 'app_settings';

  SettingsLocalDataSourceImpl(this._storageService);

  @override
  Future<Map<String, dynamic>> getSettings() async {
    // الحصول على الإعدادات من التخزين المحلي
    final settings = _storageService.getMap(_settingsKey);
    
    // إذا لم يتم العثور على إعدادات، إرجاع الإعدادات الافتراضية
    if (settings == null) {
      final defaultSettings = SettingsModel.defaultSettings().toJson();
      await updateSettings(defaultSettings);
      return defaultSettings;
    }
    
    return settings;
  }

  @override
  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    // تحديث الإعدادات في التخزين المحلي
    return await _storageService.setMap(_settingsKey, settings);
  }

  @override
  Future<bool> updateSetting({required String key, required dynamic value}) async {
    // الحصول على الإعدادات الحالية
    final currentSettings = await getSettings();
    
    // تحديث الإعداد المحدد
    currentSettings[key] = value;
    
    // حفظ الإعدادات المحدثة
    return await updateSettings(currentSettings);
  }
}
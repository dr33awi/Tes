// lib/domain/repositories/settings_repository.dart
import '../entities/settings.dart';

abstract class SettingsRepository {
  /// الحصول على الإعدادات
  Future<Settings> getSettings();
  
  /// تحديث الإعدادات
  Future<bool> updateSettings(Settings settings);
  
  /// تحديث إعداد محدد
  Future<bool> updateSetting({
    required String key,
    required dynamic value,
  });
}
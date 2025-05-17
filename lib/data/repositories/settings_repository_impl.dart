// lib/data/repositories/settings_repository_impl.dart
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/settings_local_data_source.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl(this.localDataSource);

  @override
  Future<Settings> getSettings() async {
    // الحصول على الإعدادات من مصدر البيانات المحلي
    final settingsData = await localDataSource.getSettings();
    
    // تحويل البيانات إلى كيان
    return SettingsModel.fromJson(settingsData).toEntity();
  }

  @override
  Future<bool> updateSettings(Settings settings) async {
    // تحويل الكيان إلى نموذج
    final settingsModel = SettingsModel.fromEntity(settings);
    
    // تحديث الإعدادات في مصدر البيانات المحلي
    return await localDataSource.updateSettings(settingsModel.toJson());
  }

  @override
  Future<bool> updateSetting({required String key, required dynamic value}) async {
    // تحديث إعداد محدد في مصدر البيانات المحلي
    return await localDataSource.updateSetting(key: key, value: value);
  }
}
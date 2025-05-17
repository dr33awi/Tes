// lib/domain/usecases/settings/update_settings.dart
import '../../entities/settings.dart';
import '../../repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  Future<bool> call(Settings settings) async {
    return await repository.updateSettings(settings);
  }
  
  Future<bool> updateSetting({required String key, required dynamic value}) async {
    return await repository.updateSetting(key: key, value: value);
  }
}
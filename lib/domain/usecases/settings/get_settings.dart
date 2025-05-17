// lib/domain/usecases/settings/get_settings.dart
import '../../entities/settings.dart';
import '../../repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<Settings> call() async {
    return await repository.getSettings();
  }
}
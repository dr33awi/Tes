// lib/data/models/settings_model.dart (تكملة)
import '../../domain/entities/settings.dart';

class SettingsModel {
  final bool enableNotifications;
  final bool enablePrayerTimesNotifications;
  final bool enableAthkarNotifications;
  final bool enableDarkMode;
  final String language;
  final int calculationMethod;
  final int asrMethod;

  SettingsModel({
    required this.enableNotifications,
    required this.enablePrayerTimesNotifications,
    required this.enableAthkarNotifications,
    required this.enableDarkMode,
    required this.language,
    required this.calculationMethod,
    required this.asrMethod,
  });

  // إعدادات افتراضية
  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      enableNotifications: true,
      enablePrayerTimesNotifications: true,
      enableAthkarNotifications: true,
      enableDarkMode: false,
      language: 'ar',
      calculationMethod: 4, // طريقة أم القرى
      asrMethod: 0, // طريقة الشافعي
    );
  }

  // تحويل من JSON إلى نموذج
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      enableNotifications: json['enableNotifications'] ?? true,
      enablePrayerTimesNotifications: json['enablePrayerTimesNotifications'] ?? true,
      enableAthkarNotifications: json['enableAthkarNotifications'] ?? true,
      enableDarkMode: json['enableDarkMode'] ?? false,
      language: json['language'] ?? 'ar',
      calculationMethod: json['calculationMethod'] ?? 4,
      asrMethod: json['asrMethod'] ?? 0,
    );
  }

  // تحويل من نموذج إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'enablePrayerTimesNotifications': enablePrayerTimesNotifications,
      'enableAthkarNotifications': enableAthkarNotifications,
      'enableDarkMode': enableDarkMode,
      'language': language,
      'calculationMethod': calculationMethod,
      'asrMethod': asrMethod,
    };
  }

  // تحويل من نموذج إلى كيان
  Settings toEntity() {
    return Settings(
      enableNotifications: enableNotifications,
      enablePrayerTimesNotifications: enablePrayerTimesNotifications,
      enableAthkarNotifications: enableAthkarNotifications,
      enableDarkMode: enableDarkMode,
      language: language,
      calculationMethod: calculationMethod,
      asrMethod: asrMethod,
    );
  }

  // تحويل من كيان إلى نموذج
  factory SettingsModel.fromEntity(Settings settings) {
    return SettingsModel(
      enableNotifications: settings.enableNotifications,
      enablePrayerTimesNotifications: settings.enablePrayerTimesNotifications,
      enableAthkarNotifications: settings.enableAthkarNotifications,
      enableDarkMode: settings.enableDarkMode,
      language: settings.language,
      calculationMethod: settings.calculationMethod,
      asrMethod: settings.asrMethod,
    );
  }
}
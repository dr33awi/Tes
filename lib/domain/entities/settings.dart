// lib/domain/entities/settings.dart
class Settings {
  final bool enableNotifications;
  final bool enablePrayerTimesNotifications;
  final bool enableAthkarNotifications;
  final bool enableDarkMode;
  final String language;
  final int calculationMethod;
  final int asrMethod;

  Settings({
    this.enableNotifications = true,
    this.enablePrayerTimesNotifications = true,
    this.enableAthkarNotifications = true,
    this.enableDarkMode = false,
    this.language = 'ar',
    this.calculationMethod = 4, // طريقة أم القرى
    this.asrMethod = 0, // طريقة الشافعي
  });

  Settings copyWith({
    bool? enableNotifications,
    bool? enablePrayerTimesNotifications,
    bool? enableAthkarNotifications,
    bool? enableDarkMode,
    String? language,
    int? calculationMethod,
    int? asrMethod,
  }) {
    return Settings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enablePrayerTimesNotifications: enablePrayerTimesNotifications ?? this.enablePrayerTimesNotifications,
      enableAthkarNotifications: enableAthkarNotifications ?? this.enableAthkarNotifications,
      enableDarkMode: enableDarkMode ?? this.enableDarkMode,
      language: language ?? this.language,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
    );
  }
}
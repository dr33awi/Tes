// lib/domain/entities/settings.dart
class Settings {
  // إعدادات عامة
  final bool enableNotifications;
  final bool enablePrayerTimesNotifications;
  final bool enableAthkarNotifications;
  final bool enableDarkMode;
  final String language;
  
  // إعدادات مواقيت الصلاة
  final int calculationMethod;
  final int asrMethod;
  
  // إعدادات جديدة للإشعارات
  final bool respectBatteryOptimizations;
  final bool respectDoNotDisturb;
  final bool enableHighPriorityForPrayers;
  final bool enableSilentMode;
  final int lowBatteryThreshold;
  final bool useCustomSounds;
  final Map<String, String> notificationSounds;
  
  // إعدادات الأذكار
  final bool showAthkarReminders;
  final List<int> morningAthkarTime; // [hour, minute]
  final List<int> eveningAthkarTime; // [hour, minute]
  final bool enableActionButtons;

  Settings({
    this.enableNotifications = true,
    this.enablePrayerTimesNotifications = true,
    this.enableAthkarNotifications = true,
    this.enableDarkMode = false,
    this.language = 'ar',
    this.calculationMethod = 4, // طريقة أم القرى
    this.asrMethod = 0, // طريقة الشافعي
    this.respectBatteryOptimizations = true,
    this.respectDoNotDisturb = true,
    this.enableHighPriorityForPrayers = true,
    this.enableSilentMode = false,
    this.lowBatteryThreshold = 15,
    this.showAthkarReminders = true,
    this.morningAthkarTime = const [5, 0], // 5:00 صباحًا
    this.eveningAthkarTime = const [17, 0], // 5:00 مساءً
    this.useCustomSounds = false,
    this.notificationSounds = const {
      'prayer': 'adhan_sound',
      'athkar_morning': 'morning_athkar_sound',
      'athkar_evening': 'evening_athkar_sound',
      'reminder': 'reminder_sound',
    },
    this.enableActionButtons = true,
  });

  Settings copyWith({
    bool? enableNotifications,
    bool? enablePrayerTimesNotifications,
    bool? enableAthkarNotifications,
    bool? enableDarkMode,
    String? language,
    int? calculationMethod,
    int? asrMethod,
    bool? respectBatteryOptimizations,
    bool? respectDoNotDisturb,
    bool? enableHighPriorityForPrayers,
    bool? enableSilentMode,
    int? lowBatteryThreshold,
    bool? showAthkarReminders,
    List<int>? morningAthkarTime,
    List<int>? eveningAthkarTime,
    bool? useCustomSounds,
    Map<String, String>? notificationSounds,
    bool? enableActionButtons,
  }) {
    return Settings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enablePrayerTimesNotifications: enablePrayerTimesNotifications ?? this.enablePrayerTimesNotifications,
      enableAthkarNotifications: enableAthkarNotifications ?? this.enableAthkarNotifications,
      enableDarkMode: enableDarkMode ?? this.enableDarkMode,
      language: language ?? this.language,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      respectBatteryOptimizations: respectBatteryOptimizations ?? this.respectBatteryOptimizations,
      respectDoNotDisturb: respectDoNotDisturb ?? this.respectDoNotDisturb,
      enableHighPriorityForPrayers: enableHighPriorityForPrayers ?? this.enableHighPriorityForPrayers,
      enableSilentMode: enableSilentMode ?? this.enableSilentMode,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
      showAthkarReminders: showAthkarReminders ?? this.showAthkarReminders,
      morningAthkarTime: morningAthkarTime ?? this.morningAthkarTime,
      eveningAthkarTime: eveningAthkarTime ?? this.eveningAthkarTime,
      useCustomSounds: useCustomSounds ?? this.useCustomSounds,
      notificationSounds: notificationSounds ?? this.notificationSounds,
      enableActionButtons: enableActionButtons ?? this.enableActionButtons,
    );
  }
}
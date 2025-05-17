// lib/data/models/settings_model.dart
import '../../domain/entities/settings.dart';

class SettingsModel {
  final bool enableNotifications;
  final bool enablePrayerTimesNotifications;
  final bool enableAthkarNotifications;
  final bool enableDarkMode;
  final String language;
  final int calculationMethod;
  final int asrMethod;
  
  // إعدادات جديدة للإشعارات
  final bool respectBatteryOptimizations;
  final bool respectDoNotDisturb;
  final bool enableHighPriorityForPrayers;
  final bool enableSilentMode;
  final int lowBatteryThreshold;
  
  // إعدادات الأذكار
  final bool showAthkarReminders;
  final List<int> morningAthkarTime; // [hour, minute]
  final List<int> eveningAthkarTime; // [hour, minute]

  SettingsModel({
    required this.enableNotifications,
    required this.enablePrayerTimesNotifications,
    required this.enableAthkarNotifications,
    required this.enableDarkMode,
    required this.language,
    required this.calculationMethod,
    required this.asrMethod,
    required this.respectBatteryOptimizations,
    required this.respectDoNotDisturb,
    required this.enableHighPriorityForPrayers,
    required this.enableSilentMode,
    required this.lowBatteryThreshold,
    required this.showAthkarReminders,
    required this.morningAthkarTime,
    required this.eveningAthkarTime,
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
      respectBatteryOptimizations: true,
      respectDoNotDisturb: true,
      enableHighPriorityForPrayers: true,
      enableSilentMode: false,
      lowBatteryThreshold: 15,
      showAthkarReminders: true,
      morningAthkarTime: [5, 0], // 5:00 صباحًا
      eveningAthkarTime: [17, 0], // 5:00 مساءً
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
      respectBatteryOptimizations: json['respectBatteryOptimizations'] ?? true,
      respectDoNotDisturb: json['respectDoNotDisturb'] ?? true,
      enableHighPriorityForPrayers: json['enableHighPriorityForPrayers'] ?? true,
      enableSilentMode: json['enableSilentMode'] ?? false,
      lowBatteryThreshold: json['lowBatteryThreshold'] ?? 15,
      showAthkarReminders: json['showAthkarReminders'] ?? true,
      morningAthkarTime: json['morningAthkarTime'] != null
          ? List<int>.from(json['morningAthkarTime'])
          : [5, 0],
      eveningAthkarTime: json['eveningAthkarTime'] != null
          ? List<int>.from(json['eveningAthkarTime'])
          : [17, 0],
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
      'respectBatteryOptimizations': respectBatteryOptimizations,
      'respectDoNotDisturb': respectDoNotDisturb,
      'enableHighPriorityForPrayers': enableHighPriorityForPrayers,
      'enableSilentMode': enableSilentMode,
      'lowBatteryThreshold': lowBatteryThreshold,
      'showAthkarReminders': showAthkarReminders,
      'morningAthkarTime': morningAthkarTime,
      'eveningAthkarTime': eveningAthkarTime,
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
      respectBatteryOptimizations: respectBatteryOptimizations,
      respectDoNotDisturb: respectDoNotDisturb,
      enableHighPriorityForPrayers: enableHighPriorityForPrayers,
      enableSilentMode: enableSilentMode,
      lowBatteryThreshold: lowBatteryThreshold,
      showAthkarReminders: showAthkarReminders,
      morningAthkarTime: morningAthkarTime,
      eveningAthkarTime: eveningAthkarTime,
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
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
      enableHighPriorityForPrayers: settings.enableHighPriorityForPrayers,
      enableSilentMode: settings.enableSilentMode,
      lowBatteryThreshold: settings.lowBatteryThreshold,
      showAthkarReminders: settings.showAthkarReminders,
      morningAthkarTime: settings.morningAthkarTime,
      eveningAthkarTime: settings.eveningAthkarTime,
    );
  }
}
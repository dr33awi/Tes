// lib/features/settings/presentation/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/settings.dart';

class SettingsProvider extends ChangeNotifier {
  Settings? _settings;
  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  Settings? get settings => _settings;
  String? get error => _error;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final calculationMethod = prefs.getInt('calculationMethod') ?? 2;
      final asrMethod = prefs.getInt('asrMethod') ?? 0;
      final adjustForDst = prefs.getBool('adjustForDst') ?? true;
      final themeMode = prefs.getString('themeMode') ?? 'system';
      final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      final appLanguage = prefs.getString('appLanguage') ?? 'ar';
      final highContrastMode = prefs.getBool('highContrastMode') ?? false;
      final textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
      final fontFamily = prefs.getString('fontFamily') ?? 'default';
      final reduceMotion = prefs.getBool('reduceMotion') ?? false;
      final vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      final lastOpenedTab = prefs.getInt('lastOpenedTab') ?? 0;
      final enableDataSync = prefs.getBool('enableDataSync') ?? false;
      final userAccountId = prefs.getString('userAccountId') ?? '';
      
      _settings = Settings(
        calculationMethod: calculationMethod,
        asrMethod: asrMethod,
        adjustForDst: adjustForDst,
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        appLanguage: appLanguage,
        highContrastMode: highContrastMode,
        textScaleFactor: textScaleFactor,
        fontFamily: fontFamily,
        reduceMotion: reduceMotion,
        vibrationEnabled: vibrationEnabled,
        lastOpenedTab: lastOpenedTab,
        enableDataSync: enableDataSync,
        userAccountId: userAccountId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings({
    int? calculationMethod,
    int? asrMethod,
    bool? adjustForDst,
    String? themeMode,
    bool? notificationsEnabled,
    String? appLanguage,
    bool? highContrastMode,
    double? textScaleFactor,
    String? fontFamily,
    bool? reduceMotion,
    bool? vibrationEnabled,
    int? lastOpenedTab,
    bool? enableDataSync,
    String? userAccountId,
  }) async {
    if (_settings == null) return;

    try {
      final updatedSettings = _settings!.copyWith(
        calculationMethod: calculationMethod,
        asrMethod: asrMethod,
        adjustForDst: adjustForDst,
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        appLanguage: appLanguage,
        highContrastMode: highContrastMode,
        textScaleFactor: textScaleFactor,
        fontFamily: fontFamily,
        reduceMotion: reduceMotion,
        vibrationEnabled: vibrationEnabled,
        lastOpenedTab: lastOpenedTab,
        enableDataSync: enableDataSync,
        userAccountId: userAccountId,
      );

      final prefs = await SharedPreferences.getInstance();
      
      if (calculationMethod != null) {
        await prefs.setInt('calculationMethod', calculationMethod);
      }
      
      if (asrMethod != null) {
        await prefs.setInt('asrMethod', asrMethod);
      }
      
      if (adjustForDst != null) {
        await prefs.setBool('adjustForDst', adjustForDst);
      }
      
      if (themeMode != null) {
        await prefs.setString('themeMode', themeMode);
      }
      
      if (notificationsEnabled != null) {
        await prefs.setBool('notificationsEnabled', notificationsEnabled);
      }
      
      if (appLanguage != null) {
        await prefs.setString('appLanguage', appLanguage);
      }
      
      if (highContrastMode != null) {
        await prefs.setBool('highContrastMode', highContrastMode);
      }
      
      if (textScaleFactor != null) {
        await prefs.setDouble('textScaleFactor', textScaleFactor);
      }
      
      if (fontFamily != null) {
        await prefs.setString('fontFamily', fontFamily);
      }
      
      if (reduceMotion != null) {
        await prefs.setBool('reduceMotion', reduceMotion);
      }
      
      if (vibrationEnabled != null) {
        await prefs.setBool('vibrationEnabled', vibrationEnabled);
      }
      
      if (lastOpenedTab != null) {
        await prefs.setInt('lastOpenedTab', lastOpenedTab);
      }
      
      if (enableDataSync != null) {
        await prefs.setBool('enableDataSync', enableDataSync);
      }
      
      if (userAccountId != null) {
        await prefs.setString('userAccountId', userAccountId);
      }

      _settings = updatedSettings;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Aktualisieren des Themes
  Future<void> updateTheme(String themeMode) async {
    await updateSettings(themeMode: themeMode);
  }

  // Aktualisieren der App-Sprache
  Future<void> updateLanguage(String language) async {
    await updateSettings(appLanguage: language);
  }

  // Aktivieren/Deaktivieren von Benachrichtigungen
  Future<void> toggleNotifications(bool enabled) async {
    await updateSettings(notificationsEnabled: enabled);
  }

  // Zurücksetzen auf Standardeinstellungen
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = const Settings();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calculationMethod', defaultSettings.calculationMethod);
      await prefs.setInt('asrMethod', defaultSettings.asrMethod);
      await prefs.setBool('adjustForDst', defaultSettings.adjustForDst);
      await prefs.setString('themeMode', defaultSettings.themeMode);
      await prefs.setBool('notificationsEnabled', defaultSettings.notificationsEnabled);
      await prefs.setString('appLanguage', defaultSettings.appLanguage);
      await prefs.setBool('highContrastMode', defaultSettings.highContrastMode);
      await prefs.setDouble('textScaleFactor', defaultSettings.textScaleFactor);
      await prefs.setString('fontFamily', defaultSettings.fontFamily);
      await prefs.setBool('reduceMotion', defaultSettings.reduceMotion);
      await prefs.setBool('vibrationEnabled', defaultSettings.vibrationEnabled);
      await prefs.setInt('lastOpenedTab', defaultSettings.lastOpenedTab);
      await prefs.setBool('enableDataSync', defaultSettings.enableDataSync);
      await prefs.setString('userAccountId', defaultSettings.userAccountId);
      
      _settings = defaultSettings;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
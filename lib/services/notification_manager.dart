// lib/services/notification/notification_manager.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/notification_service_interface.dart';
import 'package:test_athkar_app/services/android_notification_service.dart';
import 'package:test_athkar_app/services/ios_notification_service.dart';
import 'dart:io' show Platform;

/// Manager für alle Benachrichtigungsfunktionen der App
/// Dient als zentrale Anlaufstelle für alle Benachrichtigungsfunktionen
class NotificationManager {
  // Das spezifische Service-Implementierung basierend auf der Plattform
  late NotificationServiceInterface _notificationService;
  
  // Abhängigkeiten
  final ErrorLoggingService _errorLoggingService;
  
  // Konstanten für lokale Speicherung
  static const String _keyNotificationSettings = 'notification_settings';
  
  // Benutzereinstellungen
  NotificationSettings _settings = NotificationSettings();
  
  NotificationManager({
    required ErrorLoggingService errorLoggingService,
  }) : _errorLoggingService = errorLoggingService {
    // Plattformspezifischen Service initialisieren
    _initPlatformService();
  }
  
  /// Initialisiert den richtigen Service basierend auf der Plattform
  void _initPlatformService() {
    final serviceLocator = GetIt.instance;
    
    if (Platform.isAndroid) {
      _notificationService = serviceLocator<AndroidNotificationService>();
    } else if (Platform.isIOS) {
      _notificationService = serviceLocator<IOSNotificationService>();
    } else {
      // Fallback-Implementierung
      _notificationService = serviceLocator<AndroidNotificationService>();
    }
  }
  
  /// Initialisiert den NotificationManager
  Future<bool> initialize() async {
    try {
      // Benutzereinstellungen laden
      await _loadSettings();
      
      // Plattformspezifischen Service initialisieren
      final result = await _notificationService.initialize();
      
      // Service mit Benutzereinstellungen konfigurieren
      if (result) {
        await _notificationService.configureFromPreferences();
      }
      
      return result;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'Fehler bei der Initialisierung des NotificationManagers', 
        e
      );
      return false;
    }
  }
  
  /// Lädt die Benutzereinstellungen aus dem lokalen Speicher
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsStr = prefs.getString(_keyNotificationSettings);
      
      if (settingsStr != null) {
        _settings = NotificationSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(settingsStr))
        );
      }
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'Fehler beim Laden der Benachrichtigungseinstellungen', 
        e
      );
    }
  }
  
  /// Speichert die Benutzereinstellungen im lokalen Speicher
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationSettings, jsonEncode(_settings.toJson()));
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'Fehler beim Speichern der Benachrichtigungseinstellungen', 
        e
      );
    }
  }
  
  /// Gibt die aktuellen Benutzereinstellungen zurück
  NotificationSettings get settings => _settings;
  
  /// Aktualisiert die Benutzereinstellungen
  Future<void> updateSettings(NotificationSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    await _notificationService.configureFromPreferences();
  }
  
  /// Aktiviert oder deaktiviert alle Benachrichtigungen
  Future<bool> setNotificationsEnabled(bool enabled) async {
    try {
      final result = await _notificationService.setNotificationsEnabled(enabled);
      if (result) {
        _settings = _settings.copyWith(enabled: enabled);
        await _saveSettings();
      }
      return result;
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'Fehler beim Ändern des Benachrichtigungsstatus', 
        e
      );
      return false;
    }
  }
  
  /// Prüft, ob alle notwendigen Berechtigungen und Einstellungen für Benachrichtigungen vorhanden sind
  Future<bool> checkNotificationPrerequisites(BuildContext context) async {
    return await _notificationService.checkNotificationPrerequisites(context);
  }
  
  /// Plant eine Benachrichtigung für eine bestimmte Athkar-Kategorie
  Future<bool> scheduleAthkarNotification({
    required AthkarCategory category,
    required TimeOfDay notificationTime,
    bool repeat = true,
  }) async {
    try {
      if (!_settings.enabled) return false;
      
      // Prüfen, ob diese Kategorie aktiviert ist
      if (!_isCategoryEnabled(category.id)) return false;
      
      return await _notificationService.scheduleAthkarNotification(
        category: category,
        notificationTime: notificationTime,
        repeat: repeat,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'Fehler beim Planen einer Athkar-Benachrichtigung', 
        e
      );
      return false;
    }
  }
  
  /// Prüft, ob eine bestimmte Kategorie aktiviert ist
  bool _isCategoryEnabled(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return _settings.morningAthkarEnabled;
      case 'evening':
        return _settings.eveningAthkarEnabled;
      case 'sleep':
        return _settings.sleepAthkarEnabled;
      case 'wake':
        return _settings.wakeAthkarEnabled;
      case 'prayer':
        return _settings.prayerAthkarEnabled;
      default:
        return true; // Standardmäßig aktiviert
    }
  }
  
  /// Plant mehrere Benachrichtigungen für eine Athkar-Kategorie
  Future<bool> scheduleMultipleAthkarNotifications({
    required AthkarCategory category,
    required List<TimeOfDay> notificationTimes,
  }) async {
    try {
      if (!_settings.enabled) return false;
      if (!_isCategoryEnabled(category.id)) return false;
      
      return await _notificationService.scheduleMultipleAthkarNotifications(
        category: category,
        notificationTimes: notificationTimes,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'NotificationManager', 
        'Fehler beim Planen mehrerer Athkar-Benachrichtigungen', 
        e
      );
      return false;
    }
  }
  
  /// Bricht eine Benachrichtigung ab
  Future<bool> cancelNotification(String notificationId) async {
    return await _notificationService.cancelNotification(notificationId);
  }
  
  /// Bricht alle Benachrichtigungen ab
  Future<bool> cancelAllNotifications() async {
    return await _notificationService.cancelAllNotifications();
  }
  
  /// Plant alle gespeicherten Benachrichtigungen neu
  Future<void> rescheduleAllNotifications() async {
    await _notificationService.scheduleAllSavedNotifications();
  }
  
  /// Sendet eine Testbenachrichtigung
  Future<bool> sendTestNotification() async {
    return await _notificationService.testImmediateNotification();
  }
  
  /// Überprüft und optimiert Benachrichtigungseinstellungen
  Future<void> checkNotificationOptimizations(BuildContext context) async {
    await _notificationService.checkNotificationOptimizations(context);
  }
}

/// Benutzereinstellungen für Benachrichtigungen
class NotificationSettings {
  final bool enabled;
  final bool morningAthkarEnabled;
  final bool eveningAthkarEnabled;
  final bool sleepAthkarEnabled;
  final bool wakeAthkarEnabled;
  final bool prayerAthkarEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool shouldBypassDnd;
  final bool groupSimilarNotifications;
  
  NotificationSettings({
    this.enabled = true,
    this.morningAthkarEnabled = true,
    this.eveningAthkarEnabled = true,
    this.sleepAthkarEnabled = true,
    this.wakeAthkarEnabled = true,
    this.prayerAthkarEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.shouldBypassDnd = false,
    this.groupSimilarNotifications = true,
  });
  
  /// Erstellt ein Objekt aus JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      morningAthkarEnabled: json['morningAthkarEnabled'] ?? true,
      eveningAthkarEnabled: json['eveningAthkarEnabled'] ?? true,
      sleepAthkarEnabled: json['sleepAthkarEnabled'] ?? true,
      wakeAthkarEnabled: json['wakeAthkarEnabled'] ?? true,
      prayerAthkarEnabled: json['prayerAthkarEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      shouldBypassDnd: json['shouldBypassDnd'] ?? false,
      groupSimilarNotifications: json['groupSimilarNotifications'] ?? true,
    );
  }
  
  /// Konvertiert in JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'morningAthkarEnabled': morningAthkarEnabled,
      'eveningAthkarEnabled': eveningAthkarEnabled,
      'sleepAthkarEnabled': sleepAthkarEnabled,
      'wakeAthkarEnabled': wakeAthkarEnabled,
      'prayerAthkarEnabled': prayerAthkarEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'shouldBypassDnd': shouldBypassDnd,
      'groupSimilarNotifications': groupSimilarNotifications,
    };
  }
  
  /// Erstellt eine Kopie mit Änderungen
  NotificationSettings copyWith({
    bool? enabled,
    bool? morningAthkarEnabled,
    bool? eveningAthkarEnabled,
    bool? sleepAthkarEnabled,
    bool? wakeAthkarEnabled,
    bool? prayerAthkarEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? shouldBypassDnd,
    bool? groupSimilarNotifications,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      morningAthkarEnabled: morningAthkarEnabled ?? this.morningAthkarEnabled,
      eveningAthkarEnabled: eveningAthkarEnabled ?? this.eveningAthkarEnabled,
      sleepAthkarEnabled: sleepAthkarEnabled ?? this.sleepAthkarEnabled,
      wakeAthkarEnabled: wakeAthkarEnabled ?? this.wakeAthkarEnabled,
      prayerAthkarEnabled: prayerAthkarEnabled ?? this.prayerAthkarEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      shouldBypassDnd: shouldBypassDnd ?? this.shouldBypassDnd,
      groupSimilarNotifications: groupSimilarNotifications ?? this.groupSimilarNotifications,
    );
  }
}
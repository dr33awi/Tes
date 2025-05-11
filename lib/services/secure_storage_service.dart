// lib/services/secure_storage_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// Service zum sicheren Speichern sensibler Daten
class SecureStorageService {
  // Singleton-Pattern mit Dependency Injection
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService({
    ErrorLoggingService? errorLoggingService,
  }) {
    _instance._errorLoggingService = errorLoggingService ?? ErrorLoggingService();
    return _instance;
  }
  
  SecureStorageService._internal();
  
  // Abhängigkeiten
  late ErrorLoggingService _errorLoggingService;
  
  // Secure Storage Instanz
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  // Flag zur Markierung, ob Secure Storage verwendet werden kann
  bool _canUseSecureStorage = true;
  
  /// Initialisiert den Service
  Future<void> initialize() async {
    try {
      // Prüfen, ob Secure Storage verfügbar ist
      await _secureStorage.write(key: 'test_key', value: 'test_value');
      await _secureStorage.read(key: 'test_key');
      await _secureStorage.delete(key: 'test_key');
      
      _canUseSecureStorage = true;
    } catch (e) {
      _canUseSecureStorage = false;
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Secure Storage nicht verfügbar, verwende Fallback',
        e
      );
    }
  }
  
  /// Speichert einen String sicher
  Future<void> write({required String key, required String value}) async {
    try {
      if (_canUseSecureStorage) {
        await _secureStorage.write(key: key, value: value);
      } else {
        // Fallback zu SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Schreiben des Werts: $key',
        e
      );
      
      // Fallback zu SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (e2) {
        await _errorLoggingService.logError(
          'SecureStorageService',
          'Auch Fallback zu SharedPreferences fehlgeschlagen für: $key',
          e2
        );
      }
    }
  }
  
  /// Liest einen String sicher
  Future<String?> read({required String key}) async {
    try {
      if (_canUseSecureStorage) {
        return await _secureStorage.read(key: key);
      } else {
        // Fallback zu SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Lesen des Werts: $key',
        e
      );
      
      // Fallback zu SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (e2) {
        await _errorLoggingService.logError(
          'SecureStorageService',
          'Auch Fallback zu SharedPreferences fehlgeschlagen für: $key',
          e2
        );
        return null;
      }
    }
  }
  
  /// Entfernt einen Wert
  Future<void> delete({required String key}) async {
    try {
      if (_canUseSecureStorage) {
        await _secureStorage.delete(key: key);
      }
      
      // Immer auch aus SharedPreferences löschen, falls dort gespeichert
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Löschen des Werts: $key',
        e
      );
    }
  }
  
  /// Speichert einen beliebigen Wert als JSON
  Future<void> writeObject({required String key, required dynamic value}) async {
    try {
      final jsonString = jsonEncode(value);
      await write(key: key, value: jsonString);
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Schreiben des Objekts: $key',
        e
      );
    }
  }
  
  /// Liest ein Objekt aus JSON
  Future<T?> readObject<T>({
    required String key,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      final jsonString = await read(key: key);
      if (jsonString == null) return null;
      
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return fromJson(json);
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Lesen des Objekts: $key',
        e
      );
      return null;
    }
  }
  
  /// Speichert eine Liste von Objekten
  Future<void> writeList<T>({
    required String key,
    required List<T> list,
    required dynamic Function(T item) toJson,
  }) async {
    try {
      final jsonData = list.map((item) => toJson(item)).toList();
      final jsonString = jsonEncode(jsonData);
      await write(key: key, value: jsonString);
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Schreiben der Liste: $key',
        e
      );
    }
  }
  
  /// Liest eine Liste von Objekten
  Future<List<T>?> readList<T>({
    required String key,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      final jsonString = await read(key: key);
      if (jsonString == null) return null;
      
      final List<dynamic> jsonData = jsonDecode(jsonString);
      return jsonData
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Lesen der Liste: $key',
        e
      );
      return null;
    }
  }
  
  /// Speichert eine einfache Liste von Strings
  Future<void> writeStringList({required String key, required List<String> list}) async {
    try {
      final jsonString = jsonEncode(list);
      await write(key: key, value: jsonString);
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Schreiben der String-Liste: $key',
        e
      );
      
      // Fallback zu SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(key, list);
      } catch (e2) {
        await _errorLoggingService.logError(
          'SecureStorageService',
          'Auch Fallback zu SharedPreferences fehlgeschlagen für String-Liste: $key',
          e2
        );
      }
    }
  }
  
  /// Liest eine einfache Liste von Strings
  Future<List<String>?> readStringList({required String key}) async {
    try {
      final jsonString = await read(key: key);
      if (jsonString == null) {
        // Fallback zu SharedPreferences für Abwärtskompatibilität
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList(key);
      }
      
      final List<dynamic> jsonData = jsonDecode(jsonString);
      return jsonData.map((item) => item.toString()).toList();
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Lesen der String-Liste: $key',
        e
      );
      
      // Fallback zu SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList(key);
      } catch (e2) {
        await _errorLoggingService.logError(
          'SecureStorageService',
          'Auch Fallback zu SharedPreferences fehlgeschlagen für String-Liste: $key',
          e2
        );
        return null;
      }
    }
  }
  
  /// Prüft, ob ein Schlüssel existiert
  Future<bool> containsKey({required String key}) async {
    try {
      if (_canUseSecureStorage) {
        final allKeys = await _secureStorage.readAll();
        return allKeys.containsKey(key);
      } else {
        // Fallback zu SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        return prefs.containsKey(key);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Prüfen des Schlüssels: $key',
        e
      );
      
      // Fallback zu SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.containsKey(key);
      } catch (e2) {
        await _errorLoggingService.logError(
          'SecureStorageService',
          'Auch Fallback zu SharedPreferences fehlgeschlagen für Schlüsselprüfung: $key',
          e2
        );
        return false;
      }
    }
  }
  
  /// Löscht alle gespeicherten Werte
  Future<void> deleteAll() async {
    try {
      if (_canUseSecureStorage) {
        await _secureStorage.deleteAll();
      }
      
      // Auch SharedPreferences löschen
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      await _errorLoggingService.logError(
        'SecureStorageService',
        'Fehler beim Löschen aller Werte',
        e
      );
    }
  }
}
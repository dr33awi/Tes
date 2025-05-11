// lib/services/battery_optimization_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Datenklasse für Herstellerspezifische Anweisungen
class ManufacturerInstructions {
  final String name;
  final String instructions;
  final List<String> keywords;
  final String settingsPath;
  
  const ManufacturerInstructions({
    required this.name,
    required this.instructions,
    required this.keywords,
    required this.settingsPath,
  });
}

/// Service zur Verwaltung von Batterieoptimierungseinstellungen
class BatteryOptimizationService {
  // Singleton-Pattern mit Dependency Injection
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  
  factory BatteryOptimizationService({
    ErrorLoggingService? errorLoggingService,
  }) {
    _instance._errorLoggingService = errorLoggingService ?? ErrorLoggingService();
    return _instance;
  }
  
  BatteryOptimizationService._internal();
  
  // Abhängigkeiten
  late ErrorLoggingService _errorLoggingService;
  
  // Konstanten für lokale Speicherung
  static const String _keyBatteryOptimizationChecked = 'battery_optimization_checked';
  static const String _keyNeedsBatteryOptimization = 'needs_battery_optimization';
  static const String _keyLastCheckTime = 'battery_optimization_last_check';
  static const String _keyDeviceManufacturer = 'device_manufacturer';
  static const String _keyDeviceModel = 'device_model';
  static const String _keyUserDismissed = 'battery_optimization_dismissed';
  
  // Method Channel für native Kommunikation
  static const platform = MethodChannel('com.athkar.app/battery_optimization');
  
  // Battery Objekt
  final Battery _battery = Battery();
  
  // DeviceInfoPlugin für bessere Geräteerkennung
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Anwendungsname für Hinweise
  String _appName = "Athkar App";
  
  // Liste bekannter Hersteller und ihrer Anweisungen
  final List<ManufacturerInstructions> _manufacturers = [
    ManufacturerInstructions(
      name: "Xiaomi",
      keywords: ["xiaomi", "redmi", "poco"],
      instructions: 
        '1. Öffne "Einstellungen" > "Batterie & Leistung"\n'
        '2. Wähle "Batteriesparmodus für Apps"\n'
        '3. Suche nach {APP_NAME}\n'
        '4. Wähle "Keine Einschränkungen" und aktiviere "Im Hintergrund ausführen"',
      settingsPath: "Einstellungen > Batterie & Leistung > Batteriesparmodus für Apps",
    ),
    ManufacturerInstructions(
      name: "Samsung",
      keywords: ["samsung"],
      instructions: 
        '1. Öffne "Einstellungen" > "Batterie"\n'
        '2. Wähle "Batterieverbrauch" oder "Energiesparmodus"\n'
        '3. Suche nach {APP_NAME}\n'
        '4. Wähle "Uneingeschränkt" unter Hintergrundbetrieb',
      settingsPath: "Einstellungen > Batterie > Batterieverbrauch",
    ),
    ManufacturerInstructions(
      name: "Huawei",
      keywords: ["huawei", "honor"],
      instructions: 
        '1. Öffne "Einstellungen" > "Batterie"\n'
        '2. Wähle "App-Start" oder "Geschützte Apps"\n'
        '3. Suche nach {APP_NAME}\n'
        '4. Aktiviere sowohl "Automatisch starten" als auch "Im Hintergrund ausführen"',
      settingsPath: "Einstellungen > Batterie > App-Start",
    ),
    ManufacturerInstructions(
      name: "Oppo/Realme/Vivo/OnePlus",
      keywords: ["oppo", "realme", "vivo", "oneplus"],
      instructions: 
        '1. Öffne "Einstellungen" > "Batterie"\n'
        '2. Wähle "Batterieoptimierung" oder "Hintergrundaktivitäten"\n'
        '3. Suche nach {APP_NAME}\n'
        '4. Wähle "Keine Optimierung" und "Im Hintergrund ausführen erlauben"',
      settingsPath: "Einstellungen > Batterie > Batterieoptimierung",
    ),
  ];
  
  /// Initialisiert den Service
  Future<void> initialize() async {
    try {
      // App-Informationen laden
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      
      // Geräteinformationen speichern
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyDeviceManufacturer, androidInfo.manufacturer.toLowerCase());
        await prefs.setString(_keyDeviceModel, androidInfo.model.toLowerCase());
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService',
        'Fehler bei der Initialisierung',
        e
      );
    }
  }

  /// Prüft, ob Batterieoptimierung für die App aktiviert ist
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Zuerst versuchen, die Method Channel zu nutzen
      try {
        final bool? result = await platform.invokeMethod<bool>('isBatteryOptimizationEnabled');
        if (result != null) return result;
      } catch (e) {
        print('Method Channel Fehler: $e');
        await _errorLoggingService.logError(
          'BatteryOptimizationService', 
          'Fehler bei der Prüfung der Batterieoptimierung über Method Channel', 
          e
        );
      }
      
      // Prüfen, ob Energiesparmodus als Alternative erkannt werden kann
      final isLowPowerMode = await _battery.isInBatterySaveMode;
      
      // Dies ist nicht optimal, kann aber Hinweise geben
      final prefs = await SharedPreferences.getInstance();
      
      // Ergebnis speichern
      await prefs.setBool(_keyNeedsBatteryOptimization, isLowPowerMode ?? false);
      
      return isLowPowerMode ?? false;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler bei der Prüfung der Batterieoptimierung', 
        e
      );
      return false;
    }
  }

  /// Bittet den Nutzer, Batterieoptimierung zu deaktivieren
  Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // Zuerst versuchen, die Method Channel zu nutzen
      try {
        final bool? result = await platform.invokeMethod<bool>('requestBatteryOptimizationDisable');
        if (result != null) return result;
      } catch (e) {
        print('Method Channel Fehler: $e');
        await _errorLoggingService.logError(
          'BatteryOptimizationService', 
          'Fehler bei der Deaktivierung der Batterieoptimierung über Method Channel', 
          e
        );
      }
      
      // Batterieeinstellungen öffnen
      await AppSettings.openAppSettings();
      await _saveLastCheckTime();
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler bei der Anfrage zur Deaktivierung der Batterieoptimierung', 
        e
      );
      return false;
    }
  }
  
  /// Prüft und öffnet Batterieeinstellungen, wenn nötig
  Future<void> checkAndRequestBatteryOptimization(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      // Nur periodisch prüfen
      if (!await shouldCheckBatteryOptimization()) {
        return;
      }
      
      // Prüfen, ob der Nutzer diese Warnung bereits abgelehnt hat
      final prefs = await SharedPreferences.getInstance();
      final userDismissed = prefs.getBool(_keyUserDismissed) ?? false;
      
      if (userDismissed) {
        // Wenn der Nutzer die Warnung verworfen hat, nur selten erneut prüfen (einmal pro Monat)
        final lastCheckTime = prefs.getInt(_keyLastCheckTime) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // 30 Tage (in Millisekunden) 
        if (now - lastCheckTime < 30 * 24 * 60 * 60 * 1000) {
          return;
        }
      }
      
      final bool needsOptimization = await isBatteryOptimizationEnabled();
      if (needsOptimization) {
        showBatteryOptimizationDialog(context);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler in checkAndRequestBatteryOptimization', 
        e
      );
    }
  }
  
  /// Zeigt einen Dialog zur Batterieoptimierung an
  void showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text('Benachrichtigungen optimieren')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Für zuverlässige Athkar-Benachrichtigungen sollten Sie den Batteriesparmodus für diese App deaktivieren.\n\n'
              'Sie werden zu den Batterieeinstellungen weitergeleitet. Bitte wählen Sie dort "$_appName" und deaktivieren Sie die Batterieoptimierung.',
            ),
            SizedBox(height: 12),
            _buildManufacturerSpecificNote(),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Nicht jetzt'),
            onPressed: () {
              _markUserDismissed();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Nie wieder anzeigen'),
            onPressed: () {
              _markUserDismissedPermanently();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Einstellungen öffnen'),
            onPressed: () {
              Navigator.of(context).pop();
              _openBatterySettings();
            },
          ),
        ],
      ),
    );
  }
  
  /// Erstellt einen herstellerspezifischen Hinweis
  Widget _buildManufacturerSpecificNote() {
    return FutureBuilder<String>(
      future: _getDeviceManufacturer(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final manufacturer = snapshot.data!;
          final matchingInstructions = _getManufacturerInstructions(manufacturer);
          
          if (matchingInstructions != null) {
            final instructions = matchingInstructions.instructions.replaceAll('{APP_NAME}', _appName);
            
            return Card(
              margin: EdgeInsets.only(top: 16),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Für ${matchingInstructions.name}-Geräte:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(instructions),
                  ],
                ),
              ),
            );
          }
        }
        
        return SizedBox.shrink();
      },
    );
  }
  
  /// Markiert, dass der Nutzer den Dialog abgelehnt hat
  Future<void> _markUserDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserDismissed, true);
      await _saveLastCheckTime();
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler beim Markieren der Benutzerablehnung', 
        e
      );
    }
  }
  
  /// Markiert, dass der Nutzer den Dialog permanent ablehnt
  Future<void> _markUserDismissedPermanently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUserDismissed, true);
      
      // Sehr weit in der Zukunft als letzten Prüfzeitpunkt setzen
      final farFuture = DateTime.now().add(Duration(days: 365)).millisecondsSinceEpoch;
      await prefs.setInt(_keyLastCheckTime, farFuture);
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler beim permanenten Markieren der Benutzerablehnung', 
        e
      );
    }
  }
  
  /// Öffnet die Batterieeinstellungen direkt
  Future<void> _openBatterySettings() async {
    try {
      await requestDisableBatteryOptimization();
      await _saveLastCheckTime();
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler beim Öffnen der Batterieeinstellungen', 
        e
      );
      // Fallback zu App-Einstellungen
      AppSettings.openAppSettings();
    }
  }
  
  /// Speichert den Zeitpunkt der letzten Prüfung
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler beim Speichern des letzten Prüfzeitpunkts', 
        e
      );
    }
  }
  
  /// Prüft, ob wir den Nutzer erneut fragen sollten (nicht zu häufig)
  Future<bool> shouldCheckBatteryOptimization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_keyLastCheckTime) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Nur einmal pro Woche (604800000 Millisekunden) prüfen
      return (now - lastCheckTime) > 604800000;
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler bei der Prüfung, ob Batterieoptimierung abgefragt werden sollte', 
        e
      );
      return false;
    }
  }
  
  /// Prüft auf zusätzliche Batterieeinschränkungen, die Benachrichtigungen beeinflussen könnten
  Future<void> checkForAdditionalBatteryRestrictions(BuildContext context) async {
    if (!Platform.isAndroid) return;
    
    try {
      // Nur periodisch prüfen
      if (!await shouldCheckBatteryOptimization()) {
        return;
      }
      
      final manufacturer = await _getDeviceManufacturer();
      if (_isManufacturerWithSpecialRestrictions(manufacturer)) {
        _showManufacturerSpecificBatteryDialog(context, manufacturer);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler bei der Prüfung auf zusätzliche Batterieeinschränkungen', 
        e
      );
    }
  }
  
  /// Ermittelt den Gerätehersteller genauer
  Future<String> _getDeviceManufacturer() async {
    try {
      // Aus den gespeicherten Daten abrufen
      final prefs = await SharedPreferences.getInstance();
      final manufacturer = prefs.getString(_keyDeviceManufacturer);
      
      if (manufacturer != null && manufacturer.isNotEmpty) {
        return manufacturer;
      }
      
      // Fallback: Neu abrufen
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final newManufacturer = androidInfo.manufacturer.toLowerCase();
        
        // Für künftige Verwendung speichern
        await prefs.setString(_keyDeviceManufacturer, newManufacturer);
        
        return newManufacturer;
      }
      
      return "unknown";
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler beim Ermitteln des Geräteherstellers', 
        e
      );
      return "unknown";
    }
  }
  
  /// Prüft, ob der Hersteller besondere Einschränkungen hat
  bool _isManufacturerWithSpecialRestrictions(String manufacturer) {
    return _manufacturers.any(
      (m) => m.keywords.any((keyword) => manufacturer.toLowerCase().contains(keyword))
    );
  }
  
  /// Gibt die herstellerspezifischen Anweisungen zurück
  ManufacturerInstructions? _getManufacturerInstructions(String manufacturer) {
    for (var m in _manufacturers) {
      if (m.keywords.any((keyword) => manufacturer.toLowerCase().contains(keyword))) {
        return m;
      }
    }
    return null;
  }
  
  /// Zeigt einen herstellerspezifischen Dialog an
  void _showManufacturerSpecificBatteryDialog(BuildContext context, String manufacturer) {
    final instructions = _getManufacturerInstructions(manufacturer);
    
    if (instructions == null) return;
    
    final displayInstructions = instructions.instructions.replaceAll('{APP_NAME}', _appName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 10),
            Expanded(child: Text('Zusätzliche Einstellungen erforderlich')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Für ${instructions.name}-Geräte:'),
            SizedBox(height: 8),
            Text(displayInstructions),
            SizedBox(height: 16),
            Text(
              'Diese Einstellungen sind wichtig, damit Sie Benachrichtigungen zuverlässig erhalten.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Später'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('Einstellungen öffnen'),
            onPressed: () {
              Navigator.of(context).pop();
              _openManufacturerSpecificSettings(manufacturer);
            },
          ),
        ],
      ),
    );
  }
  
  /// Öffnet herstellerspezifische Einstellungen
  Future<void> _openManufacturerSpecificSettings(String manufacturer) async {
    try {
      // Versuch, spezifische Einstellungsbildschirme zu öffnen
      // Dies erfordert zusätzliche native Implementierung
      
      try {
        final result = await platform.invokeMethod<bool>(
          'openManufacturerSpecificSettings',
          {'manufacturer': manufacturer}
        );
        
        if (result == true) {
          // Erfolgreich geöffnet
          await _saveLastCheckTime();
          return;
        }
      } catch (e) {
        print('Method Channel Fehler: $e');
      }
      
      // Fallback: Batterieeinstellungen öffnen
      await AppSettings.openAppSettings();
      await _saveLastCheckTime();
    } catch (e) {
      await _errorLoggingService.logError(
        'BatteryOptimizationService', 
        'Fehler beim Öffnen herstellerspezifischer Einstellungen', 
        e
      );
      // Fallback zu allgemeinen App-Einstellungen
      AppSettings.openAppSettings();
    }
  }
}
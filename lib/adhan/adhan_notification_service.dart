// lib/adhan/adhan_notification_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

class AdhanNotificationService {
  // Implementación del patrón Singleton
  static final AdhanNotificationService _instance = AdhanNotificationService._internal();
  factory AdhanNotificationService() => _instance;
  AdhanNotificationService._internal();

  // Plugin de notificaciones
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Configuración de notificaciones
  bool _isNotificationEnabled = true;
  final Map<String, bool> _prayerNotificationSettings = {
    'الفجر': true,
    'الشروق': false,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };
  
  // BuildContext para diálogos
  BuildContext? _context;

  // Inicialización del servicio de notificaciones
  Future<void> initialize() async {
    try {
      // Inicializar timezone
      tz_data.initializeTimeZones();
      
      // Configurar notificaciones locales
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );
          
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Cargar configuración guardada
      await _loadNotificationSettings();
      
      // Create notification channel for Android
      await _createNotificationChannel();
      
      debugPrint('Servicio de notificaciones inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar el servicio de notificaciones: $e');
    }
  }
  
  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'adhan_channel',
        'مواقيت الصلاة',
        description: 'إشعارات أوقات الصلاة',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
      );
      
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('Created Android notification channel');
    }
  }
  
  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    // For Android 13+
    bool permissionGranted = await Permission.notification.request().isGranted;
    
    // For iOS
    final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
        _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
    if (iosPlugin != null) {
      bool? iosPermission = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      permissionGranted = permissionGranted && (iosPermission ?? false);
    }
    
    return permissionGranted;
  }
  
  // Check notification permission status
  Future<bool> checkNotificationPermission() async {
    return await Permission.notification.status.isGranted;
  }
  
  // Check and request permissions if needed
  Future<bool> checkAndRequestPermissions() async {
    if (await checkNotificationPermission()) {
      return true;
    }
    
    return await requestNotificationPermission();
  }
  
  // Set context para mostrar diálogos
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // Manejar cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Implementar navegación cuando se toca la notificación
    debugPrint('Notificación tocada: ${response.id}');
  }
  
  // Cargar configuración guardada
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar estado de activación
      _isNotificationEnabled = prefs.getBool('adhan_notification_enabled') ?? true;
      
      // Cargar configuración para cada oración
      for (final prayer in _prayerNotificationSettings.keys) {
        final enabled = prefs.getBool('adhan_notification_$prayer') ?? 
            _prayerNotificationSettings[prayer]!;
        _prayerNotificationSettings[prayer] = enabled;
      }
    } catch (e) {
      debugPrint('Error al cargar la configuración de notificaciones: $e');
    }
  }
  
  // Guardar configuración
  Future<void> saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar estado de activación
      await prefs.setBool('adhan_notification_enabled', _isNotificationEnabled);
      
      // Guardar configuración para cada oración
      for (final prayer in _prayerNotificationSettings.keys) {
        await prefs.setBool(
          'adhan_notification_$prayer', 
          _prayerNotificationSettings[prayer]!
        );
      }
      
      debugPrint('Configuración de notificaciones guardada correctamente');
    } catch (e) {
      debugPrint('Error al guardar la configuración de notificaciones: $e');
    }
  }
  
  // Programar notificación para un tiempo de oración
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    required int notificationId,
  }) async {
    // Verificar si las notificaciones están activadas para esta oración
    if (!_isNotificationEnabled || !(_prayerNotificationSettings[prayerName] ?? false)) {
      return;
    }
    
    // Verificar si el tiempo de oración está en el futuro
    if (prayerTime.isBefore(DateTime.now())) {
      return;
    }
    
    try {
      // Configurar detalles de la notificación
      final androidDetails = AndroidNotificationDetails(
        'adhan_channel',
        'مواقيت الصلاة',
        channelDescription: 'إشعارات أوقات الصلاة',
        importance: Importance.high,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        styleInformation: const BigTextStyleInformation(''),
        fullScreenIntent: true,
      );
      
      final iosDetails = const DarwinNotificationDetails(
        sound: 'adhan.aiff',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // Contenido de la notificación
      final title = 'حان وقت صلاة $prayerName';
      final body = 'حان الآن وقت صلاة $prayerName';
      
      // Programar notificación
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(prayerTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('Notificación programada para $prayerName a las $prayerTime');
    } catch (e) {
      debugPrint('Error al programar notificación para $prayerName: $e');
    }
  }
  
  // Programar notificaciones para todos los tiempos de oración
  Future<void> scheduleAllPrayerNotifications(List<Map<String, dynamic>> prayerTimes) async {
    // Cancelar notificaciones anteriores
    await cancelAllNotifications();
    
    // Programar nuevas notificaciones
    for (int i = 0; i < prayerTimes.length; i++) {
      final prayer = prayerTimes[i];
      await schedulePrayerNotification(
        prayerName: prayer['name'],
        prayerTime: prayer['time'],
        notificationId: i,
      );
    }
    
    debugPrint('Programadas ${prayerTimes.length} notificaciones para las oraciones');
  }
  
  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Todas las notificaciones canceladas');
    } catch (e) {
      debugPrint('Error al cancelar notificaciones: $e');
    }
  }
  
  // Getters y setters
  bool get isNotificationEnabled => _isNotificationEnabled;
  
  set isNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveNotificationSettings();
  }
  
  Map<String, bool> get prayerNotificationSettings => _prayerNotificationSettings;
  
  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    if (_prayerNotificationSettings.containsKey(prayer)) {
      _prayerNotificationSettings[prayer] = enabled;
      await saveNotificationSettings();
    }
  }
}
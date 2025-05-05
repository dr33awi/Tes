// lib/adhan/prayer_times_service.dart
import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/adhan/prayer_times_model.dart';
import 'package:test_athkar_app/adhan/location_permission_dialog.dart';
import 'package:test_athkar_app/adhan/adhan_notification_service.dart';

/// Servicio para gestionar los tiempos de oración
/// 
/// Este servicio proporciona métodos para obtener tiempos de oración basados
/// en la ubicación del usuario y configuración personalizada, gestionar
/// permisos de ubicación y programar notificaciones.
class PrayerTimesService {
  // Implementación del patrón Singleton
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  // Variables de configuración y estado
  late CalculationParameters _calculationParameters;
  late Madhab _madhab;
  final Map<String, int> _adjustments = {};
  
  // Nueva variable para almacenar el nombre del método seleccionado
  String _currentCalculationMethodName = 'Umm al-Qura';
  
  // Información de ubicación
  double? _latitude;
  double? _longitude;
  String? _locationName;
  
  // BuildContext para diálogos
  BuildContext? _context;
  
  // Cache para tiempos de oración
  List<PrayerTimeModel>? _cachedPrayerTimes;
  
  // Función de inicialización
  Future<void> initialize() async {
    try {
      await _loadSettings();
      final AdhanNotificationService notificationService = AdhanNotificationService();
      await notificationService.initialize();
    } catch (e) {
      debugPrint('Error al inicializar servicio de tiempos de oración: $e');
      // Usar configuración predeterminada en caso de error
      _setDefaultSettings();
    }
  }
  
  // Establecer configuración predeterminada
  void _setDefaultSettings() {
    // Usar método Umm al-Qura como predeterminado
    _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
    _madhab = Madhab.shafi;
    _calculationParameters.madhab = _madhab;
    _adjustments.clear();
    _currentCalculationMethodName = 'Umm al-Qura';
  }
  
  // Cargar configuración guardada
  Future<void> _loadSettings() async {
    // Configuración predeterminada
    String calculationMethod = 'Umm al-Qura';
    String madhab = 'Shafi';
    _adjustments.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar método de cálculo
      calculationMethod = prefs.getString('prayer_calculation_method') ?? calculationMethod;
      
      // Cargar madhab
      madhab = prefs.getString('prayer_madhab') ?? madhab;
      
      // Cargar ajustes de tiempo
      final adjustmentsJson = prefs.getString('prayer_adjustments');
      if (adjustmentsJson != null) {
        final Map<String, dynamic> decoded = json.decode(adjustmentsJson);
        decoded.forEach((key, value) {
          _adjustments[key] = value as int;
        });
      }
      
      // Cargar ubicación guardada si existe
      _latitude = prefs.getDouble('prayer_location_latitude');
      _longitude = prefs.getDouble('prayer_location_longitude');
      _locationName = prefs.getString('prayer_location_name');
      
      debugPrint('Configuración cargada: Método = $calculationMethod, Madhab = $madhab');
    } catch (e) {
      debugPrint('Error al cargar configuración de tiempos de oración: $e');
    }
    
    // Aplicar configuración
    _setCalculationMethod(calculationMethod);
    _setMadhab(madhab);
  }
  
  // Guardar configuración
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar configuración actual antes de guardar
      final currentMethod = getCalculationMethodName();
      final currentMadhab = getMadhabName();
      
      debugPrint('Guardando configuración - Método: $currentMethod, Madhab: $currentMadhab');
      
      // Guardar método de cálculo
      await prefs.setString('prayer_calculation_method', currentMethod);
      
      // Guardar madhab
      await prefs.setString('prayer_madhab', currentMadhab);
      
      // Guardar ajustes de tiempo
      final String adjustmentsJson = json.encode(_adjustments);
      await prefs.setString('prayer_adjustments', adjustmentsJson);
      
      // Guardar ubicación si disponible
      if (_latitude != null && _longitude != null) {
        await prefs.setDouble('prayer_location_latitude', _latitude!);
        await prefs.setDouble('prayer_location_longitude', _longitude!);
        
        if (_locationName != null) {
          await prefs.setString('prayer_location_name', _locationName!);
        }
      }
      
      // Verificar guardado
      final savedMethod = prefs.getString('prayer_calculation_method');
      final savedMadhab = prefs.getString('prayer_madhab');
      
      debugPrint('Configuración guardada y verificada - Método: $savedMethod, Madhab: $savedMadhab');
      
      // Reinicializar la caché de tiempos de oración para reflejar los nuevos ajustes
      _cachedPrayerTimes = null;
      
    } catch (e) {
      debugPrint('Error al guardar configuración de tiempos de oración: $e');
      rethrow;
    }
  }
  
  // Nueva función para recalcular los tiempos de oración automáticamente
  Future<void> recalculatePrayerTimes() async {
    // Limpiar caché de tiempos de oración para forzar un recálculo
    _cachedPrayerTimes = null;
    
    debugPrint('Recalculando tiempos de oración con método: ${getCalculationMethodName()}');
    
    // Recalcular los tiempos de oración con la nueva configuración
    try {
      final prayerTimes = await getPrayerTimesFromAPI(useDefaultLocationIfNeeded: true);
      debugPrint('Tiempos de oración recalculados correctamente. Tamaño: ${prayerTimes.length}');
      
      // Programar notificaciones con los nuevos tiempos
      await schedulePrayerNotifications();
    } catch (e) {
      debugPrint('Error al recalcular tiempos de oración: $e');
      try {
        // Intentar método local como respaldo
        final localTimes = getPrayerTimesLocally();
        debugPrint('Tiempos recalculados localmente. Tamaño: ${localTimes.length}');
      } catch (e2) {
        debugPrint('Error también al recalcular localmente: $e2');
      }
    }
  }
  
  // Establecer método de cálculo
  void _setCalculationMethod(String method) {
    debugPrint('Estableciendo método de cálculo interno: $method');
    
    // Guardar el nombre del método para referencia futura
    _currentCalculationMethodName = method;
    
    switch (method) {
      case 'Muslim World League':
        _calculationParameters = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'Egyptian':
        _calculationParameters = CalculationMethod.egyptian.getParameters();
        break;
      case 'Karachi':
        _calculationParameters = CalculationMethod.karachi.getParameters();
        break;
      case 'Umm al-Qura':
        _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'Dubai':
        _calculationParameters = CalculationMethod.dubai.getParameters();
        break;
      case 'Qatar':
        _calculationParameters = CalculationMethod.qatar.getParameters();
        break;
      case 'Kuwait':
        _calculationParameters = CalculationMethod.kuwait.getParameters();
        break;
      case 'Moonsighting Committee':
        _calculationParameters = CalculationMethod.moon_sighting_committee.getParameters();
        break;
      case 'Singapore':
        _calculationParameters = CalculationMethod.singapore.getParameters();
        break;
      case 'Turkey':
        _calculationParameters = CalculationMethod.turkey.getParameters();
        break;
      case 'Tehran':
        _calculationParameters = CalculationMethod.tehran.getParameters();
        break;
      case 'North America':
        _calculationParameters = CalculationMethod.north_america.getParameters();
        break;
      default:
        debugPrint('Método de cálculo no reconocido, usando predeterminado: $method');
        _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
        _currentCalculationMethodName = 'Umm al-Qura';
    }
    
    // Asegurarse de que se aplica el madhab actual
    _calculationParameters.madhab = _madhab;
    
    // Limpiar caché para forzar un recálculo
    _cachedPrayerTimes = null;
  }
  
  // Obtener nombre del método de cálculo actual
  String getCalculationMethodName() {
    return _currentCalculationMethodName;
  }
  
  // Determinar método de cálculo actual
  CalculationMethod getCurrentCalculationMethod() {
    // Este es un método simplificado, en una implementación real
    // se debería comparar la configuración actual con los parámetros de cada método
    
    // Convertir el nombre del método a un enum de CalculationMethod
    switch (_currentCalculationMethodName) {
      case 'Muslim World League':
        return CalculationMethod.muslim_world_league;
      case 'Egyptian':
        return CalculationMethod.egyptian;
      case 'Karachi':
        return CalculationMethod.karachi;
      case 'Umm al-Qura':
        return CalculationMethod.umm_al_qura;
      case 'Dubai':
        return CalculationMethod.dubai;
      case 'Qatar':
        return CalculationMethod.qatar;
      case 'Kuwait':
        return CalculationMethod.kuwait;
      case 'Moonsighting Committee':
        return CalculationMethod.moon_sighting_committee;
      case 'Singapore':
        return CalculationMethod.singapore;
      case 'Turkey':
        return CalculationMethod.turkey;
      case 'Tehran':
        return CalculationMethod.tehran;
      case 'North America':
        return CalculationMethod.north_america;
      default:
        return CalculationMethod.umm_al_qura;
    }
  }
  
  // Establecer madhab
  void _setMadhab(String madhabName) {
    _madhab = madhabName == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;
    _calculationParameters.madhab = _madhab;
    
    // Limpiar caché para forzar un recálculo
    _cachedPrayerTimes = null;
  }
  
  // Obtener nombre del madhab actual
  String getMadhabName() {
    return _madhab == Madhab.hanafi ? 'Hanafi' : 'Shafi';
  }
  
  // Verificar permisos de ubicación
  Future<bool> checkLocationPermission() async {
    try {
      // Verificar estado de permisos
      PermissionStatus status = await Permission.location.status;
      
      if (status.isGranted) {
        // Verificar si el servicio de ubicación está activado
        bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        return isServiceEnabled;
      }
    } catch (e) {
      debugPrint('Error al verificar permisos de ubicación: $e');
    }
    
    return false;
  }
  
  // Solicitar permisos de ubicación
  Future<bool> requestLocationPermission() async {
    try {
      // Verificar estado de permisos
      PermissionStatus status = await Permission.location.status;
      
      if (status.isGranted) {
        // Asegurarse de que el servicio de ubicación está activado
        bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        
        if (!isServiceEnabled && _context != null) {
          // Solicitar activar servicio de ubicación
          final shouldOpen = await showLocationServiceDialog(_context!);
          
          if (shouldOpen) {
            await Geolocator.openLocationSettings();
            // Verificar nuevamente después de abrir configuración
            isServiceEnabled = await Geolocator.isLocationServiceEnabled();
          }
        }
        
        return isServiceEnabled;
      } else if (status.isDenied) {
        if (_context != null) {
          // Mostrar explicación de por qué necesitamos ubicación
          final shouldRequest = await showLocationPermissionRationaleDialog(_context!);
          
          if (shouldRequest) {
            status = await Permission.location.request();
            return status.isGranted;
          }
        } else {
          // Si no hay contexto, intentar solicitar directamente
          status = await Permission.location.request();
          return status.isGranted;
        }
      } else if (status.isPermanentlyDenied) {
        if (_context != null) {
          // Solicitar abrir configuración de la aplicación para cambiar permisos
          final shouldOpenSettings = await showOpenAppSettingsDialog(_context!);
          
          if (shouldOpenSettings) {
            await openAppSettings();
            // Verificar nuevamente después de abrir configuración
            status = await Permission.location.status;
            return status.isGranted;
          }
        }
      }
    } catch (e) {
      debugPrint('Error al solicitar permisos de ubicación: $e');
    }
    
    return false;
  }
  
  // Obtener ubicación actual
  Future<Position?> _getCurrentLocation() async {
    try {
      // Verificar si tenemos permisos
      bool hasPermission = await checkLocationPermission();
      
      // Si no tenemos permisos, intentar solicitarlos
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
      }
      
      if (hasPermission) {
        // Obtener ubicación con precisión específica y tiempo límite
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
        
        // Cachear la ubicación
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // Intentar obtener nombre de ubicación
        _locationName = await _getLocationName(position.latitude, position.longitude) 
                     ?? 'موقعك الحالي';
        
        // Guardar ubicación para futuras referencias
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('prayer_location_latitude', position.latitude);
          await prefs.setDouble('prayer_location_longitude', position.longitude);
          if (_locationName != null) {
            await prefs.setString('prayer_location_name', _locationName!);
          }
        } catch (e) {
          debugPrint('Error al guardar ubicación: $e');
        }
        
        return position;
      }
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
    }
    
    // Si llegamos aquí, intentar usar ubicación cacheada
    if (_latitude != null && _longitude != null) {
      return Position(
        longitude: _longitude!,
        latitude: _latitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    
    return null;
  }
  
  // Obtener nombre de ubicación a partir de coordenadas
  Future<String?> _getLocationName(double latitude, double longitude) async {
    try {
      // Usar API de geocodificación inversa de OpenStreetMap
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?' +
        'lat=$latitude&lon=$longitude&format=json&accept-language=ar'
      );
      
      final response = await http.get(
        url, 
        headers: {'User-Agent': 'Islamic Prayer Times App'}
      ).timeout(
        const Duration(seconds: 10), 
        onTimeout: () => throw TimeoutException('Tiempo de espera excedido al obtener nombre de ubicación')
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Intentar extraer nombre de lugar de diferentes maneras
        String? name;
        
        // Ciudad o pueblo
        if (data['address'] != null) {
          final address = data['address'] as Map<String, dynamic>;
          
          // Intentar diferentes niveles de ubicación
          name = address['city'] ?? 
                 address['town'] ?? 
                 address['village'] ?? 
                 address['state'] ?? 
                 address['country'];
        }
        
        // Usar nombre mostrado si no encontramos nada específico
        if (name == null && data['display_name'] != null) {
          final parts = data['display_name'].toString().split(',');
          if (parts.isNotEmpty) {
            name = parts[0].trim();
          }
        }
        
        return name;
      }
    } catch (e) {
      debugPrint('Error al obtener nombre de ubicación: $e');
    }
    
    return null;
  }
  
  // Establecer contexto para mostrar diálogos
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // Obtener tiempos de oración desde API
  Future<List<PrayerTimeModel>> getPrayerTimesFromAPI({
    bool useDefaultLocationIfNeeded = true
  }) async {
    try {
      // Primero, intentar obtener ubicación actual
      final position = await _getCurrentLocation();
      
      if (position != null) {
        // Éxito al obtener ubicación
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // Si no tenemos nombre de ubicación, intentar obtenerlo
        if (_locationName == null) {
          _locationName = await _getLocationName(position.latitude, position.longitude) ?? 'موقعك الحالي';
        }
        
        // Calcular tiempos de oración con ubicación actual
        final prayerTimes = getPrayerTimesLocally();
        
        // Cachear resultados
        _cachedPrayerTimes = prayerTimes;
        
        return prayerTimes;
      } else if (useDefaultLocationIfNeeded) {
        // Si no podemos obtener ubicación, usar ubicación predeterminada (Meca)
        _setDefaultLocation();
        
        final prayerTimes = getPrayerTimesLocally();
        
        // Cachear resultados
        _cachedPrayerTimes = prayerTimes;
        
        return prayerTimes;
      } else {
        // Si no queremos usar ubicación predeterminada, lanzar excepción
        throw Exception('No se pudo obtener la ubicación actual');
      }
    } catch (e) {
      debugPrint('Error al obtener tiempos de oración desde API: $e');
      
      // En caso de error, usar ubicación predeterminada si es necesario
      if (useDefaultLocationIfNeeded) {
        _setDefaultLocation();
        return getPrayerTimesLocally();
      }
      
      // Propagar el error si no podemos usar ubicación predeterminada
      rethrow;
    }
  }
  
  // Establecer ubicación predeterminada (Meca)
  void _setDefaultLocation() {
    _latitude = 21.4225;
    _longitude = 39.8262;
    _locationName = 'مكة المكرمة (الموقع الافتراضي)';
  }
  
  // Obtener tiempos de oración localmente
  List<PrayerTimeModel> getPrayerTimesLocally() {
    try {
      // Si hay tiempos en caché y no ha habido cambios en la configuración, usarlos
      if (_cachedPrayerTimes != null) {
        debugPrint('Usando tiempos de oración en caché');
        return _cachedPrayerTimes!;
      }
      
      debugPrint('Calculando tiempos de oración con método: ${getCalculationMethodName()}');
      
      // Asegurarse de que tenemos datos de ubicación
      if (_latitude == null || _longitude == null) {
        // Usar valores predeterminados para Meca
        _setDefaultLocation();
      }
      
      // Crear objeto de coordenadas
      final coordinates = Coordinates(_latitude!, _longitude!);
      
      // Aplicar ajustes a parámetros de cálculo
      try {
        // Reiniciar ajustes para evitar acumulación
        _calculationParameters.adjustments = PrayerAdjustments();
        
        // Aplicar ajustes configurados
        for (final entry in _adjustments.entries) {
          switch (entry.key) {
            case 'الفجر':
              _calculationParameters.adjustments.fajr = entry.value;
              break;
            case 'الشروق':
              _calculationParameters.adjustments.sunrise = entry.value;
              break;
            case 'الظهر':
              _calculationParameters.adjustments.dhuhr = entry.value;
              break;
            case 'العصر':
              _calculationParameters.adjustments.asr = entry.value;
              break;
            case 'المغرب':
              _calculationParameters.adjustments.maghrib = entry.value;
              break;
            case 'العشاء':
              _calculationParameters.adjustments.isha = entry.value;
              break;
          }
        }
      } catch (e) {
        debugPrint('Error al aplicar ajustes: $e');
        // Ignorar error de ajustes y continuar sin ellos
      }
      
      // Crear componentes de fecha para hora actual
      final now = DateTime.now();
      final date = DateComponents(now.year, now.month, now.day);
      
      // Calcular tiempos de oración
      try {
        final prayerTimes = PrayerTimes(coordinates, date, _calculationParameters);
        
        // Convertir tiempos de oración al modelo personalizado
        final prayerModels = PrayerTimeModel.fromPrayerTimes(prayerTimes);
        
        // Cachear resultados
        _cachedPrayerTimes = prayerModels;
        
        debugPrint('Tiempos de oración calculados correctamente con método: ${getCalculationMethodName()}');
        
        return prayerModels;
      } catch (e) {
        debugPrint('Error al calcular tiempos de oración: $e');
        
        // Verificar si tenemos resultados en caché
        if (_cachedPrayerTimes != null) {
          return _cachedPrayerTimes!;
        }
        
        // Si no hay caché, lanzar el error para manejarlo en el método de respaldo
        throw e;
      }
    } catch (e) {
      debugPrint('Error al obtener tiempos de oración localmente: $e');
      
      // Si tenemos resultados en caché, usarlos como último recurso
      if (_cachedPrayerTimes != null) {
        return _cachedPrayerTimes!;
      }
      
      // Crear tiempos predeterminados si todo lo demás falla
      return _createDefaultPrayerTimes();
    }
  }
  
  // Crear tiempos de oración predeterminados
  List<PrayerTimeModel> _createDefaultPrayerTimes() {
    final now = DateTime.now();
    final defaultPrayers = [
      PrayerTimeModel(
        name: 'الفجر',
        time: DateTime(now.year, now.month, now.day, 5, 0),
        icon: Icons.brightness_2,
        color: const Color(0xFF5B68D9),
      ),
      PrayerTimeModel(
        name: 'الشروق',
        time: DateTime(now.year, now.month, now.day, 6, 15),
        icon: Icons.wb_sunny_outlined,
        color: const Color(0xFFFF9E0D),
      ),
      PrayerTimeModel(
        name: 'الظهر',
        time: DateTime(now.year, now.month, now.day, 12, 0),
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFB746),
      ),
      PrayerTimeModel(
        name: 'العصر',
        time: DateTime(now.year, now.month, now.day, 15, 30),
        icon: Icons.wb_twighlight,
        color: const Color(0xFFFF8A65),
      ),
      PrayerTimeModel(
        name: 'المغرب',
        time: DateTime(now.year, now.month, now.day, 18, 0),
        icon: Icons.nights_stay_outlined,
        color: const Color(0xFF5C6BC0),
      ),
      PrayerTimeModel(
        name: 'العشاء',
        time: DateTime(now.year, now.month, now.day, 19, 30),
        icon: Icons.nightlight_round,
        color: const Color(0xFF1A237E),
      ),
    ];
    
    // Determinar la oración siguiente
    PrayerTimeModel? nextPrayer;
    for (final prayer in defaultPrayers) {
      if (prayer.time.isAfter(now)) {
        if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
          nextPrayer = prayer;
        }
      }
    }
    
    // Actualizar la oración marcada como siguiente
    if (nextPrayer != null) {
      final index = defaultPrayers.indexWhere((p) => p.name == nextPrayer!.name);
      if (index != -1) {
        defaultPrayers[index] = defaultPrayers[index].copyWith(isNext: true);
      }
    }
    
    // Cachear estos resultados para uso futuro
    _cachedPrayerTimes = defaultPrayers;
    
    return defaultPrayers;
  }
  
  // Programar notificaciones de oración
  Future<void> schedulePrayerNotifications() async {
    try {
      // Obtener tiempos de oración
      List<PrayerTimeModel> prayerTimes;
      try {
        // Intentar obtener tiempos actualizados
        prayerTimes = await getPrayerTimesFromAPI(useDefaultLocationIfNeeded: true);
      } catch (e) {
        debugPrint('Error al obtener tiempos de oración para notificaciones: $e');
        
        // Usar caché si está disponible
        if (_cachedPrayerTimes != null) {
          prayerTimes = _cachedPrayerTimes!;
        } else {
          // Usar tiempos predeterminados en caso de error
          prayerTimes = _createDefaultPrayerTimes();
        }
      }
      
      // Preparar lista de tiempos de oración para programar notificaciones
      final List<Map<String, dynamic>> notificationTimes = [];
      
      final now = DateTime.now();
      
      for (final prayer in prayerTimes) {
        // Ignorar Sunrise ya que no es un tiempo de oración real
        // y tiempos que ya han pasado
        if (prayer.name != 'الشروق' && prayer.time.isAfter(now)) {
          notificationTimes.add({
            'name': prayer.name,
            'time': prayer.time,
          });
        }
      }
      
      // Programar notificaciones para todos los tiempos de oración futuros de hoy
      if (notificationTimes.isNotEmpty) {
        final AdhanNotificationService notificationService = AdhanNotificationService();
        await notificationService.scheduleAllPrayerNotifications(notificationTimes);
      }
    } catch (e) {
      debugPrint('Error al programar notificaciones de oración: $e');
    }
  }
  
  // Actualizar método de cálculo
  void updateCalculationMethod(String method) {
    // Depuración
    debugPrint('Actualizando método de cálculo a: $method');
    
    // Comprobar que el método existe en los disponibles
    if (!getAvailableCalculationMethods().contains(method)) {
      debugPrint('ADVERTENCIA: Método de cálculo no reconocido: $method');
      method = 'Umm al-Qura'; // Valor predeterminado seguro
    }
    
    _setCalculationMethod(method);
    
    // Verificar que se ha establecido correctamente
    debugPrint('Método de cálculo actualizado: ${getCalculationMethodName()}');
  }
  
  // Actualizar madhab
  void updateMadhab(String madhabName) {
    // Depuración
    debugPrint('Actualizando madhab a: $madhabName');
    
    // Comprobar que el madhab existe en los disponibles
    if (!getAvailableMadhabs().contains(madhabName)) {
      debugPrint('ADVERTENCIA: Madhab no reconocido: $madhabName');
      madhabName = 'Shafi'; // Valor predeterminado seguro
    }
    
    _setMadhab(madhabName);
    
    // Verificar que se ha establecido correctamente
    debugPrint('Madhab actualizado: ${getMadhabName()}');
  }
  
  // Añadir ajuste para tiempo de oración
  void setAdjustment(String prayerName, int minutes) {
    _adjustments[prayerName] = minutes;
    // Limpiar caché para forzar un recálculo
    _cachedPrayerTimes = null;
  }
  
  // Eliminar todos los ajustes
  void clearAdjustments() {
    _adjustments.clear();
    // Limpiar caché para forzar un recálculo
    _cachedPrayerTimes = null;
  }
  
  // Obtener lista de métodos de cálculo disponibles
  List<String> getAvailableCalculationMethods() {
    return [
      'Muslim World League',
      'Egyptian',
      'Karachi',
      'Umm al-Qura',
      'Dubai',
      'Qatar',
      'Kuwait',
      'Moonsighting Committee',
      'Singapore',
      'Turkey',
      'Tehran',
      'North America',
    ];
  }
  
  // Obtener lista de madhabs disponibles
  List<String> getAvailableMadhabs() {
    return ['Shafi', 'Hanafi'];
  }
  
  // Obtener configuración actual
  Map<String, dynamic> getUserSettings() {
    return {
      'calculationMethod': getCalculationMethodName(),
      'madhab': getMadhabName(),
      'adjustments': Map<String, int>.from(_adjustments),
    };
  }
  
  // Obtener nombre de ubicación
  String? get locationName => _locationName;
}

// Excepción personalizada para tiempos de espera
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}
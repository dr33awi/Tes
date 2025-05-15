// lib/adhan/services/prayer_times_service.dart
import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:test_athkar_app/adhan/models/prayer_time_model.dart';
import 'package:test_athkar_app/adhan/widgets/location_permission_dialog.dart';
import 'package:test_athkar_app/adhan/services/prayer_notification_service.dart';
import 'package:test_athkar_app/services/retry_service.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/di_container.dart';
import 'package:test_athkar_app/services/notification/notification_manager.dart';
import 'package:test_athkar_app/services/notification/notification_helpers.dart';

/// Service for managing prayer times
/// 
/// This service provides methods for:
/// - Calculating prayer times based on location and user preferences
/// - Managing location permissions
/// - Handling prayer time settings (calculation method, madhab, adjustments)
/// - Scheduling prayer time notifications
/// - Loading and saving user preferences
class PrayerTimesService {
  // Singleton implementation
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  // Configuration variables
  late CalculationParameters _calculationParameters;
  late Madhab _madhab;
  final Map<String, int> _adjustments = {};
  
  // Current calculation method name
  String _currentCalculationMethodName = 'Umm al-Qura';
  
  // Location information
  double? _latitude;
  double? _longitude;
  String? _locationName;
  
  // Context for dialogs
  BuildContext? _context;
  
  // Cache for prayer times and settings
  List<PrayerTimeModel>? _cachedPrayerTimes;
  DateTime? _lastCalculationTime;
  
  // Dependencies
  late final ErrorLoggingService _errorLoggingService;
  late final RetryService _retryService;
  late final NotificationManager _notificationManager;
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Notification service instance
  final PrayerNotificationService _notificationService = PrayerNotificationService();
  
  /// Initialize the service
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Prayer times service already initialized');
      return true;
    }
    
    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // Initialize dependencies
      _errorLoggingService = serviceLocator<ErrorLoggingService>();
      _retryService = serviceLocator<RetryService>();
      _notificationManager = serviceLocator<NotificationManager>();
      
      // Load saved settings
      await _loadSettings();
      
      // Initialize notification service
      await _notificationService.initialize();
      
      _isInitialized = true;
      debugPrint('Prayer times service initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error initializing prayer times service: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Log error with centralized error logging service
      await _errorLoggingService.logError(
        'PrayerTimesService',
        'Error during initialization',
        e,
        stackTrace: stackTrace
      );
      
      // Use default settings in case of error
      _setDefaultSettings();
      return false;
    }
  }
  
  /// Set default settings
  void _setDefaultSettings() {
    // Use Umm al-Qura method as default
    _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
    _madhab = Madhab.shafi;
    _calculationParameters.madhab = _madhab;
    _adjustments.clear();
    _currentCalculationMethodName = 'Umm al-Qura';
    
    debugPrint('Using default prayer time settings');
  }
  
  /// Load saved settings
  Future<void> _loadSettings() async {
    // Default configuration
    String calculationMethod = 'Umm al-Qura';
    String madhab = 'Shafi';
    _adjustments.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load calculation method
      calculationMethod = prefs.getString('prayer_calculation_method') ?? calculationMethod;
      
      // Load madhab
      madhab = prefs.getString('prayer_madhab') ?? madhab;
      
      // Load time adjustments
      final adjustmentsJson = prefs.getString('prayer_adjustments');
      if (adjustmentsJson != null) {
        final Map<String, dynamic> decoded = json.decode(adjustmentsJson);
        decoded.forEach((key, value) {
          _adjustments[key] = value as int;
        });
      }
      
      // Load saved location if exists
      _latitude = prefs.getDouble('prayer_location_latitude');
      _longitude = prefs.getDouble('prayer_location_longitude');
      _locationName = prefs.getString('prayer_location_name');
      
      debugPrint('Settings loaded: Method = $calculationMethod, Madhab = $madhab');
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error loading prayer time settings',
        e
      );
      // Continue with defaults in case of error
    }
    
    // Apply settings
    _setCalculationMethod(calculationMethod);
    _setMadhab(madhab);
  }
  
  /// Save settings
  Future<bool> saveSettings() async {
    try {
      final result = await _retryService.executeWithRetry<bool>(
        operation: () async {
          final prefs = await SharedPreferences.getInstance();
          
          // Get current configuration
          final currentMethod = getCalculationMethodName();
          final currentMadhab = getMadhabName();
          
          debugPrint('Saving settings - Method: $currentMethod, Madhab: $currentMadhab');
          
          // Save calculation method
          await prefs.setString('prayer_calculation_method', currentMethod);
          
          // Save madhab
          await prefs.setString('prayer_madhab', currentMadhab);
          
          // Save time adjustments
          final String adjustmentsJson = json.encode(_adjustments);
          await prefs.setString('prayer_adjustments', adjustmentsJson);
          
          // Save location if available
          if (_latitude != null && _longitude != null) {
            await prefs.setDouble('prayer_location_latitude', _latitude!);
            await prefs.setDouble('prayer_location_longitude', _longitude!);
            
            if (_locationName != null) {
              await prefs.setString('prayer_location_name', _locationName!);
            }
          }
          
          // Verify saved settings
          final savedMethod = prefs.getString('prayer_calculation_method');
          final savedMadhab = prefs.getString('prayer_madhab');
          
          debugPrint('Settings saved and verified - Method: $savedMethod, Madhab: $savedMadhab');
          
          // Clear cached prayer times to force recalculation
          _cachedPrayerTimes = null;
          _lastCalculationTime = null;
          
          return true;
        },
        operationName: 'save_prayer_settings',
        config: RetryConfig(
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 300),
          strategy: RetryStrategy.exponentialBackoff
        )
      );
      
      return result.success;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService', 
        'Error saving prayer time settings', 
        e
      );
      return false;
    }
  }
  
  /// Recalculate prayer times with current settings
  Future<bool> recalculatePrayerTimes() async {
    // Clear cache to force recalculation
    _cachedPrayerTimes = null;
    _lastCalculationTime = null;
    
    debugPrint('Recalculating prayer times with method: ${getCalculationMethodName()}');
    
    try {
      // Recalculate prayer times
      final prayerTimes = await getPrayerTimesFromAPI(useDefaultLocationIfNeeded: true);
      debugPrint('Prayer times recalculated successfully. Count: ${prayerTimes.length}');
      
      // Schedule notifications with new times
      await schedulePrayerNotifications();
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService', 
        'Error recalculating prayer times', 
        e
      );
      
      try {
        // Try local calculation as fallback
        final localTimes = getPrayerTimesLocally();
        debugPrint('Prayer times recalculated locally. Count: ${localTimes.length}');
        
        // Schedule notifications with local times
        await schedulePrayerNotifications();
        
        return true;
      } catch (e2) {
        _errorLoggingService.logError(
          'PrayerTimesService', 
          'Error with local calculation fallback', 
          e2
        );
        return false;
      }
    }
  }
  
  /// Set calculation method
  void _setCalculationMethod(String method) {
    debugPrint('Setting internal calculation method: $method');
    
    // Save method name for future reference
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
        debugPrint('Unrecognized calculation method, using default: $method');
        _calculationParameters = CalculationMethod.umm_al_qura.getParameters();
        _currentCalculationMethodName = 'Umm al-Qura';
    }
    
    // Apply current madhab
    _calculationParameters.madhab = _madhab;
    
    // Clear cache to force recalculation
    _cachedPrayerTimes = null;
    _lastCalculationTime = null;
  }
  
  /// Get current calculation method name
  String getCalculationMethodName() {
    return _currentCalculationMethodName;
  }
  
  /// Determine current calculation method enum
  CalculationMethod getCurrentCalculationMethod() {
    // Convert method name to CalculationMethod enum
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
  
  /// Set madhab
  void _setMadhab(String madhabName) {
    _madhab = madhabName == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;
    _calculationParameters.madhab = _madhab;
    
    // Clear cache to force recalculation
    _cachedPrayerTimes = null;
    _lastCalculationTime = null;
  }
  
  /// Get current madhab name
  String getMadhabName() {
    return _madhab == Madhab.hanafi ? 'Hanafi' : 'Shafi';
  }
  
  /// Check location permission
  Future<bool> checkLocationPermission() async {
    try {
      // Check permission status
      PermissionStatus status = await Permission.location.status;
      
      if (status.isGranted) {
        // Check if location service is enabled
        bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        return isServiceEnabled;
      }
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error checking location permission',
        e
      );
    }
    
    return false;
  }
  
  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      // Check permission status
      PermissionStatus status = await Permission.location.status;
      
      if (status.isGranted) {
        // Ensure location service is enabled
        bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        
        if (!isServiceEnabled && _context != null) {
          // Request to enable location service
          final shouldOpen = await showLocationServiceDialog(_context!);
          
          if (shouldOpen) {
            await Geolocator.openLocationSettings();
            // Check again after opening settings
            isServiceEnabled = await Geolocator.isLocationServiceEnabled();
          }
        }
        
        return isServiceEnabled;
      } else if (status.isDenied) {
        if (_context != null) {
          // Show explanation why we need location
          final shouldRequest = await showLocationPermissionRationaleDialog(_context!);
          
          if (shouldRequest) {
            status = await Permission.location.request();
            return status.isGranted;
          }
        } else {
          // If no context, try to request directly
          status = await Permission.location.request();
          return status.isGranted;
        }
      } else if (status.isPermanentlyDenied) {
        if (_context != null) {
          // Request to open app settings to change permissions
          final shouldOpenSettings = await showOpenAppSettingsDialog(_context!);
          
          if (shouldOpenSettings) {
            await openAppSettings();
            // Check again after opening settings
            status = await Permission.location.status;
            return status.isGranted;
          }
        }
      }
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error requesting location permission',
        e
      );
    }
    
    return false;
  }
  
  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if we have permission
      bool hasPermission = await checkLocationPermission();
      
      // If no permission, try to request it
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
      }
      
      if (hasPermission) {
        // Get location with specific accuracy and timeout
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
        
        // Cache the location
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // Try to get location name
        String? locationName = await _getLocationName(position.latitude, position.longitude);
        if (locationName != null) {
          _locationName = locationName;
        } else {
          _locationName = 'موقعك الحالي'; // Your current location
        }
        
        // Save location for future reference
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('prayer_location_latitude', position.latitude);
          await prefs.setDouble('prayer_location_longitude', position.longitude);
          if (_locationName != null) {
            await prefs.setString('prayer_location_name', _locationName!);
          }
        } catch (e) {
          _errorLoggingService.logError(
            'PrayerTimesService',
            'Error saving location',
            e
          );
          // Continue despite error saving location
        }
        
        return position;
      }
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error getting location',
        e
      );
    }
    
    // If we get here, try to use cached location
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
  
  /// Get location name from coordinates
  Future<String?> _getLocationName(double latitude, double longitude) async {
    try {
      // Wrap this in a RetryService call to improve reliability
      final result = await _retryService.executeWithRetry<String?>(
        operation: () async {
          // Use OpenStreetMap reverse geocoding API
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?' +
            'lat=$latitude&lon=$longitude&format=json&accept-language=ar'
          );
          
          final response = await http.get(
            url, 
            headers: {'User-Agent': 'Islamic Prayer Times App'}
          ).timeout(
            const Duration(seconds: 10)
          );
          
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            
            // Try to extract place name in different ways
            String? name;
            
            // City or town
            if (data['address'] != null) {
              final address = data['address'] as Map<String, dynamic>;
              
              // Try different location levels
              name = address['city'] ?? 
                     address['town'] ?? 
                     address['village'] ?? 
                     address['state'] ?? 
                     address['country'];
            }
            
            // Use display name if nothing specific found
            if (name == null && data['display_name'] != null) {
              final parts = data['display_name'].toString().split(',');
              if (parts.isNotEmpty) {
                name = parts[0].trim();
              }
            }
            
            return name;
          }
          
          return null;
        },
        operationName: 'get_location_name',
        config: RetryConfig(
          maxAttempts: 3,
          initialDelay: const Duration(seconds: 1),
          strategy: RetryStrategy.exponentialBackoffWithJitter
        )
      );
      
      return result.value;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error getting location name',
        e
      );
      return null;
    }
  }
  
  /// Set context for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
    // Also set context in notification service
    _notificationService.setContext(context);
  }
  
  /// Get prayer times from API or location
  Future<List<PrayerTimeModel>> getPrayerTimesFromAPI({
    bool useDefaultLocationIfNeeded = true
  }) async {
    try {
      // First, try to get current location
      final position = await _getCurrentLocation();
      
      if (position != null) {
        // Success getting location
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // If no location name, try to get it
        if (_locationName == null) {
          _locationName = await _getLocationName(position.latitude, position.longitude) ?? 'موقعك الحالي';
        }
        
        // Calculate prayer times with current location
        final prayerTimes = getPrayerTimesLocally();
        
        // Cache results
        _cachedPrayerTimes = prayerTimes;
        _lastCalculationTime = DateTime.now();
        
        return prayerTimes;
      } else if (useDefaultLocationIfNeeded) {
        // If can't get location, use default location (Mecca)
        setDefaultLocation();
        
        final prayerTimes = getPrayerTimesLocally();
        
        // Cache results
        _cachedPrayerTimes = prayerTimes;
        _lastCalculationTime = DateTime.now();
        
        return prayerTimes;
      } else {
        // If we don't want to use default location, throw exception
        throw Exception('Could not get current location');
      }
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error getting prayer times from API',
        e
      );
      
      // In case of error, use default location if needed
      if (useDefaultLocationIfNeeded) {
        setDefaultLocation();
        return getPrayerTimesLocally();
      }
      
      // Propagate error if we can't use default location
      rethrow;
    }
  }
  
  /// Set default location (Mecca)
  void setDefaultLocation() {
    _latitude = 21.4225;
    _longitude = 39.8262;
    _locationName = 'مكة المكرمة (الموقع الافتراضي)'; // Mecca (Default Location)
  }
  
  /// Get prayer times locally using Adhan library
  List<PrayerTimeModel> getPrayerTimesLocally() {
    try {
      // If we have cached times and no configuration changes, use them
      final now = DateTime.now();
      if (_cachedPrayerTimes != null && _lastCalculationTime != null) {
        // Cache valid for same day only
        final isSameDay = now.year == _lastCalculationTime!.year && 
                         now.month == _lastCalculationTime!.month &&
                         now.day == _lastCalculationTime!.day;
        
        if (isSameDay) {
          debugPrint('Using cached prayer times');
          return _cachedPrayerTimes!;
        }
      }
      
      debugPrint('Calculating prayer times with method: ${getCalculationMethodName()}');
      
      // Ensure we have location data
      if (_latitude == null || _longitude == null) {
        // Use default values for Mecca
        setDefaultLocation();
      }
      
      // Create coordinates object
      final coordinates = Coordinates(_latitude!, _longitude!);
      
      // Apply adjustments to calculation parameters
      try {
        // Reset adjustments to avoid accumulation
        _calculationParameters.adjustments = PrayerAdjustments();
        
        // Apply configured adjustments
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
        _errorLoggingService.logError(
          'PrayerTimesService',
          'Error applying adjustments',
          e
        );
        // Ignore adjustment errors and continue without them
      }
      
      // Create date components for current time
      final date = DateComponents(now.year, now.month, now.day);
      
      // Calculate prayer times
      try {
        final prayerTimes = PrayerTimes(coordinates, date, _calculationParameters);
        
        // Convert prayer times to custom model
        final prayerModels = PrayerTimeModel.fromPrayerTimes(prayerTimes);
        
        // Cache results
        _cachedPrayerTimes = prayerModels;
        _lastCalculationTime = now;
        
        debugPrint('Prayer times calculated successfully with method: ${getCalculationMethodName()}');
        
        return prayerModels;
      } catch (e) {
        _errorLoggingService.logError(
          'PrayerTimesService',
          'Error calculating prayer times',
          e
        );
        
        // Check if we have cached results
        if (_cachedPrayerTimes != null) {
          return _cachedPrayerTimes!;
        }
        
        // If no cache, throw error to be handled in fallback method
        throw e;
      }
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error getting prayer times locally',
        e
      );
      
      // If we have cached results, use them as last resort
      if (_cachedPrayerTimes != null) {
        return _cachedPrayerTimes!;
      }
      
      // Create default times if all else fails
      return _createDefaultPrayerTimes();
    }
  }
  
  /// Create default prayer times
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
    
    // Determine next prayer
    PrayerTimeModel? nextPrayer;
    for (final prayer in defaultPrayers) {
      if (prayer.time.isAfter(now)) {
        if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
          nextPrayer = prayer;
        }
      }
    }
    
    // Update prayer marked as next
    if (nextPrayer != null) {
      final index = defaultPrayers.indexWhere((p) => p.name == nextPrayer!.name);
      if (index != -1) {
        defaultPrayers[index] = defaultPrayers[index].copyWith(isNext: true);
      }
    }
    
    // Cache these results for future use
    _cachedPrayerTimes = defaultPrayers;
    _lastCalculationTime = now;
    
    return defaultPrayers;
  }
  
  /// Schedule prayer notifications - Using the unified notification system
  Future<bool> schedulePrayerNotifications() async {
    try {
      // Get prayer times
      List<PrayerTimeModel> prayerTimes;
      try {
        // Try to get updated times
        prayerTimes = await getPrayerTimesFromAPI(useDefaultLocationIfNeeded: true);
      } catch (e) {
        _errorLoggingService.logError(
          'PrayerTimesService',
          'Error getting prayer times for notifications, using cached ones',
          e
        );
        
        // Use cache if available
        if (_cachedPrayerTimes != null) {
          prayerTimes = _cachedPrayerTimes!;
        } else {
          // Use default times in case of error
          prayerTimes = _createDefaultPrayerTimes();
        }
      }
      
      // Filter out past prayers and prepare batch items for scheduling
      final now = DateTime.now();
      final List<Map<String, dynamic>> notificationData = [];
      
      for (final prayer in prayerTimes) {
        // Include all prayers that occur in the future
        if (prayer.time.isAfter(now)) {
          // Create standardized notification payload
          final payload = NotificationNavigation.createNavigationPayload(
            navigationId: 'prayer',
            targetId: prayer.name,
            extraData: {
              'prayerTime': prayer.time.millisecondsSinceEpoch,
              'englishName': prayer.englishName,
            },
          );
          
          // Add notification data
          notificationData.add({
            'name': prayer.name,
            'time': prayer.time,
            'payload': payload,
            'color': prayer.color,
            'priority': _getPriorityForPrayer(prayer.name),
            'title': _getNotificationTitle(prayer.name),
            'body': _getNotificationBody(prayer.name),
          });
        }
      }
      
      // Schedule using notification manager for tomorrow's prayers if none left today
      if (notificationData.isEmpty) {
        // Schedule tomorrow's prayers
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final date = DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
        
        // Calculate tomorrow's prayers
        try {
          final coordinates = Coordinates(_latitude!, _longitude!);
          final tomorrowPrayerTimes = PrayerTimes(coordinates, date, _calculationParameters);
          final tomorrowModels = PrayerTimeModel.fromPrayerTimes(tomorrowPrayerTimes);
          
          for (final prayer in tomorrowModels) {
            // Create notification payload
            final payload = NotificationNavigation.createNavigationPayload(
              navigationId: 'prayer',
              targetId: prayer.name,
              extraData: {
                'prayerTime': prayer.time.millisecondsSinceEpoch,
                'englishName': prayer.englishName,
              },
            );
            
            // Add to notification data
            notificationData.add({
              'name': prayer.name,
              'time': prayer.time,
              'payload': payload,
              'color': prayer.color,
              'priority': _getPriorityForPrayer(prayer.name),
              'title': _getNotificationTitle(prayer.name),
              'body': _getNotificationBody(prayer.name),
            });
          }
        } catch (e) {
          _errorLoggingService.logError(
            'PrayerTimesService',
            'Error calculating tomorrow prayers, using defaults',
            e
          );
          
          // Use default times shifted to tomorrow
          final tomorrowDefaults = _createDefaultPrayerTimes().map((prayer) {
            return prayer.copyWith(
              time: DateTime(
                tomorrow.year,
                tomorrow.month,
                tomorrow.day,
                prayer.time.hour,
                prayer.time.minute,
              ),
            );
          }).toList();
          
          for (final prayer in tomorrowDefaults) {
            // Create notification payload
            final payload = NotificationNavigation.createNavigationPayload(
              navigationId: 'prayer',
              targetId: prayer.name,
              extraData: {
                'prayerTime': prayer.time.millisecondsSinceEpoch,
                'englishName': prayer.englishName,
              },
            );
            
            // Add to notification data
            notificationData.add({
              'name': prayer.name,
              'time': prayer.time,
              'payload': payload,
              'color': prayer.color,
              'priority': _getPriorityForPrayer(prayer.name),
              'title': _getNotificationTitle(prayer.name),
              'body': _getNotificationBody(prayer.name),
            });
          }
        }
      }
      
      // Schedule notifications using the modern notification service
      int scheduledCount = 0;
      
      // Option 1: Using the legacy service for compatibility
      scheduledCount = await _notificationService.scheduleAllPrayerNotifications(notificationData);
      
      // Option 2: Using the modern notification manager (better for the future)
      if (scheduledCount == 0) {
        // Try modern notification manager as fallback
        for (final prayer in notificationData) {
          final timeOfDay = TimeOfDay(
            hour: prayer['time'].hour,
            minute: prayer['time'].minute,
          );
          
          final success = await _notificationManager.scheduleNotification(
            notificationId: 'prayer_${prayer['name']}',
            title: prayer['title'],
            body: prayer['body'],
            notificationTime: timeOfDay,
            channelId: 'prayer_channel',
            payload: prayer['payload'],
            color: prayer['color'],
            priority: prayer['priority'],
          );
          
          if (success) scheduledCount++;
        }
      }
      
      debugPrint('Scheduled $scheduledCount prayer notifications');
      return scheduledCount > 0;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error scheduling prayer notifications',
        e
      );
      return false;
    }
  }
  
  /// Get the notification title for a specific prayer
  String _getNotificationTitle(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return 'حان وقت صلاة الفجر';
      case 'الشروق':
        return 'الشمس تشرق الآن';
      case 'الظهر':
        return 'حان وقت صلاة الظهر';
      case 'العصر':
        return 'حان وقت صلاة العصر';
      case 'المغرب':
        return 'حان وقت صلاة المغرب';
      case 'العشاء':
        return 'حان وقت صلاة العشاء';
      default:
        return 'حان وقت الصلاة';
    }
  }
  
  /// Get the notification body for a specific prayer
  String _getNotificationBody(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return 'حان الآن وقت صلاة الفجر. قم وصلِ قبل طلوع الشمس';
      case 'الشروق':
        return 'الشمس تشرق الآن. وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ الشَّمْسِ';
      case 'الظهر':
        return 'حان الآن وقت صلاة الظهر. حي على الصلاة';
      case 'العصر':
        return 'حان الآن وقت صلاة العصر. حي على الفلاح';
      case 'المغرب':
        return 'حان الآن وقت صلاة المغرب. وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ غُرُوبِ الشَّمْسِ';
      case 'العشاء':
        return 'حان الآن وقت صلاة العشاء. أقم الصلاة لدلوك الشمس إلى غسق الليل';
      default:
        return 'حان الآن وقت الصلاة';
    }
  }
  
  /// Get the priority level for a specific prayer
  int _getPriorityForPrayer(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return 5; // Highest priority for Fajr
      case 'المغرب':
        return 4; // High priority for Maghrib
      default:
        return 3; // Normal priority for other prayers
    }
  }
  
  /// Update calculation method
  void updateCalculationMethod(String method) {
    // Debug
    debugPrint('Updating calculation method to: $method');
    
    // Check if method exists in available ones
    if (!getAvailableCalculationMethods().contains(method)) {
      debugPrint('WARNING: Unrecognized calculation method: $method');
      method = 'Umm al-Qura'; // Safe default
    }
    
    _setCalculationMethod(method);
    
    // Verify it was set correctly
    debugPrint('Calculation method updated: ${getCalculationMethodName()}');
  }
  
  /// Update madhab
  void updateMadhab(String madhabName) {
    // Debug
    debugPrint('Updating madhab to: $madhabName');
    
    // Check if madhab exists in available ones
    if (!getAvailableMadhabs().contains(madhabName)) {
      debugPrint('WARNING: Unrecognized madhab: $madhabName');
      madhabName = 'Shafi'; // Safe default
    }
    
    _setMadhab(madhabName);
    
    // Verify it was set correctly
    debugPrint('Madhab updated: ${getMadhabName()}');
  }
  
  /// Add adjustment for prayer time
  void setAdjustment(String prayerName, int minutes) {
    _adjustments[prayerName] = minutes;
    // Clear cache to force recalculation
    _cachedPrayerTimes = null;
    _lastCalculationTime = null;
  }
  
  /// Remove all adjustments
  void clearAdjustments() {
    _adjustments.clear();
    // Clear cache to force recalculation
    _cachedPrayerTimes = null;
    _lastCalculationTime = null;
  }
  
  /// Get available calculation methods
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
  
  /// Get available madhabs
  List<String> getAvailableMadhabs() {
    return ['Shafi', 'Hanafi'];
  }
  
  /// Get current settings
  Map<String, dynamic> getUserSettings() {
    return {
      'calculationMethod': getCalculationMethodName(),
      'madhab': getMadhabName(),
      'adjustments': Map<String, int>.from(_adjustments),
      'location': _locationName,
      'latitude': _latitude,
      'longitude': _longitude,
    };
  }
  
  /// Get prayer times statistics
  Future<Map<String, dynamic>> getPrayerTimesStatistics() async {
    try {
      // Get current prayer times
      final prayerTimes = _cachedPrayerTimes ?? getPrayerTimesLocally();
      final now = DateTime.now();
      
      // Find next prayer
      PrayerTimeModel? nextPrayer;
      for (final prayer in prayerTimes) {
        if (prayer.time.isAfter(now)) {
          if (nextPrayer == null || prayer.time.isBefore(nextPrayer.time)) {
            nextPrayer = prayer;
          }
        }
      }
      
      // Find current prayer period
      String currentPeriod = "";
      for (int i = 0; i < prayerTimes.length - 1; i++) {
        if (now.isAfter(prayerTimes[i].time) && now.isBefore(prayerTimes[i + 1].time)) {
          currentPeriod = "${prayerTimes[i].name} - ${prayerTimes[i + 1].name}";
          break;
        }
      }
      
      // Get notification statistics
      final notificationStats = await _notificationService.getNotificationStatistics();
      
      // Get remaining time until next prayer
      String remainingTime = "";
      if (nextPrayer != null) {
        remainingTime = nextPrayer.remainingTime;
      }
      
      return {
        'current_time': now.toString(),
        'next_prayer': nextPrayer?.name ?? 'None',
        'next_prayer_time': nextPrayer?.formattedTime ?? 'N/A',
        'remaining_time': remainingTime,
        'current_period': currentPeriod,
        'calculation_method': getCalculationMethodName(),
        'madhab': getMadhabName(),
        'location': _locationName ?? 'Unknown',
        'notification_stats': notificationStats,
        'adjustments': _adjustments,
      };
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error getting prayer times statistics',
        e
      );
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// Get location name
  String? get locationName => _locationName;
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Testing features
  
  /// Test prayer notifications
  Future<bool> testPrayerNotifications() async {
    try {
      final now = DateTime.now();
      final testPrayerTime = now.add(const Duration(seconds: 5));
      
      // Test with both services for better reliability
      
      // Test with legacy service
      await _notificationService.testImmediateNotification();
      
      // Test with unified service
      await _notificationManager.showSimpleNotification(
        "اختبار إشعارات الصلاة",
        "هذا اختبار لنظام إشعارات الصلاة باستخدام الخدمة الموحدة",
        payload: "test_prayer_notification",
      );
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'PrayerTimesService',
        'Error testing prayer notifications',
        e
      );
      return false;
    }
  }
}

/// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

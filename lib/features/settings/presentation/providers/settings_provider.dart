// lib/presentation/blocs/settings/settings_provider.dart
// Modificado para manejar la inicialización segura de servicios
import 'package:flutter/material.dart';
import '../../domain/entities/settings.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import '../../../../core/services/interfaces/notification_service.dart';
import '../../../../core/services/interfaces/battery_service.dart';
import '../../../../core/services/utils/notification_scheduler.dart';
import '../../../../app/di/service_locator.dart';

class SettingsProvider extends ChangeNotifier {
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;
  
  // Usa métodos para acceder a los servicios de forma segura en lugar de inicializarlos como campos
  NotificationService? _notificationService;
  BatteryService? _batteryService;
  NotificationScheduler? _notificationScheduler;
  
  Settings? _settings;
  bool _isLoading = false;
  String? _error;
  
  SettingsProvider({
    required GetSettings getSettings,
    required UpdateSettings updateSettings,
  })  : _getSettings = getSettings,
        _updateSettings = updateSettings;
  
  // الحالة الحالية
  Settings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  
  // التأكد من تهيئة الخدمات بشكل آمن
  void _ensureServicesInitialized() {
    try {
      _notificationService ??= getIt<NotificationService>();
      _batteryService ??= getIt<BatteryService>();
      _notificationScheduler ??= getIt<NotificationScheduler>();
    } catch (e) {
      debugPrint('خطأ في تهيئة الخدمات في SettingsProvider: $e');
      // لا نقوم بإعادة إثارة الاستثناء هنا، فقط نسجله
    }
  }
  
  // استدعاء خدمة الإشعارات بشكل آمن
  NotificationService? get _safeNotificationService {
    _ensureServicesInitialized();
    return _notificationService;
  }
  
  // استدعاء خدمة البطارية بشكل آمن
  BatteryService? get _safeBatteryService {
    _ensureServicesInitialized();
    return _batteryService;
  }
  
  // استدعاء جدولة الإشعارات بشكل آمن
  NotificationScheduler? get _safeNotificationScheduler {
    _ensureServicesInitialized();
    return _notificationScheduler;
  }
  
  // تحميل الإعدادات
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _settings = await _getSettings();
      
      // تحديث إعدادات خدمة الإشعارات إذا كانت متوفرة
      await _updateNotificationServiceSettings();
      
      // تحديث إعدادات خدمة البطارية إذا كانت متوفرة
      await _updateBatteryServiceSettings();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // تحديث الإعدادات
  Future<bool> updateSettings(Settings newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _updateSettings(newSettings);
      if (success) {
        // حفظ الإعدادات القديمة لمعرفة ما إذا تم تغيير إعدادات الإشعارات
        final oldSettings = _settings;
        _settings = newSettings;
        
        // تحديث إعدادات خدمة الإشعارات
        await _updateNotificationServiceSettings();
        
        // تحديث إعدادات خدمة البطارية
        await _updateBatteryServiceSettings();
        
        // إعادة جدولة الإشعارات إذا تم تغيير إعدادات الإشعارات
        if (_shouldRescheduleNotifications(oldSettings, newSettings)) {
          await _safeNotificationScheduler?.scheduleAllNotifications(newSettings);
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return false;
    }
  }
  
  // التحقق مما إذا كان يجب إعادة جدولة الإشعارات
  bool _shouldRescheduleNotifications(Settings? oldSettings, Settings newSettings) {
    if (oldSettings == null) return true;
    
    // التحقق من التغيرات في إعدادات الإشعارات
    return oldSettings.enableNotifications != newSettings.enableNotifications ||
           oldSettings.enablePrayerTimesNotifications != newSettings.enablePrayerTimesNotifications ||
           oldSettings.enableAthkarNotifications != newSettings.enableAthkarNotifications ||
           oldSettings.morningAthkarTime != newSettings.morningAthkarTime ||
           oldSettings.eveningAthkarTime != newSettings.eveningAthkarTime ||
           oldSettings.showAthkarReminders != newSettings.showAthkarReminders ||
           oldSettings.respectBatteryOptimizations != newSettings.respectBatteryOptimizations ||
           oldSettings.respectDoNotDisturb != newSettings.respectDoNotDisturb ||
           oldSettings.enableHighPriorityForPrayers != newSettings.enableHighPriorityForPrayers ||
           oldSettings.enableSilentMode != newSettings.enableSilentMode ||
           oldSettings.useCustomSounds != newSettings.useCustomSounds ||
           oldSettings.notificationSounds != newSettings.notificationSounds ||
           oldSettings.enableActionButtons != newSettings.enableActionButtons ||
           oldSettings.calculationMethod != newSettings.calculationMethod ||
           oldSettings.asrMethod != newSettings.asrMethod;
  }
  
  // تحديث إعداد محدد
  Future<bool> updateSetting({required String key, required dynamic value}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _updateSettings.updateSetting(key: key, value: value);
      if (success && _settings != null) {
        // حفظ الإعدادات القديمة
        final oldSettings = _settings!;
        
        // تحديث الإعدادات المحلية
        final newSettings = _updateLocalSettings(key, value);
        
        // تحديث إعدادات خدمة الإشعارات إذا لزم الأمر
        if (_isNotificationRelatedSetting(key)) {
          await _updateNotificationServiceSettings();
        }
        
        // تحديث إعدادات خدمة البطارية إذا لزم الأمر
        if (key == 'lowBatteryThreshold') {
          await _updateBatteryServiceSettings();
        }
        
        // إعادة جدولة الإشعارات إذا لزم الأمر
        if (_shouldRescheduleNotificationForKey(key)) {
          await _safeNotificationScheduler?.scheduleAllNotifications(newSettings);
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      
      return false;
    }
  }
  
  // تحديث الإعدادات المحلية
  Settings _updateLocalSettings(String key, dynamic value) {
    switch (key) {
      case 'enableNotifications':
        _settings = _settings!.copyWith(enableNotifications: value as bool);
        break;
      case 'enablePrayerTimesNotifications':
        _settings = _settings!.copyWith(enablePrayerTimesNotifications: value as bool);
        break;
      case 'enableAthkarNotifications':
        _settings = _settings!.copyWith(enableAthkarNotifications: value as bool);
        break;
      case 'enableDarkMode':
        _settings = _settings!.copyWith(enableDarkMode: value as bool);
        break;
      case 'language':
        _settings = _settings!.copyWith(language: value as String);
        break;
      case 'calculationMethod':
        _settings = _settings!.copyWith(calculationMethod: value as int);
        break;
      case 'asrMethod':
        _settings = _settings!.copyWith(asrMethod: value as int);
        break;
      case 'respectBatteryOptimizations':
        _settings = _settings!.copyWith(respectBatteryOptimizations: value as bool);
        break;
      case 'respectDoNotDisturb':
        _settings = _settings!.copyWith(respectDoNotDisturb: value as bool);
        break;
      case 'enableHighPriorityForPrayers':
        _settings = _settings!.copyWith(enableHighPriorityForPrayers: value as bool);
        break;
      case 'enableSilentMode':
        _settings = _settings!.copyWith(enableSilentMode: value as bool);
        break;
      case 'lowBatteryThreshold':
        _settings = _settings!.copyWith(lowBatteryThreshold: value as int);
        break;
      case 'showAthkarReminders':
        _settings = _settings!.copyWith(showAthkarReminders: value as bool);
        break;
      case 'morningAthkarTime':
        _settings = _settings!.copyWith(morningAthkarTime: value as List<int>);
        break;
      case 'eveningAthkarTime':
        _settings = _settings!.copyWith(eveningAthkarTime: value as List<int>);
        break;
      case 'useCustomSounds':
        _settings = _settings!.copyWith(useCustomSounds: value as bool);
        break;
      case 'notificationSounds':
        _settings = _settings!.copyWith(notificationSounds: value as Map<String, String>);
        break;
      case 'enableActionButtons':
        _settings = _settings!.copyWith(enableActionButtons: value as bool);
        break;
    }
    return _settings!;
  }
  
  // التحقق مما إذا كان الإعداد متعلق بالإشعارات
  bool _isNotificationRelatedSetting(String key) {
    return [
      'enableNotifications',
      'enablePrayerTimesNotifications',
      'enableAthkarNotifications',
      'respectBatteryOptimizations',
      'respectDoNotDisturb',
      'enableHighPriorityForPrayers',
      'enableSilentMode',
    ].contains(key);
  }
  
  // التحقق مما إذا كان يجب إعادة جدولة الإشعارات لهذا الإعداد
  bool _shouldRescheduleNotificationForKey(String key) {
    return [
      'enableNotifications',
      'enablePrayerTimesNotifications',
      'enableAthkarNotifications',
      'morningAthkarTime',
      'eveningAthkarTime',
      'showAthkarReminders',
      'useCustomSounds',
      'notificationSounds',
      'enableActionButtons',
      'calculationMethod',
      'asrMethod',
    ].contains(key);
  }
  
  // تحديث إعدادات خدمة الإشعارات
  Future<void> _updateNotificationServiceSettings() async {
    if (_settings == null) return;
    
    final notificationService = _safeNotificationService;
    if (notificationService == null) return;
    
    // تحديث إعدادات احترام البطارية ووضع عدم الإزعاج
    await notificationService.setRespectBatteryOptimizations(_settings!.respectBatteryOptimizations);
    await notificationService.setRespectDoNotDisturb(_settings!.respectDoNotDisturb);
  }
  
  // تحديث إعدادات خدمة البطارية
  Future<void> _updateBatteryServiceSettings() async {
    if (_settings == null) return;
    
    final batteryService = _safeBatteryService;
    if (batteryService == null) return;
    
    // تحديث الحد الأدنى لمستوى البطارية
    await batteryService.setMinimumBatteryLevel(_settings!.lowBatteryThreshold);
  }
  
  // إعادة جدولة جميع الإشعارات
  Future<void> rescheduleAllNotifications() async {
    if (_settings == null) return;
    
    final scheduler = _safeNotificationScheduler;
    if (scheduler != null) {
      await scheduler.rescheduleAllNotifications(_settings!);
    }
  }
  
  // الحصول على حالة الإشعارات
  Future<Map<String, dynamic>> getNotificationStatus() async {
    final scheduler = _safeNotificationScheduler;
    if (scheduler != null) {
      return await scheduler.getNotificationStatus();
    }
    return {
      'can_send_now': false,
      'has_permission': false,
      'battery_optimization_enabled': false,
      'dnd_enabled': false,
      'scheduled_notifications_count': 0,
    };
  }
}
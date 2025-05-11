// lib/services/notification/android_notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';
import 'package:test_athkar_app/services/permissions_service.dart';
import 'package:test_athkar_app/services/notification_service_interface.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/timezone.dart' as tz;


/// تنفيذ خدمة الإشعارات لنظام Android
class AndroidNotificationService implements NotificationServiceInterface {
  // كائن FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // خدمات التبعية المعكوسة
  final ErrorLoggingService _errorLoggingService;
  final DoNotDisturbService _doNotDisturbService;
  final BatteryOptimizationService _batteryOptimizationService;
  final PermissionsService _permissionsService;
  
  // معرفات قناة الإشعارات
  static const String _defaultChannelId = 'default_channel';
  static const String _highPriorityChannelId = 'high_priority_channel';
  static const String _morningChannelId = 'morning_athkar_channel';
  static const String _eveningChannelId = 'evening_athkar_channel';
  static const String _prayerChannelId = 'prayer_athkar_channel';
  
  // مفاتيح التخزين المحلي
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyScheduledNotifications = 'scheduled_notifications';
  static const String _keyLastSyncTime = 'last_notification_sync';
  static const String _keyNotificationConfig = 'notification_config';
  
  // كائن التكوين
  NotificationConfig _config = NotificationConfig();
  
  // المنشئ
  AndroidNotificationService({
    required ErrorLoggingService errorLoggingService,
    required DoNotDisturbService doNotDisturbService,
    required BatteryOptimizationService batteryOptimizationService,
    required PermissionsService permissionsService,
  }) : 
    _errorLoggingService = errorLoggingService,
    _doNotDisturbService = doNotDisturbService,
    _batteryOptimizationService = batteryOptimizationService,
    _permissionsService = permissionsService;
  
  @override
  Future<bool> initialize() async {
    try {
      print('بدء تهيئة خدمة إشعارات Android...');
      
      // تهيئة مدير التنبيهات للاعتمادية
      await AndroidAlarmManager.initialize();
      
      // تهيئة Workmanager للمهام الخلفية
      await Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: false,
      );
      
      // تحميل تكوين الإشعارات
      await _loadNotificationConfig();
      
      // إعداد قنوات الإشعارات
      await _initializeNotificationChannels();
      
      // تكوين معالجات الإشعارات
      await _setupNotificationHandlers();
      
      // تكوين وضع عدم الإزعاج للإشعارات
      await _doNotDisturbService.configureNotificationChannelsForDoNotDisturb();
      
      print('اكتملت تهيئة خدمة إشعارات Android بنجاح');
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تهيئة خدمة إشعارات Android', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> configureFromPreferences() async {
    try {
      await _loadNotificationConfig();
      await _initializeNotificationChannels();
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تكوين الإشعارات من التفضيلات', 
        e
      );
      return false;
    }
  }
  
  /// تحميل تكوين الإشعارات من التخزين المحلي
  Future<void> _loadNotificationConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString(_keyNotificationConfig);
      
      if (configString != null) {
        _config = NotificationConfig.fromJson(
          Map<String, dynamic>.from(
            await jsonDecode(configString)
          )
        );
      } else {
        // استخدام التكوين الافتراضي
        _config = NotificationConfig();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تحميل تكوين الإشعارات', 
        e
      );
    }
  }
  
  /// حفظ تكوين الإشعارات
  Future<void> _saveNotificationConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationConfig, jsonEncode(_config.toJson()));
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في حفظ تكوين الإشعارات', 
        e
      );
    }
  }
  
  @override
  Future<bool> checkNotificationPrerequisites(BuildContext context) async {
    try {
      // التحقق من أذونات الإشعارات
      final hasPermission = await _permissionsService.checkNotificationPermission();
      if (!hasPermission) {
        final granted = await _permissionsService.showNotificationPermissionDialog(context);
        if (!granted) {
          return false;
        }
      }
      
      // التحقق من تحسينات البطارية
      final batteryOptEnabled = await _batteryOptimizationService.isBatteryOptimizationEnabled();
      if (batteryOptEnabled) {
        await _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
      }
      
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في التحقق من متطلبات الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// تهيئة قنوات الإشعارات
  Future<void> _initializeNotificationChannels() async {
    try {
      // قائمة قنوات الإشعارات
      List<AndroidNotificationChannel> channels = [
        // القناة الافتراضية
        AndroidNotificationChannel(
          _defaultChannelId,
          'التنبيهات الافتراضية',
          description: 'التنبيهات العامة للتطبيق',
          importance: Importance.values[_config.importance],
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
        ),
        
        // قناة ذات أولوية عالية (لتجاوز وضع عدم الإزعاج)
        AndroidNotificationChannel(
          _highPriorityChannelId,
          'تنبيهات مهمة',
          description: 'تنبيهات ذات أولوية عالية',
          importance: Importance.max,
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
          showBadge: true,
        ),
        
        // قناة أذكار الصباح
        AndroidNotificationChannel(
          _morningChannelId,
          'أذكار الصباح',
          description: 'إشعارات أذكار الصباح',
          importance: Importance.high,
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
        ),
        
        // قناة أذكار المساء
        AndroidNotificationChannel(
          _eveningChannelId,
          'أذكار المساء',
          description: 'إشعارات أذكار المساء',
          importance: Importance.high,
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
        ),
        
        // قناة أذكار الصلاة
        AndroidNotificationChannel(
          _prayerChannelId,
          'أذكار الصلاة',
          description: 'إشعارات أذكار الصلاة',
          importance: Importance.high,
          enableVibration: _config.enableVibration,
          playSound: _config.enableSound,
          enableLights: _config.enableLights,
        ),
      ];
      
      // تسجيل قنوات الإشعارات
      for (var channel in channels) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
      
      // إعداد منصة Android
      final androidInitSettings = AndroidInitializationSettings('app_icon');
      
      // إعداد الإشعارات
      final initSettings = InitializationSettings(
        android: androidInitSettings,
      );
      
      // تهيئة الإشعارات مع تعيين معالجات الاستجابة
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في تهيئة قنوات الإشعارات', 
        e
      );
    }
  }
  
  /// إعداد معالجات الإشعارات
  Future<void> _setupNotificationHandlers() async {
    try {
      // معالجة إشعارات الخلفية
      _flutterLocalNotificationsPlugin.initialize(
        InitializationSettings(
          android: AndroidInitializationSettings('app_icon'),
        ),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );
    } catch (e) {
      _errorLoggingService.logError(
        'AndroidNotificationService', 
        'خطأ في إعداد معالجات الإشعارات', 
        e
      );
    }
  }
  
  /// معالجة استجابة الإشعار
  void _onNotificationResponse(NotificationResponse response) {
    try {
      final String? payload = response.payload;
      final String? actionId = response.actionId;
      
      print('استجابة إشعار: action=$actionId, payload=$payload');
      
      if (payloa
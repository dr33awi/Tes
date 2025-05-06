// lib/adhan/adhan_notification_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';

/// خدمة إدارة إشعارات أوقات الصلاة
///
/// تتولى هذه الخدمة:
/// - إنشاء وجدولة إشعارات لأوقات الصلاة
/// - إدارة تفضيلات الإشعارات لكل صلاة
/// - طلب والتحقق من أذونات الإشعارات
/// - تحميل وحفظ تفضيلات الإشعارات للمستخدم
class AdhanNotificationService {
  // تطبيق نمط Singleton
  static final AdhanNotificationService _instance = AdhanNotificationService._internal();
  factory AdhanNotificationService() => _instance;
  AdhanNotificationService._internal();

  // إضافة الإشعارات المحلية
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // إعدادات الإشعارات
  bool _isNotificationEnabled = true;
  final Map<String, bool> _prayerNotificationSettings = {
    'الفجر': true,
    'الشروق': false,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };
  
  // تتبع حالة التهيئة لمنع تكرار التهيئة
  bool _isInitialized = false;
  
  // سياق لعرض مربعات الحوار
  BuildContext? _context;

  /// تهيئة خدمة الإشعارات
  /// 
  /// تقوم بإعداد قنوات الإشعارات، وتحميل التفضيلات المحفوظة،
  /// وتكوين إعدادات الإشعارات.
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('تم تهيئة خدمة الإشعارات مسبقًا');
      return true;
    }
    
    try {
      // تهيئة بيانات المنطقة الزمنية
      tz_data.initializeTimeZones();
      
      // تكوين الإشعارات المحلية
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
      
      final bool? initResult = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      if (initResult != true) {
        debugPrint('تحذير: إرجاع تهيئة إضافة الإشعارات: $initResult');
      }
      
      // تحميل الإعدادات المحفوظة
      await _loadNotificationSettings();
      
      // إنشاء قناة إشعارات لنظام Android
      await _createNotificationChannel();
      
      _isInitialized = true;
      debugPrint('تم تهيئة خدمة إشعارات الصلاة بنجاح');
      return true;
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة الإشعارات: $e');
      return false;
    }
  }
  
  /// إنشاء قناة إشعارات لنظام Android
  Future<void> _createNotificationChannel() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'adhan_channel',
          'مواقيت الصلاة',
          description: 'إشعارات أوقات الصلاة',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        );
        
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('تم إنشاء قناة إشعارات Android بنجاح');
      } else {
        debugPrint('إضافة Android غير متوفرة، تخطي إنشاء القناة');
      }
    } catch (e) {
      debugPrint('خطأ في إنشاء قناة الإشعارات: $e');
      // متابعة التنفيذ رغم خطأ إنشاء القناة
    }
  }
  
  /// طلب أذونات الإشعارات
  ///
  /// يطلب أذونات الإشعارات لكل من نظامي Android و iOS.
  /// يعيد true إذا تم منح الأذونات، و false خلاف ذلك.
  Future<bool> requestNotificationPermission() async {
    try {
      // لنظام Android 13+ (مطلوب إذن الإشعارات)
      bool permissionGranted = await Permission.notification.request().isGranted;
      
      // لنظام iOS
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
      
      debugPrint('حالة إذن الإشعارات: $permissionGranted');
      return permissionGranted;
    } catch (e) {
      debugPrint('خطأ في طلب إذن الإشعارات: $e');
      return false;
    }
  }
  
  /// التحقق من حالة إذن الإشعارات
  Future<bool> checkNotificationPermission() async {
    try {
      return await Permission.notification.status.isGranted;
    } catch (e) {
      debugPrint('خطأ في التحقق من إذن الإشعارات: $e');
      return false;
    }
  }
  
  /// التحقق وطلب الأذونات إذا لزم الأمر
  Future<bool> checkAndRequestPermissions() async {
    try {
      if (await checkNotificationPermission()) {
        return true;
      }
      
      return await requestNotificationPermission();
    } catch (e) {
      debugPrint('خطأ في checkAndRequestPermissions: $e');
      return false;
    }
  }
  
  /// تعيين السياق لعرض مربعات الحوار
  void setContext(BuildContext context) {
    _context = context;
  }
  
  /// التعامل مع النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    // التعامل مع التنقل عند النقر على الإشعار
    debugPrint('تم النقر على الإشعار: ${response.id}');
    debugPrint('حمولة الإشعار: ${response.payload}');
  }
  
  /// تحميل إعدادات الإشعارات المحفوظة
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل حالة التفعيل العامة
      _isNotificationEnabled = prefs.getBool('adhan_notification_enabled') ?? true;
      
      // تحميل الإعدادات لكل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        final enabled = prefs.getBool('adhan_notification_$prayer') ?? 
            _prayerNotificationSettings[prayer]!;
        _prayerNotificationSettings[prayer] = enabled;
      }
      
      debugPrint('تم تحميل إعدادات الإشعارات بنجاح');
    } catch (e) {
      debugPrint('خطأ في تحميل إعدادات الإشعارات: $e');
      // استمرار باستخدام الإعدادات الافتراضية في حالة الخطأ
    }
  }
  
  /// حفظ إعدادات الإشعارات
  Future<void> saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ حالة التفعيل العامة
      await prefs.setBool('adhan_notification_enabled', _isNotificationEnabled);
      
      // حفظ الإعدادات لكل صلاة
      for (final prayer in _prayerNotificationSettings.keys) {
        await prefs.setBool(
          'adhan_notification_$prayer', 
          _prayerNotificationSettings[prayer]!
        );
      }
      
      debugPrint('تم حفظ إعدادات الإشعارات بنجاح');
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات الإشعارات: $e');
    }
  }
  
  /// جدولة إشعار لوقت صلاة محدد
  Future<bool> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
    required int notificationId,
  }) async {
    // التحقق مما إذا كانت الإشعارات مفعلة لهذه الصلاة
    if (!_isNotificationEnabled || !(_prayerNotificationSettings[prayerName] ?? false)) {
      debugPrint('الإشعارات لـ $prayerName معطلة، تخطي');
      return false;
    }
    
    // التحقق مما إذا كان وقت الصلاة في المستقبل
    final now = DateTime.now();
    if (prayerTime.isBefore(now)) {
      debugPrint('وقت صلاة $prayerName في $prayerTime قد مضى، تخطي');
      return false;
    }
    
    try {
      // معلومات التصحيح
      debugPrint('===== تفاصيل الإشعار =====');
      debugPrint('اسم الصلاة: $prayerName');
      debugPrint('وقت الصلاة: $prayerTime');
      debugPrint('معرّف الإشعار: $notificationId');
      
      // تكوين تفاصيل الإشعار
      final androidDetails = AndroidNotificationDetails(
        'adhan_channel',
        'مواقيت الصلاة',
        channelDescription: 'إشعارات أوقات الصلاة',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const BigTextStyleInformation(''),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );
      
      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      // محتوى الإشعار
      final title = 'حان وقت صلاة $prayerName';
      final body = 'حان الآن وقت صلاة $prayerName';
      
      // جدولة الإشعار
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(prayerTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'prayer_$prayerName',
      );
      
      debugPrint('تم جدولة إشعار لـ $prayerName في $prayerTime');
      return true;
    } catch (e) {
      debugPrint('خطأ في جدولة إشعار لـ $prayerName: $e');
      return false;
    }
  }
  
  /// جدولة إشعارات لجميع أوقات الصلاة
  Future<int> scheduleAllPrayerNotifications(List<Map<String, dynamic>> prayerTimes) async {
    if (!_isInitialized) {
      debugPrint('تحذير: محاولة جدولة إشعارات قبل التهيئة');
      await initialize();
    }
    
    // إلغاء الإشعارات السابقة
    await cancelAllNotifications();
    
    // التحقق من الإذن قبل الجدولة
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      debugPrint('لم يتم منح إذن الإشعارات، تخطي الجدولة');
      return 0;
    }
    
    int scheduledCount = 0;
    
    // جدولة إشعارات جديدة
    for (int i = 0; i < prayerTimes.length; i++) {
      final prayer = prayerTimes[i];
      final success = await schedulePrayerNotification(
        prayerName: prayer['name'],
        prayerTime: prayer['time'],
        notificationId: i,
      );
      
      if (success) {
        scheduledCount++;
      }
    }
    
    debugPrint('تم جدولة $scheduledCount من أصل ${prayerTimes.length} إشعارات للصلاة');
    return scheduledCount;
  }
  
  /// إلغاء جميع الإشعارات المجدولة
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('تم إلغاء جميع الإشعارات');
    } catch (e) {
      debugPrint('خطأ في إلغاء الإشعارات: $e');
    }
  }
  
  /// جدولة إشعار اختباري
Future<void> scheduleDhuhrTestNotification() async {
  // Verificar si las notificaciones están habilitadas
  if (!_isNotificationEnabled || !(_prayerNotificationSettings['الظهر'] ?? false)) {
    debugPrint('Las notificaciones para الظهر están desactivadas');
    return;
  }
  
  try {
    // Verificar permisos
    bool hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        debugPrint('No se tienen permisos de notificación para realizar la prueba');
        return;
      }
    }
    
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
    
    // Configurar tiempo de prueba (10 segundos después de solicitar)
    final testTime = DateTime.now().add(const Duration(seconds: 10));
    
    // Contenido de la notificación
    final title = 'حان وقت صلاة الظهر';
    final body = 'حان الآن وقت صلاة الظهر (اختبار)';
    
    // Programar notificación de prueba
    await _notificationsPlugin.zonedSchedule(
      999, // ID único para la notificación de prueba
      title,
      body,
      tz.TZDateTime.from(testTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint('Notificación de prueba para الظهر programada para: $testTime');
  } catch (e) {
    debugPrint('Error al programar notificación de prueba para الظهر: $e');
  }
}
  
  // الدوال الجالبة والمعينة
  bool get isNotificationEnabled => _isNotificationEnabled;
  
  set isNotificationEnabled(bool value) {
    _isNotificationEnabled = value;
    saveNotificationSettings();
  }
  
  Map<String, bool> get prayerNotificationSettings => Map.unmodifiable(_prayerNotificationSettings);
  
  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    if (_prayerNotificationSettings.containsKey(prayer)) {
      _prayerNotificationSettings[prayer] = enabled;
      await saveNotificationSettings();
    }
  }
  
  bool get isInitialized => _isInitialized;
}
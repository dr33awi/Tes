// lib/services/notification_service.dart
import 'dart:io';
import 'dart:convert'; // إضافة import للتعامل مع json
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/do_not_disturb_service.dart';
import 'package:test_athkar_app/services/ios_notification_service.dart';
import 'package:test_athkar_app/services/notification_grouping_service.dart';
import 'package:test_athkar_app/services/battery_optimization_service.dart';



/// خدمة موحدة للإشعارات في التطبيق
class NotificationService {
  // مكونات الخدمة باستخدام التبعية المعكوسة
  final ErrorLoggingService _errorLoggingService;
  final DoNotDisturbService _doNotDisturbService;
  final IOSNotificationService _iosNotificationService;
  final NotificationGroupingService _notificationGroupingService;
  final BatteryOptimizationService _batteryOptimizationService;
  
  // كائن الإشعارات المحلية
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  
  // مفاتيح التخزين المحلي
  static const String _keySavedNotifications = 'saved_notifications';
  static const String _keyNotificationIdsMapping = 'notification_ids_mapping';
  static const String _keyNotificationEnabled = 'notification_enabled';
  
  // معرف قناة الإشعارات الافتراضية
  static const String _defaultChannelId = 'athkar_channel';
  
  // المُعرف الدولي لعرض الإشعارات
  static const String _defaultIconResourceName = '@mipmap/ic_launcher';
  
  // سجل التهيئة
  bool _isInitialized = false;
  
  // تنفيذ نمط Singleton مع التبعية المعكوسة
  static NotificationService? _instance;
  
  factory NotificationService({
    ErrorLoggingService? errorLoggingService,
    DoNotDisturbService? doNotDisturbService,
    IOSNotificationService? iosNotificationService,
    NotificationGroupingService? notificationGroupingService,
    BatteryOptimizationService? batteryOptimizationService,
    FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin,
  }) {
    _instance ??= NotificationService._internal(
      errorLoggingService ?? ErrorLoggingService(),
      doNotDisturbService ?? DoNotDisturbService(),
      iosNotificationService ?? IOSNotificationService(),
      notificationGroupingService ?? NotificationGroupingService(),
      batteryOptimizationService ?? BatteryOptimizationService(),
      flutterLocalNotificationsPlugin ?? FlutterLocalNotificationsPlugin(),
    );
    return _instance!;
  }
  
  // المُنشئ الداخلي
  NotificationService._internal(
    this._errorLoggingService,
    this._doNotDisturbService,
    this._iosNotificationService,
    this._notificationGroupingService,
    this._batteryOptimizationService,
    this.flutterLocalNotificationsPlugin,
  );
  
  /// تهيئة خدمة الإشعارات
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        return true;
      }
      
      // تهيئة بيانات المناطق الزمنية
      tz_data.initializeTimeZones();
      
      // إعدادات تهيئة الإشعارات لنظام أندرويد
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings(_defaultIconResourceName);
      
      // إعدادات تهيئة الإشعارات لنظام iOS
      final DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
            // حذف المعلمة غير الموجودة
            // onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            requestCriticalPermission: true,
          );
      
      // دمج إعدادات التهيئة لجميع الأنظمة
      final InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );
      
      // تهيئة البلاجن بالإعدادات
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      
      // تهيئة قنوات الإشعارات لنظام أندرويد
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }
      
      // تهيئة إعدادات iOS الخاصة
      if (Platform.isIOS) {
        await _iosNotificationService.initializeIOSNotifications();
      }
      
      // تعيين علامة التهيئة
      _isInitialized = true;
      
      // تعيين إعدادات عدم الإزعاج لتجاوزها عند الحاجة
      await _doNotDisturbService.configureNotificationChannelsForDoNotDisturb();
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error initializing notification service', 
        e
      );
      return false;
    }
  }
  
  /// إنشاء قنوات الإشعارات لنظام أندرويد
  Future<void> _createNotificationChannels() async {
    try {
      // قناة إشعارات أذكار الصباح
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'athkar_morning_channel',
            'أذكار الصباح',
            description: 'إشعارات أذكار الصباح',
            importance: Importance.high,
            sound: RawResourceAndroidNotificationSound('morning_notification'),
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFFFFD54F),
          ));
      
      // قناة إشعارات أذكار المساء
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'athkar_evening_channel',
            'أذكار المساء',
            description: 'إشعارات أذكار المساء',
            importance: Importance.high,
            sound: RawResourceAndroidNotificationSound('evening_notification'),
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFFAB47BC),
          ));
      
      // قناة إشعارات أذكار النوم
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'athkar_sleep_channel',
            'أذكار النوم',
            description: 'إشعارات أذكار النوم',
            importance: Importance.high,
            sound: RawResourceAndroidNotificationSound('sleep_notification'),
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFF5C6BC0),
          ));
      
      // قناة إشعارات أذكار الاستيقاظ
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'athkar_wake_channel',
            'أذكار الاستيقاظ',
            description: 'إشعارات أذكار الاستيقاظ',
            importance: Importance.high,
            sound: RawResourceAndroidNotificationSound('wake_notification'),
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFFFFB74D),
          ));
      
      // قناة إشعارات عامة للأذكار
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _defaultChannelId,
            'إشعارات الأذكار',
            description: 'الإشعارات العامة للأذكار',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
          ));
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error creating notification channels', 
        e
      );
    }
  }
  
  /// معالجة استجابة الإشعارات
  void _onNotificationResponse(NotificationResponse response) async {
    try {
      final String? payload = response.payload;
      final actionId = response.actionId;
      
      // تسجيل استجابة الإشعار للتصحيح
      print('Notification response: $payload, action: $actionId');
      
      // توجيه الإشعار إلى المعالج المناسب
      if (actionId == 'MARK_READ') {
        // معالجة تمييز الإشعار كمقروء
        _handleMarkAsRead(payload);
      } else if (actionId == 'SNOOZE' || actionId == 'REMIND_LATER') {
        // معالجة تأجيل الإشعار
        _handleSnoozeNotification(payload);
      } else {
        // تخزين معلومات الإشعار للتنقل عند فتح التطبيق
        if (payload != null && payload.isNotEmpty) {
          await _saveNotificationOpenInfo(payload);
        }
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error handling notification response', 
        e
      );
    }
  }
  
  /// حفظ معلومات فتح الإشعار للتنقل لاحقاً
  Future<void> _saveNotificationOpenInfo(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('opened_from_notification', true);
      await prefs.setString('notification_payload', payload);
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error saving notification open info', 
        e
      );
    }
  }
  
  /// معالجة إشعارات iOS القديمة - تم الاحتفاظ بها للتوافقية
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    print('iOS local notification: $id, $title, $payload');
    // هذه الدالة مطلوبة للأجهزة القديمة، ولكن معظم المنطق موجود في _onNotificationResponse
  }
  
  /// معالجة تمييز الإشعار كمقروء
  Future<void> _handleMarkAsRead(String? payload) async {
    try {
      if (payload == null || payload.isEmpty) return;
      
      // تحليل معرف الفئة من البيانات
      final categoryId = payload.split(':').first;
      
      // تنفيذ المنطق المناسب بناءً على نوع الأذكار
      // يمكن هنا تحديث العدادات أو تخزين معلومات القراءة
      
      // إرسال إشعار تأكيد
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'تم تسجيل قراءة الأذكار',
        'بارك الله فيك على قراءة أذكار $categoryId',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannelId,
            'إشعارات الأذكار',
            channelDescription: 'الإشعارات العامة للأذكار',
            importance: Importance.low,
            priority: Priority.low,
            showWhen: true,
          ),
        ),
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error handling mark as read', 
        e
      );
    }
  }
  
  /// معالجة تأجيل الإشعار
  Future<void> _handleSnoozeNotification(String? payload) async {
    try {
      if (payload == null || payload.isEmpty) return;
      
      // تحليل معرف الفئة من البيانات
      final categoryId = payload.split(':').first;
      
      // جدولة تذكير بعد 30 دقيقة
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 30));
      
      // تحديد معرف الإشعار الجديد
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      // جدولة الإشعار المؤجل
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'تذكير بالأذكار',
        'حان وقت قراءة الأذكار التي قمت بتأجيلها',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannelId,
            'إشعارات الأذكار',
            channelDescription: 'الإشعارات العامة للأذكار',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      // إشعار تأكيد التأجيل
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(90000),
        'تم تأجيل الإشعار',
        'سيتم تذكيرك بعد 30 دقيقة',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannelId,
            'إشعارات الأذكار',
            channelDescription: 'الإشعارات العامة للأذكار',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error handling snooze notification', 
        e
      );
    }
  }
  
  /// جدولة إشعار لفئة أذكار محددة
  Future<bool> scheduleNotification(AthkarCategory category, TimeOfDay time) async {
    try {
      // التحقق من تفعيل الإشعارات
      if (!await isNotificationEnabled()) {
        return false;
      }
      
      // الحصول على معرف فريد للإشعار
      int notificationId = await _getNotificationId(category.id);
      
      // الحصول على وقت الإشعار المجدول
      final tz.TZDateTime scheduledDate = _getScheduledDateTime(time);
      
      // إعداد تفاصيل الإشعار بناءً على نظام التشغيل
      NotificationDetails? notificationDetails = await _getNotificationDetails(category);
      
      if (notificationDetails == null) {
        throw Exception('فشل في إنشاء تفاصيل الإشعار');
      }
      
      // تحديد عنوان ونص الإشعار
      final String title = category.notifyTitle ?? 'حان موعد ${category.title}';
      final String body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
      
      // جدولة الإشعار
// Schedule notification
await flutterLocalNotificationsPlugin.zonedSchedule(
  notificationId,
  title,
  body,
  scheduledDate,
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  matchDateTimeComponents: DateTimeComponents.time, // Daily repeat at same time
  payload: category.id,
);
      
      // حفظ الإشعار في الإعدادات
      await _saveScheduledNotification(
        category.id, 
        notificationId, 
        time.hour, 
        time.minute
      );
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error scheduling notification for ${category.id}', 
        e
      );
      return false;
    }
  }
  
  /// جدولة إشعارات متعددة لفئة أذكار
  Future<bool> scheduleMultipleNotifications(
    AthkarCategory category, 
    List<TimeOfDay> times,
  ) async {
    // استخدام خدمة تجميع الإشعارات إذا كان هناك أكثر من إشعار
    if (times.length > 1) {
      final List<String> timeStrings = times.map((time) => '${time.hour}:${time.minute}').toList();
      return await _notificationGroupingService.scheduleMultipleNotifications(
        category, 
        timeStrings.sublist(1), // استثناء الوقت الرئيسي
        times.first, // الوقت الرئيسي
      );
    } else if (times.length == 1) {
      // جدولة إشعار واحد
      return await scheduleNotification(category, times.first);
    }
    
    return false;
  }
  
  /// الحصول على تفاصيل الإشعار بناءً على نظام التشغيل وفئة الأذكار
  Future<NotificationDetails?> _getNotificationDetails(AthkarCategory category) async {
    try {
      if (Platform.isAndroid) {
        // إعداد تفاصيل الإشعار لنظام أندرويد
        String channelId = _getChannelIdForCategory(category.id);
        
        AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          channelId,
          _getChannelNameForCategory(category.id),
          channelDescription: _getChannelDescriptionForCategory(category.id),
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'حان وقت ${category.title}',
          color: _getCategoryColor(category.id),
          ledColor: _getCategoryColor(category.id),
          ledOnMs: 1000,
          ledOffMs: 500,
          enableLights: true,
          enableVibration: true,
          sound: _getCategorySound(category.id),
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: false, // تعيين إلى true للإشعارات المهمة جدًا
          visibility: NotificationVisibility.public,
          actions: [
            AndroidNotificationAction(
              'MARK_READ',
              'تم القراءة',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'SNOOZE',
              'تأجيل',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        );
        
        return NotificationDetails(android: androidDetails);
      } else if (Platform.isIOS) {
        // استخدام خدمة إشعارات iOS المحسنة
        DarwinNotificationDetails iosDetails = _iosNotificationService.createIOSNotificationDetails(category);
        return NotificationDetails(iOS: iosDetails);
      }
      
      // للأنظمة الأخرى، استخدم إعدادات إشعار عامة
      return const NotificationDetails();
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error getting notification details', 
        e
      );
      return null;
    }
  }
  
  /// الحصول على معرف قناة الإشعارات بناءً على فئة الأذكار
  String _getChannelIdForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return 'athkar_morning_channel';
      case 'evening':
        return 'athkar_evening_channel';
      case 'sleep':
        return 'athkar_sleep_channel';
      case 'wake':
        return 'athkar_wake_channel';
      default:
        return _defaultChannelId;
    }
  }
  
  /// الحصول على اسم قناة الإشعارات بناءً على فئة الأذكار
  String _getChannelNameForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return 'أذكار الصباح';
      case 'evening':
        return 'أذكار المساء';
      case 'sleep':
        return 'أذكار النوم';
      case 'wake':
        return 'أذكار الاستيقاظ';
      default:
        return 'إشعارات الأذكار';
    }
  }
  
  /// الحصول على وصف قناة الإشعارات بناءً على فئة الأذكار
  String _getChannelDescriptionForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return 'إشعارات أذكار الصباح';
      case 'evening':
        return 'إشعارات أذكار المساء';
      case 'sleep':
        return 'إشعارات أذكار النوم';
      case 'wake':
        return 'إشعارات أذكار الاستيقاظ';
      default:
        return 'الإشعارات العامة للأذكار';
    }
  }
  
  /// الحصول على لون الإشعار بناءً على فئة الأذكار
  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const Color(0xFFFFD54F); // أصفر
      case 'evening':
        return const Color(0xFFAB47BC); // بنفسجي
      case 'sleep':
        return const Color(0xFF5C6BC0); // أزرق
      case 'wake':
        return const Color(0xFFFFB74D); // برتقالي
      case 'prayer':
        return const Color(0xFF4DB6AC); // أزرق فاتح
      default:
        return const Color(0xFF447055); // اللون الافتراضي للتطبيق
    }
  }
  
  /// إضافة جديدة: الحصول على أيقونة الفئة بناءً على المعرف
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.nightlight_round;
      case 'sleep':
        return Icons.bedtime;
      case 'wake':
        return Icons.alarm;
      case 'prayer':
        return Icons.mosque;
      default:
        return Icons.notifications;
    }
  }
  
  /// الحصول على صوت الإشعار بناءً على فئة الأذكار
  AndroidNotificationSound? _getCategorySound(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return const RawResourceAndroidNotificationSound('morning_notification');
      case 'evening':
        return const RawResourceAndroidNotificationSound('evening_notification');
      case 'sleep':
        return const RawResourceAndroidNotificationSound('sleep_notification');
      case 'wake':
        return const RawResourceAndroidNotificationSound('wake_notification');
      default:
        return null; // استخدام الصوت الافتراضي للنظام
    }
  }
  
  /// الحصول على وقت الإشعار المجدول
  tz.TZDateTime _getScheduledDateTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // إذا كان الوقت قد مر اليوم، قم بالجدولة لليوم التالي
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  /// الحصول على معرف فريد للإشعار
  Future<int> _getNotificationId(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> idsMapping = {};
      
      // قراءة معرفات الإشعارات المحفوظة
      final String? savedMapping = prefs.getString(_keyNotificationIdsMapping);
      if (savedMapping != null) {
        idsMapping = Map<String, dynamic>.from(
          json.decode(savedMapping) // تم التصحيح هنا
        );
      }
      
      // إعادة استخدام المعرف إذا كان موجودًا
      if (idsMapping.containsKey(categoryId)) {
        return idsMapping[categoryId] as int;
      }
      
      // إنشاء معرف جديد فريد
      final int newId = DateTime.now().millisecondsSinceEpoch.remainder(100000) + categoryId.hashCode.abs();
      idsMapping[categoryId] = newId;
      
      // حفظ المعرف الجديد
      await prefs.setString(
        _keyNotificationIdsMapping,
        json.encode(idsMapping) // تم التصحيح هنا
      );
      
      return newId;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error getting notification id for $categoryId', 
        e
      );
      // إرجاع معرف عشوائي في حالة الخطأ
      return DateTime.now().millisecondsSinceEpoch.remainder(100000);
    }
  }
  
  /// حفظ معلومات الإشعار المجدول
  Future<void> _saveScheduledNotification(
    String categoryId, 
    int notificationId, 
    int hour, 
    int minute
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // قراءة الإشعارات المحفوظة
      Map<String, dynamic> savedNotifications = {};
      final String? savedData = prefs.getString(_keySavedNotifications);
      
      if (savedData != null) {
        savedNotifications = Map<String, dynamic>.from(
          json.decode(savedData) // تم التصحيح هنا
        );
      }
      
      // حفظ معلومات الإشعار الجديد
      savedNotifications[categoryId] = {
        'id': notificationId,
        'hour': hour,
        'minute': minute,
        'enabled': true,
      };
      
      // حفظ البيانات المحدثة
      await prefs.setString(
        _keySavedNotifications,
        json.encode(savedNotifications) // تم التصحيح هنا
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error saving scheduled notification', 
        e
      );
    }
  }
  
  /// إلغاء إشعار محدد
  Future<bool> cancelNotification(String categoryId) async {
    try {
      // التحقق مما إذا كان هذا ينتمي إلى مجموعة إشعارات
      final notificationIds = await _notificationGroupingService.getGroupedNotificationIds(categoryId);
      
      if (notificationIds.isNotEmpty) {
        // إلغاء مجموعة الإشعارات
        await _notificationGroupingService.cancelGroupedNotifications(categoryId);
      } else {
        // الحصول على معرف الإشعار
        final notificationId = await _getNotificationId(categoryId);
        
        // إلغاء الإشعار
        await flutterLocalNotificationsPlugin.cancel(notificationId);
      }
      
      // حذف معلومات الإشعار المحفوظة
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> savedNotifications = {};
      final String? savedData = prefs.getString(_keySavedNotifications);
      
      if (savedData != null) {
        savedNotifications = Map<String, dynamic>.from(
          json.decode(savedData) // تم التصحيح هنا
        );
        
        // حذف الإشعار من القائمة المحفوظة
        savedNotifications.remove(categoryId);
        
        // حفظ البيانات المحدثة
        await prefs.setString(
          _keySavedNotifications,
          json.encode(savedNotifications) // تم التصحيح هنا
        );
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error canceling notification for $categoryId', 
        e
      );
      return false;
    }
  }
  
  /// إلغاء جميع الإشعارات
  Future<bool> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      
      // حذف جميع المعلومات المحفوظة
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySavedNotifications);
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error canceling all notifications', 
        e
      );
      return false;
    }
  }
  
  /// إعادة جدولة جميع الإشعارات المحفوظة
  Future<bool> scheduleAllSavedNotifications() async {
    try {
      // التحقق من تفعيل الإشعارات
      if (!await isNotificationEnabled()) {
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString(_keySavedNotifications);
      
      if (savedData == null) {
        return false; // لا توجد إشعارات محفوظة
      }
      
      Map<String, dynamic> savedNotifications = Map<String, dynamic>.from(
        json.decode(savedData) // تم التصحيح هنا
      );
      
      // تتبع النجاح والفشل
      int successCount = 0;
      int failureCount = 0;
      
      // إعادة جدولة كل إشعار
      for (final entry in savedNotifications.entries) {
        final categoryId = entry.key;
        final notificationData = entry.value;
        
        if (notificationData['enabled'] == true) {
          try {
            // الحصول على وقت الإشعار
            final hour = notificationData['hour'] as int;
            final minute = notificationData['minute'] as int;
            final time = TimeOfDay(hour: hour, minute: minute);
            
            // الحصول على فئة الأذكار
            final categoryData = await _getCategoryData(categoryId);
            
            if (categoryData != null) {
              // إعادة جدولة الإشعار
              final success = await scheduleNotification(categoryData, time);
              
              if (success) {
                successCount++;
              } else {
                failureCount++;
              }
            }
          } catch (e) {
            failureCount++;
            await _errorLoggingService.logError(
              'NotificationService', 
              'Error rescheduling notification for $categoryId', 
              e
            );
          }
        }
      }
      
      print('Rescheduled notifications: $successCount success, $failureCount failures');
      return successCount > 0;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error rescheduling all notifications', 
        e
      );
      return false;
    }
  }
  
  /// الحصول على بيانات فئة الأذكار - يمكن تعديل هذه الدالة لتناسب نموذج البيانات الخاص بك
  Future<AthkarCategory?> _getCategoryData(String categoryId) async {
    try {
      // تنفيذ منطق للحصول على بيانات فئة الأذكار
      // هذا مثال مبسط، يمكنك استبداله بالمنطق الحقيقي
      
      String title;
      switch (categoryId) {
        case 'morning':
          title = 'أذكار الصباح';
          break;
        case 'evening':
          title = 'أذكار المساء';
          break;
        case 'sleep':
          title = 'أذكار النوم';
          break;
        case 'wake':
          title = 'أذكار الاستيقاظ';
          break;
        default:
          title = 'أذكار $categoryId';
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error getting category data for $categoryId', 
        e
      );
      return null;
    }
  }
  
  /// الحصول على الإشعارات المحفوظة
  Future<Map<String, dynamic>> getSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString(_keySavedNotifications);
      
      if (savedData == null) {
        return {};
      }
      
      return Map<String, dynamic>.from(
        json.decode(savedData) // تم التصحيح هنا
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error getting saved notifications', 
        e
      );
      return {};
    }
  }
  
  /// الحصول على الإشعارات المعلقة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error getting pending notifications', 
        e
      );
      return [];
    }
  }
  
  /// تحديث حالة تفعيل الإشعارات
  Future<bool> setNotificationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationEnabled, enabled);
      
      if (enabled) {
        // إعادة جدولة الإشعارات إذا تم تفعيلها
        await scheduleAllSavedNotifications();
      } else {
        // إلغاء جميع الإشعارات إذا تم تعطيلها
        await flutterLocalNotificationsPlugin.cancelAll();
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error setting notification enabled: $enabled', 
        e
      );
      return false;
    }
  }
  
  /// التحقق من حالة تفعيل الإشعارات
  Future<bool> isNotificationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyNotificationEnabled) ?? true; // مفعل افتراضيًا
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error checking if notification is enabled', 
        e
      );
      return true; // افتراض أنها مفعلة في حالة الخطأ
    }
  }
  
  /// دالة لفحص وطلب تفعيل الإشعارات
  Future<void> checkNotificationOptimizations(BuildContext context) async {
    try {
      // فحص وطلب تعطيل تحسين البطارية
      await _batteryOptimizationService.checkAndRequestBatteryOptimization(context);
      
      // فحص وضع عدم الإزعاج
      final shouldPrompt = await _doNotDisturbService.shouldPromptAboutDoNotDisturb();
      if (shouldPrompt) {
        await _doNotDisturbService.showDoNotDisturbDialog(context);
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error checking notification optimizations', 
        e
      );
    }
  }
  
  /// إرسال إشعار اختباري
  Future<bool> sendTestNotification() async {
    try {
      if (Platform.isIOS) {
        // استخدام إشعار iOS محسن للاختبار
        return await _iosNotificationService.sendTestNotification();
      } else {
        // إرسال إشعار اختباري عام
        final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
        
        // إعداد تفاصيل الإشعار
        const NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannelId,
            'إشعارات الأذكار',
            channelDescription: 'الإشعارات العامة للأذكار',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'اختبار الإشعارات',
          ),
        );
        
        // إرسال الإشعار
        await flutterLocalNotificationsPlugin.show(
          notificationId,
          'اختبار الإشعارات',
          'هذا اختبار للتحقق من عمل نظام الإشعارات بشكل صحيح',
          notificationDetails,
          payload: 'test',
        );
        
        return true;
      }
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error sending test notification', 
        e
      );
      return false;
    }
  }
  
  /// إرسال إشعار مجمّع للاختبار
  Future<bool> sendGroupedTestNotification(AthkarCategory category) async {
    try {
      await _notificationGroupingService.showGroupedTestNotification(category);
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'NotificationService', 
        'Error sending grouped test notification', 
        e
      );
      return false;
    }
  }
}
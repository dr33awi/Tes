// lib/services/ios_notification_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:test_athkar_app/services/notification_service_interface.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// تنفيذ خدمة الإشعارات الموحدة لنظام iOS
class IOSNotificationService implements NotificationServiceInterface {
  // نمط Singleton للتنفيذ
  static final IOSNotificationService _instance = IOSNotificationService._internal();
  factory IOSNotificationService() => _instance;
  
  // التبعية المعكوسة
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  // كائن Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // فئات الإشعارات في iOS
  static const String categoryGeneral = 'general_category';
  static const String categoryReminder = 'reminder_category';
  static const String categoryImportant = 'important_category';
  
  // مفاتيح التخزين المحلي
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyScheduledNotifications = 'scheduled_notifications';
  static const String _keyNotificationConfig = 'notification_config';
  
  // كائن التكوين
  NotificationConfig _config = NotificationConfig();
  
  // المنشئ الداخلي
  IOSNotificationService._internal();
  
  @override
  Future<bool> initialize() async {
    if (!Platform.isIOS) return false;
    
    try {
      // طلب الأذونات مع خيار الإشعارات الحرجة
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true, // تمكين الإشعارات الحرجة
          );
      
      print('نتيجة إذن إشعارات iOS: $result');
      
      // إعداد فئات الإشعارات لنظام iOS
      await _setupNotificationCategories();
      
      // تحميل تكوين الإشعارات
      await _loadNotificationConfig();
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في تهيئة إشعارات iOS', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> configureFromPreferences() async {
    try {
      await _loadNotificationConfig();
      return true;
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
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
        _config = NotificationConfig();
      }
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
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
        'IOSNotificationService', 
        'خطأ في حفظ تكوين الإشعارات', 
        e
      );
    }
  }
  
  @override
  Future<bool> checkNotificationPrerequisites(BuildContext context) async {
    if (!Platform.isIOS) return false;
    
    try {
      // التحقق من الأذونات
      final bool? hasPermission = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
      
      return hasPermission ?? false;
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في التحقق من متطلبات الإشعارات', 
        e
      );
      return false;
    }
  }
  
  /// إعداد فئات الإشعارات لنظام iOS
  Future<void> _setupNotificationCategories() async {
    if (!Platform.isIOS) return;
    
    try {
      // تعريف فئات الإشعارات
      final List<DarwinNotificationCategory> darwinNotificationCategories = [
        // فئة عامة
        DarwinNotificationCategory(
          categoryGeneral,
          actions: [
            // إجراء لتمييز كمقروء
            DarwinNotificationAction.plain(
              'MARK_READ',
              'تم القراءة',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            // إجراء للتأجيل
            DarwinNotificationAction.plain(
              'SNOOZE',
              'تأجيل',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          }
        ),
        
        // فئة التذكيرات
        DarwinNotificationCategory(
          categoryReminder,
          actions: [
            DarwinNotificationAction.plain(
              'MARK_READ',
              'تم القراءة',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'REMIND_LATER',
              'ذكرني لاحقاً',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        
        // فئة مهمة
        DarwinNotificationCategory(
          categoryImportant,
          actions: [
            DarwinNotificationAction.plain(
              'MARK_READ',
              'تم القراءة',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ];
      
      // تعيين الفئات
      final darwinNotificationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
        notificationCategories: darwinNotificationCategories,
      );
      
      // تهيئة إعدادات iOS
      final initializationSettings = InitializationSettings(
        iOS: darwinNotificationSettings,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );
      
      print('تم تهيئة فئات الإشعارات في iOS');
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في إعداد فئات الإشعارات', 
        e
      );
    }
  }
  
  /// معالجة استجابة إجراء الإشعار
  void _onNotificationResponse(NotificationResponse response) {
    if (!Platform.isIOS) return;
    
    try {
      final String? payload = response.payload;
      final String? actionId = response.actionId;
      
      print('استجابة الإشعار: action=$actionId, payload=$payload');
      
      if (actionId == 'MARK_READ') {
        _handleMarkAsRead(payload);
      } else if (actionId == 'SNOOZE' || actionId == 'REMIND_LATER') {
        _handleSnoozeNotification(payload);
      }
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في معالجة استجابة الإشعار', 
        e
      );
    }
  }
  
  /// معالجة استجابة الإشعار في الخلفية
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('استجابة الإشعار في الخلفية: ${response.actionId}, ${response.payload}');
  }
  
  /// معالجة إجراء تمييز كمقروء
  Future<void> _handleMarkAsRead(String? payload) async {
    if (payload == null) return;
    
    try {
      print('تمييز كمقروء: $payload');
      
      await _flutterLocalNotificationsPlugin.show(
        10000,
        'تم تسجيل القراءة',
        'بارك الله فيك',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            categoryIdentifier: categoryGeneral,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في معالجة تمييز كمقروء', 
        e
      );
    }
  }
  
  /// معالجة إجراء تأجيل الإشعار
  Future<void> _handleSnoozeNotification(String? payload) async {
    if (payload == null) return;
    
    try {
      // جدولة تذكير بعد 30 دقيقة
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: 30));
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        20000,
        'تذكير',
        'حان وقت القراءة',
        scheduledDate,
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            categoryIdentifier: categoryReminder,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        10001,
        'تم تأجيل الإشعار',
        'سيتم تذكيرك بعد 30 دقيقة',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في معالجة تأجيل الإشعار', 
        e
      );
    }
  }
  
  /// الحصول على الوقت التالي لجدولة الإشعار
  tz.TZDateTime _getNextInstanceOfTime(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  @override
  Future<bool> scheduleNotification({
    required String notificationId,
    required String title,
    required String body,
    required TimeOfDay notificationTime,
    String? channelId,
    String? payload,
    Color? color,
    bool repeat = true,
    int? priority,
  }) async {
    if (!Platform.isIOS) return false;
    
    try {
      final id = notificationId.hashCode.abs() % 100000;
      final scheduledDate = _getNextInstanceOfTime(notificationTime);
      
      String categoryIdentifier = categoryGeneral;
      if (priority != null && priority >= 4) {
        categoryIdentifier = categoryImportant;
      } else if (channelId == 'reminder') {
        categoryIdentifier = categoryReminder;
      }
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: _config.enableSound,
        sound: 'default',
        interruptionLevel: priority != null && priority >= 4 
            ? InterruptionLevel.active 
            : InterruptionLevel.passive,
        categoryIdentifier: categoryIdentifier,
        threadIdentifier: 'notification_$notificationId',
      );
      
      final notificationDetails = NotificationDetails(iOS: iosDetails);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeat ? DateTimeComponents.time : null,
        payload: payload ?? notificationId,
      );
      
      await _saveNotificationTime(notificationId, notificationTime);
      await _updateScheduledNotificationsList(notificationId);
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في جدولة إشعار iOS', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> scheduleMultipleNotifications({
    required String baseId,
    required String title,
    required String body,
    required List<TimeOfDay> notificationTimes,
    String? channelId,
    String? payload,
    Color? color,
    bool repeat = true,
  }) async {
    if (!Platform.isIOS) return false;
    
    try {
      bool allSuccess = true;
      
      for (int i = 0; i < notificationTimes.length; i++) {
        final notificationId = '${baseId}_$i';
        final success = await scheduleNotification(
          notificationId: notificationId,
          title: title,
          body: body,
          notificationTime: notificationTimes[i],
          channelId: channelId,
          payload: payload ?? baseId,
          color: color,
          repeat: repeat,
        );
        
        if (!success) {
          allSuccess = false;
        }
      }
      
      return allSuccess;
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في جدولة إشعارات متعددة', 
        e
      );
      return false;
    }
  }
  
  /// حفظ وقت الإشعار في التخزين المحلي
  Future<void> _saveNotificationTime(String notificationId, TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await prefs.setString('notification_${notificationId}_time', timeString);
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في حفظ وقت الإشعار: $notificationId', 
        e
      );
    }
  }
  
  /// تحديث قائمة الإشعارات المجدولة
  Future<void> _updateScheduledNotificationsList(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      if (!scheduledList.contains(notificationId)) {
        scheduledList.add(notificationId);
        await prefs.setStringList(_keyScheduledNotifications, scheduledList);
      }
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في تحديث قائمة الإشعارات المجدولة', 
        e
      );
    }
  }
  
  @override
  Future<bool> cancelNotification(String notificationId) async {
    if (!Platform.isIOS) return false;
    
    try {
      final id = notificationId.hashCode.abs() % 100000;
      await _flutterLocalNotificationsPlugin.cancel(id);
      
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      if (scheduledList.contains(notificationId)) {
        scheduledList.remove(notificationId);
        await prefs.setStringList(_keyScheduledNotifications, scheduledList);
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في إلغاء الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> cancelAllNotifications() async {
    if (!Platform.isIOS) return false;
    
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyScheduledNotifications, []);
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في إلغاء جميع الإشعارات', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<void> scheduleAllSavedNotifications() async {
    if (!Platform.isIOS) return;
    
    try {
      print('جاري إعادة جدولة جميع الإشعارات المحفوظة...');
      
      final prefs = await SharedPreferences.getInstance();
      
      final bool notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      if (!notificationsEnabled) {
        print('الإشعارات غير مفعلة في الإعدادات');
        return;
      }
      
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      
      for (String notificationId in scheduledList) {
        final timeString = prefs.getString('notification_${notificationId}_time');
        if (timeString != null) {
          final timeParts = timeString.split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            
            if (hour != null && minute != null) {
              // هنا يجب استرجاع معلومات الإشعار الأخرى من التخزين
              // لكننا سنكتفي بإعادة جدولة إشعار بسيط كمثال
              final time = TimeOfDay(hour: hour, minute: minute);
              
              await scheduleNotification(
                notificationId: notificationId,
                title: 'تذكير',
                body: 'حان وقت التذكير',
                notificationTime: time,
                repeat: true,
              );
            }
          }
        }
      }
      
      print('تمت إعادة جدولة الإشعارات المحفوظة');
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في جدولة جميع الإشعارات المحفوظة', 
        e
      );
    }
  }
  
  @override
  Future<bool> isNotificationEnabled(String notificationId) async {
    if (!Platform.isIOS) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> scheduledList = prefs.getStringList(_keyScheduledNotifications) ?? [];
      return scheduledList.contains(notificationId);
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في التحقق من تفعيل الإشعار: $notificationId', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (!Platform.isIOS) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotificationsEnabled, enabled);
      
      if (enabled) {
        await scheduleAllSavedNotifications();
      } else {
        await cancelAllNotifications();
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في تغيير حالة تفعيل الإشعارات', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isIOS) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool localEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
      
      // التحقق من أذونات النظام
      final bool? systemEnabled = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions()
          .then((value) => value?.isEnabled ?? false);
      
      return localEnabled && (systemEnabled ?? false);
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في التحقق من تفعيل الإشعارات', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!Platform.isIOS) return [];
    
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في الحصول على الإشعارات المعلقة', 
        e
      );
      return [];
    }
  }
  
  @override
  Future<void> showSimpleNotification(
    String title,
    String body,
    int id, {
    String? payload,
  }) async {
    if (!Platform.isIOS) return;
    
    try {
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: _config.enableSound,
      );
      
      final notificationDetails = NotificationDetails(iOS: iosDetails);
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في إرسال إشعار بسيط', 
        e
      );
    }
  }
  
  @override
  Future<bool> testImmediateNotification() async {
    if (!Platform.isIOS) return false;
    
    try {
      await showSimpleNotification(
        'اختبار الإشعارات',
        'هذا إشعار اختباري للتأكد من عمل الإشعارات بشكل صحيح',
        9999,
        payload: 'test',
      );
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في إرسال إشعار اختباري', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<bool> sendGroupedTestNotification() async {
    if (!Platform.isIOS) return false;
    
    try {
      for (int i = 0; i <= 3; i++) {
        final iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'test_group',
          subtitle: i == 0 ? 'رسالة رئيسية' : 'إشعار فرعي $i',
        );
        
        final details = NotificationDetails(iOS: iosDetails);
        
        await _flutterLocalNotificationsPlugin.show(
          9000 + i,
          i == 0 ? 'مجموعة إشعارات الاختبار' : 'اختبار إشعار $i',
          i == 0 ? 'اختبار تجميع الإشعارات' : 'هذا إشعار اختباري رقم $i',
          details,
          payload: 'test_notification_$i',
        );
        
        await Future.delayed(Duration(milliseconds: 300));
      }
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في إرسال إشعار اختباري مجمع', 
        e
      );
      return false;
    }
  }
  
  @override
  Future<void> checkNotificationOptimizations(BuildContext context) async {
    if (!Platform.isIOS) return;
    
    // iOS لا يحتاج لفحص تحسينات إضافية مثل Android
    print('لا تحتاج iOS لتحسينات إضافية للإشعارات');
  }
  
  @override
  Future<TimeOfDay?> getNotificationTime(String notificationId) async {
    if (!Platform.isIOS) return null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('notification_${notificationId}_time');
      
      if (timeString != null) {
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          
          if (hour != null && minute != null) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      }
      
      return null;
    } catch (e) {
      _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في الحصول على وقت الإشعار: $notificationId', 
        e
      );
      return null;
    }
  }
}
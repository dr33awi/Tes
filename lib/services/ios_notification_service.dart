// lib/services/ios_notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_athkar_app/screens/athkarscreen/model/athkar_model.dart';
import 'package:test_athkar_app/services/error_logging_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// خدمة للتعامل مع ميزات الإشعارات الخاصة بنظام iOS
class IOSNotificationService {
  // نمط Singleton للتنفيذ
  static final IOSNotificationService _instance = IOSNotificationService._internal();
  factory IOSNotificationService() => _instance;
  
  // التبعية المعكوسة
  final ErrorLoggingService _errorLoggingService = ErrorLoggingService();
  
  // كائن Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // فئات الإشعارات في iOS
  static const String categoryAthkar = 'athkar_category';
  static const String categoryMorning = 'morning_category';
  static const String categoryEvening = 'evening_category';
  static const String categorySleep = 'sleep_category';
  static const String categoryWake = 'wake_category';
  
  // المنشئ الداخلي
  IOSNotificationService._internal();
  
  /// تهيئة إعدادات الإشعارات الخاصة بنظام iOS
  Future<void> initializeIOSNotifications() async {
    if (!Platform.isIOS) return;
    
    try {
      // طلب الأذونات مع خيار الإشعارات الحرجة
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true, // تمكين الإشعارات الحرجة (تجاوز وضع عدم الإزعاج)
          );
      
      print('نتيجة إذن إشعارات iOS: $result');
      
      // إعداد فئات الإشعارات لنظام iOS
      await _setupNotificationCategories();
      
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في تهيئة إشعارات iOS', 
        e
      );
    }
  }
  
  /// إعداد فئات الإشعارات لنظام iOS
  Future<void> _setupNotificationCategories() async {
    if (!Platform.isIOS) return;
    
    try {
      // تعريف فئات الإشعارات
      final List<DarwinNotificationCategory> darwinNotificationCategories = [
        // فئة الأذكار العامة
        DarwinNotificationCategory(
          categoryAthkar,
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
        
        // فئة أذكار الصباح
        DarwinNotificationCategory(
          categoryMorning,
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
        
        // فئة أذكار المساء
        DarwinNotificationCategory(
          categoryEvening,
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
        
        // فئة أذكار النوم
        DarwinNotificationCategory(
          categorySleep,
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
        
        // فئة أذكار الاستيقاظ
        DarwinNotificationCategory(
          categoryWake,
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
      
      await flutterLocalNotificationsPlugin.initialize(
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
        // معالجة إجراء تمييز كمقروء
        // يمكن تحديث عداد أو تمييز الأذكار كمكتملة
        _handleMarkAsRead(payload);
      } else if (actionId == 'SNOOZE' || actionId == 'REMIND_LATER') {
        // معالجة إجراء تأجيل/تذكير لاحقًا
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
    // هذه طريقة ثابتة سيتم استدعاؤها عندما يكون التطبيق في الخلفية
    // يمكننا القيام بمعالجة الحد الأدنى هنا
    print('استجابة الإشعار في الخلفية: ${response.actionId}, ${response.payload}');
  }
  
  /// معالجة إجراء تمييز كمقروء
  Future<void> _handleMarkAsRead(String? payload) async {
    if (payload == null) return;
    
    try {
      // يمكننا تحديث عداد أو تمييز الأذكار كمكتملة في SharedPreferences
      print('تمييز كمقروء: $payload');
      
      // لالآن، فقط إرسال إشعار تأكيد
      await flutterLocalNotificationsPlugin.show(
        10000,
        'تم تسجيل قراءة الأذكار',
        'بارك الله فيك',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            categoryIdentifier: categoryAthkar,
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
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        20000,
        'تذكير: أذكار',
        'حان وقت قراءة الأذكار',
        scheduledDate,
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            categoryIdentifier: categoryAthkar,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      // عرض تأكيد
      await flutterLocalNotificationsPlugin.show(
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
  
  /// إنشاء تفاصيل إشعار iOS محسنة لفئة معينة
  DarwinNotificationDetails createIOSNotificationDetails(AthkarCategory category) {
    // الحصول على معرف الفئة المناسب
    String categoryIdentifier = categoryAthkar;
    
    switch (category.id) {
      case 'morning':
        categoryIdentifier = categoryMorning;
        break;
      case 'evening':
        categoryIdentifier = categoryEvening;
        break;
      case 'sleep':
        categoryIdentifier = categorySleep;
        break;
      case 'wake':
        categoryIdentifier = categoryWake;
        break;
    }
    
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.active, // تجاوز وضع عدم الإزعاج
      categoryIdentifier: categoryIdentifier,
      threadIdentifier: 'athkar_${category.id}', // تجميع حسب الفئة
      attachments: null, // يمكن إضافة مرفقات الصور هنا
      subtitle: category.title, // إضافة عنوان فرعي
    );
  }
  
  /// جدولة إشعار iOS محسن
  Future<bool> scheduleEnhancedNotification(
    AthkarCategory category, 
    TimeOfDay notificationTime, 
    int notificationId
  ) async {
    if (!Platform.isIOS) return false;
    
    try {
      // الحصول على وقت الجدولة
      final tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        tz.TZDateTime.now(tz.local).year,
        tz.TZDateTime.now(tz.local).month,
        tz.TZDateTime.now(tz.local).day,
        notificationTime.hour,
        notificationTime.minute,
      );
      
      // إذا كان الوقت قد مر اليوم، قم بالجدولة للغد
      final tz.TZDateTime adjustedDate = scheduledDate.isBefore(tz.TZDateTime.now(tz.local))
          ? scheduledDate.add(Duration(days: 1))
          : scheduledDate;
      
      // إنشاء تفاصيل إشعار iOS
      final iosDetails = createIOSNotificationDetails(category);
      
      // تعيين محتوى الإشعار
      final String title = category.notifyTitle ?? 'حان موعد ${category.title}';
      final String body = category.notifyBody ?? 'اضغط هنا لقراءة الأذكار';
      
      // جدولة الإشعار
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        adjustedDate,
        NotificationDetails(iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // تكرار يومي
        payload: category.id,
      );
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في جدولة إشعار iOS محسن', 
        e
      );
      return false;
    }
  }
  
  /// إرسال إشعار اختباري بميزات iOS الخاصة
  Future<bool> sendTestNotification() async {
    if (!Platform.isIOS) return false;
    
    try {
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: categoryAthkar,
        subtitle: 'اختبار الإشعارات', // عنوان فرعي لنظام iOS
      );
      
      await flutterLocalNotificationsPlugin.show(
        30000,
        'اختبار إشعارات iOS',
        'هذا اختبار لميزات إشعارات iOS المحسنة. يمكنك استخدام الإجراءات أدناه.',
        NotificationDetails(iOS: iosDetails),
        payload: 'test',
      );
      
      return true;
    } catch (e) {
      await _errorLoggingService.logError(
        'IOSNotificationService', 
        'خطأ في إرسال إشعار اختباري لنظام iOS', 
        e
      );
      return false;
    }
  }
}
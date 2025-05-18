// lib/core/services/utils/notification_scheduler.dart
import 'package:flutter/material.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/interfaces/battery_service.dart';
import '../../../core/services/interfaces/do_not_disturb_service.dart';
import '../../../core/services/interfaces/notification_service.dart';
import '../../../core/services/interfaces/prayer_times_service.dart';
import '../../../core/services/interfaces/timezone_service.dart';
import '../../../domain/entities/settings.dart';

/// مساعد لجدولة الإشعارات المختلفة في التطبيق
class NotificationScheduler {
  final NotificationService _notificationService = getIt<NotificationService>();
  final BatteryService _batteryService = getIt<BatteryService>();
  final DoNotDisturbService _doNotDisturbService = getIt<DoNotDisturbService>();
  final PrayerTimesService _prayerTimesService = getIt<PrayerTimesService>();
  final TimezoneService _timezoneService = getIt<TimezoneService>();
  
  // تخزين معرفات الإشعارات التي تم جدولتها
  final Set<int> _scheduledNotificationIds = {};
  
  /// جدولة جميع الإشعارات بناءً على الإعدادات
  Future<void> scheduleAllNotifications(Settings settings) async {
    if (!settings.enableNotifications) {
      // إلغاء جميع الإشعارات السابقة
      await _notificationService.cancelAllNotifications();
      _scheduledNotificationIds.clear();
      return;
    }
    
    // جدولة إشعارات الأذكار
    if (settings.enableAthkarNotifications) {
      await _scheduleAthkarNotifications(settings);
    } else {
      // إلغاء إشعارات الأذكار فقط
      await _cancelNotificationsByType('athkar');
    }
    
    // جدولة إشعارات مواقيت الصلاة
    if (settings.enablePrayerTimesNotifications) {
      await _schedulePrayerNotifications(settings);
    } else {
      // إلغاء إشعارات مواقيت الصلاة فقط
      await _cancelNotificationsByType('prayer');
    }
  }
  
  /// جدولة إشعارات الأذكار
  Future<void> _scheduleAthkarNotifications(Settings settings) async {
    if (!settings.showAthkarReminders) {
      await _cancelNotificationsByType('athkar');
      return;
    }
    
    await _scheduleMorningAthkarNotification(settings);
    await _scheduleEveningAthkarNotification(settings);
  }
  
  /// جدولة إشعار أذكار الصباح
  Future<void> _scheduleMorningAthkarNotification(Settings settings) async {
    final DateTime now = DateTime.now();
    final int morningHour = settings.morningAthkarTime[0];
    final int morningMinute = settings.morningAthkarTime[1];
    
    DateTime morningTime = DateTime(
      now.year,
      now.month,
      now.day,
      morningHour,
      morningMinute,
    );
    
    // إذا كان الوقت قد فات اليوم، جدولته ليوم غد
    if (morningTime.isBefore(now)) {
      morningTime = morningTime.add(const Duration(days: 1));
    }
    
    // إعداد إجراءات الإشعار
    final List<NotificationAction> morningActions = [
      NotificationAction(
        id: 'read_now',
        title: 'قراءة الآن',
      ),
      NotificationAction(
        id: 'remind_later',
        title: 'تذكير لاحقًا',
      ),
    ];
    
    // payload يحتوي على معلومات عن الإشعار والشاشة المراد فتحها
    final Map<String, dynamic> morningPayload = {
      'type': 'athkar',
      'category': 'morning',
      'route': '/athkar-details',
      'arguments': {
        'categoryId': 'morning',
        'categoryName': 'أذكار الصباح',
      }
    };
    
    final NotificationData morningNotification = NotificationData(
      id: 1001,
      title: 'أذكار الصباح',
      body: 'حان وقت أذكار الصباح، اضغط هنا لقراءة الأذكار',
      scheduledDate: morningTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: NotificationTime.morning,
      priority: settings.enableHighPriorityForPrayers 
          ? NotificationPriority.high 
          : NotificationPriority.normal,
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
      channelId: AppConstants.athkarNotificationChannelId,
      soundName: settings.enableSilentMode ? null : settings.notificationSounds['athkar_morning'],
      payload: morningPayload,
    );
    
    // محاولة جدولة الإشعار مع الإجراءات
    if (settings.enableActionButtons) {
      final scheduled = await _notificationService.scheduleNotificationWithActions(
        morningNotification,
        morningActions,
      );
      
      if (scheduled) {
        _scheduledNotificationIds.add(1001);
      }
    } else {
      final scheduled = await _notificationService.scheduleNotification(morningNotification);
      
      if (scheduled) {
        _scheduledNotificationIds.add(1001);
      }
    }
  }
  
  /// جدولة إشعار أذكار المساء
  Future<void> _scheduleEveningAthkarNotification(Settings settings) async {
    final DateTime now = DateTime.now();
    final int eveningHour = settings.eveningAthkarTime[0];
    final int eveningMinute = settings.eveningAthkarTime[1];
    
    DateTime eveningTime = DateTime(
      now.year,
      now.month,
      now.day,
      eveningHour,
      eveningMinute,
    );
    
    // إذا كان الوقت قد فات اليوم، جدولته ليوم غد
    if (eveningTime.isBefore(now)) {
      eveningTime = eveningTime.add(const Duration(days: 1));
    }
    
    // إعداد إجراءات الإشعار
    final List<NotificationAction> eveningActions = [
      NotificationAction(
        id: 'read_now',
        title: 'قراءة الآن',
      ),
      NotificationAction(
        id: 'remind_later',
        title: 'تذكير لاحقًا',
      ),
    ];
    
    // payload يحتوي على معلومات عن الإشعار والشاشة المراد فتحها
    final Map<String, dynamic> eveningPayload = {
      'type': 'athkar',
      'category': 'evening',
      'route': '/athkar-details',
      'arguments': {
        'categoryId': 'evening',
        'categoryName': 'أذكار المساء',
      }
    };
    
    final NotificationData eveningNotification = NotificationData(
      id: 1002,
      title: 'أذكار المساء',
      body: 'حان وقت أذكار المساء، اضغط هنا لقراءة الأذكار',
      scheduledDate: eveningTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: NotificationTime.evening,
      priority: settings.enableHighPriorityForPrayers 
          ? NotificationPriority.high 
          : NotificationPriority.normal,
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
      channelId: AppConstants.athkarNotificationChannelId,
      soundName: settings.enableSilentMode ? null : settings.notificationSounds['athkar_evening'],
      payload: eveningPayload,
    );
    
    if (settings.enableActionButtons) {
      final scheduled = await _notificationService.scheduleNotificationWithActions(
        eveningNotification,
        eveningActions,
      );
      
      if (scheduled) {
        _scheduledNotificationIds.add(1002);
      }
    } else {
      final scheduled = await _notificationService.scheduleNotification(eveningNotification);
      
      if (scheduled) {
        _scheduledNotificationIds.add(1002);
      }
    }
  }
  
  /// جدولة إشعارات مواقيت الصلاة
  Future<void> _schedulePrayerNotifications(Settings settings) async {
    try {
      // الحصول على موقع المستخدم واستخدامه في الحصول على مواقيت الصلاة
      // ملاحظة: في التطبيق الحقيقي، يجب استخدام موقع المستخدم الفعلي
      const double latitude = 21.422487; // مكة المكرمة
      const double longitude = 39.826206;
      
      // معلمات حساب مواقيت الصلاة
      final params = PrayerTimesCalculationParams(
        calculationMethod: _getCalculationMethodFromSettings(settings.calculationMethod),
        adjustmentMinutes: 0,
        asrMethodIndex: settings.asrMethod,
      );
      
      // الحصول على مواقيت الصلاة لليوم الحالي والأيام القادمة
      await _schedulePrayerTimesForNextDays(settings, latitude, longitude, params, 7);
      
    } catch (e) {
      debugPrint('حدث خطأ أثناء جدولة إشعارات الصلاة: $e');
    }
  }
  
  /// جدولة مواقيت الصلاة لعدة أيام قادمة
  Future<void> _schedulePrayerTimesForNextDays(
    Settings settings,
    double latitude,
    double longitude,
    PrayerTimesCalculationParams params,
    int numberOfDays,
  ) async {
    final DateTime now = DateTime.now();
    
    for (int i = 0; i < numberOfDays; i++) {
      final DateTime date = now.add(Duration(days: i));
      final DateTime dateOnly = DateTime(date.year, date.month, date.day);
      
      final PrayerData prayerTimes = await _prayerTimesService.getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: dateOnly,
        params: params,
      );
      
      // جدولة الإشعارات لهذا اليوم
      await _schedulePrayerTimesForDay(settings, prayerTimes, i);
    }
  }
  
  /// جدولة إشعارات مواقيت الصلاة ليوم معين
  Future<void> _schedulePrayerTimesForDay(
    Settings settings,
    PrayerData prayerTimes,
    int dayOffset,
  ) async {
    // قائمة بالصلوات لجدولة إشعاراتها
    final prayerInfo = [
      {
        'prayer': 'الفجر', 
        'time': prayerTimes.fajr, 
        'id': 2001 + (dayOffset * 100), 
        'reminder_id': 2101 + (dayOffset * 100),
        'notification_time': NotificationTime.fajr,
      },
      {
        'prayer': 'الظهر', 
        'time': prayerTimes.dhuhr, 
        'id': 2002 + (dayOffset * 100), 
        'reminder_id': 2102 + (dayOffset * 100),
        'notification_time': NotificationTime.dhuhr,
      },
      {
        'prayer': 'العصر', 
        'time': prayerTimes.asr, 
        'id': 2003 + (dayOffset * 100), 
        'reminder_id': 2103 + (dayOffset * 100),
        'notification_time': NotificationTime.asr,
      },
      {
        'prayer': 'المغرب', 
        'time': prayerTimes.maghrib, 
        'id': 2004 + (dayOffset * 100), 
        'reminder_id': 2104 + (dayOffset * 100),
        'notification_time': NotificationTime.maghrib,
      },
      {
        'prayer': 'العشاء', 
        'time': prayerTimes.isha, 
        'id': 2005 + (dayOffset * 100), 
        'reminder_id': 2105 + (dayOffset * 100),
        'notification_time': NotificationTime.isha,
      },
    ];
    
    // جدولة إشعارات لكل صلاة
    for (final prayer in prayerInfo) {
      await _schedulePrayerNotification(
        prayer['time'] as DateTime,
        prayer['prayer'] as String,
        prayer['id'] as int,
        prayer['notification_time'] as NotificationTime,
        prayer['reminder_id'] as int,
        settings,
        dayOffset,
      );
    }
  }
  
  /// جدولة إشعار لصلاة محددة
  Future<void> _schedulePrayerNotification(
    DateTime prayerTime,
    String prayerName,
    int id,
    NotificationTime notificationTime,
    int reminderId,
    Settings settings,
    int dayOffset,
  ) async {
    final DateTime now = DateTime.now();
    
    // تجاهل الصلوات التي مرت بالفعل في هذا اليوم
    if (dayOffset == 0 && prayerTime.isBefore(now)) {
      return;
    }
    
    // تعيين تذكير قبل وقت الصلاة بـ الوقت المحدد في الإعدادات
    final reminderMinutes = AppConstants.prayerNotificationAdvanceMinutes;
    final DateTime reminderTime = prayerTime.subtract(Duration(minutes: reminderMinutes));
    
    // تجاهل التذكيرات التي مرت بالفعل
    if (reminderTime.isBefore(now)) {
      return;
    }
    
    // إعداد إجراءات الإشعار
    final List<NotificationAction> prayerActions = [
      NotificationAction(
        id: 'view_prayer_times',
        title: 'عرض المواقيت',
      ),
      NotificationAction(
        id: 'dismiss',
        title: 'إغلاق',
        cancelNotification: true,
      ),
    ];
    
    // payload يحتوي على معلومات عن الإشعار والشاشة المراد فتحها
    final Map<String, dynamic> prayerPayload = {
      'type': 'prayer',
      'prayer_name': prayerName,
      'route': '/prayer-times',
    };
    
    // جدولة تذكير قبل الصلاة
    final NotificationData reminderNotification = NotificationData(
      id: reminderId,
      title: 'تذكير: صلاة $prayerName',
      body: 'سيحين وقت صلاة $prayerName بعد $reminderMinutes دقيقة',
      scheduledDate: reminderTime,
      notificationTime: notificationTime,
      priority: settings.enableHighPriorityForPrayers
          ? NotificationPriority.high
          : NotificationPriority.normal,
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: false, // دائماً إظهار تذكير الصلاة حتى في وضع عدم الإزعاج
      channelId: AppConstants.prayerTimesNotificationChannelId,
      soundName: settings.enableSilentMode ? null : settings.notificationSounds['prayer'],
      payload: prayerPayload,
    );
    
    final scheduledReminder = await _notificationService.scheduleNotification(reminderNotification);
    if (scheduledReminder) {
      _scheduledNotificationIds.add(reminderId);
    }
    
    // جدولة إشعار وقت الصلاة
    final NotificationData prayerNotification = NotificationData(
      id: id,
      title: 'صلاة $prayerName',
      body: 'حان وقت صلاة $prayerName',
      scheduledDate: prayerTime,
      notificationTime: notificationTime,
      priority: settings.enableHighPriorityForPrayers
          ? NotificationPriority.high
          : NotificationPriority.normal,
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: false, // دائماً إظهار إشعار الصلاة حتى في وضع عدم الإزعاج
      channelId: AppConstants.prayerTimesNotificationChannelId,
      soundName: settings.enableSilentMode ? null : settings.notificationSounds['prayer'],
      payload: prayerPayload,
    );
    
    if (settings.enableActionButtons) {
      final scheduledPrayer = await _notificationService.scheduleNotificationWithActions(
        prayerNotification,
        prayerActions,
      );
      
      if (scheduledPrayer) {
        _scheduledNotificationIds.add(id);
      }
    } else {
      final scheduledPrayer = await _notificationService.scheduleNotification(prayerNotification);
      
      if (scheduledPrayer) {
        _scheduledNotificationIds.add(id);
      }
    }
  }
  
  /// إلغاء الإشعارات حسب النوع
  Future<void> _cancelNotificationsByType(String type) async {
    await _notificationService.cancelNotificationsByTag(type);
  }
  
  /// تحويل رقم طريقة الحساب إلى اسم الطريقة المناسب
  String _getCalculationMethodFromSettings(int methodIndex) {
    switch (methodIndex) {
      case 0:
        return 'karachi';
      case 1:
        return 'north_america';
      case 2:
        return 'muslim_world_league';
      case 3:
        return 'egyptian';
      case 4:
        return 'umm_al_qura';
      case 5:
        return 'dubai';
      case 6:
        return 'qatar';
      case 7:
        return 'kuwait';
      case 8:
        return 'singapore';
      case 9:
        return 'turkey';
      case 10:
        return 'tehran';
      default:
        return 'muslim_world_league';
    }
  }
  
  /// التحقق من حالة الإشعارات
  Future<Map<String, dynamic>> getNotificationStatus() async {
    final bool canSendNow = await _notificationService.canSendNotificationsNow();
    final bool hasPermission = await _notificationService.requestPermission();
    final bool batteryOptimizationEnabled = await _batteryService.isPowerSaveMode();
    final bool dndEnabled = await _doNotDisturbService.isDoNotDisturbEnabled();
    
    return {
      'can_send_now': canSendNow,
      'has_permission': hasPermission,
      'battery_optimization_enabled': batteryOptimizationEnabled,
      'dnd_enabled': dndEnabled,
      'scheduled_notifications_count': _scheduledNotificationIds.length,
    };
  }
  
  /// إعادة جدولة جميع الإشعارات
  Future<void> rescheduleAllNotifications(Settings settings) async {
    await _notificationService.cancelAllNotifications();
    _scheduledNotificationIds.clear();
    await scheduleAllNotifications(settings);
  }
}
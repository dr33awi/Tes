// lib/core/utils/notification_scheduler.dart
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/core/services/interfaces/battery_service.dart';
import 'package:athkar_app/core/services/interfaces/do_not_disturb_service.dart';
import 'package:athkar_app/core/services/interfaces/notification_service.dart';
import 'package:athkar_app/core/services/interfaces/prayer_times_service.dart';
import 'package:athkar_app/domain/entities/settings.dart';
import 'package:flutter/material.dart';
/// مساعد لجدولة الإشعارات المختلفة في التطبيق
class NotificationScheduler {
  final NotificationService _notificationService = getIt<NotificationService>();
  final BatteryService _batteryService = getIt<BatteryService>();
  final DoNotDisturbService _doNotDisturbService = getIt<DoNotDisturbService>();
  final PrayerTimesService _prayerTimesService = getIt<PrayerTimesService>();
  
  /// جدولة جميع الإشعارات بناءً على الإعدادات
  Future<void> scheduleAllNotifications(Settings settings) async {
    if (!settings.enableNotifications) return;
    
    // إلغاء جميع الإشعارات السابقة
    await _notificationService.cancelAllNotifications();
    
    // جدولة إشعارات الأذكار
    if (settings.enableAthkarNotifications) {
      await _scheduleAthkarNotifications(settings);
    }
    
    // جدولة إشعارات مواقيت الصلاة
    if (settings.enablePrayerTimesNotifications) {
      await _schedulePrayerNotifications(settings);
    }
  }
  
  /// جدولة إشعارات الأذكار
  Future<void> _scheduleAthkarNotifications(Settings settings) async {
    if (!settings.showAthkarReminders) return;
    
    // إشعار أذكار الصباح
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
    
    final NotificationData morningNotification = NotificationData(
      id: 1001,
      title: 'أذكار الصباح',
      body: 'حان وقت أذكار الصباح، اضغط هنا لقراءة الأذكار',
      scheduledDate: morningTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: NotificationTime.morning,
      priority: NotificationPriority.normal,
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
    );
    
    await _notificationService.scheduleRepeatingNotification(morningNotification);
    
    // إشعار أذكار المساء
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
    
    final NotificationData eveningNotification = NotificationData(
      id: 1002,
      title: 'أذكار المساء',
      body: 'حان وقت أذكار المساء، اضغط هنا لقراءة الأذكار',
      scheduledDate: eveningTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: NotificationTime.evening,
      priority: NotificationPriority.normal,
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: settings.respectDoNotDisturb,
    );
    
    await _notificationService.scheduleRepeatingNotification(eveningNotification);
  }
  
  /// جدولة إشعارات مواقيت الصلاة
  Future<void> _schedulePrayerNotifications(Settings settings) async {
    // الحصول على مواقيت الصلاة لليوم الحالي
    final DateTime now = DateTime.now();
    
    // معلمات حساب مواقيت الصلاة
    final params = PrayerTimesCalculationParams(
      calculationMethod: _getCalculationMethodFromSettings(settings.calculationMethod),
      adjustmentMinutes: 0,
    );
    
    try {
      // الحصول على موقع المستخدم واستخدامه في الحصول على مواقيت الصلاة
      // ملاحظة: في التطبيق الحقيقي، يجب استخدام موقع المستخدم الفعلي
      const double latitude = 21.422487; // مكة المكرمة
      const double longitude = 39.826206;
      
      final PrayerData prayerTimes = await _prayerTimesService.getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: now,
        params: params,
      );
      
      // جدولة إشعارات لكل صلاة
      await _schedulePrayerNotification(
        prayerTimes.fajr,
        'الفجر',
        'حان وقت صلاة الفجر',
        2001,
        NotificationTime.fajr,
        settings,
      );
      
      await _schedulePrayerNotification(
        prayerTimes.dhuhr,
        'الظهر',
        'حان وقت صلاة الظهر',
        2002,
        NotificationTime.dhuhr,
        settings,
      );
      
      await _schedulePrayerNotification(
        prayerTimes.asr,
        'العصر',
        'حان وقت صلاة العصر',
        2003,
        NotificationTime.asr,
        settings,
      );
      
      await _schedulePrayerNotification(
        prayerTimes.maghrib,
        'المغرب',
        'حان وقت صلاة المغرب',
        2004,
        NotificationTime.maghrib,
        settings,
      );
      
      await _schedulePrayerNotification(
        prayerTimes.isha,
        'العشاء',
        'حان وقت صلاة العشاء',
        2005,
        NotificationTime.isha,
        settings,
      );
    } catch (e) {
      debugPrint('حدث خطأ أثناء جدولة إشعارات الصلاة: $e');
    }
  }
  
  /// جدولة إشعار لصلاة محددة
  Future<void> _schedulePrayerNotification(
    DateTime prayerTime,
    String prayerName,
    String body,
    int id,
    NotificationTime notificationTime,
    Settings settings,
  ) async {
    // التحقق مما إذا كان وقت الصلاة قد فات
    final DateTime now = DateTime.now();
    DateTime scheduledTime = prayerTime;
    
    // إذا كان وقت الصلاة قد فات اليوم، جدولته ليوم غد
    if (scheduledTime.isBefore(now)) {
      scheduledTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        scheduledTime.hour,
        scheduledTime.minute,
      );
    }
    
    // تعيين تذكير قبل وقت الصلاة بـ 15 دقيقة
    final DateTime reminderTime = scheduledTime.subtract(const Duration(minutes: 15));
    
    // جدولة تذكير قبل الصلاة
    if (reminderTime.isAfter(now)) {
      final NotificationData reminderNotification = NotificationData(
        id: id + 100, // معرف مختلف للتذكير
        title: 'تذكير: صلاة $prayerName',
        body: 'سيحين وقت صلاة $prayerName بعد 15 دقيقة',
        scheduledDate: reminderTime,
        notificationTime: notificationTime,
        priority: settings.enableHighPriorityForPrayers
            ? NotificationPriority.high
            : NotificationPriority.normal,
        respectBatteryOptimizations: settings.respectBatteryOptimizations,
        respectDoNotDisturb: false, // دائماً إظهار تذكير الصلاة حتى في وضع عدم الإزعاج
      );
      
      await _notificationService.scheduleNotification(reminderNotification);
    }
    
    // جدولة إشعار وقت الصلاة
    final NotificationData prayerNotification = NotificationData(
      id: id,
      title: 'صلاة $prayerName',
      body: body,
      scheduledDate: scheduledTime,
      repeatInterval: NotificationRepeatInterval.daily,
      notificationTime: notificationTime,
      priority: settings.enableHighPriorityForPrayers
          ? NotificationPriority.high
          : NotificationPriority.normal,
      respectBatteryOptimizations: settings.respectBatteryOptimizations,
      respectDoNotDisturb: false, // دائماً إظهار إشعار الصلاة حتى في وضع عدم الإزعاج
    );
    
    await _notificationService.scheduleRepeatingNotification(prayerNotification);
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
}
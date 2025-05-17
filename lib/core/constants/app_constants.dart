// lib/core/constants/app_constants.dart
class AppConstants {
  // معلومات التطبيق
  static const String appName = 'تطبيق الأذكار';
  static const String appVersion = '1.0.0';
  
  // اللغة الافتراضية
  static const String defaultLanguage = 'ar';
  
  // مفاتيح التخزين
  static const String settingsKey = 'app_settings';
  static const String lastLocationKey = 'last_location';
  static const String notificationsKey = 'notifications_data';
  
  // فئات الأذكار
  static const String morningAthkarCategory = 'morning';
  static const String eveningAthkarCategory = 'evening';
  static const String sleepAthkarCategory = 'sleep';
  static const String wakeupAthkarCategory = 'wakeup';
  static const String prayerAthkarCategory = 'prayer';
  
  // أوقات الإشعارات الافتراضية
  static const int defaultMorningAthkarHour = 5; // 5 صباحًا
  static const int defaultMorningAthkarMinute = 0;
  static const int defaultEveningAthkarHour = 17; // 5 مساءً
  static const int defaultEveningAthkarMinute = 0;
  static const int defaultSleepAthkarHour = 22; // 10 مساءً
  static const int defaultSleepAthkarMinute = 0;
  
  // معرفات قنوات الإشعارات
  static const String athkarNotificationChannelId = 'athkar_notification_channel';
  static const String prayerTimesNotificationChannelId = 'prayer_times_notification_channel';
  
  // فترات التنبيه قبل الصلاة (بالدقائق)
  static const int prayerNotificationAdvanceMinutes = 15;
}
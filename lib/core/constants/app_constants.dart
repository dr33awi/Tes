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
  static const String athkarNotificationChannelId = 'athkar_channel';
  static const String prayerTimesNotificationChannelId = 'prayer_channel';
  
  // فترات التنبيه قبل الصلاة (بالدقائق)
  static const int prayerNotificationAdvanceMinutes = 15;
  
  // معرفات الإشعارات
  // - إشعارات الأذكار: 1001-1999
  static const int morningAthkarNotificationId = 1001;
  static const int eveningAthkarNotificationId = 1002;
  static const int sleepAthkarNotificationId = 1003;
  
  // - إشعارات الصلوات: 2001-2999 (اليوم الأول)
  // -- الفجر: 2001
  // -- الظهر: 2002
  // -- العصر: 2003
  // -- المغرب: 2004
  // -- العشاء: 2005
  
  // - تذكيرات الصلوات: 2101-2999 (اليوم الأول)
  // -- تذكير الفجر: 2101
  // -- تذكير الظهر: 2102
  // -- تذكير العصر: 2103
  // -- تذكير المغرب: 2104
  // -- تذكير العشاء: 2105
  
  // - إشعارات الصلوات لليوم الثاني: 2101-2999
  // إلخ...
}
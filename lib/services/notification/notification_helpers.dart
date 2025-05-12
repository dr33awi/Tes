// lib/services/notification_helpers.dart
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

/// دوال مساعدة مشتركة للإشعارات
class NotificationHelpers {
  
  /// الحصول على لون الفئة بناءً على المعرف
  static Color getCategoryColor(String categoryId) {
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
      case 'home':
        return const Color(0xFF66BB6A); // أخضر
      case 'food':
        return const Color(0xFFE57373); // أحمر
      case 'quran':
        return const Color(0xFF9575CD); // بنفسجي فاتح
      default:
        return const Color(0xFF447055); // اللون الافتراضي للتطبيق
    }
  }
  
  /// الحصول على أيقونة الفئة بناءً على المعرف
  static IconData getCategoryIcon(String categoryId) {
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
      case 'home':
        return Icons.home;
      case 'food':
        return Icons.restaurant;
      case 'quran':
        return Icons.menu_book;
      default:
        return Icons.notifications;
    }
  }
  
  /// الحصول على عنوان الفئة بناءً على المعرف
  static String getCategoryTitle(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return 'أذكار الصباح';
      case 'evening':
        return 'أذكار المساء';
      case 'sleep':
        return 'أذكار النوم';
      case 'wake':
        return 'أذكار الاستيقاظ';
      case 'prayer':
        return 'أذكار الصلاة';
      case 'home':
        return 'أذكار المنزل';
      case 'food':
        return 'أذكار الطعام';
      case 'quran':
        return 'تلاوة القرآن';
      default:
        return 'أذكار';
    }
  }
  
  /// الحصول على مفتاح المجموعة للفئة
  static String getGroupKeyForCategory(String categoryId) {
    switch (categoryId) {
      case 'morning':
        return 'morning_athkar_group';
      case 'evening':
        return 'evening_athkar_group';
      case 'sleep':
        return 'sleep_athkar_group';
      case 'wake':
        return 'wake_athkar_group';
      case 'prayer':
        return 'prayer_athkar_group';
      case 'home':
        return 'home_athkar_group';
      case 'food':
        return 'food_athkar_group';
      case 'quran':
        return 'quran_group';
      default:
        return 'athkar_group';
    }
  }
  
  /// الحصول على الوقت التالي لجدولة الإشعار
  static tz.TZDateTime getNextInstanceOfTime(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    
    // إذا كان الوقت قد مر اليوم، جدولة ليوم غد
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  /// تحديد قناة الإشعار بناءً على الفئة
  static String getNotificationChannel(String categoryId) {
    switch (categoryId) {
      case 'prayer':
        return 'prayer_channel';
      case 'quran':
        return 'quran_channel';
      default:
        return 'athkar_channel';
    }
  }
  
  /// الحصول على أولوية الإشعار بناءً على الفئة
  static int getNotificationPriority(String categoryId) {
    switch (categoryId) {
      case 'prayer':
        return 5; // أقصى أولوية للصلاة
      case 'morning':
      case 'evening':
        return 4; // أولوية عالية لأذكار الصباح والمساء
      default:
        return 3; // أولوية متوسطة للبقية
    }
  }
  
  /// تحديد هل يجب تفعيل الصوت للفئة
  static bool shouldEnableSound(String categoryId) {
    switch (categoryId) {
      case 'prayer':
        return true; // دائماً صوت للصلاة
      case 'sleep':
        return false; // لا صوت لأذكار النوم
      default:
        return true;
    }
  }
  
  /// تحديد هل يجب تفعيل الاهتزاز للفئة
  static bool shouldEnableVibration(String categoryId) {
    switch (categoryId) {
      case 'sleep':
        return false; // لا اهتزاز لأذكار النوم
      default:
        return true;
    }
  }
}
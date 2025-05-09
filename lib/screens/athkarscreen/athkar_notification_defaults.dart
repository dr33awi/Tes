// lib/services/athkar_notification_defaults.dart
import 'package:flutter/material.dart';

/// Provides default values for Athkar notifications
class AthkarNotificationDefaults {
  // Default notification times for each Athkar category
  static Map<String, TimeOfDay> defaultNotificationTimes = {
    'morning': const TimeOfDay(hour: 6, minute: 0),    // 6:00 AM
    'evening': const TimeOfDay(hour: 16, minute: 0),   // 4:00 PM
    'sleep': const TimeOfDay(hour: 22, minute: 0),     // 10:00 PM
    'wake': const TimeOfDay(hour: 5, minute: 30),      // 5:30 AM
    'prayer': const TimeOfDay(hour: 13, minute: 0),    // 1:00 PM
    'home': const TimeOfDay(hour: 18, minute: 0),      // 6:00 PM
    'food': const TimeOfDay(hour: 12, minute: 0),      // 12:00 PM
    'quran': const TimeOfDay(hour: 20, minute: 0),     // 8:00 PM
  };
  
  // Default notification titles for each Athkar category
  static Map<String, String> defaultNotificationTitles = {
    'morning': 'أذكار الصباح',
    'evening': 'أذكار المساء',
    'sleep': 'أذكار النوم',
    'wake': 'أذكار الاستيقاظ',
    'prayer': 'أذكار الصلاة',
    'home': 'أذكار المنزل',
    'food': 'أذكار الطعام',
    'quran': 'أدعية قرآنية',
  };
  
  // Default notification messages for each Athkar category
  static Map<String, String> defaultNotificationMessages = {
    'morning': 'حان الآن وقت أذكار الصباح. اضغط لقراءة الأذكار وبدء يومك بذكر الله',
    'evening': 'حان الآن وقت أذكار المساء. اضغط هنا لقراءة الأذكار',
    'sleep': 'تذكير بأذكار النوم قبل أن تخلد للراحة',
    'wake': 'تذكير بأذكار الاستيقاظ من النوم',
    'prayer': 'تذكير بأذكار ما بعد الصلاة',
    'home': 'تذكير بأذكار المنزل',
    'food': 'تذكير بأذكار الطعام',
    'quran': 'تذكير بالأدعية القرآنية',
  };
  
  // Default notification sounds for each Athkar category
  static Map<String, String> defaultNotificationSounds = {
    'morning': 'short_azan',
    'evening': 'short_azan',
    'sleep': 'dua',
    'wake': 'short_azan',
    'prayer': 'dua',
    'home': 'birds',
    'food': 'reminder',
    'quran': 'quran',
  };
  
  /// Get the default notification time for a specific category
  static TimeOfDay getDefaultTimeForCategory(String categoryId) {
    return defaultNotificationTimes[categoryId] ?? const TimeOfDay(hour: 8, minute: 0);
  }
  
  /// Get the default notification title for a specific category
  static String getDefaultTitleForCategory(String categoryId) {
    return defaultNotificationTitles[categoryId] ?? 'تذكير بالأذكار';
  }
  
  /// Get the default notification message for a specific category
  static String getDefaultMessageForCategory(String categoryId) {
    return defaultNotificationMessages[categoryId] ?? 'حان وقت الأذكار. اضغط هنا للقراءة';
  }
  
  /// Get the default notification sound for a specific category
  static String getDefaultSoundForCategory(String categoryId) {
    return defaultNotificationSounds[categoryId] ?? 'default';
  }
}
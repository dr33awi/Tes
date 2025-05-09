import 'package:flutter/material.dart';

class AthkarCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String? description;
  final List<Thikr> athkar;
  
  // تحسين نظام الإشعارات
  final String? notifyTime; // الوقت الافتراضي للإشعارات (بصيغة "HH:MM")
  final String? notifySound; // إضافة خيار الصوت المخصص لكل فئة
  final String? notifyTitle; // عنوان الإشعار المخصص
  final String? notifyBody; // نص الإشعار المخصص
  final bool hasMultipleReminders; // إمكانية تعيين تذكيرات متعددة
  final List<String>? additionalNotifyTimes; // أوقات إشعارات إضافية

  AthkarCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.description,
    required this.athkar,
    this.notifyTime,
    this.notifySound,
    this.notifyTitle,
    this.notifyBody,
    this.hasMultipleReminders = false,
    this.additionalNotifyTimes,
  });

  // Factory constructor to create a category from JSON data
  factory AthkarCategory.fromJson(Map<String, dynamic> json, IconData icon, Color color) {
    List<Thikr> athkarList = [];
    
    if (json['athkar'] != null) {
      for (var thikrData in json['athkar']) {
        athkarList.add(Thikr.fromJson(thikrData));
      }
    }
    
    return AthkarCategory(
      id: json['id'],
      title: json['title'],
      icon: icon,
      color: color,
      description: json['description'],
      athkar: athkarList,
      notifyTime: json['notify_time'],
      notifySound: json['notify_sound'],
      notifyTitle: json['notify_title'],
      notifyBody: json['notify_body'],
      hasMultipleReminders: json['has_multiple_reminders'] ?? false,
      additionalNotifyTimes: json['additional_notify_times'] != null
          ? List<String>.from(json['additional_notify_times'])
          : null,
    );
  }

  // تحويل الفئة إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': _iconToString(icon),
      'color': _colorToHex(color),
      'description': description,
      'athkar': athkar.map((thikr) => thikr.toJson()).toList(),
      'notify_time': notifyTime,
      'notify_sound': notifySound,
      'notify_title': notifyTitle,
      'notify_body': notifyBody,
      'has_multiple_reminders': hasMultipleReminders,
      'additional_notify_times': additionalNotifyTimes,
    };
  }
  
  // Helper method to convert IconData to string
  String _iconToString(IconData icon) {
    if (icon == Icons.wb_sunny) return 'Icons.wb_sunny';
    if (icon == Icons.nightlight_round) return 'Icons.nightlight_round';
    if (icon == Icons.bedtime) return 'Icons.bedtime';
    if (icon == Icons.alarm) return 'Icons.alarm';
    if (icon == Icons.mosque) return 'Icons.mosque';
    if (icon == Icons.home) return 'Icons.home';
    if (icon == Icons.restaurant) return 'Icons.restaurant';
    if (icon == Icons.menu_book) return 'Icons.menu_book';
    return 'Icons.label_important';
  }
  
  // Helper method to convert Color to hex string
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  // إنشاء نسخة جديدة من الفئة مع تعديل بعض الخصائص
  AthkarCategory copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    String? description,
    List<Thikr>? athkar,
    String? notifyTime,
    String? notifySound,
    String? notifyTitle,
    String? notifyBody,
    bool? hasMultipleReminders,
    List<String>? additionalNotifyTimes,
  }) {
    return AthkarCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      athkar: athkar ?? this.athkar,
      notifyTime: notifyTime ?? this.notifyTime,
      notifySound: notifySound ?? this.notifySound,
      notifyTitle: notifyTitle ?? this.notifyTitle,
      notifyBody: notifyBody ?? this.notifyBody,
      hasMultipleReminders: hasMultipleReminders ?? this.hasMultipleReminders,
      additionalNotifyTimes: additionalNotifyTimes ?? this.additionalNotifyTimes,
    );
  }
}

class Thikr {
  final int id;
  final String text;
  final int count;
  final String? fadl;
  final String? source;
  // إضافة حقول جديدة
  final bool isQuranVerse; // هل هذا الذكر آية قرآنية؟
  final String? surahName; // اسم السورة إذا كان آية قرآنية
  final String? verseNumbers; // أرقام الآيات إذا كان آية قرآنية
  final String? audioUrl; // رابط ملف صوتي للذكر (إن وجد)

  Thikr({
    required this.id,
    required this.text,
    required this.count,
    this.fadl,
    this.source,
    this.isQuranVerse = false,
    this.surahName,
    this.verseNumbers,
    this.audioUrl,
  });
  
  // Factory constructor to create a thikr from JSON data
  factory Thikr.fromJson(Map<String, dynamic> json) {
    return Thikr(
      id: json['id'],
      text: json['text'],
      count: json['count'],
      fadl: json['fadl'],
      source: json['source'],
      isQuranVerse: json['is_quran_verse'] ?? false,
      surahName: json['surah_name'],
      verseNumbers: json['verse_numbers'],
      audioUrl: json['audio_url'],
    );
  }
  
  // تحويل الذكر إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
      'fadl': fadl,
      'source': source,
      'is_quran_verse': isQuranVerse,
      'surah_name': surahName,
      'verse_numbers': verseNumbers,
      'audio_url': audioUrl,
    };
  }
  
  // إنشاء نسخة جديدة من الذكر مع تعديل بعض الخصائص
  Thikr copyWith({
    int? id,
    String? text,
    int? count,
    String? fadl,
    String? source,
    bool? isQuranVerse,
    String? surahName,
    String? verseNumbers,
    String? audioUrl,
  }) {
    return Thikr(
      id: id ?? this.id,
      text: text ?? this.text,
      count: count ?? this.count,
      fadl: fadl ?? this.fadl,
      source: source ?? this.source,
      isQuranVerse: isQuranVerse ?? this.isQuranVerse,
      surahName: surahName ?? this.surahName,
      verseNumbers: verseNumbers ?? this.verseNumbers,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

// نموذج لإعدادات الإشعارات
class NotificationSettings {
  final bool isEnabled;
  final String? customTime;
  final String? customSound;
  final bool vibrate;
  final bool showLed;
  final Color? ledColor;
  final int? importance; // أهمية الإشعار (0-5)

  NotificationSettings({
    this.isEnabled = true,
    this.customTime,
    this.customSound,
    this.vibrate = true,
    this.showLed = true,
    this.ledColor,
    this.importance = 4, // High importance by default
  });
  
  // Factory constructor to create settings from JSON data
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      isEnabled: json['is_enabled'] ?? true,
      customTime: json['custom_time'],
      customSound: json['custom_sound'],
      vibrate: json['vibrate'] ?? true,
      showLed: json['show_led'] ?? true,
      ledColor: json['led_color'] != null ? Color(int.parse(json['led_color'])) : null,
      importance: json['importance'] ?? 4,
    );
  }
  
  // تحويل الإعدادات إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'custom_time': customTime,
      'custom_sound': customSound,
      'vibrate': vibrate,
      'show_led': showLed,
      'led_color': ledColor?.value.toString(),
      'importance': importance,
    };
  }
  
  // إنشاء نسخة جديدة من الإعدادات مع تعديل بعض الخصائص
  NotificationSettings copyWith({
    bool? isEnabled,
    String? customTime,
    String? customSound,
    bool? vibrate,
    bool? showLed,
    Color? ledColor,
    int? importance,
  }) {
    return NotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      customTime: customTime ?? this.customTime,
      customSound: customSound ?? this.customSound,
      vibrate: vibrate ?? this.vibrate,
      showLed: showLed ?? this.showLed,
      ledColor: ledColor ?? this.ledColor,
      importance: importance ?? this.importance,
    );
  }
}
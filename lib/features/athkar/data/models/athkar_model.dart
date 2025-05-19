// lib/features/athkar/data/models/athkar_model.dart
import 'package:flutter/material.dart';
import '../../domain/entities/athkar.dart';
import '../utils/icon_helper.dart'; // سنقوم بإنشاء هذا الملف لاحقًا

// نموذج لفئة الأذكار مع دعم التحويل من JSON وإلى JSON
class AthkarCategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String? description;
  final List<ThikrModel> athkar;
  
  // إعدادات الإشعارات
  final String? notifyTime;
  final String? notifyTitle;
  final String? notifyBody;
  final bool hasMultipleReminders;
  final List<String>? additionalNotifyTimes;

  AthkarCategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.description,
    required this.athkar,
    this.notifyTime,
    this.notifyTitle,
    this.notifyBody,
    this.hasMultipleReminders = false,
    this.additionalNotifyTimes,
  });

  // من JSON إلى موديل
  factory AthkarCategoryModel.fromJson(Map<String, dynamic> json) {
    // تحويل IconData من النص
    IconData icon = IconHelper.getIconFromString(json['icon'] as String? ?? 'Icons.label_important');
    
    // تحويل اللون من النص
    Color color = IconHelper.getColorFromHex(json['color'] as String? ?? '#447055');
    
    List<ThikrModel> athkarList = [];
    
    if (json['athkar'] != null) {
      for (var thikrData in json['athkar']) {
        athkarList.add(ThikrModel.fromJson(thikrData));
      }
    }
    
    return AthkarCategoryModel(
      id: json['id'],
      title: json['title'],
      icon: icon,
      color: color,
      description: json['description'],
      athkar: athkarList,
      notifyTime: json['notify_time'],
      notifyTitle: json['notify_title'],
      notifyBody: json['notify_body'],
      hasMultipleReminders: json['has_multiple_reminders'] ?? false,
      additionalNotifyTimes: json['additional_notify_times'] != null
          ? List<String>.from(json['additional_notify_times'])
          : null,
    );
  }

  // تحويل الموديل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': IconHelper.iconToString(icon),
      'color': IconHelper.colorToHex(color),
      'description': description,
      'athkar': athkar.map((thikr) => thikr.toJson()).toList(),
      'notify_time': notifyTime,
      'notify_title': notifyTitle,
      'notify_body': notifyBody,
      'has_multiple_reminders': hasMultipleReminders,
      'additional_notify_times': additionalNotifyTimes,
    };
  }
  
  // تحويل النموذج إلى كيان
  AthkarCategory toEntity() {
    return AthkarCategory(
      id: id,
      name: title,
      description: description ?? '',
      icon: IconHelper.iconToString(icon),
    );
  }
  
  // اختصار نسخة معدلة
  AthkarCategoryModel copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    String? description,
    List<ThikrModel>? athkar,
    String? notifyTime,
    String? notifyTitle,
    String? notifyBody,
    bool? hasMultipleReminders,
    List<String>? additionalNotifyTimes,
  }) {
    return AthkarCategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      athkar: athkar ?? this.athkar,
      notifyTime: notifyTime ?? this.notifyTime,
      notifyTitle: notifyTitle ?? this.notifyTitle,
      notifyBody: notifyBody ?? this.notifyBody,
      hasMultipleReminders: hasMultipleReminders ?? this.hasMultipleReminders,
      additionalNotifyTimes: additionalNotifyTimes ?? this.additionalNotifyTimes,
    );
  }
}

// نموذج للذكر الواحد
class ThikrModel {
  final int id;
  final String text;
  final int count;
  final String? fadl;
  final String? source;
  final bool isQuranVerse;
  final String? surahName;
  final String? verseNumbers;
  final String? audioUrl;

  ThikrModel({
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
  
  // من JSON إلى نموذج
  factory ThikrModel.fromJson(Map<String, dynamic> json) {
    return ThikrModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      text: json['text'] ?? json['content'] ?? '', // دعم اسمين مختلفين
      count: json['count'] ?? 1,
      fadl: json['fadl'],
      source: json['source'],
      isQuranVerse: json['is_quran_verse'] ?? false,
      surahName: json['surah_name'],
      verseNumbers: json['verse_numbers'],
      audioUrl: json['audio_url'],
    );
  }
  
  // تحويل النموذج إلى JSON
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
  
  // تحويل النموذج إلى كيان
  Athkar toEntity() {
    return Athkar(
      id: id.toString(),
      title: surahName ?? 'ذكر',
      content: text,
      count: count,
      categoryId: '', // سيتم تعيينه لاحقًا
      source: source,
      notes: null,
      fadl: fadl,
    );
  }
  
  // اختصار نسخة معدلة
  ThikrModel copyWith({
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
    return ThikrModel(
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

// نموذج إعدادات الإشعارات
class AthkarNotificationSettings {
  final bool isEnabled;
  final String? customTime;
  final bool vibrate;
  final int? importance;

  AthkarNotificationSettings({
    this.isEnabled = true,
    this.customTime,
    this.vibrate = true,
    this.importance = 4,
  });
  
  // من JSON إلى نموذج
  factory AthkarNotificationSettings.fromJson(Map<String, dynamic> json) {
    return AthkarNotificationSettings(
      isEnabled: json['is_enabled'] ?? true,
      customTime: json['custom_time'],
      vibrate: json['vibrate'] ?? true,
      importance: json['importance'] ?? 4,
    );
  }
  
  // تحويل النموذج إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'custom_time': customTime,
      'vibrate': vibrate,
      'importance': importance,
    };
  }
  
  // اختصار نسخة معدلة
  AthkarNotificationSettings copyWith({
    bool? isEnabled,
    String? customTime,
    bool? vibrate,
    int? importance,
  }) {
    return AthkarNotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      customTime: customTime ?? this.customTime,
      vibrate: vibrate ?? this.vibrate,
      importance: importance ?? this.importance,
    );
  }
}
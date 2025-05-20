// lib/features/athkar/data/models/athkar_model.dart
import 'package:flutter/material.dart';
import '../../domain/entities/athkar.dart';
import '../utils/icon_helper.dart';

/// نموذج لفئة الأذكار مع دعم التحويل من JSON وإلى JSON
///
/// يستخدم هذا النموذج لتمثيل فئة من فئات الأذكار ويحتوي على قائمة من الأذكار
/// يدعم التحويل من JSON وإلى JSON لسهولة التخزين والتحميل
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

  const AthkarCategoryModel({
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

  /// من JSON إلى موديل
  /// 
  /// تحويل بيانات JSON إلى كائن [AthkarCategoryModel]
  /// @param json بيانات JSON المراد تحويلها
  /// @return كائن [AthkarCategoryModel] جديد
  factory AthkarCategoryModel.fromJson(Map<String, dynamic> json) {
    // تحويل IconData من النص
    IconData icon = IconHelper.getIconFromString(json['icon'] as String? ?? 'Icons.label_important');
    
    // تحويل اللون من النص
    Color color = IconHelper.getColorFromHex(json['color'] as String? ?? '#447055');
    
    // تحويل قائمة الأذكار
    List<ThikrModel> athkarList = [];
    
    if (json['athkar'] != null) {
      final athkarJson = json['athkar'] as List;
      athkarList = athkarJson
          .map((thikrData) => ThikrModel.fromJson(thikrData as Map<String, dynamic>))
          .toList();
    }
    
    // قائمة الأوقات الإضافية
    List<String>? additionalTimes;
    if (json['additional_notify_times'] != null) {
      additionalTimes = List<String>.from(json['additional_notify_times'] as List);
    }
    
    return AthkarCategoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: icon,
      color: color,
      description: json['description'] as String?,
      athkar: athkarList,
      notifyTime: json['notify_time'] as String?,
      notifyTitle: json['notify_title'] as String?,
      notifyBody: json['notify_body'] as String?,
      hasMultipleReminders: json['has_multiple_reminders'] as bool? ?? false,
      additionalNotifyTimes: additionalTimes,
    );
  }

  /// تحويل الموديل إلى JSON
  /// 
  /// تحويل كائن [AthkarCategoryModel] إلى Map قابلة للتحويل إلى JSON
  /// @return Map تمثل الكائن
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
  
  /// تحويل النموذج إلى كيان
  /// 
  /// تحويل النموذج [AthkarCategoryModel] إلى كيان [AthkarCategory]
  /// @return كائن [AthkarCategory] جديد
  AthkarCategory toEntity() {
    return AthkarCategory(
      id: id,
      name: title,
      description: description ?? '',
      icon: IconHelper.iconToString(icon),
    );
  }
  
  /// إنشاء نسخة جديدة من النموذج مع تعديلات
  /// 
  /// تُستخدم هذه الطريقة لإنشاء نسخة جديدة من النموذج مع تعديل بعض الخصائص
  /// @param id المعرف الجديد (اختياري)
  /// @param title العنوان الجديد (اختياري)
  /// @param icon الأيقونة الجديدة (اختياري)
  /// @param color اللون الجديد (اختياري)
  /// @param description الوصف الجديد (اختياري)
  /// @param athkar قائمة الأذكار الجديدة (اختياري)
  /// @param notifyTime وقت الإشعار الجديد (اختياري)
  /// @param notifyTitle عنوان الإشعار الجديد (اختياري)
  /// @param notifyBody نص الإشعار الجديد (اختياري)
  /// @param hasMultipleReminders هل لديه إشعارات متعددة (اختياري)
  /// @param additionalNotifyTimes قائمة الأوقات الإضافية الجديدة (اختياري)
  /// @return نسخة جديدة من النموذج مع التعديلات
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
  
  /// التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AthkarCategoryModel &&
      other.id == id &&
      other.title == title &&
      other.icon == icon &&
      other.color == color &&
      other.description == description &&
      other.notifyTime == notifyTime &&
      other.notifyTitle == notifyTitle &&
      other.notifyBody == notifyBody &&
      other.hasMultipleReminders == hasMultipleReminders &&
      _listEquals(other.additionalNotifyTimes, additionalNotifyTimes) &&
      _listEquals(other.athkar, athkar);
  }
  
  /// حساب قيمة الهاش للكائن
  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      icon.hashCode ^
      color.hashCode ^
      description.hashCode ^
      notifyTime.hashCode ^
      notifyTitle.hashCode ^
      notifyBody.hashCode ^
      hasMultipleReminders.hashCode ^
      (additionalNotifyTimes?.hashCode ?? 0) ^
      (athkar.hashCode);
  }
  
  /// طريقة مساعدة للتحقق من تساوي قائمتين
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }
}

/// نموذج للذكر الواحد
///
/// يستخدم هذا النموذج لتمثيل ذكر واحد ويحتوي على نص الذكر وعدد التكرار والمصدر
/// يدعم التحويل من JSON وإلى JSON لسهولة التخزين والتحميل
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

  const ThikrModel({
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
  
  /// من JSON إلى نموذج
  /// 
  /// تحويل بيانات JSON إلى كائن [ThikrModel]
  /// @param json بيانات JSON المراد تحويلها
  /// @return كائن [ThikrModel] جديد
  factory ThikrModel.fromJson(Map<String, dynamic> json) {
    // التعامل مع المعرف الذي قد يكون نصًا أو رقمًا
    final dynamic rawId = json['id'];
    final int id = rawId is String ? int.parse(rawId) : rawId as int;
    
    // التعامل مع نص الذكر الذي قد يكون بمفتاح 'text' أو 'content'
    final String text = (json['text'] ?? json['content']) as String? ?? '';
    
    return ThikrModel(
      id: id,
      text: text,
      count: json['count'] as int? ?? 1,
      fadl: json['fadl'] as String?,
      source: json['source'] as String?,
      isQuranVerse: json['is_quran_verse'] as bool? ?? false,
      surahName: json['surah_name'] as String?,
      verseNumbers: json['verse_numbers'] as String?,
      audioUrl: json['audio_url'] as String?,
    );
  }
  
  /// تحويل النموذج إلى JSON
  /// 
  /// تحويل كائن [ThikrModel] إلى Map قابلة للتحويل إلى JSON
  /// @return Map تمثل الكائن
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
  
  /// تحويل النموذج إلى كيان
  /// 
  /// تحويل النموذج [ThikrModel] إلى كيان [Athkar]
  /// @return كائن [Athkar] جديد
  Athkar toEntity({String categoryId = ''}) {
    return Athkar(
      id: id.toString(),
      title: surahName ?? 'ذكر',
      content: text,
      count: count,
      categoryId: categoryId,
      source: source,
      notes: null,
      fadl: fadl,
    );
  }
  
  /// إنشاء نسخة جديدة من النموذج مع تعديلات
  /// 
  /// تُستخدم هذه الطريقة لإنشاء نسخة جديدة من النموذج مع تعديل بعض الخصائص
  /// @param id المعرف الجديد (اختياري)
  /// @param text النص الجديد (اختياري)
  /// @param count العدد الجديد (اختياري)
  /// @param fadl الفضل الجديد (اختياري)
  /// @param source المصدر الجديد (اختياري)
  /// @param isQuranVerse هل هو آية قرآنية (اختياري)
  /// @param surahName اسم السورة الجديد (اختياري)
  /// @param verseNumbers أرقام الآيات الجديدة (اختياري)
  /// @param audioUrl عنوان الصوت الجديد (اختياري)
  /// @return نسخة جديدة من النموذج مع التعديلات
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
  
  /// التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ThikrModel &&
      other.id == id &&
      other.text == text &&
      other.count == count &&
      other.fadl == fadl &&
      other.source == source &&
      other.isQuranVerse == isQuranVerse &&
      other.surahName == surahName &&
      other.verseNumbers == verseNumbers &&
      other.audioUrl == audioUrl;
  }

  /// حساب قيمة الهاش للكائن
  @override
  int get hashCode {
    return id.hashCode ^
      text.hashCode ^
      count.hashCode ^
      fadl.hashCode ^
      source.hashCode ^
      isQuranVerse.hashCode ^
      surahName.hashCode ^
      verseNumbers.hashCode ^
      audioUrl.hashCode;
  }
}

/// نموذج إعدادات الإشعارات
///
/// يستخدم هذا النموذج لتمثيل إعدادات الإشعارات لفئة من فئات الأذكار
/// يدعم التحويل من JSON وإلى JSON لسهولة التخزين والتحميل
class AthkarNotificationSettings {
  final bool isEnabled;
  final String? customTime;
  final bool vibrate;
  final int? importance;

  const AthkarNotificationSettings({
    this.isEnabled = true,
    this.customTime,
    this.vibrate = true,
    this.importance = 4,
  });
  
  /// من JSON إلى نموذج
  /// 
  /// تحويل بيانات JSON إلى كائن [AthkarNotificationSettings]
  /// @param json بيانات JSON المراد تحويلها
  /// @return كائن [AthkarNotificationSettings] جديد
  factory AthkarNotificationSettings.fromJson(Map<String, dynamic> json) {
    return AthkarNotificationSettings(
      isEnabled: json['is_enabled'] as bool? ?? true,
      customTime: json['custom_time'] as String?,
      vibrate: json['vibrate'] as bool? ?? true,
      importance: json['importance'] as int? ?? 4,
    );
  }
  
  /// قيم افتراضية جاهزة للإشعارات المعطلة
  static AthkarNotificationSettings get disabled => const AthkarNotificationSettings(
    isEnabled: false,
    customTime: null,
    vibrate: true,
    importance: 4,
  );
  
  /// قيم افتراضية جاهزة للإشعارات المفعلة
  static AthkarNotificationSettings get enabled => const AthkarNotificationSettings(
    isEnabled: true,
    customTime: null,
    vibrate: true,
    importance: 4,
  );
  
  /// تحويل النموذج إلى JSON
  /// 
  /// تحويل كائن [AthkarNotificationSettings] إلى Map قابلة للتحويل إلى JSON
  /// @return Map تمثل الكائن
  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'custom_time': customTime,
      'vibrate': vibrate,
      'importance': importance,
    };
  }
  
  /// إنشاء نسخة جديدة من النموذج مع تعديلات
  /// 
  /// تُستخدم هذه الطريقة لإنشاء نسخة جديدة من النموذج مع تعديل بعض الخصائص
  /// @param isEnabled حالة التفعيل الجديدة (اختياري)
  /// @param customTime الوقت المخصص الجديد (اختياري)
  /// @param vibrate حالة الاهتزاز الجديدة (اختياري)
  /// @param importance الأهمية الجديدة (اختياري)
  /// @return نسخة جديدة من النموذج مع التعديلات
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
  
  /// التحقق من تساوي كائنين
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AthkarNotificationSettings &&
      other.isEnabled == isEnabled &&
      other.customTime == customTime &&
      other.vibrate == vibrate &&
      other.importance == importance;
  }

  /// حساب قيمة الهاش للكائن
  @override
  int get hashCode {
    return isEnabled.hashCode ^
      customTime.hashCode ^
      vibrate.hashCode ^
      (importance?.hashCode ?? 0);
  }
  
  /// تحويل النموذج إلى نص مقروء
  @override
  String toString() {
    return 'AthkarNotificationSettings(isEnabled: $isEnabled, customTime: $customTime, vibrate: $vibrate, importance: $importance)';
  }
}
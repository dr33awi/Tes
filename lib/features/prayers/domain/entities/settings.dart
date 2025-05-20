// lib/features/settings/domain/entities/settings.dart
import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final int calculationMethod; // رقم طريقة حساب مواقيت الصلاة
  final int asrMethod; // طريقة حساب وقت العصر (0 للشافعي، 1 للحنفي)
  final bool adjustForDst; // ضبط التوقيت الصيفي
  final String themeMode; // نمط السمة (light / dark / system)
  final bool notificationsEnabled; // تفعيل الإشعارات
  final String appLanguage; // لغة التطبيق (ar / en)
  final bool highContrastMode; // وضع التباين العالي
  final double textScaleFactor; // معامل حجم النص
  final String fontFamily; // عائلة الخط
  final bool reduceMotion; // تقليل الحركة
  final bool vibrationEnabled; // تفعيل الاهتزاز
  final int lastOpenedTab; // آخر تبويب تم فتحه
  final bool enableDataSync; // تفعيل مزامنة البيانات
  final String userAccountId; // معرّف حساب المستخدم

  const Settings({
    this.calculationMethod = 2, // رابطة العالم الإسلامي
    this.asrMethod = 0, // المذهب الشافعي
    this.adjustForDst = true,
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    this.appLanguage = 'ar',
    this.highContrastMode = false,
    this.textScaleFactor = 1.0,
    this.fontFamily = 'default',
    this.reduceMotion = false,
    this.vibrationEnabled = true,
    this.lastOpenedTab = 0,
    this.enableDataSync = false,
    this.userAccountId = '',
  });

  // نسخة معدلة من الإعدادات
  Settings copyWith({
    int? calculationMethod,
    int? asrMethod,
    bool? adjustForDst,
    String? themeMode,
    bool? notificationsEnabled,
    String? appLanguage,
    bool? highContrastMode,
    double? textScaleFactor,
    String? fontFamily,
    bool? reduceMotion,
    bool? vibrationEnabled,
    int? lastOpenedTab,
    bool? enableDataSync,
    String? userAccountId,
  }) {
    return Settings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      adjustForDst: adjustForDst ?? this.adjustForDst,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      appLanguage: appLanguage ?? this.appLanguage,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      fontFamily: fontFamily ?? this.fontFamily,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      lastOpenedTab: lastOpenedTab ?? this.lastOpenedTab,
      enableDataSync: enableDataSync ?? this.enableDataSync,
      userAccountId: userAccountId ?? this.userAccountId,
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'calculationMethod': calculationMethod,
      'asrMethod': asrMethod,
      'adjustForDst': adjustForDst,
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
      'appLanguage': appLanguage,
      'highContrastMode': highContrastMode,
      'textScaleFactor': textScaleFactor,
      'fontFamily': fontFamily,
      'reduceMotion': reduceMotion,
      'vibrationEnabled': vibrationEnabled,
      'lastOpenedTab': lastOpenedTab,
      'enableDataSync': enableDataSync,
      'userAccountId': userAccountId,
    };
  }

  // إنشاء من JSON
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      calculationMethod: json['calculationMethod'] ?? 2,
      asrMethod: json['asrMethod'] ?? 0,
      adjustForDst: json['adjustForDst'] ?? true,
      themeMode: json['themeMode'] ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      appLanguage: json['appLanguage'] ?? 'ar',
      highContrastMode: json['highContrastMode'] ?? false,
      textScaleFactor: json['textScaleFactor'] ?? 1.0,
      fontFamily: json['fontFamily'] ?? 'default',
      reduceMotion: json['reduceMotion'] ?? false,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      lastOpenedTab: json['lastOpenedTab'] ?? 0,
      enableDataSync: json['enableDataSync'] ?? false,
      userAccountId: json['userAccountId'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        calculationMethod,
        asrMethod,
        adjustForDst,
        themeMode,
        notificationsEnabled,
        appLanguage,
        highContrastMode,
        textScaleFactor,
        fontFamily,
        reduceMotion,
        vibrationEnabled,
        lastOpenedTab,
        enableDataSync,
        userAccountId,
      ];
}
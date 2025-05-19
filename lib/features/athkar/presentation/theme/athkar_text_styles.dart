// lib/features/athkar/presentation/theme/athkar_text_styles.dart
import 'package:flutter/material.dart';

/// مدير لأنماط النصوص في قسم الأذكار
class AthkarTextStyles {
  // نمط عنوان الفئة
  static TextStyle getCategoryTitleStyle() {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'Tajawal',
    );
  }
  
  // نمط للنص الرئيسي للذكر
  static TextStyle getThikrTextStyle() {
    return const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      height: 2.0,
      color: Colors.white,
      fontFamily: 'Amiri-Bold',
      letterSpacing: 0.5,
    );
  }
  
  // نمط لمصدر الذكر
  static TextStyle getThikrSourceStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
  
  // نمط للوصف
  static TextStyle getDescriptionStyle() {
    return TextStyle(
      fontSize: 14,
      color: Colors.white.withOpacity(0.8),
    );
  }
  
  // نمط للتنبيهات والرسائل
  static TextStyle getAlertStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
  
  // نمط للعدادات والأرقام
  static TextStyle getCounterStyle() {
    return const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
  }
  
  // نمط للأزرار
  static TextStyle getButtonTextStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
  
  // نمط للعناوين الفرعية
  static TextStyle getSubtitleStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );
  }
}
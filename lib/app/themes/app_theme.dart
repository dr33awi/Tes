// lib/app/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import 'theme_constants.dart';

class AppTheme {
  // الثيمات الأساسية
  static ThemeData get lightTheme => LightTheme.theme;
  static ThemeData get darkTheme => DarkTheme.theme;
  
  // دوال مساعدة للثيمات
  
  // التحقق من الوضع الداكن
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  // الحصول على ألوان الثيم الحالي
  static Color getPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? ThemeColors.primaryLight : ThemeColors.primary;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? Colors.grey[850]! : ThemeColors.surface;
  }
  
  static Color getHighlightColor(BuildContext context) {
    return isDarkMode(context) ? ThemeColors.darkHighlightColor : ThemeColors.highlightColor;
  }
  
  static Color getTextColor(BuildContext context, {bool isSecondary = false}) {
    if (isSecondary) {
      return isDarkMode(context) ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary;
    }
    return isDarkMode(context) ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary;
  }
  
  // تنسيقات مخصصة للنصوص
  static TextStyle getArabicTextStyle(BuildContext context, {
    bool isBold = false,
    bool isLarge = false,
    bool isSecondary = false,
  }) {
    return TextStyle(
      fontFamily: 'Amiri',
      height: 1.5,
      fontSize: isLarge ? 18 : 16,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: getTextColor(context, isSecondary: isSecondary),
    );
  }
  
  // زخرفة لبطاقات الأذكار
  static BoxDecoration getAthkarCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: isDarkMode(context) ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode(context) ? 0.3 : 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: getPrimaryColor(context).withOpacity(0.2),
        width: 1,
      ),
    );
  }
  
  // زخرفة للصلاة الحالية
  static BoxDecoration getCurrentPrayerDecoration(BuildContext context) {
    return BoxDecoration(
      color: getPrimaryColor(context).withOpacity(0.15),
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
      border: Border.all(
        color: getPrimaryColor(context),
        width: 2,
      ),
    );
  }
  
  // زخرفة لاتجاه القبلة
  static BoxDecoration getQiblaDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: RadialGradient(
        colors: [
          ThemeColors.primary.withOpacity(0.7),
          ThemeColors.primary,
        ],
        center: Alignment.center,
        radius: 0.8,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: ThemeColors.primary.withOpacity(0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
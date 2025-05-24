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
  
  static Color getAccentColor(BuildContext context) {
    return isDarkMode(context) ? ThemeColors.accentLight : ThemeColors.accent;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? ThemeColors.darkCardBackground : ThemeColors.surface;
  }
  
  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? ThemeColors.darkBackground : ThemeColors.lightBackground;
  }
  
  static Color getCardColor(BuildContext context) {
    return isDarkMode(context) ? ThemeColors.darkCardBackground : ThemeColors.lightCardBackground;
  }
  
  static Color getDividerColor(BuildContext context) {
    return isDarkMode(context) 
        ? ThemeColors.primaryLight.withOpacity(0.1) 
        : ThemeColors.dividerColor;
  }
  
  static Color getTextColor(BuildContext context, {bool isSecondary = false}) {
    if (isSecondary) {
      return isDarkMode(context) ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary;
    }
    return isDarkMode(context) ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary;
  }
  
  // تنسيقات مخصصة للنصوص
  static TextStyle getHeadingStyle(BuildContext context, {
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: 'Cairo',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: getTextColor(context),
      height: 1.4,
    );
  }
  
  static TextStyle getBodyStyle(BuildContext context, {
    double fontSize = 16,
    bool isSecondary = false,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'Cairo',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: getTextColor(context, isSecondary: isSecondary),
      height: 1.6,
    );
  }
  
  static TextStyle getCaptionStyle(BuildContext context) {
    return TextStyle(
      fontFamily: 'Cairo',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: getTextColor(context, isSecondary: true),
      height: 1.5,
    );
  }
  
  // تنسيقات مخصصة للنصوص العربية
  static TextStyle getArabicTextStyle(BuildContext context, {
    bool isBold = false,
    bool isLarge = false,
    bool isSecondary = false,
  }) {
    return TextStyle(
      fontFamily: 'Cairo',
      height: 1.6,
      fontSize: isLarge ? 18 : 16,
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      color: getTextColor(context, isSecondary: isSecondary),
    );
  }
  
  // زخرفة لبطاقات عامة
  static BoxDecoration getCardDecoration(BuildContext context, {
    bool hasBorder = true,
    bool hasShadow = false,
    double borderRadius = ThemeSizes.borderRadiusMedium,
  }) {
    return BoxDecoration(
      color: getCardColor(context),
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder
          ? Border.all(
              color: getDividerColor(context),
              width: ThemeSizes.borderWidthThin,
            )
          : null,
      boxShadow: hasShadow ? ThemeEffects.lightCardShadow : null,
    );
  }
  
  // زخرفة لبطاقات الأذكار
  static BoxDecoration getAthkarCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: isDarkMode(context) 
          ? ThemeColors.darkCardBackground 
          : ThemeColors.athkarCardBackground,
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
      border: Border.all(
        color: getPrimaryColor(context).withOpacity(0.1),
        width: ThemeSizes.borderWidthThin,
      ),
      boxShadow: ThemeEffects.lightCardShadow,
    );
  }
  
  // زخرفة للصلاة الحالية
  static BoxDecoration getCurrentPrayerDecoration(BuildContext context) {
    return BoxDecoration(
      color: getPrimaryColor(context).withOpacity(0.1),
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
      border: Border.all(
        color: getPrimaryColor(context).withOpacity(0.3),
        width: ThemeSizes.borderWidthNormal,
      ),
    );
  }
  
  // زخرفة لاتجاه القبلة
  static BoxDecoration getQiblaDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: RadialGradient(
        colors: [
          ThemeColors.qiblaColor.withOpacity(0.2),
          ThemeColors.qiblaColor.withOpacity(0.1),
        ],
        center: Alignment.center,
        radius: 0.8,
      ),
      shape: BoxShape.circle,
      border: Border.all(
        color: ThemeColors.qiblaColor,
        width: ThemeSizes.borderWidthThick,
      ),
      boxShadow: [
        BoxShadow(
          color: ThemeColors.qiblaColor.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
  
  // زخرفة للأزرار
  static BoxDecoration getButtonDecoration(BuildContext context, {
    bool isPrimary = true,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        border: Border.all(
          color: getPrimaryColor(context),
          width: ThemeSizes.borderWidthNormal,
        ),
      );
    }
    
    return BoxDecoration(
      gradient: isPrimary ? ThemeEffects.buttonGradient : null,
      color: isPrimary ? null : getSurfaceColor(context),
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
      boxShadow: isPrimary ? ThemeEffects.lightCardShadow : null,
    );
  }
  
  // تنسيق للإشعارات
  static BoxDecoration getNotificationDecoration(BuildContext context, {
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? getAccentColor(context).withOpacity(0.1),
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
      border: Border.all(
        color: getAccentColor(context).withOpacity(0.3),
        width: ThemeSizes.borderWidthThin,
      ),
    );
  }
  
  // ظلال مخصصة
  static List<BoxShadow> getElevatedShadow(BuildContext context) {
    return isDarkMode(context) 
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : ThemeEffects.elevatedShadow;
  }
  
  // تأثير التحويم (Hover)
  static BoxDecoration getHoverDecoration(BuildContext context) {
    return BoxDecoration(
      color: getPrimaryColor(context).withOpacity(0.05),
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
    );
  }
  
  // تأثير التحديد (Selection)
  static BoxDecoration getSelectionDecoration(BuildContext context) {
    return BoxDecoration(
      color: getPrimaryColor(context).withOpacity(0.1),
      borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
      border: Border.all(
        color: getPrimaryColor(context).withOpacity(0.3),
        width: ThemeSizes.borderWidthNormal,
      ),
    );
  }
}
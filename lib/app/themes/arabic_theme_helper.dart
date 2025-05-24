// lib/app/themes/arabic_theme_helper.dart
import 'package:flutter/material.dart';
import 'theme_constants.dart';

/// مساعد للثيم العربي - يوفر خصائص وتنسيقات مناسبة للتطبيقات العربية
class ArabicThemeHelper {
  /// إعداد اتجاه النص للعربية
  static TextDirection get arabicTextDirection => TextDirection.rtl;
  
  /// التحقق من الوضع الداكن
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  /// الحصول على الوان متوافقة مع معايير الوصول
  static Color getAccessibleTextColor(Color backgroundColor, {bool isSecondary = false}) {
    // حساب نسبة التباين للتأكد من مطابقة معايير WCAG 2.0
    final double luminance = backgroundColor.computeLuminance();
    
    if (luminance > 0.5) {
      // خلفية فاتحة تحتاج نص داكن
      return isSecondary ? const Color(0xFF505050) : const Color(0xFF202020);
    } else {
      // خلفية داكنة تحتاج نص فاتح
      return isSecondary ? const Color(0xDDFFFFFF) : Colors.white;
    }
  }
  
  /// تنسيقات مخصصة للنصوص العربية
  static TextStyle getArabicTextStyle({
    bool isBold = false,
    bool isLarge = false,
    bool isSecondary = false,
    Color? textColor,
    Color? backgroundColor,
    double? fontSize,
  }) {
    // تفضيل الخط وحجمه حسب المتطلبات العربية
    return TextStyle(
      fontFamily: 'Cairo', // توحيد الخط المستخدم
      height: 1.5, // ارتفاع مناسب للنصوص العربية
      fontSize: fontSize ?? (isLarge ? 18 : 16),
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: textColor ?? (isSecondary ? ThemeColors.lightTextSecondary : ThemeColors.lightTextPrimary), // استخدام الألوان من ThemeColors
      // خصائص إضافية للغة العربية
      letterSpacing: -0.3, // تقليل التباعد بين الحروف العربية
      wordSpacing: 0.5, // زيادة التباعد بين الكلمات
      locale: const Locale('ar'), // تحديد اللغة للمساعدة في تنسيق النص
    );
  }
  
  /// زخرفة لبطاقات مخصصة مع تحسين لمعايير الوصول
  static BoxDecoration getAccessibleCardDecoration(BuildContext context, {
    double opacity = ThemeColors.opacityMedium, // استخدام شفافية متوسطة
    double borderRadius = ThemeSizes.borderRadiusLarge, // زيادة نصف القطر للبطاقات
  }) {
    final isDark = isDarkMode(context);
    final baseColor = isDark ? ThemeColors.darkCardBackground : ThemeColors.lightCardBackground; // استخدام ألوان البطاقات المخصصة
    
    return BoxDecoration(
      color: baseColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: baseColor.withOpacity(isDark ? 0.4 : 0.3), // زيادة شفافية الحدود للوضوح
        width: ThemeSizes.borderWidthNormal, // استخدام سمك الحدود الطبيعي
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.4 : 0.2), // تعديل الظل ليتناسب مع الزجاجية
          blurRadius: ThemeSizes.marginMedium, // زيادة التضبيب
          offset: const Offset(0, ThemeSizes.marginSmall), // تعديل الإزاحة
        ),
      ],
    );
  }
  
  /// تنسيق للأزرار المناسبة للتصميم العربي
  static ButtonStyle getArabicButtonStyle(BuildContext context, {
    bool isOutlined = false,
    double borderRadius = ThemeSizes.borderRadiusMedium,
  }) {
    final isDark = isDarkMode(context);
    final buttonColor = ThemeColors.primaryLight; // اللون الأخضر المفضل
    final textColor = isDark ? Colors.white : Colors.white; // نص أبيض على الأزرار
    
    if (isOutlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: textColor, // لون النص للأزرار المحددة
        side: BorderSide(
          color: buttonColor.withOpacity(isDark ? 0.7 : 0.5), // حدود شفافة للأزرار المحددة
          width: ThemeSizes.borderWidthNormal, // سمك الحدود
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginLarge, // زيادة التباعد الأفقي
          vertical: ThemeSizes.marginMedium, // زيادة التباعد العمودي
        ),
      );
    } else {
      return ElevatedButton.styleFrom(
        backgroundColor: buttonColor.withOpacity(ThemeColors.opacityMedium), // خلفية شبه شفافة
        foregroundColor: textColor, // لون النص
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginLarge,
          vertical: ThemeSizes.marginMedium,
        ),
        shadowColor: Colors.transparent, // إزالة الظل التقليدي
      );
    }
  }
  
  /// تخصيص المدخلات للغة العربية
  static InputDecoration getArabicInputDecoration(BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = isDarkMode(context);
    final fillColor = isDark ? ThemeColors.darkCardBackground.withOpacity(ThemeColors.opacityLight) : ThemeColors.lightCardBackground.withOpacity(ThemeColors.opacityLight); // استخدام ألوان البطاقات كخلفية
    
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      fillColor: fillColor,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ThemeSizes.marginMedium,
        vertical: ThemeSizes.marginMedium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        borderSide: BorderSide(
          color: isDark ? ThemeColors.primaryLight.withOpacity(0.5) : Colors.white.withOpacity(0.3),
          width: ThemeSizes.borderWidthNormal,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        borderSide: BorderSide(
          color: isDark ? ThemeColors.primaryLight.withOpacity(0.5) : Colors.white.withOpacity(0.3),
          width: ThemeSizes.borderWidthNormal,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        borderSide: BorderSide(
          color: ThemeColors.accentLight, // لون مميز عند التركيز
          width: ThemeSizes.borderWidthThick,
        ),
      ),
      hintStyle: TextStyle(
        fontFamily: 'Cairo',
        color: isDark ? ThemeColors.darkTextSecondary.withOpacity(0.7) : ThemeColors.lightTextSecondary.withOpacity(0.7),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        color: isDark ? ThemeColors.darkTextPrimary.withOpacity(0.8) : ThemeColors.lightTextPrimary.withOpacity(0.8),
      ),
      // التوجيه المناسب للعربية
      alignLabelWithHint: true,
      floatingLabelAlignment: FloatingLabelAlignment.start,
    );
  }
}
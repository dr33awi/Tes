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
      color: textColor ?? (isSecondary ? const Color(0xCCFFFFFF) : Colors.white),
      // خصائص إضافية للغة العربية
      letterSpacing: -0.3, // تقليل التباعد بين الحروف العربية
      wordSpacing: 0.5, // زيادة التباعد بين الكلمات
      locale: const Locale('ar'), // تحديد اللغة للمساعدة في تنسيق النص
    );
  }
  
  /// زخرفة لبطاقات مخصصة مع تحسين لمعايير الوصول
  static BoxDecoration getAccessibleCardDecoration(BuildContext context, {
    double opacity = 0.15,
    double borderRadius = ThemeSizes.borderRadiusMedium,
  }) {
    final isDark = isDarkMode(context);
    final baseColor = isDark ? Colors.white : ThemeColors.primary;
    
    return BoxDecoration(
      color: baseColor.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: baseColor.withOpacity(isDark ? 0.3 : 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
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
    
    if (isOutlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : ThemeColors.primary,
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.5) : ThemeColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginSmall,
        ),
      );
    } else {
      return ElevatedButton.styleFrom(
        backgroundColor: isDark ? ThemeColors.primaryLight : ThemeColors.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginSmall,
        ),
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
    final fillColor = isDark ? Colors.grey[800] : Colors.white.withOpacity(0.1);
    
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
          color: isDark ? Colors.grey[600]! : Colors.white.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.white.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        borderSide: BorderSide(
          color: isDark ? ThemeColors.primaryLight : Colors.white,
          width: ThemeSizes.borderWidthThick,
        ),
      ),
      hintStyle: TextStyle(
        fontFamily: 'Cairo',
        color: isDark ? Colors.grey[500] : Colors.white.withOpacity(0.5),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        color: isDark ? Colors.grey[400] : Colors.white.withOpacity(0.7),
      ),
      // التوجيه المناسب للعربية
      alignLabelWithHint: true,
      floatingLabelAlignment: FloatingLabelAlignment.start,
    );
  }
}
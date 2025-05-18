// lib/app/themes/theme_constants.dart
import 'package:flutter/material.dart';

/// ثوابت الألوان المستخدمة في التطبيق
class ThemeColors {
  // الألوان الأساسية
  static const Color primary = Color(0xFF0B8457); // أخضر غامق
  static const Color primaryLight = Color(0xFF27B376); // أخضر فاتح
  static const Color surface = Color(0xFFE7E8E3); // رمادي فاتح بلمسة خضراء
  
  // ألوان الخلفية
  static const Color lightBackground = Colors.white;
  static const Color darkBackground = Color(0xFF121212);
  
  // ألوان البطاقات
  static const Color lightCardBackground = Colors.white;
  static const Color darkCardBackground = Color(0xFF2A2A2A);
  
  // ألوان الحالة
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  
  // ألوان وظيفية أخرى
  static const Color disabledButton = Colors.grey;
  static const Color highlightColor = Color(0xFFE0F2EC); // هالة خضراء فاتحة
  static const Color darkHighlightColor = Color(0xFF0F5E3D); // أخضر غامق للوضع الداكن
  
  // ألوان النصوص
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  
  // ألوان مخصصة للتطبيق الإسلامي
  static const Color prayerTimeHighlight = Color(0xFF27B376); // الأخضر الفاتح للصلاة الحالية
  static const Color athkarCardBackground = Color(0xFFF5F5F5); // خلفية فاتحة لبطاقات الأذكار
  static const Color qiblaColor = Color(0xFF0B8457); // لون اتجاه القبلة
}

/// قياسات ثابتة للتباعد والحجم
class ThemeSizes {
  // تباعد الهوامش
  static const double marginXSmall = 4.0;
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 32.0;
  
  // نصف القطر للزوايا
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusCircular = 50.0;
  
  // سمك الحدود
  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthThick = 2.0;
  
  // ارتفاع وعرض العناصر
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardElevation = 2.0;
  static const double itemSpacing = 16.0;
}

/// ظلال وتأثيرات متكررة
class ThemeEffects {
  // ظل خفيف للبطاقات
  static List<BoxShadow> get lightCardShadow => [
    const BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  // ظل أكثر بروزاً للعناصر المهمة
  static List<BoxShadow> get elevatedShadow => [
    const BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
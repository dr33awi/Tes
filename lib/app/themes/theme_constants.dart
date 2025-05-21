// lib/app/themes/theme_constants.dart
import 'package:flutter/material.dart';

/// ثوابت الألوان المستخدمة في التطبيق
class ThemeColors {
  // الألوان الأساسية - تم تعديل اللون الأخضر ليتناسب مع الصورة
  static const Color primary = Color(0xFF1D483C); // أخضر داكن مثل الصورة
  static const Color primaryLight = Color(0xFF2A5E4F); // أخضر داكن فاتح قليلاً
  static const Color surface = Color(0xFFE7E8E3); // رمادي فاتح بلمسة خضراء
  
  // ألوان الخلفية
  static const Color lightBackground = Color(0xFF1D483C); // تم تعديل لون الخلفية للوضع الفاتح
  static const Color darkBackground = Color(0xFF1A3C32); // تم تعديل لون الخلفية للوضع الداكن
  
  // ألوان البطاقات - شبه شفافة للتأثير الزجاجي
  static const Color lightCardBackground = Color(0x40FFFFFF); // أبيض شبه شفاف
  static const Color darkCardBackground = Color(0x40263F36); // أخضر داكن شبه شفاف
  
  // ألوان الحالة
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  
  // ألوان وظيفية أخرى
  static const Color disabledButton = Colors.grey;
  static const Color highlightColor = Color(0x33FFFFFF); // هالة بيضاء شبه شفافة
  static const Color darkHighlightColor = Color(0xFF2A5E4F); // أخضر فاتح قليلاً للوضع الداكن
  
  // ألوان النصوص
  static const Color lightTextPrimary = Colors.white; // تم تعديل لون النص الأساسي للوضع الفاتح
  static const Color lightTextSecondary = Color(0xCCFFFFFF); // أبيض شبه شفاف
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xBBFFFFFF); // أبيض شبه شفاف
  
  // ألوان مخصصة للتطبيق الإسلامي
  static const Color prayerTimeHighlight = Color(0xFF2A5E4F); // تم تعديل لون تمييز الصلاة الحالية
  static const Color athkarCardBackground = Color(0x25FFFFFF); // خلفية شبه شفافة لبطاقات الأذكار
  static const Color qiblaColor = Color(0xFF2A5E4F); // تم تعديل لون اتجاه القبلة
  
  // ألوان جديدة للتأثير الزجاجي
  static const Color glassMorphismLight = Color(0x15FFFFFF); // تأثير زجاجي خفيف
  static const Color glassMorphismMedium = Color(0x25FFFFFF); // تأثير زجاجي متوسط
  static const Color glassMorphismDark = Color(0x40FFFFFF); // تأثير زجاجي غامق
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
  
  // تأثيرات جديدة للتصميم الزجاجي
  static BoxDecoration getGlassMorphismDecoration({
    double opacity = 0.15,
    double borderRadius = ThemeSizes.borderRadiusMedium,
    Color borderColor = Colors.white,
    double borderWidth = 0.5,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor.withOpacity(0.3),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ],
    );
  }
  
  // تدرج لوني للخلفية
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1D483C), // نفس لون الخلفية في الصورة 
      Color(0xFF163229), // قاتم أكثر قليلاً
    ],
  );
}
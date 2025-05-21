// lib/app/themes/theme_constants.dart
import 'package:flutter/material.dart';

/// ثوابت الألوان المستخدمة في التطبيق
class ThemeColors {
  // الألوان الأساسية - تدرجات اللون الأخضر
  static const Color primary = Color(0xFF1D483C); // أخضر داكن مثل الصورة
  static const Color primaryLight = Color(0xFF2A5E4F); // أخضر داكن فاتح قليلاً
  static const Color primaryDark = Color(0xFF163229); // أخضر أغمق للتباين
  static const Color surface = Color(0xFFE7E8E3); // رمادي فاتح بلمسة خضراء
  
  // ألوان الخلفية
  static const Color lightBackground = Color(0xFF1D483C); // خلفية الوضع الفاتح
  static const Color darkBackground = Color(0xFF1A3C32); // خلفية الوضع الداكن
  
  // ألوان ثانوية للتمييز
  static const Color accent = Color(0xFF4CAF84); // لون مميز أخضر فاتح
  static const Color accentLight = Color(0xFF65D19E); // أخضر فاتح أكثر
  
  // ألوان متوافقة مع معايير الوصول (WCAG)
  // هذه الألوان تضمن نسبة تباين كافية للقراءة
  static const Color accessibleLight = Color(0xFFE7F3EF); // فاتح مقروء على الخلفية الداكنة
  static const Color accessibleDark = Color(0xFF0C231E); // داكن مقروء على الخلفية الفاتحة
  
  // ألوان البطاقات - شبه شفافة للتأثير الزجاجي
  static const Color lightCardBackground = Color(0x40FFFFFF); // أبيض شبه شفاف
  static const Color darkCardBackground = Color(0x40263F36); // أخضر داكن شبه شفاف
  
  // ألوان الحالة
  static const Color error = Color(0xFFD32F2F); // أحمر
  static const Color success = Color(0xFF388E3C); // أخضر
  static const Color warning = Color(0xFFF57C00); // برتقالي
  static const Color info = Color(0xFF1976D2); // أزرق
  
  // ألوان وظيفية أخرى
  static const Color disabledButton = Color(0xFF9E9E9E); // رمادي
  static const Color highlightColor = Color(0x33FFFFFF); // هالة بيضاء شبه شفافة
  static const Color darkHighlightColor = Color(0xFF2A5E4F); // أخضر فاتح للوضع الداكن
  static const Color dividerColor = Color(0x1FFFFFFF); // لون الفواصل
  
  // ألوان النصوص
  static const Color lightTextPrimary = Colors.white; // نص أساسي للوضع الفاتح
  static const Color lightTextSecondary = Color(0xCCFFFFFF); // نص ثانوي للوضع الفاتح
  static const Color darkTextPrimary = Colors.white; // نص أساسي للوضع الداكن
  static const Color darkTextSecondary = Color(0xBBFFFFFF); // نص ثانوي للوضع الداكن
  
  // ألوان مخصصة للتطبيق الإسلامي
  static const Color prayerTimeHighlight = Color(0xFF2A5E4F); // تمييز الصلاة الحالية
  static const Color athkarCardBackground = Color(0x25FFFFFF); // خلفية بطاقات الأذكار
  static const Color qiblaColor = Color(0xFF4CAF84); // اتجاه القبلة (أكثر وضوحاً)
  static const Color prayerNextTime = Color(0x33FFFFFF); // الصلاة القادمة
  
  // ألوان للتأثير الزجاجي
  static const Color glassMorphismLight = Color(0x15FFFFFF); // تأثير زجاجي خفيف
  static const Color glassMorphismMedium = Color(0x25FFFFFF); // تأثير زجاجي متوسط
  static const Color glassMorphismDark = Color(0x40FFFFFF); // تأثير زجاجي غامق
  
  // شفافية موحدة
  static const double opacityLight = 0.1;
  static const double opacityMedium = 0.2;
  static const double opacityHigh = 0.3;
}

/// قياسات ثابتة للتباعد والحجم
class ThemeSizes {
  // تباعد الهوامش
  static const double marginXXSmall = 2.0;
  static const double marginXSmall = 4.0;
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 32.0;
  static const double marginXXLarge = 48.0;
  
  // نصف القطر للزوايا
  static const double borderRadiusXSmall = 2.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusXXLarge = 24.0;
  static const double borderRadiusCircular = 50.0;
  
  // سمك الحدود
  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;
  static const double borderWidthXThick = 3.0;
  
  // ارتفاع وعرض العناصر
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeight = 48.0;
  static const double buttonHeightLarge = 56.0;
  static const double inputHeight = 56.0;
  static const double inputHeightSmall = 40.0;
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 4.0;
  static const double itemSpacing = 16.0;
  
  // حجم الأيقونات
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  // الخط
  static const double fontSizeXSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 22.0;
  
  // ارتفاع سطر النص
  static const double lineHeightSmall = 1.2;
  static const double lineHeightMedium = 1.5;
  static const double lineHeightLarge = 1.8;
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
  
  // ظل للعناصر البارزة جداً
  static List<BoxShadow> get highlightedShadow => [
    const BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      spreadRadius: 2,
      offset: Offset(0, 6),
    ),
  ];
  
  // هالة للعناصر المهمة
  static List<BoxShadow> glowEffect(Color color, {double intensity = 0.5}) => [
    BoxShadow(
      color: color.withOpacity(intensity * 0.3),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
  
  // تأثيرات جديدة للتصميم الزجاجي
  static BoxDecoration getGlassMorphismDecoration({
    double opacity = 0.15,
    double borderRadius = ThemeSizes.borderRadiusMedium,
    Color borderColor = Colors.white,
    double borderWidth = 0.5,
    double blurRadius = 10.0,
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
  
  // تدرج لوني للخلفية الأساسية
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ThemeColors.primary,
      ThemeColors.primaryDark,
    ],
  );
  
  // تدرج لوني للعناصر المميزة
  static LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ThemeColors.accent,
      ThemeColors.primaryLight,
    ],
  );
  
  // تدرج لوني لاتجاه القبلة
  static RadialGradient get qiblaGradient => const RadialGradient(
    colors: [
      ThemeColors.accent,
      ThemeColors.qiblaColor,
    ],
    center: Alignment.center,
    radius: 0.8,
  );
  
  // تأثير نقش إسلامي للخلفية - يتطلب إضافة الصورة الفعلية
  static DecorationImage? getIslamicPatternDecoration() {
    // تعليق: هذه الدالة تحتاج إلى إضافة مسار الصورة الفعلي عند الاستخدام
    // مثال للاستخدام:
    // return DecorationImage(
    //   image: AssetImage('assets/images/islamic_pattern.png'),
    //   fit: BoxFit.cover,
    //   opacity: 0.05, // شفافية منخفضة جداً للنقش
    // );
    
    // حالياً نرجع null لتجنب خطأ البناء
    return null;
  }
}

/// قيم زمنية للرسوم المتحركة
class ThemeDurations {
  static const Duration veryFast = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// منحنيات الرسوم المتحركة
class ThemeCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve decelerate = Curves.easeOut;
  static const Curve emphasize = Curves.easeInOutCubic;
  static const Curve bounce = Curves.elasticOut;
}
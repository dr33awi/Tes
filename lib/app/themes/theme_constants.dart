// lib/app/themes/theme_constants.dart
import 'package:flutter/material.dart';

/// ثوابت الألوان المستخدمة في التطبيق - نظام اللون الأخضر
class ThemeColors {
  // الألوان الأساسية - تدرجات اللون الأخضر #0b8457
  static const Color primary = Color(0xFF0B8457); // أخضر أساسي
  static const Color primaryLight = Color(0xFF1FA06D); // أخضر فاتح
  static const Color primaryDark = Color(0xFF076842); // أخضر داكن
  static const Color primarySoft = Color(0xFF4DB381); // أخضر ناعم
  static const Color surface = Color(0xFFF5FAF8); // سطح بلمسة خضراء خفيفة
  
  // ألوان الخلفية
  static const Color lightBackground = Color(0xFFFCFDFC); // خلفية فاتحة نقية
  static const Color darkBackground = Color(0xFF0A1F17); // خلفية داكنة
  
  // ألوان ثانوية للتمييز
  static const Color accent = Color(0xFF2ECC71); // أخضر مشرق
  static const Color accentLight = Color(0xFF5DADE2); // أزرق فاتح متمم
  static const Color accentDark = Color(0xFF27AE60); // أخضر متوسط
  
  // ألوان محايدة
  static const Color neutralWarm = Color(0xFFE8F5E9); // أخضر فاتح جداً
  static const Color neutralCool = Color(0xFFE0F2E9); // رمادي بلمسة خضراء
  static const Color neutralDark = Color(0xFF2C3E50); // رمادي داكن
  
  // ألوان متوافقة مع معايير الوصول (WCAG)
  static const Color accessibleLight = Color(0xFFFAFAF7); 
  static const Color accessibleDark = Color(0xFF1A1F14);
  
  // ألوان البطاقات - شبه شفافة للتأثير الزجاجي
  static const Color lightCardBackground = Color(0xFFFFFFFF); // أبيض
  static const Color darkCardBackground = Color(0xFF0D2920); // أخضر داكن
  
  // ألوان الحالة
  static const Color error = Color(0xFFE74C3C); // أحمر
  static const Color success = Color(0xFF27AE60); // أخضر نجاح
  static const Color warning = Color(0xFFF39C12); // برتقالي
  static const Color info = Color(0xFF3498DB); // أزرق
  
  // ألوان وظيفية أخرى
  static const Color disabledButton = Color(0xFFB0BEC5); // رمادي
  static const Color highlightColor = Color(0x1A0B8457); // هالة خضراء خفيفة
  static const Color darkHighlightColor = Color(0xFF1FA06D); 
  static const Color dividerColor = Color(0xFFE0E0E0); // لون الفواصل
  static const Color shadowColor = Color(0x1A000000); // ظل خفيف
  
  // ألوان النصوص
  static const Color lightTextPrimary = Color(0xFF212121); // نص داكن للوضع الفاتح
  static const Color lightTextSecondary = Color(0xFF757575); // نص ثانوي للوضع الفاتح
  static const Color darkTextPrimary = Color(0xFFF5F5F5); // نص فاتح للوضع الداكن
  static const Color darkTextSecondary = Color(0xFFBDBDBD); // نص ثانوي للوضع الداكن
  
  // ألوان مخصصة للتطبيق الإسلامي
  static const Color prayerTimeHighlight = Color(0xFF1FA06D); // تمييز الصلاة الحالية
  static const Color athkarCardBackground = Color(0xFFF0F9F4); // خلفية بطاقات الأذكار
  static const Color qiblaColor = Color(0xFF0B8457); // اتجاه القبلة
  static const Color prayerNextTime = Color(0xFFE8F5E9); // الصلاة القادمة
  
  // ألوان للتأثير الزجاجي الناعم
  static const Color glassMorphismLight = Color(0x0DFFFFFF); // تأثير زجاجي خفيف جداً
  static const Color glassMorphismMedium = Color(0x1AFFFFFF); // تأثير زجاجي متوسط
  static const Color glassMorphismDark = Color(0x33FFFFFF); // تأثير زجاجي غامق
  
  // شفافية موحدة
  static const double opacityLight = 0.05;
  static const double opacityMedium = 0.1;
  static const double opacityHigh = 0.2;
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
  
  // نصف القطر للزوايا - أكثر نعومة
  static const double borderRadiusXSmall = 4.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  static const double borderRadiusXXLarge = 28.0;
  static const double borderRadiusCircular = 50.0;
  
  // سمك الحدود - أنحف للمظهر الناعم
  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;
  static const double borderWidthXThick = 3.0;
  
  // ارتفاع وعرض العناصر
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeight = 52.0;
  static const double buttonHeightLarge = 60.0;
  static const double inputHeight = 56.0;
  static const double inputHeightSmall = 44.0;
  static const double cardElevation = 0.0; // بدون ظل للمظهر الناعم
  static const double cardElevationHigh = 2.0;
  static const double itemSpacing = 16.0;
  
  // حجم الأيقونات
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  // الخط
  static const double fontSizeXSmall = 11.0;
  static const double fontSizeSmall = 13.0;
  static const double fontSizeMedium = 15.0;
  static const double fontSizeLarge = 17.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  
  // ارتفاع سطر النص
  static const double lineHeightSmall = 1.3;
  static const double lineHeightMedium = 1.5;
  static const double lineHeightLarge = 1.7;
}

/// ظلال وتأثيرات متكررة
class ThemeEffects {
  // ظل خفيف جداً للبطاقات
  static List<BoxShadow> get lightCardShadow => [
    BoxShadow(
      color: ThemeColors.shadowColor.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  // ظل ناعم للعناصر المرتفعة
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: ThemeColors.shadowColor.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ظل للعناصر البارزة
  static List<BoxShadow> get highlightedShadow => [
    BoxShadow(
      color: ThemeColors.primary.withOpacity(0.15),
      blurRadius: 25,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];
  
  // هالة ناعمة للعناصر المهمة
  static List<BoxShadow> glowEffect(Color color, {double intensity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(intensity * 0.4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
  
  // تأثيرات للتصميم الناعم
  static BoxDecoration getSoftCardDecoration({
    Color? backgroundColor,
    double borderRadius = ThemeSizes.borderRadiusMedium,
    bool hasBorder = false,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? ThemeColors.lightCardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder
          ? Border.all(
              color: ThemeColors.dividerColor,
              width: ThemeSizes.borderWidthThin,
            )
          : null,
      boxShadow: hasShadow ? lightCardShadow : null,
    );
  }
  
  // تأثيرات للتصميم الزجاجي (للتوافق مع الكود القديم)
  static BoxDecoration getGlassMorphismDecoration({
    double opacity = 0.15,
    double borderRadius = ThemeSizes.borderRadiusMedium,
    Color borderColor = const Color(0xFFE0E0E0),
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
          color: Colors.black.withOpacity(0.05),
          blurRadius: blurRadius,
          spreadRadius: 0,
        ),
      ],
    );
  }
  
  // تدرج لوني ناعم للخلفية
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ThemeColors.lightBackground,
      Color(0xFFF0F9F4), // لمسة خضراء خفيفة
    ],
  );
  
  // تدرج لوني أخضر للعناصر المميزة
  static LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ThemeColors.primary,
      ThemeColors.primaryLight,
    ],
  );
  
  // تدرج ناعم للأزرار
  static LinearGradient get buttonGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ThemeColors.primaryLight,
      ThemeColors.primary,
    ],
  );
  
  // تدرج دائري لاتجاه القبلة
  static RadialGradient get qiblaGradient => const RadialGradient(
    colors: [
      ThemeColors.primaryLight,
      ThemeColors.primary,
    ],
    center: Alignment.center,
    radius: 0.8,
  );
}

/// قيم زمنية للرسوم المتحركة السلسة
class ThemeDurations {
  static const Duration veryFast = Duration(milliseconds: 200);
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 1000);
}

/// منحنيات الرسوم المتحركة السلسة
class ThemeCurves {
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve accelerate = Curves.easeInCubic;
  static const Curve decelerate = Curves.easeOutCubic;
  static const Curve emphasize = Curves.easeInOutQuart;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutQuint;
}
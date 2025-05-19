// lib/features/athkar/presentation/theme/athkar_theme_manager.dart
import 'package:flutter/material.dart';
import '../../data/utils/icon_helper.dart';

/// مدير لموضوع قسم الأذكار في التطبيق
class AthkarThemeManager {
  // الحصول على موضوع محدد للفئة
  static ThemeData getThemeForCategory(String categoryId, Brightness brightness) {
    // الحصول على ألوان الفئة
    final primaryColor = IconHelper.getCategoryColor(categoryId);
    final List<Color> gradientColors = IconHelper.getCategoryGradient(categoryId);
    
    // ألوان الموضوع الفاتح
    if (brightness == Brightness.light) {
      return ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: gradientColors[1],
          background: Colors.grey[50]!,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(
            color: primaryColor,
          ),
        ),
        // إزالة cardTheme واستخدام cardColor فقط
        cardColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: primaryColor,
        ),
        fontFamily: 'Tajawal',
      );
    } 
    // ألوان الموضوع الداكن
    else {
      return ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: gradientColors[1],
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
        ),
        // إزالة cardTheme واستخدام cardColor فقط
        cardColor: const Color(0xFF2C2C2C),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        fontFamily: 'Tajawal',
      );
    }
  }
  
  // الحصول على تدرج خلفية للفئة
  static BoxDecoration getGradientBackground(String categoryId) {
    final gradientColors = IconHelper.getCategoryGradient(categoryId);
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          gradientColors[0],
          gradientColors[1],
        ],
        stops: const [0.3, 1.0],
      ),
    );
  }
  
  // إضافة طريقة للحصول على مظهر البطاقة
  static ShapeBorder getCardShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
  }
  
  // الحصول على خصائص البطاقة مباشرة
  static CardStyle getCardStyle({Color? color, double elevation = 4.0}) {
    return CardStyle(
      color: color,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
  
  // الحصول على نمط لعنوان فئة
  static TextStyle getCategoryTitleStyle() {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
  
  // الحصول على نمط للنص الرئيسي للذكر
  static TextStyle getThikrTextStyle() {
    return const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      height: 2.0,
      color: Colors.white,
      fontFamily: 'Amiri-Bold',
    );
  }
  
  // الحصول على نمط لمصدر الذكر
  static TextStyle getThikrSourceStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white70,
    );
  }
}

// فئة مساعدة للتعامل مع أنماط البطاقات
class CardStyle {
  final Color? color;
  final double elevation;
  final ShapeBorder shape;
  
  const CardStyle({
    this.color,
    this.elevation = 4.0,
    required this.shape,
  });
  
  // تطبيق النمط على بطاقة
  void applyToCard(Card card) {
    // تم تصميم هذه الطريقة للتوافق مع إصدارات مختلفة من Flutter
    // ولكن لا يمكن استخدامها مباشرة بهذه الطريقة لأن Card غير قابلة للتعديل
    // إنها فقط لإظهار الفكرة
  }
}
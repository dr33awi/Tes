// lib/app/themes/light_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_constants.dart';

class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      // تصحيح: تغيير السطوع للوضع الفاتح رغم استخدام خلفية داكنة
      // وهذا لأن الواجهة تستخدم خلفية داكنة ولكن بنمط الثيم الفاتح
      brightness: Brightness.light,
      primaryColor: ThemeColors.primary,
      scaffoldBackgroundColor: ThemeColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: ThemeColors.primary,
        secondary: ThemeColors.primaryLight,
        tertiary: ThemeColors.surface,
        error: ThemeColors.error,
        background: ThemeColors.lightBackground,
        surface: ThemeColors.surface,
        onSurface: ThemeColors.lightTextPrimary,
        onBackground: ThemeColors.lightTextPrimary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      useMaterial3: true, // استخدام Material 3 للحصول على تصميم أفضل
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: ThemeColors.primary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.15),
        shadowColor: Colors.black.withOpacity(0.1),
        elevation: ThemeSizes.cardElevation,
        margin: const EdgeInsets.symmetric(
          vertical: ThemeSizes.marginSmall,
          horizontal: 0,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(ThemeSizes.borderRadiusMedium),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
            side: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSizes.marginMedium,
            vertical: ThemeSizes.marginSmall,
          ),
          minimumSize: const Size(double.infinity, ThemeSizes.buttonHeight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.5)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSizes.marginMedium,
            vertical: ThemeSizes.marginSmall,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          color: Colors.white,
          height: 1.5, // تحسين ارتفاع النص للعربية
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: Colors.white,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: ThemeColors.lightTextSecondary,
          height: 1.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white.withOpacity(0.1),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: const BorderSide(
            color: Colors.white,
            width: ThemeSizes.borderWidthThick,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginMedium,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontFamily: 'Cairo',
        ),
        // تحسينات للغة العربية
        alignLabelWithHint: true,
        floatingLabelAlignment: FloatingLabelAlignment.start,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.2),
        thickness: ThemeSizes.borderWidthNormal,
        space: ThemeSizes.marginMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        // تحسين التباين وقابلية القراءة
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white,
              width: 3.0,
            ),
          ),
        ),
        // إضافة نمط كتابة للعلامات
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(ThemeColors.primary),
        side: BorderSide(color: Colors.white.withOpacity(0.7)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusSmall),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white.withOpacity(0.5);
          }
          return Colors.white.withOpacity(0.2);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.2),
        valueIndicatorColor: ThemeColors.primary,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginSmall,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ThemeColors.primary,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
        ),
        // تحسين النصوص داخل مربعات الحوار
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.2),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ThemeSizes.borderRadiusMedium),
            topRight: Radius.circular(ThemeSizes.borderRadiusMedium),
          ),
        ),
      ),
    );
  }
}
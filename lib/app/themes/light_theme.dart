// lib/app/themes/light_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_constants.dart';

class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ThemeColors.primary,
      scaffoldBackgroundColor: ThemeColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: ThemeColors.primary,
        secondary: ThemeColors.accent,
        tertiary: ThemeColors.primarySoft,
        error: ThemeColors.error,
        background: ThemeColors.lightBackground,
        surface: ThemeColors.surface,
        onSurface: ThemeColors.lightTextPrimary,
        onBackground: ThemeColors.lightTextPrimary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      useMaterial3: true,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeColors.lightBackground,
        foregroundColor: ThemeColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ThemeColors.lightTextPrimary,
        ),
        iconTheme: const IconThemeData(
          color: ThemeColors.lightTextPrimary,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: ThemeColors.lightBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: ThemeColors.lightCardBackground,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          vertical: ThemeSizes.marginSmall,
          horizontal: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          side: const BorderSide(
            color: ThemeColors.dividerColor,
            width: ThemeSizes.borderWidthThin,
          ),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ThemeColors.disabledButton,
          disabledForegroundColor: Colors.white70,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSizes.marginLarge,
            vertical: ThemeSizes.marginMedium,
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, ThemeSizes.buttonHeight),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ThemeColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSizes.marginMedium,
            vertical: ThemeSizes.marginSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.primary,
          side: const BorderSide(
            color: ThemeColors.primary,
            width: ThemeSizes.borderWidthNormal,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSizes.marginLarge,
            vertical: ThemeSizes.marginMedium,
          ),
          minimumSize: const Size(double.infinity, ThemeSizes.buttonHeight),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: ThemeColors.lightTextPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ThemeColors.lightTextPrimary,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ThemeColors.lightTextPrimary,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ThemeColors.lightTextPrimary,
          height: 1.4,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ThemeColors.lightTextPrimary,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ThemeColors.lightTextPrimary,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: ThemeColors.lightTextPrimary,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ThemeColors.lightTextPrimary,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ThemeColors.lightTextPrimary,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ThemeColors.lightTextPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ThemeColors.lightTextPrimary,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ThemeColors.lightTextSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ThemeColors.lightTextPrimary,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ThemeColors.lightTextPrimary,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ThemeColors.lightTextSecondary,
          height: 1.4,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        fillColor: ThemeColors.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: const BorderSide(
            color: ThemeColors.dividerColor,
            width: ThemeSizes.borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: const BorderSide(
            color: ThemeColors.dividerColor,
            width: ThemeSizes.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: const BorderSide(
            color: ThemeColors.primary,
            width: ThemeSizes.borderWidthNormal,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: const BorderSide(
            color: ThemeColors.error,
            width: ThemeSizes.borderWidthNormal,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: const BorderSide(
            color: ThemeColors.error,
            width: ThemeSizes.borderWidthNormal,
          ),
        ),
        hintStyle: const TextStyle(
          color: ThemeColors.lightTextSecondary,
          fontFamily: 'Cairo',
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: ThemeColors.lightTextSecondary,
          fontFamily: 'Cairo',
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: ThemeColors.error,
          fontFamily: 'Cairo',
          fontSize: 12,
        ),
        prefixIconColor: ThemeColors.lightTextSecondary,
        suffixIconColor: ThemeColors.lightTextSecondary,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ThemeColors.dividerColor,
        thickness: ThemeSizes.borderWidthThin,
        space: ThemeSizes.marginLarge,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.lightCardBackground,
        selectedItemColor: ThemeColors.primary,
        unselectedItemColor: ThemeColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        selectedIconTheme: IconThemeData(
          size: 26,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24,
        ),
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: ThemeColors.primary,
        unselectedLabelColor: ThemeColors.lightTextSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: ThemeColors.primary,
              width: 2.0,
            ),
          ),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return ThemeColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(
          color: ThemeColors.lightTextSecondary,
          width: ThemeSizes.borderWidthNormal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusSmall),
        ),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return ThemeColors.lightTextSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return ThemeColors.primary;
          }
          return ThemeColors.dividerColor;
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      
      // Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: ThemeColors.primary,
        inactiveTrackColor: ThemeColors.dividerColor,
        thumbColor: ThemeColors.primary,
        overlayColor: ThemeColors.highlightColor,
        valueIndicatorColor: ThemeColors.primary,
        valueIndicatorTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
        trackHeight: 4,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ThemeColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 8,
        shape: CircleBorder(),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: ThemeColors.lightCardBackground,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ThemeColors.lightTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ThemeColors.lightTextPrimary,
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ThemeColors.neutralDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: ThemeColors.surface,
        deleteIconColor: ThemeColors.lightTextSecondary,
        disabledColor: ThemeColors.disabledButton,
        selectedColor: ThemeColors.primary,
        secondarySelectedColor: ThemeColors.primaryLight,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeColors.lightTextPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        brightness: Brightness.light,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ThemeColors.primary,
        linearTrackColor: ThemeColors.dividerColor,
        circularTrackColor: ThemeColors.dividerColor,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: ThemeColors.lightTextPrimary,
        size: 24,
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
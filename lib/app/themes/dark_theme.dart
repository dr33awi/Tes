// lib/app/themes/dark_theme.dart
import 'package:flutter/material.dart';
import 'theme_constants.dart';

class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ThemeColors.primary,
      scaffoldBackgroundColor: ThemeColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: ThemeColors.primaryLight,
        secondary: ThemeColors.primary,
        tertiary: ThemeColors.darkHighlightColor,
        error: ThemeColors.error,
        background: ThemeColors.darkBackground,
        surface: Colors.grey[850]!,
        onSurface: ThemeColors.darkTextPrimary,
        onBackground: ThemeColors.darkTextPrimary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: ThemeColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[850],
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
          backgroundColor: ThemeColors.primaryLight,
          foregroundColor: Colors.white,
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
          minimumSize: const Size(double.infinity, ThemeSizes.buttonHeight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ThemeColors.primaryLight,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.primaryLight,
          side: const BorderSide(color: ThemeColors.primaryLight),
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
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        displayMedium: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        displaySmall: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        headlineLarge: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        headlineSmall: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        titleSmall: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ThemeColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          color: Colors.grey[200],
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: Colors.grey[300],
        ),
        bodySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[800],
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: const BorderSide(
            color: ThemeColors.primaryLight,
            width: ThemeSizes.borderWidthThick,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginMedium,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[500],
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[700],
        thickness: ThemeSizes.borderWidthNormal,
        space: ThemeSizes.marginMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: ThemeColors.primaryLight,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ThemeColors.darkTextPrimary,
        unselectedLabelColor: Colors.grey[600],
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: ThemeColors.primaryLight,
              width: 3.0,
            ),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return ThemeColors.primaryLight;
          }
          return Colors.transparent;
        }),
        side: BorderSide(color: Colors.grey[400]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusSmall),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return ThemeColors.primaryLight;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return ThemeColors.primaryLight.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ThemeColors.primaryLight,
        inactiveTrackColor: ThemeColors.primaryLight.withOpacity(0.3),
        thumbColor: ThemeColors.primaryLight,
        overlayColor: ThemeColors.primaryLight.withOpacity(0.2),
        valueIndicatorColor: ThemeColors.primaryLight,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ThemeColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.grey[850],
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[800],
        contentTextStyle: const TextStyle(
          color: ThemeColors.darkTextPrimary,
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
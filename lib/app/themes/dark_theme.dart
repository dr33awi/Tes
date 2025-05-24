// lib/app/themes/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_constants.dart';

class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ThemeColors.primaryLight,
      scaffoldBackgroundColor: ThemeColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: ThemeColors.primaryLight,
        secondary: ThemeColors.accent,
        tertiary: ThemeColors.accentLight,
        error: ThemeColors.error,
        background: ThemeColors.darkBackground,
        surface: ThemeColors.darkCardBackground,
        onSurface: ThemeColors.darkTextPrimary,
        onBackground: ThemeColors.darkTextPrimary,
        onPrimary: ThemeColors.darkBackground,
        onSecondary: ThemeColors.darkBackground,
      ),
      useMaterial3: true,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeColors.darkBackground,
        foregroundColor: ThemeColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ThemeColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(
          color: ThemeColors.darkTextPrimary,
          size: 24,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: ThemeColors.darkBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: ThemeColors.darkCardBackground,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          vertical: ThemeSizes.marginSmall,
          horizontal: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          side: BorderSide(
            color: ThemeColors.primaryLight.withOpacity(0.1),
            width: ThemeSizes.borderWidthThin,
          ),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.primaryLight,
          foregroundColor: ThemeColors.darkBackground,
          disabledBackgroundColor: ThemeColors.disabledButton.withOpacity(0.3),
          disabledForegroundColor: ThemeColors.darkTextSecondary,
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
          foregroundColor: ThemeColors.accentLight,
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
          foregroundColor: ThemeColors.accentLight,
          side: BorderSide(
            color: ThemeColors.accentLight.withOpacity(0.5),
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
          color: ThemeColors.darkTextPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ThemeColors.darkTextPrimary,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ThemeColors.darkTextPrimary,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ThemeColors.darkTextPrimary,
          height: 1.4,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ThemeColors.darkTextPrimary,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ThemeColors.darkTextPrimary,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: ThemeColors.darkTextPrimary,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ThemeColors.darkTextPrimary,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ThemeColors.darkTextPrimary,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ThemeColors.darkTextPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ThemeColors.darkTextPrimary,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ThemeColors.darkTextSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ThemeColors.darkTextPrimary,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ThemeColors.darkTextPrimary,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ThemeColors.darkTextSecondary,
          height: 1.4,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        fillColor: ThemeColors.darkCardBackground,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginMedium,
          vertical: ThemeSizes.marginMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: ThemeColors.primaryLight.withOpacity(0.2),
            width: ThemeSizes.borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: ThemeColors.primaryLight.withOpacity(0.2),
            width: ThemeSizes.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
          borderSide: BorderSide(
            color: ThemeColors.primaryLight.withOpacity(0.6),
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
          color: ThemeColors.darkTextSecondary,
          fontFamily: 'Cairo',
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: ThemeColors.darkTextSecondary,
          fontFamily: 'Cairo',
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: ThemeColors.error,
          fontFamily: 'Cairo',
          fontSize: 12,
        ),
        prefixIconColor: ThemeColors.darkTextSecondary,
        suffixIconColor: ThemeColors.darkTextSecondary,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: ThemeColors.primaryLight.withOpacity(0.1),
        thickness: ThemeSizes.borderWidthThin,
        space: ThemeSizes.marginLarge,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.darkCardBackground,
        selectedItemColor: ThemeColors.accentLight,
        unselectedItemColor: ThemeColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        selectedIconTheme: const IconThemeData(
          size: 26,
        ),
        unselectedIconTheme: const IconThemeData(
          size: 24,
        ),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: ThemeColors.accentLight,
        unselectedLabelColor: ThemeColors.darkTextSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: ThemeColors.accentLight,
              width: 2.0,
            ),
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return ThemeColors.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(ThemeColors.darkBackground),
        side: BorderSide(
          color: ThemeColors.darkTextSecondary,
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
            return ThemeColors.accentLight;
          }
          return ThemeColors.darkTextSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return ThemeColors.primaryLight.withOpacity(0.5);
          }
          return ThemeColors.darkCardBackground;
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: ThemeColors.primaryLight,
        inactiveTrackColor: ThemeColors.primaryLight.withOpacity(0.2),
        thumbColor: ThemeColors.accentLight,
        overlayColor: ThemeColors.accentLight.withOpacity(0.2),
        valueIndicatorColor: ThemeColors.primaryLight,
        valueIndicatorTextStyle: const TextStyle(
          color: ThemeColors.darkBackground,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackHeight: 4,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ThemeColors.primaryLight,
        foregroundColor: ThemeColors.darkBackground,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 8,
        shape: const CircleBorder(),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: ThemeColors.darkCardBackground,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ThemeColors.darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ThemeColors.darkTextPrimary,
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ThemeColors.accentDark,
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
        backgroundColor: ThemeColors.darkCardBackground,
        deleteIconColor: ThemeColors.darkTextSecondary,
        disabledColor: ThemeColors.disabledButton.withOpacity(0.3),
        selectedColor: ThemeColors.primaryLight,
        secondarySelectedColor: ThemeColors.accent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeColors.darkTextPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeColors.darkBackground,
        ),
        brightness: Brightness.dark,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: ThemeColors.accentLight,
        linearTrackColor: ThemeColors.primaryLight.withOpacity(0.2),
        circularTrackColor: ThemeColors.primaryLight.withOpacity(0.2),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: ThemeColors.darkTextPrimary,
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
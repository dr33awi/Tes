// lib/app/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ألوان السمة الفاتحة
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: const Color(0xFF2E8B57), // أخضر متوسط
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF2E8B57),
      secondary: const Color(0xFF4CAF50),
      tertiary: const Color(0xFFE0F2F1),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      background: Colors.white,
      surface: Colors.white,
      error: Colors.red.shade700,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: Color(0xFF2E8B57),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        displayMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        displaySmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF2E8B57),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF2E8B57),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2E8B57),
        side: const BorderSide(color: Color(0xFF2E8B57)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2E8B57),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
    ),
  );

  // ألوان السمة الداكنة
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: const Color(0xFF388E3C), // أخضر داكن
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF388E3C),
      secondary: const Color(0xFF66BB6A),
      tertiary: const Color(0xFF1E3C32),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      error: Colors.red.shade400,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      color: Color(0xFF388E3C),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF66BB6A),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF388E3C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF66BB6A),
        side: const BorderSide(color: Color(0xFF66BB6A)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF66BB6A),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3E3E3E),
      thickness: 1,
    ),
  );
}
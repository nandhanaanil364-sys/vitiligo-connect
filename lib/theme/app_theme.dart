import 'package:flutter/material.dart';

class AppTheme {
  // Main pastel sage green
  static const Color primary = Color(0xFF8FB9A8);
  static const Color primaryDark = Color(0xFF5F8F7D);

  // Background
  static const Color background = Color(0xFFF8FAF8);

  // Cards and surfaces
  static const Color surface = Color(0xFFFFFFFF);

  // Pastel accent colors
  static const Color pastelPink = Color(0xFFF5D9DE);
  static const Color pastelBlue = Color(0xFFDCECF2);
  static const Color pastelGreen = Color(0xFFE1F0E8);
  static const Color pastelYellow = Color(0xFFF7EED7);

  // Text
  static const Color textDark = Color(0xFF34423C);
  static const Color textGrey = Color(0xFF78827E);

  static ThemeData theme = ThemeData(
    useMaterial3: true,

    // Main colors
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),

    // App background
    scaffoldBackgroundColor: background,

    // App bar
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
    ),

    // Text
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),

      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),

      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        color: textDark,
      ),

      bodyMedium: TextStyle(
        fontSize: 14,
        color: textGrey,
      ),
    ),

    // Text fields
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: surface,

      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Color(0xFFE2E8E4),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: primary,
          width: 2,
        ),
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,

        minimumSize: const Size(
          double.infinity,
          54,
        ),

        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,

      margin: EdgeInsets.zero,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),

        side: const BorderSide(
          color: Color(0xFFE8ECE9),
        ),
      ),
    ),

    // Bottom navigation
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,

      indicatorColor: pastelGreen,

      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
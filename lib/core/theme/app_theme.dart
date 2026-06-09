import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets/font_family.dart';

enum AppThemeMode { light, dark }

class AppTheme {
  // 🔵 Trust & Professional Theme (HomeEase)

  static const Color mainColor = Color(0xFF1E3A8A); // Deep Trust Blue
  static const Color mainDarkColor = Color(0xFF142B63); // Dark Blue

  static const Color secondColor = Color(0xFF14B8A6); // Calm Teal
  static const Color secondDarkColor = Color(0xFF0F766E); // Dark Teal

static const Color accentColor = Color(0xFF2563EB); // Professional Action Blue
static const Color accentDarkColor = Color(0xFF1D4ED8); // Dark Action Blue

  static const Color scaffoldColor = Color(0xFFF5F7FA); // Clean Light Grey
  static const Color scaffoldDarkColor = Color(0xFF1F2937); // Dark Grey

  // Additional colors for comprehensive theming
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFF59E0B);


static const rattingYellow = Color(0xFF14B8A6); // Theme Teal instead of Yellow
  static const Color redColor = Colors.red;

  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: FontFamily.fontsPoppinsRegular,
      brightness: Brightness.light,
      hintColor: textSecondaryLight,
      shadowColor: Colors.grey.withValues(alpha: 0.5),
      primaryColor: mainColor,
      primaryColorDark: mainDarkColor,
      scaffoldBackgroundColor: scaffoldColor,
      colorScheme: ColorScheme.light(
        outline: Color(0xFFE5E7EB),
        primary: mainColor,
        secondary: secondColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        surface: scaffoldColor,
        onSurface: textPrimaryLight,
        error: errorColor,
        onTertiary: redColor,
   onSurfaceVariant: secondColor,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimaryLight),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryLight),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // Light theme: Status bar WHITE, Icons BLACK
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor, // Action color
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: secondColor,
        labelStyle: TextStyle(color: textPrimaryLight),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: mainColor),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      dividerColor: Color(0xFFE5E7EB),
      iconTheme: IconThemeData(color: textPrimaryLight),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldColor,
        selectedItemColor: mainColor,
        unselectedItemColor: textSecondaryLight,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: FontFamily.fontsPoppinsRegular,
      hintColor: textSecondaryDark,
      shadowColor: Colors.grey.withValues(alpha: 0.5),
      primaryColor: const Color.fromARGB(255, 63, 117, 255),
      primaryColorDark: mainDarkColor,

      scaffoldBackgroundColor: scaffoldDarkColor,
      colorScheme: ColorScheme.dark(
        primary: const Color.fromARGB(255, 63, 117, 255),
        secondary: secondDarkColor,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        surface: scaffoldDarkColor,
        onSurface: textPrimaryDark,
        outline: Color(0xFF374151),
        onTertiary: redColor,
    onSurfaceVariant: secondDarkColor,

        error: errorColor,
      ),
      dividerTheme: DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: mainColor),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF374151),
        selectedColor: secondDarkColor,
        labelStyle: TextStyle(color: textPrimaryDark),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimaryDark),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: mainDarkColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // Dark theme: Status bar BLACK, Icons WHITE
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondDarkColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondDarkColor,
        foregroundColor: Colors.white,
      ),
      // cardTheme: CardTheme(
      //   color: Color(0xFF3A3A3A),
      //   elevation: 2,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(12),
      //   ),
      // ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF374151),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4B5563)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: mainColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerColor: Color(0xFF374151),
      iconTheme: IconThemeData(color: textPrimaryDark),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldDarkColor,
        elevation: 8,
        selectedItemColor: mainColor,
        unselectedItemColor: textSecondaryDark,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppConstants {
  // Default backend URL (Local dev or Railway production)
  static const String defaultBaseUrl = 'http://localhost:3100';
  
  // Storage Keys
  static const String keyStoreProfile = 'store_profile_data';
  static const String keyPrinterAddress = 'saved_printer_mac_address';
  static const String keyPrinterName = 'saved_printer_name';
  static const String keyPaperSize = 'saved_paper_size_mm'; // 58 or 80
  static const String keyBaseUrl = 'saved_api_base_url';
  static const String keyProducts = 'saved_local_products';
  static const String keyCategories = 'saved_local_categories';
}

class AppTheme {
  // Aksiva & Neo-Brutalist Palette
  static const Color primaryNavy = Color(0xFF01518E);
  static const Color accentOrange = Color(0xFFFA6800);
  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color backgroundSand = Color(0xFFF4F4F0);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderBlack = Color(0xFF000000);

  // Neo-Brutalist Box Shadow
  static List<BoxShadow> brutalistShadow({double offset = 4.0}) => [
    BoxShadow(
      color: borderBlack,
      offset: Offset(offset, offset),
      blurRadius: 0,
    ),
  ];

  static ThemeData get theme => themeData;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundSand,
      primaryColor: primaryNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: accentOrange,
        surface: backgroundSand,
      ),
      fontFamily: 'sans-serif',
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderBlack, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: borderBlack, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

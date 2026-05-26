import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
class AppColors {
  static const Color primary = Color(0xFF658C21);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFFE6EFD2);
  static const Color primaryActive = Color(0xFF78A12A);
  static const Color background = Color(0xFFEFDEC0);
  static const Color wave = Color(0xFFE7D4B1);
  static const Color waveLight = Color(0xFFF3E7D3);
  static const Color card = Colors.white;
  static const Color input = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;
  static const Color border = Color(0xFFE8DCC7);
  static const Color shadow = Color(0x14000000);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFE4B85C);
  static const Color error = Color(0xFFD97566);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF8F3EB);
  static const Color white = Colors.white;
}
 
class AppTheme {
  static const Color verdePrincipal = AppColors.primary;
  static const Color verdeOscuro = AppColors.primaryDark;
  static const Color verdeClaro = AppColors.primaryLight;
  static const Color crema = AppColors.background;
  static const Color textoPrincipal = AppColors.textPrimary;
  static const Color textoSecundario = AppColors.textSecondary;
  static const Color error = AppColors.error;
 
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: Colors.white,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.12),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.border, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.dmSans(
          color: AppColors.textHint,
          fontSize: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
      dividerColor: AppColors.border,
    );
  }
}
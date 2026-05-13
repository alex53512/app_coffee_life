import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Verdes principales (igual que la web)
  static const Color primary        = Color(0xFF658C21); // verde oliva web
  static const Color primaryDark    = Color(0xFF2E7D32); // verde oscuro web
  static const Color primaryLight   = Color(0xFF4CAF50); // verde acento web
  static const Color primaryActive  = Color(0xFF489D4A); // verde borde activo

  // Fondos
  static const Color background     = Color(0xFFEFDEC0); // beige web
  static const Color surfaceVariant = Color(0xFFF5EDD5); // beige más claro
  static const Color surface        = Color(0xFFFFFFFF);

  // Textos
  static const Color textPrimary    = Color(0xFF000000);
  static const Color textSecondary  = Color(0xFF4A5568); // gris oscuro web
  static const Color textHint       = Color(0xFFA8C4A8); // verde grisáceo web
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // Estados
  static const Color error          = Color(0xFFF62E2E); // rojo web
  static const Color border         = Color(0xFFD4C9A8);
}

class AppTheme {
  static const Color verdePrincipal = Color(0xFF658C21);
  static const Color verdeOscuro    = Color(0xFF2E7D32);
  static const Color verdeClaro     = Color(0xFF4CAF50);
  static const Color marronClaro    = Color(0xFFD2B48C);
  static const Color crema          = Color(0xFFEFDEC0); // beige web
  static const Color textoPrincipal = Color(0xFF000000);
  static const Color textoSecundario = Color(0xFF4A5568);
  static const Color error          = Color(0xFFF62E2E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

      textTheme: GoogleFonts.nunitoTextTheme(),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          color: AppColors.textHint,
          fontSize: 15,
        ),
      ),
    );
  }
}
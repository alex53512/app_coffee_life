import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {


  static const Color blancoCalido = Color(0xFFFFFEFB);

  static const Color marfilSuave = Color(0xFFFBF7EF);

  static const Color beigeCrema = Color(0xFFF4E7D6);

  static const Color arenaClaro = Color(0xFFEFDCC2);

  static const Color duraznoSuave = Color(0xFFF7E9DA);

  static const Color beigeRosado = Color(0xFFF2DDC4);

  static const Color cafeClaro = Color(0xFFD8B98F);


  static const Color verdeOscuro = Color(0xFF4F8F1F);

  static const Color verdeClaro = Color(0xFFB5D75C);


  static const Color primary = verdeOscuro;

  static const Color primaryDark = verdeOscuro;

  static const Color primaryLight = verdeClaro;

  static const Color primaryActive = verdeOscuro;


  static const Color background = blancoCalido;

  static const Color wave = arenaClaro;

  static const Color waveLight = duraznoSuave;

  static const Color card = marfilSuave;

  static const Color input = Colors.white;


  static const Color textPrimary = Color(0xFF1A1A1A);

  static const Color textSecondary = Color(0xFF6B7280);

  static const Color textHint = Color(0xFF9CA3AF);

  static const Color textOnPrimary = Colors.white;


  static const Color border = beigeRosado;


  static const Color shadow = Color(0x14000000);


  static const Color success = Color(0xFF4CAF50);

  static const Color warning = Color(0xFFE4B85C);

  static const Color error = Color(0xFFD97566);


  static const Color surface = Colors.white;

  static const Color surfaceVariant = marfilSuave;

  static const Color white = Colors.white;


  static Color cardBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C241E)
        : Colors.white;
  }

  static Color surfaceVariantBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D322A)
        : const Color(0xFFFBF7EF);
  }

  static Color successBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E3A1E)
        : const Color(0xFFE8F5E9);
  }

  static Color warningBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D2E1B)
        : const Color(0xFFFFF8E1);
  }

  static Color infoBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E2D3A)
        : const Color(0xFFF1F8E9);
  }

  static Color headerBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C241E)
        : const Color(0xFFF4E7D6);
  }

  static Color inputFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D322A)
        : Colors.white;
  }

  static Color warningLightBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D2E1B)
        : const Color(0xFFFFF3E0);
  }
}

class AppTheme {


  static const Color verdePrincipal = AppColors.primary;

  static const Color verdeOscuro = AppColors.verdeOscuro;

  static const Color verdeClaro = AppColors.verdeClaro;

  static const Color crema = AppColors.background;

  static const Color textoPrincipal = AppColors.textPrimary;

  static const Color textoSecundario = AppColors.textSecondary;

  static const Color error = AppColors.error;



  static ThemeData get darkTheme {
    const scaffoldBg = Color(0xFF1C1612);
    const surfaceBg = Color(0xFF2C241E);
    const surfaceVariantBg = Color(0xFF3D322A);
    const textPrimary = Color(0xFFF0EAE4);
    const textSecondary = Color(0xFFA89888);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.verdeClaro,
        secondary: AppColors.verdeClaro,
        surface: surfaceBg,
        error: const Color(0xFFE57373),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verdeClaro,
          foregroundColor: const Color(0xFF1C1612),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verdeClaro,
          backgroundColor: surfaceBg,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: textSecondary.withOpacity(0.4), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.nunito(color: textSecondary, fontSize: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: textSecondary.withOpacity(0.3), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.verdeClaro, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withOpacity(0.4),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: textSecondary.withOpacity(0.15), width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceBg,
        selectedItemColor: AppColors.verdeClaro,
        unselectedItemColor: textSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: const IconThemeData(color: AppColors.verdeClaro),
      dividerColor: textSecondary.withOpacity(0.2),
    );
  }

  static ThemeData get lightTheme {

    return ThemeData(

      useMaterial3: true,

      scaffoldBackgroundColor:
          AppColors.background,


      colorScheme: ColorScheme.fromSeed(

        seedColor:
            AppColors.primary,

        primary:
            AppColors.primary,

        secondary:
            AppColors.verdeClaro,

        surface:
            AppColors.marfilSuave,

        error:
            AppColors.error,

        brightness:
            Brightness.light,
      ),


      textTheme:
          GoogleFonts.nunitoTextTheme(),


      appBarTheme: AppBarTheme(

        backgroundColor:
            AppColors.blancoCalido,

        foregroundColor:
            AppColors.textPrimary,

        elevation: 0,

        centerTitle: true,

        scrolledUnderElevation: 0,

        surfaceTintColor:
            Colors.transparent,

        iconTheme:
            const IconThemeData(
          color:
              AppColors.textPrimary,
        ),

        titleTextStyle:
            GoogleFonts.nunito(
          fontSize: 20,
          fontWeight:
              FontWeight.w800,
          color:
              AppColors.textPrimary,
        ),
      ),


      elevatedButtonTheme:
          ElevatedButtonThemeData(

        style:
            ElevatedButton.styleFrom(

          backgroundColor:
              AppColors.primary,

          foregroundColor:
              Colors.white,

          elevation: 2,

          shadowColor:
              Colors.black.withOpacity(0.12),

          minimumSize:
              const Size(
            double.infinity,
            54,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    18),
          ),

          textStyle:
              GoogleFonts.nunito(
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),


      outlinedButtonTheme:
          OutlinedButtonThemeData(

        style:
            OutlinedButton.styleFrom(

          foregroundColor:
              AppColors.primary,

          backgroundColor:
              AppColors.blancoCalido,

          minimumSize:
              const Size(
            double.infinity,
            54,
          ),

          side:
              const BorderSide(
            color:
                AppColors.border,
            width: 1.4,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    18),
          ),

          textStyle:
              GoogleFonts.nunito(
            fontSize: 15,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),


      inputDecorationTheme:
          InputDecorationTheme(

        filled: true,

        fillColor:
            AppColors.blancoCalido,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        hintStyle:
            GoogleFonts.nunito(
          color:
              AppColors.textHint,
          fontSize: 15,
        ),

        enabledBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(
                  18),

          borderSide:
              const BorderSide(
            color:
                AppColors.border,
            width: 1.4,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(
                  18),

          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
            width: 2,
          ),
        ),

        errorBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(
                  18),

          borderSide:
              const BorderSide(
            color:
                AppColors.error,
            width: 1.5,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(
                  18),

          borderSide:
              const BorderSide(
            color:
                AppColors.error,
            width: 2,
          ),
        ),
      ),


      cardTheme: CardThemeData(

        color:
            AppColors.marfilSuave,

        elevation: 0,

        margin:
            EdgeInsets.zero,

        shadowColor:
            Colors.black.withOpacity(
                0.05),

        surfaceTintColor:
            Colors.transparent,

        shape:
            RoundedRectangleBorder(

          borderRadius:
              BorderRadius.circular(
                  22),

          side:
              const BorderSide(
            color:
                AppColors.border,
            width: 1,
          ),
        ),
      ),


      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(

        backgroundColor:
            AppColors.blancoCalido,

        selectedItemColor:
            AppColors.primary,

        unselectedItemColor:
            AppColors.textSecondary,

        elevation: 10,

        type:
            BottomNavigationBarType.fixed,
      ),


      iconTheme:
          const IconThemeData(
        color:
            AppColors.primary,
      ),


      dividerColor:
          AppColors.border,
    );
  }

  static String formatFechaColombia(dynamic fechaStr, {bool withTime = true}) {
    final raw = fechaStr?.toString() ?? '';
    if (raw.isEmpty) return 'Sin fecha';

    DateTime? dt;
    try {
      dt = DateTime.parse(raw).toUtc().add(const Duration(hours: -5));
    } catch (_) {
      debugPrint('formatFechaColombia: no se pudo parsear "$raw"');
      return raw;
    }

    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final fecha = '${dt.day.toString().padLeft(2,'0')} ${meses[dt.month-1]} ${dt.year}';
    if (!withTime) return fecha;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final h12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    return '$fecha · ${h12.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} $ampm';
  }
}
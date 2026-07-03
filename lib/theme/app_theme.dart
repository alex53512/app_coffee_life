import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {

  // =========================================================
  // COLORES PRINCIPALES
  // =========================================================

  /// Fondo principal de la app
  /// Ideal para Scaffold y pantallas completas
  static const Color blancoCalido = Color(0xFFFFFEFB);

  /// Base clara secundaria
  /// Úsalo en cards, contenedores o secciones suaves
  static const Color marfilSuave = Color(0xFFFBF7EF);

  /// Degradado superior
  /// Perfecto para headers y fondos elegantes
  static const Color beigeCrema = Color(0xFFF4E7D6);

  /// Ondas inferiores o decoraciones
  /// Bueno para formas curvas o fondos inferiores
  static const Color arenaClaro = Color(0xFFEFDCC2);

  /// Capas transparentes o overlays suaves
  /// Útil para sombras ligeras o efectos glass
  static const Color duraznoSuave = Color(0xFFF7E9DA);

  /// Sombras suaves y profundidad
  /// Excelente para bordes y elevaciones suaves
  static const Color beigeRosado = Color(0xFFF2DDC4);

  /// Detalles cálidos mínimos
  /// Para íconos, líneas decorativas o pequeños detalles
  static const Color cafeClaro = Color(0xFFD8B98F);

  // =========================================================
  // COLORES VERDES
  // =========================================================

  /// Verde principal
  /// Botones, textos importantes y acciones principales
  static const Color verdeOscuro = Color(0xFF4F8F1F);

  /// Verde secundario
  /// Indicadores, estados activos y detalles visuales
  static const Color verdeClaro = Color(0xFFB5D75C);

  // =========================================================
  // ALIASES SEMÁNTICOS (para uso en toda la app)
  // =========================================================

  // VERDE PRINCIPAL
  static const Color primary = verdeOscuro;

  // VERDE OSCURO
  static const Color primaryDark = verdeOscuro;

  // VERDE CLARO
  static const Color primaryLight = verdeClaro;

  // VERDE ACTIVO
  static const Color primaryActive = verdeOscuro;

  // =========================================================
  // FONDOS
  // =========================================================

  // FONDO PRINCIPAL
  static const Color background = blancoCalido;

  // OLAS DECORATIVAS
  static const Color wave = arenaClaro;

  static const Color waveLight = duraznoSuave;

  // TARJETAS
  static const Color card = marfilSuave;

  // INPUTS
  static const Color input = Colors.white;

  // =========================================================
  // TEXTOS
  // =========================================================

  static const Color textPrimary = Color(0xFF1A1A1A);

  static const Color textSecondary = Color(0xFF6B7280);

  static const Color textHint = Color(0xFF9CA3AF);

  static const Color textOnPrimary = Colors.white;

  // =========================================================
  // BORDES
  // =========================================================

  static const Color border = beigeRosado;

  // =========================================================
  // SOMBRAS
  // =========================================================

  static const Color shadow = Color(0x14000000);

  // =========================================================
  // ALERTAS
  // =========================================================

  static const Color success = Color(0xFF4CAF50);

  static const Color warning = Color(0xFFE4B85C);

  static const Color error = Color(0xFFD97566);

  // =========================================================
  // COMPATIBILIDAD
  // =========================================================

  static const Color surface = Colors.white;

  static const Color surfaceVariant = marfilSuave;

  static const Color white = Colors.white;
}

class AppTheme {

  // ── Helper de fecha con timezone Colombia (UTC-5) ────────

  /// Parsea [fechaStr] (ISO 8601) y devuelve fecha + hora en hora
  /// local (Colombia UTC-5). Si el string trae un offset explícito
  /// (Z, +HH:MM, -HH:MM), lo usa; si no, asume que ya está en hora local.
  static String formatFechaColombia(dynamic fechaStr, {bool withTime = true}) {
    final raw = fechaStr?.toString() ?? '';
    if (raw.isEmpty) return 'Sin fecha';

    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})').firstMatch(raw);
    debugPrint('⏰ raw="$raw" match=${m?.group(0)}');
    if (m == null) return raw;

    int h = int.parse(m[4]!);
    final int min = int.parse(m[5]!);
    int d = int.parse(m[3]!);
    final int mes = int.parse(m[2]!);
    final int anio = int.parse(m[1]!);

    if (raw.endsWith('Z')) {
      h -= 5;
      debugPrint('⏰ UTC detectado: h=$h tras -5');
    } else {
      final tz = RegExp(r'([+-])(\d{2}):(\d{2})$').firstMatch(raw);
      if (tz != null) {
        final signo = tz[1]!;
        final tzh = int.parse(tz[2]!);
        h += (signo == '-' ? tzh : -tzh) - 5;
        debugPrint('⏰ offset ${signo}${tzh} detectado: h=$h');
      } else {
        debugPrint('⏰ sin timezone: h=$h (asumido local)');
      }
    }

    if (h < 0) { h += 24; d -= 1; }
    if (h > 23) { h -= 24; d += 1; }
    int dAjustado = d;
    if (dAjustado < 1) { dAjustado = 1; }

    const meses = [
      'Ene','Feb','Mar','Abr','May','Jun',
      'Jul','Ago','Sep','Oct','Nov','Dic'
    ];
    final fecha = '${dAjustado.toString().padLeft(2,'0')} ${meses[mes-1]} $anio';
    if (!withTime) return fecha;
    return '$fecha · ${h.toString().padLeft(2,'0')}:${min.toString().padLeft(2,'0')}';
  }

  // =========================================================
  // COMPATIBILIDAD CON TU APP
  // =========================================================

  static const Color verdePrincipal = AppColors.primary;

  static const Color verdeOscuro = AppColors.verdeOscuro;

  static const Color verdeClaro = AppColors.verdeClaro;

  static const Color crema = AppColors.background;

  static const Color textoPrincipal = AppColors.textPrimary;

  static const Color textoSecundario = AppColors.textSecondary;

  static const Color error = AppColors.error;

  // =========================================================
  // THEME
  // =========================================================

  static ThemeData get lightTheme {

    return ThemeData(

      useMaterial3: true,

      scaffoldBackgroundColor:
          AppColors.background,

      // =====================================================
      // COLOR SCHEME
      // =====================================================

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

      // =====================================================
      // TIPOGRAFÍA
      // =====================================================

      textTheme:
          GoogleFonts.nunitoTextTheme(),

      // =====================================================
      // APP BAR
      // =====================================================

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

      // =====================================================
      // BOTONES
      // =====================================================

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

      // =====================================================
      // OUTLINED BUTTON
      // =====================================================

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

      // =====================================================
      // INPUTS
      // =====================================================

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

      // =====================================================
      // CARDS
      // =====================================================

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

      // =====================================================
      // NAVBAR
      // =====================================================

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

      // =====================================================
      // ICONOS
      // =====================================================

      iconTheme:
          const IconThemeData(
        color:
            AppColors.primary,
      ),

      // =====================================================
      // DIVIDERS
      // =====================================================

      dividerColor:
          AppColors.border,
    );
  }
}
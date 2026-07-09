import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

Widget sinDatosHelper({required IconData icono, required String titulo, required String mensaje}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: Icon(icono, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(mensaje, textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      ],
    ),
  );
}

Widget seccionTituloHelper(String titulo) {
  return Text(titulo,
      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary));
}

Widget cardHelper({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: child,
  );
}

Widget infoFilaHelper(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    ],
  );
}

Widget infoFilaColorHelper(String label, String value, Color color) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    ],
  );
}

Widget imagenPlaceholderHelper() {
  return Container(
    color: const Color(0xFFE8F5E9),
    child: const Center(child: Icon(Icons.eco_outlined, color: Colors.green, size: 40)),
  );
}

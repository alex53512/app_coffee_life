import 'package:flutter/material.dart';
import '../models/recomendacion.dart';

class DetalleIconColor {
  final IconData icon;
  final Color color;
  const DetalleIconColor(this.icon, this.color);
}

class DetalleRecomendacionIA {
  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final List<String> tratamientos;
  final RecomendacionDetalle? detalle;
  const DetalleRecomendacionIA(this.icon, this.color, this.titulo, this.subtitulo,
      {this.tratamientos = const [], this.detalle});
}

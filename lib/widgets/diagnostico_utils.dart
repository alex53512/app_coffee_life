import 'package:flutter/material.dart';
import '../models/recomendacion.dart';

class DiagnosticoIconColor {
  final IconData icon;
  final Color color;
  const DiagnosticoIconColor(this.icon, this.color);
}

class DiagnosticoRec {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> tratamientos;
  final RecomendacionDetalle? detalle;
  const DiagnosticoRec(this.icon, this.color, this.title, this.subtitle,
      {this.tratamientos = const [], this.detalle});
}

class CornerPainter extends CustomPainter {
  final bool top, left;
  const CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

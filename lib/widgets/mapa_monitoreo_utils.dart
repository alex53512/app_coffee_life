import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const Color amarilloRiesgoLote = Color(0xFFFBC02D);

Color riesgoColor(int nivel) => switch (nivel) {
      1 => AppColors.primary,
      2 => amarilloRiesgoLote,
      3 => Colors.red,
      _ => AppColors.primary,
    };

String riesgoLabel(int nivel) => switch (nivel) {
      1 => 'Bajo',
      2 => 'Medio',
      3 => 'Alto',
      _ => 'Sin datos',
    };

class LoteLayout {
  final List<Offset> centers;
  final List<List<Offset>> cells;
  const LoteLayout(this.centers, this.cells);
}

List<Offset> generarSemillas(Size size, int n) {
  if (n <= 0) return [];
  if (n == 1) return [Offset(size.width / 2, size.height / 2)];

  final marginX = size.width * 0.10;
  final marginY = size.height * 0.10;
  final minDist =
      math.sqrt(size.width * size.height / n) * (n <= 3 ? 0.7 : 0.45);
  final rnd = math.Random(7000 + n * 131);

  Offset puntoAleatorio() => Offset(
        marginX + rnd.nextDouble() * (size.width - marginX * 2),
        marginY + rnd.nextDouble() * (size.height - marginY * 2),
      );

  final seeds = <Offset>[];
  int attempts = 0;
  while (seeds.length < n && attempts < n * 300) {
    attempts++;
    final p = puntoAleatorio();
    final tooClose = seeds.any((s) => (s - p).distance < minDist);
    if (!tooClose) seeds.add(p);
  }
  while (seeds.length < n) {
    seeds.add(puntoAleatorio());
  }
  return seeds;
}

List<double> generarPesos(Size size, int n) {
  if (n <= 0) return [];
  final rnd = math.Random(5000 + n * 97);
  final escala = size.width * size.height / n;
  return List.generate(
      n, (_) => (rnd.nextDouble() - 0.5) * 2 * escala * 0.5);
}

List<Offset> clipHalfPlane(List<Offset> poly, Offset normal, double c) {
  if (poly.isEmpty) return poly;
  final out = <Offset>[];
  for (int i = 0; i < poly.length; i++) {
    final curr = poly[i];
    final next = poly[(i + 1) % poly.length];
    final dCurr = curr.dx * normal.dx + curr.dy * normal.dy - c;
    final dNext = next.dx * normal.dx + next.dy * normal.dy - c;
    if (dCurr <= 0) out.add(curr);
    if ((dCurr < 0 && dNext > 0) || (dCurr > 0 && dNext < 0)) {
      final t = dCurr / (dCurr - dNext);
      out.add(Offset(
        curr.dx + t * (next.dx - curr.dx),
        curr.dy + t * (next.dy - curr.dy),
      ));
    }
  }
  return out;
}

List<List<Offset>> calcularCeldasVoronoi(
    Size size, List<Offset> seeds, List<double> weights) {
  final rect = [
    const Offset(0, 0),
    Offset(size.width, 0),
    Offset(size.width, size.height),
    Offset(0, size.height),
  ];
  final cells = <List<Offset>>[];
  for (int i = 0; i < seeds.length; i++) {
    var poly = List<Offset>.from(rect);
    final s = seeds[i];
    final wS = weights[i];
    for (int j = 0; j < seeds.length; j++) {
      if (i == j) continue;
      final t = seeds[j];
      final wT = weights[j];
      final normal = Offset(t.dx - s.dx, t.dy - s.dy);
      final c = ((t.dx * t.dx + t.dy * t.dy - wT) -
              (s.dx * s.dx + s.dy * s.dy - wS)) /
          2;
      poly = clipHalfPlane(poly, normal, c);
      if (poly.isEmpty) break;
    }
    cells.add(poly);
  }
  return cells;
}

const double factorEscalaLote = 0.92;

List<Offset> encogerPoligono(List<Offset> poly, double factor) {
  if (poly.isEmpty) return poly;
  double cx = 0, cy = 0;
  for (final p in poly) {
    cx += p.dx;
    cy += p.dy;
  }
  cx /= poly.length;
  cy /= poly.length;
  return poly
      .map((p) => Offset(
            cx + (p.dx - cx) * factor,
            cy + (p.dy - cy) * factor,
          ))
      .toList();
}

LoteLayout computeLoteLayout(Size size, int n) {
  if (n <= 0 || size.width <= 0 || size.height <= 0) {
    return const LoteLayout([], []);
  }
  if (n == 1) {
    final rect = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    return LoteLayout(
      [Offset(size.width / 2, size.height / 2)],
      [encogerPoligono(rect, factorEscalaLote)],
    );
  }
  final seeds = generarSemillas(size, n);
  final weights = generarPesos(size, n);
  final cells = calcularCeldasVoronoi(size, seeds, weights)
      .map((celda) => encogerPoligono(celda, factorEscalaLote))
      .toList();
  return LoteLayout(seeds, cells);
}

bool puntoEnPoligono(Offset p, List<Offset> poly) {
  if (poly.length < 3) return false;
  bool inside = false;
  for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i];
    final b = poly[j];
    if (((a.dy > p.dy) != (b.dy > p.dy)) &&
        (p.dx < a.dx + (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy))) {
      inside = !inside;
    }
  }
  return inside;
}

List<Offset> bordeFacetado(Offset a, Offset b) {
  final length = (b - a).distance;
  if (length < 14) return [a, b];

  final reversed = (a.dx > b.dx) || (a.dx == b.dx && a.dy > b.dy);
  final p1 = reversed ? b : a;
  final p2 = reversed ? a : b;

  final seed = ((p1.dx * 131.7).round() +
          (p1.dy * 743.3).round() +
          (p2.dx * 977.1).round() +
          (p2.dy * 53.9).round())
      .abs();
  final rnd = math.Random(seed);

  final dir = Offset((p2.dx - p1.dx) / length, (p2.dy - p1.dy) / length);
  final normal = Offset(-dir.dy, dir.dx);

  final nSeg = (length / 24).clamp(2, 7).round();
  final amplitude = (length * 0.05).clamp(2.5, 10.0);

  final pts = <Offset>[p1];
  for (int k = 1; k < nSeg; k++) {
    final t = k / nSeg;
    final base = Offset(
      p1.dx + (p2.dx - p1.dx) * t,
      p1.dy + (p2.dy - p1.dy) * t,
    );
    final taper = math.sin(t * math.pi);
    final off = (rnd.nextDouble() * 2 - 1) * amplitude * taper;
    pts.add(Offset(base.dx + normal.dx * off, base.dy + normal.dy * off));
  }
  pts.add(p2);

  return reversed ? pts.reversed.toList() : pts;
}

Path poligonoOrganico(List<Offset> pts) {
  final path = Path();
  final n = pts.length;
  if (n < 3) {
    if (n > 0) path.addPolygon(pts, true);
    return path;
  }
  bool first = true;
  for (int i = 0; i < n; i++) {
    final a = pts[i];
    final b = pts[(i + 1) % n];
    final borde = bordeFacetado(a, b);
    if (first) {
      path.moveTo(borde.first.dx, borde.first.dy);
      first = false;
    }
    for (int k = 1; k < borde.length; k++) {
      path.lineTo(borde[k].dx, borde[k].dy);
    }
  }
  path.close();
  return path;
}

double radioPromedio(Size size, int n) {
  if (n <= 0) return 60;
  final area = size.width * size.height / n;
  return math.sqrt(area) * 0.5;
}

class MapaFincaPainter extends CustomPainter {
  final List<LoteRiesgo> lotes;
  final int? selectedIdCultivo;

  MapaFincaPainter({required this.lotes, this.selectedIdCultivo});

  void _drawPin(Canvas canvas, Offset center, Color color,
      {bool selected = false}) {
    final r = selected ? 11.0 : 9.0;
    final pinTop = Offset(center.dx, center.dy - r * 2.2);

    canvas.drawCircle(
      pinTop.translate(1, 1),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    final tipPath = Path()
      ..moveTo(center.dx - r * 0.55, pinTop.dy + r * 0.65)
      ..lineTo(center.dx, pinTop.dy + r * 1.9)
      ..lineTo(center.dx + r * 0.55, pinTop.dy + r * 0.65)
      ..close();
    canvas.drawPath(tipPath,
        Paint()..color = selected ? color : Colors.white);
    canvas.drawPath(
      tipPath,
      Paint()
        ..color = selected ? Colors.white.withValues(alpha: 0.4) : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.drawCircle(pinTop, r,
        Paint()..color = selected ? color : Colors.white);
    canvas.drawCircle(
      pinTop,
      r,
      Paint()
        ..color = selected ? Colors.white.withValues(alpha: 0.5) : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.0 : 1.8,
    );

    canvas.drawCircle(
      pinTop,
      r * 0.38,
      Paint()..color = selected ? Colors.white : color,
    );
  }

  void _drawLabel(Canvas canvas, Offset center, LoteRiesgo lote,
      double refSize) {
    final color = riesgoColor(lote.nivel);
    final label = lote.nivel == 0 ? 'Sin datos' : riesgoLabel(lote.nivel);
    final nameFontSize = (refSize * 0.22).clamp(9.0, 13.0);
    final riskFontSize = (refSize * 0.16).clamp(7.0, 10.0);

    final tp = TextPainter(
      text: TextSpan(
        text: lote.nombre,
        style: TextStyle(
          color: Colors.white,
          fontSize: nameFontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: refSize * 1.4);

    final labelY = center.dy + refSize * 0.18;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, labelY + tp.height / 2),
          width: tp.width + 14,
          height: tp.height + 8,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );
    tp.paint(canvas, Offset(center.dx - tp.width / 2, labelY));

    final tp2 = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: riskFontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final riskY = labelY + tp.height + 12;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, riskY),
          width: tp2.width + 14,
          height: tp2.height + 8,
        ),
        const Radius.circular(9),
      ),
      Paint()..color = color.withValues(alpha: 0.38),
    );
    tp2.paint(
        canvas, Offset(center.dx - tp2.width / 2, riskY - tp2.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (lotes.isEmpty) return;

    final layout = computeLoteLayout(size, lotes.length);
    if (layout.cells.isEmpty) return;

    final refSize = radioPromedio(size, lotes.length);

    for (int i = 0; i < lotes.length; i++) {
      final lote = lotes[i];
      final cellPts = layout.cells[i];
      if (cellPts.length < 3) continue;

      final color = riesgoColor(lote.nivel);
      final isSel =
          selectedIdCultivo != null && lote.idCultivo == selectedIdCultivo;

      final path = poligonoOrganico(cellPts);

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: isSel ? 0.62 : 0.46)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: isSel ? 1.0 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 3.2 : 2.0,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    for (int i = 0; i < lotes.length; i++) {
      final lote = lotes[i];
      final center = layout.centers[i];
      final color = riesgoColor(lote.nivel);
      final isSel =
          selectedIdCultivo != null && lote.idCultivo == selectedIdCultivo;

      _drawPin(canvas, center, color, selected: isSel);
      if (isSel) _drawLabel(canvas, center, lote, refSize);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant MapaFincaPainter old) =>
      old.lotes != lotes || old.selectedIdCultivo != selectedIdCultivo;
}

class LoteRiesgo {
  final int idCultivo;
  final String nombre;
  final int nivel;

  const LoteRiesgo({
    required this.idCultivo,
    required this.nombre,
    required this.nivel,
  });
}

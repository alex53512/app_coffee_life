import 'dart:math' as math;
 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import 'monitoreo_detalle_screen.dart';
 
// ─── Helpers generales ────────────────────────────────────────────────────────
 
int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
double? _toDouble(dynamic v) =>
    v == null ? null : double.tryParse(v.toString());
 
/// Amarillo usado para el riesgo "Medio" de los lotes (mapa y leyendas).
const Color _amarilloRiesgoLote = Color(0xFFFBC02D);
 
Color _riesgoColor(int nivel) => switch (nivel) {
      1 => AppColors.primary,
      2 => _amarilloRiesgoLote,
      3 => Colors.red,
      _ => AppColors.primary,
    };
 
String _riesgoLabel(int nivel) => switch (nivel) {
      1 => 'Bajo',
      2 => 'Medio',
      3 => 'Alto',
      _ => 'Sin datos',
    };
 
// ─── Layout tipo Voronoi (lotes irregulares que encajan entre sí) ────────────
 
class _LoteLayout {
  final List<Offset> centers;
  final List<List<Offset>> cells;
  const _LoteLayout(this.centers, this.cells);
}
 
/// Genera puntos "semilla" repartidos por el lienzo (uno por lote) de forma
/// realmente aleatoria (con una semilla fija para que no "salte" en cada
/// rebuild), evitando que queden demasiado pegados entre sí. Esto, sumado a
/// los pesos de `_generarPesos`, hace que cada lote termine con una forma y
/// un tamaño distintos a los demás, en vez de polígonos parecidos.
List<Offset> _generarSemillas(Size size, int n) {
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
  // Si el espacio no alcanzó para respetar la distancia mínima, se completa
  // sin esa restricción (mejor tener el lote visible que perderlo).
  while (seeds.length < n) {
    seeds.add(puntoAleatorio());
  }
  return seeds;
}
 
/// Genera un "peso" aleatorio por lote para un diagrama de Voronoi ponderado
/// (power diagram): entre más peso tiene una semilla, más territorio gana
/// frente a sus vecinas. Así, aunque dos lotes estén cerca, sus formas y
/// tamaños finales se ven claramente distintos entre sí.
List<double> _generarPesos(Size size, int n) {
  if (n <= 0) return [];
  final rnd = math.Random(5000 + n * 97);
  final escala = size.width * size.height / n;
  return List.generate(
      n, (_) => (rnd.nextDouble() - 0.5) * 2 * escala * 0.5);
}
 
/// Recorta un polígono convexo contra un semiplano (Sutherland–Hodgman).
/// Se conservan los puntos donde dot(P, normal) <= c.
List<Offset> _clipHalfPlane(List<Offset> poly, Offset normal, double c) {
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
 
/// Calcula las celdas de un diagrama de Voronoi ponderado (una por semilla),
/// recortadas al rectángulo del lienzo. El resultado son polígonos
/// irregulares que encajan perfectamente entre sí, como parcelas reales,
/// cada uno con un tamaño y forma distintos según su peso.
List<List<Offset>> _calcularCeldasVoronoi(
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
      poly = _clipHalfPlane(poly, normal, c);
      if (poly.isEmpty) break;
    }
    cells.add(poly);
  }
  return cells;
}
 
/// Factor de escala aplicado a cada lote respecto a su propio centro,
/// para que no ocupen el 100% del mapa y quede un pequeño espacio
/// (de "calle") visible entre lotes vecinos.
const double _factorEscalaLote = 0.92;
 
/// Encoge un polígono hacia su propio centro (promedio de sus vértices)
/// según [factor] (1.0 = tamaño original, valores menores = más pequeño).
List<Offset> _encogerPoligono(List<Offset> poly, double factor) {
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
 
_LoteLayout _computeLoteLayout(Size size, int n) {
  if (n <= 0 || size.width <= 0 || size.height <= 0) {
    return const _LoteLayout([], []);
  }
  if (n == 1) {
    final rect = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    return _LoteLayout(
      [Offset(size.width / 2, size.height / 2)],
      [_encogerPoligono(rect, _factorEscalaLote)],
    );
  }
  final seeds = _generarSemillas(size, n);
  final weights = _generarPesos(size, n);
  final cells = _calcularCeldasVoronoi(size, seeds, weights)
      .map((celda) => _encogerPoligono(celda, _factorEscalaLote))
      .toList();
  return _LoteLayout(seeds, cells);
}
 
/// Test punto-en-polígono (ray casting), usado para detectar toques.
bool _puntoEnPoligono(Offset p, List<Offset> poly) {
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
 
/// Genera una versión "facetada" e irregular del segmento a→b, como el
/// borde real de una parcela vista desde arriba (no una línea recta
/// perfecta). La semilla aleatoria se calcula a partir de las coordenadas
/// del propio segmento en un orden canónico (sin importar si se recorre de
/// a→b o de b→a), así que cuando dos lotes vecinos comparten ese borde,
/// ambos dibujan exactamente la misma línea quebrada y no queda ningún
/// hueco entre ellos.
List<Offset> _bordeFacetado(Offset a, Offset b) {
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
    // El desplazamiento es 0 en los extremos (para que las esquinas sigan
    // coincidiendo) y máximo cerca del centro del borde.
    final taper = math.sin(t * math.pi);
    final off = (rnd.nextDouble() * 2 - 1) * amplitude * taper;
    pts.add(Offset(base.dx + normal.dx * off, base.dy + normal.dy * off));
  }
  pts.add(p2);
 
  return reversed ? pts.reversed.toList() : pts;
}
 
/// Convierte una lista de vértices del Voronoi en un Path con bordes
/// facetados (irregulares), para que cada lote se vea como una parcela
/// real, con su propia forma distintiva, en vez de un polígono limpio.
Path _poligonoOrganico(List<Offset> pts) {
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
    final borde = _bordeFacetado(a, b);
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
 
double _radioPromedio(Size size, int n) {
  if (n <= 0) return 60;
  final area = size.width * size.height / n;
  return math.sqrt(area) * 0.5;
}
 
// ─── Painter principal ────────────────────────────────────────────────────────
 
class _MapaFincaPainter extends CustomPainter {
  final List<_LoteRiesgo> lotes;
  final int? selectedIdCultivo;
 
  _MapaFincaPainter({required this.lotes, this.selectedIdCultivo});
 
  // ── Pin estilo "drop pin" ─────────────────────────────────────────────────
 
  void _drawPin(Canvas canvas, Offset center, Color color,
      {bool selected = false}) {
    final r = selected ? 11.0 : 9.0;
    final pinTop = Offset(center.dx, center.dy - r * 2.2);
 
    // Sombra
    canvas.drawCircle(
      pinTop.translate(1, 1),
      r,
      Paint()..color = Colors.black.withOpacity(0.25),
    );
 
    // Punta triangular
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
        ..color = selected ? Colors.white.withOpacity(0.4) : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
 
    // Círculo principal
    canvas.drawCircle(pinTop, r,
        Paint()..color = selected ? color : Colors.white);
    canvas.drawCircle(
      pinTop,
      r,
      Paint()
        ..color = selected ? Colors.white.withOpacity(0.5) : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.0 : 1.8,
    );
 
    // Punto interior
    canvas.drawCircle(
      pinTop,
      r * 0.38,
      Paint()..color = selected ? Colors.white : color,
    );
  }
 
  // ── Etiqueta del lote seleccionado ───────────────────────────────────────
 
  void _drawLabel(Canvas canvas, Offset center, _LoteRiesgo lote,
      double refSize) {
    final color = _riesgoColor(lote.nivel);
    final label = lote.nivel == 0 ? 'Sin datos' : _riesgoLabel(lote.nivel);
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
      Paint()..color = Colors.black.withOpacity(0.48),
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
      Paint()..color = color.withOpacity(0.38),
    );
    tp2.paint(
        canvas, Offset(center.dx - tp2.width / 2, riskY - tp2.height / 2));
  }
 
  // ── paint ─────────────────────────────────────────────────────────────────
 
  @override
  void paint(Canvas canvas, Size size) {
    if (lotes.isEmpty) return;
 
    final layout = _computeLoteLayout(size, lotes.length);
    if (layout.cells.isEmpty) return;
 
    final refSize = _radioPromedio(size, lotes.length);
 
    // Paso 1 – polígonos de cada lote (encajan entre sí, sin huecos)
    for (int i = 0; i < lotes.length; i++) {
      final lote = lotes[i];
      final cellPts = layout.cells[i];
      if (cellPts.length < 3) continue;
 
      final color = _riesgoColor(lote.nivel);
      final isSel =
          selectedIdCultivo != null && lote.idCultivo == selectedIdCultivo;
 
      final path = _poligonoOrganico(cellPts);
 
      // Relleno semitransparente
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(isSel ? 0.62 : 0.46)
          ..style = PaintingStyle.fill,
      );
      // Borde blanco (separa visualmente cada lote)
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(isSel ? 1.0 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 3.2 : 2.0,
      );
      // Borde de color fino
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
 
    // Paso 2 – pines y etiquetas (encima de los polígonos)
    for (int i = 0; i < lotes.length; i++) {
      final lote = lotes[i];
      final center = layout.centers[i];
      final color = _riesgoColor(lote.nivel);
      final isSel =
          selectedIdCultivo != null && lote.idCultivo == selectedIdCultivo;
 
      _drawPin(canvas, center, color, selected: isSel);
      if (isSel) _drawLabel(canvas, center, lote, refSize);
    }
 
    // Borde interior del contenedor
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
 
  @override
  bool shouldRepaint(covariant _MapaFincaPainter old) =>
      old.lotes != lotes || old.selectedIdCultivo != selectedIdCultivo;
}
 
// ─── ViewModel lote ───────────────────────────────────────────────────────────
 
class _LoteRiesgo {
  final int idCultivo;
  final String nombre;
  final int nivel;
 
  const _LoteRiesgo({
    required this.idCultivo,
    required this.nombre,
    required this.nivel,
  });
}
 
// ─────────────────────────────────────────────────────────────────────────────
 
class MontoreosScreen extends StatefulWidget {
  const MontoreosScreen({super.key});
 
  @override
  State<MontoreosScreen> createState() => _MontoreosScreenState();
}
 
class _MontoreosScreenState extends State<MontoreosScreen> {
  int _tabIndex = 0;
  bool _cargando = true;
  String? _error;
  List _monitoreos = [];
 
  String _busqueda = '';
 
  List get _monitoreosFiltrados {
    if (_busqueda.isEmpty) return _monitoreos;
    final q = _busqueda.toLowerCase();
    return _monitoreos.where((m) {
      final fecha = _fecha(m).toLowerCase();
      final parcela = _parcela(m).toLowerCase();
      final nivel = _labelNivel(m).toLowerCase();
      final titulo = _titulo(m).toLowerCase();
      return fecha.contains(q) ||
          parcela.contains(q) ||
          nivel.contains(q) ||
          titulo.contains(q);
    }).toList();
  }
 
  bool _cargandoMapa = false;
  List<_LoteRiesgo> _lotes = [];
  _LoteRiesgo? _loteSeleccionado;
 
  Map<String, dynamic>? get _fincaActiva =>
      AppState.instance.fincaSeleccionada;
 
  int? get _idFincaActiva =>
      _toInt(_fincaActiva?['idFinca'] ?? _fincaActiva?['id_finca']);
 
  String get _nombreFincaActiva =>
      _fincaActiva?['nombreFinca'] ??
      _fincaActiva?['nombre_finca'] ??
      'Finca';
 
  @override
  void initState() {
    super.initState();
    _cargarMonitoreos();
    AppState.instance.addListener(_onFincaCambiada);
  }
 
  void _onFincaCambiada() {
    setState(() {
      _busqueda = '';
      _lotes = [];
      _loteSeleccionado = null;
    });
    _cargarMonitoreos();
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onFincaCambiada);
    super.dispose();
  }
 
  // ── Carga monitoreos ───────────────────────────────────────────────────────
 
  Future<void> _cargarMonitoreos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final idFinca = _idFincaActiva;
 
      // NOTA: el backend (AdonisJS) todavía no soporta filtrar por
      // "idFinca" directamente -- solo entiende "id_cultivo" o
      // "id_experto". Por eso el filtro real por finca se sigue haciendo
      // aquí en el cliente (más abajo). El problema es que, sin filtro
      // server-side, el endpoint aplica su paginación por defecto
      // (page=1, limit=10) sobre TODOS los monitoreos de la base de
      // datos, ordenados por id_monitoreo DESC. Si hay otros usuarios o
      // cultivos generando monitoreos en el mismo backend (por ejemplo,
      // otros compañeros probando la app contra el mismo servidor), los
      // tuyos pueden quedar fuera de esos primeros 10 antes de que el
      // filtro local por finca llegue a verlos, dando la impresión de
      // que "se borran" cuando en realidad solo quedaron fuera de la
      // página actual.
      //
      // Mientras el backend no exponga un filtro real por finca, subimos
      // el límite de paginación para traer suficientes registros y que
      // el filtro local no se quede corto. Esto es un parche temporal:
      // lo correcto a futuro es que el backend acepte un filtro real
      // "id_finca" (haciendo join con cultivos) para no depender de
      // pedir cientos de registros cada vez.
      const limiteSeguro = 200;
 
      final endpoint = idFinca != null
          ? '/monitoreos?idFinca=$idFinca&limit=$limiteSeguro'
          : '/monitoreos?limit=$limiteSeguro';
 
      final data = await ApiService.get(endpoint);
      List lista =
          data is List ? List.from(data) : List.from(data['data'] ?? []);
      // Filtrar monitoreos del experto (creados aparte con tag [EXPERTO])
      // para evitar duplicados — ahora las recomendaciones se vinculan directo
      lista = lista.where((m) {
        final obs = (m['observaciones'] ?? '').toString();
        return !obs.startsWith('[EXPERTO]');
      }).toList();
      if (idFinca != null) {
        lista = lista.where((m) {
          final fId = _toInt(
            m['cultivo']?['finca']?['idFinca'] ??
                m['cultivo']?['idFinca'] ??
                m['finca']?['idFinca'] ??
                m['idFinca'] ??
                m['id_finca'],
          );
          return fId == null || fId == idFinca;
        }).toList();
      }
      // Marcar monitoreos que tienen diagnóstico de experto
      Set<dynamic> conExperto = {};
      try {
        final recData = await ApiService.get('/recomendaciones?limit=500');
        final recs = recData is List ? recData : (recData['data'] ?? []);
        for (final r in recs) {
          final idM = r['id_monitoreo'] ?? r['idMonitoreo'];
          if (idM != null) conExperto.add(idM);
        }
      } catch (_) {}

      lista.sort((a, b) {
        final aExp = conExperto.contains(a['idMonitoreo'] ?? a['id_monitoreo']);
        final bExp = conExperto.contains(b['idMonitoreo'] ?? b['id_monitoreo']);
        if (aExp != bExp) return aExp ? -1 : 1;
        final idA = _toInt(a['idMonitoreo'] ?? a['id_monitoreo']) ?? 0;
        final idB = _toInt(b['idMonitoreo'] ?? b['id_monitoreo']) ?? 0;
        return idB.compareTo(idA);
      });

      setState(() {
        _monitoreos = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }
 
  // ── Carga lotes coloreados por riesgo ──────────────────────────────────────
 
  Future<void> _cargarMapa() async {
    if (_lotes.isNotEmpty) return;
    setState(() => _cargandoMapa = true);
    try {
      final idFinca = _idFincaActiva;
      final resCultivos = await ApiService.get(
          idFinca != null ? '/cultivos?idFinca=$idFinca' : '/cultivos');
      List cultivos = resCultivos is List
          ? List.from(resCultivos)
          : List.from(resCultivos['data'] ?? []);
 
      if (idFinca != null) {
        cultivos = cultivos.where((c) {
          final fId = _toInt(
              c['idFinca'] ?? c['finca']?['idFinca'] ?? c['id_finca']);
          return fId == null || fId == idFinca;
        }).toList();
      }
 
      if (cultivos.isEmpty) {
        setState(() {
          _lotes = [];
          _cargandoMapa = false;
        });
        return;
      }
 
      final Map<int, int> nivelPorCultivo = {};
      for (final m in _monitoreos) {
        final idCultivo = _toInt(m['idCultivo'] ??
            m['id_cultivo'] ??
            m['cultivo']?['idCultivo'] ??
            m['cultivo']?['id_cultivo']);
        if (idCultivo == null) continue;
        final label = _labelNivel(m);
        final nivel = label == 'Alto'
            ? 3
            : label == 'Medio'
                ? 2
                : 1;
        final actual = nivelPorCultivo[idCultivo] ?? 0;
        if (nivel > actual) nivelPorCultivo[idCultivo] = nivel;
      }
 
      final List<_LoteRiesgo> resultado = [];
      for (final c in cultivos) {
        final idCultivo = _toInt(c['idCultivo'] ?? c['id_cultivo']);
        if (idCultivo == null) continue;
        final nombre =
            c['nombreCultivo'] ?? c['nombre_cultivo'] ?? 'Lote $idCultivo';
        final nivel = nivelPorCultivo[idCultivo] ?? 0;
        resultado.add(
            _LoteRiesgo(idCultivo: idCultivo, nombre: nombre, nivel: nivel));
      }
 
      setState(() {
        _lotes = resultado;
        _cargandoMapa = false;
      });
    } catch (e) {
      setState(() => _cargandoMapa = false);
    }
  }
 
  // ── Eliminar ───────────────────────────────────────────────────────────────
 
  Future<void> _eliminarMonitoreo(dynamic m) async {
    final id = m['idMonitoreo'] ?? m['id_monitoreo'];
    try {
      await ApiService.delete('/monitoreos/$id');
      setState(() {
        _monitoreos.removeWhere(
            (item) => (item['idMonitoreo'] ?? item['id_monitoreo']) == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Monitoreo eliminado'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }
 
  Future<void> _confirmarEliminar(dynamic m) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar monitoreo',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
          '¿Seguro que quieres eliminar este monitoreo? Esta acción no se puede deshacer.',
          style: GoogleFonts.nunito(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
    if (confirmado == true) _eliminarMonitoreo(m);
  }
 
  // ── Helpers de nivel ───────────────────────────────────────────────────────
 
  String _labelNivel(dynamic m) {
    final nivelRoyaObj = m['nivelRoya'] ?? m['nivel_roya'];
    if (nivelRoyaObj != null) {
      String nombre = '';
      if (nivelRoyaObj is Map) {
        nombre = (nivelRoyaObj['nombreNivel'] ??
                nivelRoyaObj['nombre_nivel'] ??
                '')
            .toString()
            .toLowerCase();
      } else {
        nombre = nivelRoyaObj.toString().toLowerCase();
      }
      if (nombre.contains('alt') ||
          nombre.contains('crít') ||
          nombre.contains('critico')) return 'Alto';
      if (nombre.contains('med')) return 'Medio';
      if (nombre.contains('baj') ||
          nombre.contains('sano') ||
          nombre.contains('normal')) return 'Bajo';
    }
    final obs =
        (m['observaciones'] ?? m['cultivo']?['observaciones'] ?? '')
            .toString()
            .toLowerCase();
    if (obs.contains('roya') ||
        obs.contains('alto') ||
        obs.contains('critico') ||
        obs.contains('enfermedad')) return 'Alto';
    if (obs.contains('medio') ||
        obs.contains('manchas') ||
        obs.contains('sospechosas') ||
        obs.contains('observación') ||
        obs.contains('observacion')) return 'Medio';
    return 'Bajo';
  }
 
  Color _colorNivel(dynamic m) {
    final nivel = _labelNivel(m).toLowerCase();
    if (nivel.contains('alt')) return Colors.red;
    if (nivel.contains('med')) return _amarilloRiesgoLote;
    return AppColors.primary;
  }
 
  String _titulo(dynamic m) {
    final nivel = _labelNivel(m).toLowerCase();
    if (nivel.contains('alt')) return 'Roya encontrada';
    if (nivel.contains('med')) return 'Riesgo medio';
    return 'Riesgo bajo';
  }
 
  String _fecha(dynamic m) {
    final f = m['fechaMonitoreo'] ??
        m['fecha_monitoreo'] ??
        m['fechaRegistro'] ??
        '';
    if (f.toString().isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(f.toString());
      const meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return f.toString();
    }
  }
 
  String _parcela(dynamic m) {
    final fincaNombre = m['cultivo']?['finca']?['nombreFinca'] ??
        m['cultivo']?['finca']?['nombre_finca'] ??
        m['cultivo']?['finca']?['nombre'];
    if (fincaNombre != null && fincaNombre.toString().isNotEmpty) {
      return fincaNombre.toString();
    }
    final fincaEnCultivo =
        m['cultivo']?['nombreFinca'] ?? m['cultivo']?['nombre_finca'];
    if (fincaEnCultivo != null && fincaEnCultivo.toString().isNotEmpty) {
      return fincaEnCultivo.toString();
    }
    final fincaRaiz = m['finca']?['nombreFinca'] ??
        m['finca']?['nombre_finca'] ??
        m['nombreFinca'] ??
        m['nombre_finca'];
    if (fincaRaiz != null && fincaRaiz.toString().isNotEmpty) {
      return fincaRaiz.toString();
    }
    final cultivo =
        m['cultivo']?['nombreCultivo'] ?? m['cultivo']?['nombre_cultivo'];
    if (cultivo != null && cultivo.toString().isNotEmpty) {
      return cultivo.toString();
    }
    return 'Sin finca';
  }
 
  String? _imagenUrl(dynamic m) {
    final imagenes = m['imagenes'];
    if (imagenes == null || imagenes is! List || imagenes.isEmpty) return null;
    final ruta = imagenes[0]['urlImagen'] ??
        imagenes[0]['url_imagen'] ??
        imagenes[0]['rutaImagen'] ??
        imagenes[0]['ruta_imagen'];
    if (ruta == null || ruta.toString().isEmpty) return null;
    if (ruta.toString().startsWith('http')) return ruta.toString();
    return 'https://coffeelife-api.up.railway.app/$ruta';
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _error != null
                      ? _buildError()
                      : _tabIndex == 0
                          ? _buildHistorial()
                          : _buildMapa(),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E7D6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monitoreo',
                      style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  if (_fincaActiva != null)
                    Text(
                      _nombreFincaActiva,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: _cargarMonitoreos,
                tooltip: 'Recargar',
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 8),
          ],
        ),
        child: Row(children: [
          _tabItem('Historial', 0),
          _tabItem('Lotes', 1),
        ]),
      ),
    );
  }
 
  Widget _tabItem(String label, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tabIndex = index);
          if (index == 1) _cargarMapa();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      isActive ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
 
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error al cargar monitoreos',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _cargarMonitoreos,
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
            child: Text('Reintentar',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
 
  // ── Historial ─────────────────────────────────────────────────────────────
 
  Widget _buildHistorial() {
    final lista = _monitoreosFiltrados;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar por finca, nivel, fecha...',
              hintStyle: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textSecondary, size: 20),
              suffixIcon: _busqueda.isNotEmpty
                  ? GestureDetector(
                      onTap: () => setState(() => _busqueda = ''),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.textSecondary),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            style: GoogleFonts.nunito(fontSize: 14),
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco_outlined,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _busqueda.isEmpty
                            ? 'No hay monitoreos para\n$_nombreFincaActiva'
                            : 'Sin resultados para "$_busqueda"',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _busqueda.isEmpty
                            ? 'Realiza un diagnóstico para crear uno'
                            : 'Intenta con otro término de búsqueda',
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarMonitoreos,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _monitoreoCard(lista[i]),
                  ),
                ),
        ),
      ],
    );
  }
 
  Widget _monitoreoCard(dynamic m) {
    final color = _colorNivel(m);
    final nivel = _labelNivel(m);
    final fecha = _fecha(m);
    final parcela = _parcela(m);
    final imgUrl = _imagenUrl(m);
 
    final obs = (m['observaciones'] ?? '').toString();
    final partes = obs.contains('—')
        ? obs.split('—').map((p) => p.trim()).toList()
        : <String>[];
    final diagnostico = partes.isNotEmpty
        ? partes[0]
        : (obs.isNotEmpty ? obs : _titulo(m));
    final confianza = partes.length > 1 ? partes[1] : '';
    final nombreCientifico = partes.length > 2 ? partes[2] : '';
 
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MonitoreoDetalleScreen(
            monitoreo: Map<String, dynamic>.from(m),
          ),
        ),
      ),
      onLongPress: () => _confirmarEliminar(m),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imgUrl != null
                  ? Image.network(imgUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _colorFallback(color))
                  : _colorFallback(color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(fecha,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(nivel,
                            style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(diagnostico,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  if (confianza.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(confianza,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        if (nombreCientifico.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('· $nombreCientifico',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(parcela,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MonitoreoDetalleScreen(
                            monitoreo: Map<String, dynamic>.from(m),
                            initialTab: 1,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('Ver Diagnóstico del Experto',
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _colorFallback(Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
 
  // ── Tab Lotes ─────────────────────────────────────────────────────────────
 
  Widget _buildMapa() {
    if (_fincaActiva == null) {
      return _mapaPlaceholder(
        icon: Icons.grid_view_rounded,
        mensaje:
            'Selecciona una finca en el inicio\npara ver sus lotes',
      );
    }
    if (_cargandoMapa) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_lotes.isEmpty) {
      return _mapaPlaceholder(
        icon: Icons.eco_outlined,
        mensaje: 'No hay lotes registrados\nen "$_nombreFincaActiva"',
      );
    }
 
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ────────────────────────────────────────────────
          Text('Lotes de $_nombreFincaActiva',
              style: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(
            '${_lotes.length} lote${_lotes.length != 1 ? "s" : ""} registrado${_lotes.length != 1 ? "s" : ""}',
            style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
 
          // ── Info lote seleccionado ────────────────────────────────────
          if (_loteSeleccionado != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _riesgoColor(_loteSeleccionado!.nivel)
                        .withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8)
                ],
              ),
              child: Row(children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _riesgoColor(_loteSeleccionado!.nivel),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_loteSeleccionado!.nombre,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      Text(
                        'Riesgo: ${_riesgoLabel(_loteSeleccionado!.nivel)}',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: _riesgoColor(_loteSeleccionado!.nivel),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _loteSeleccionado = null),
                  child: const Icon(Icons.close,
                      size: 18, color: Colors.black38),
                ),
              ]),
            ),
 
          // ── Contenedor del "mapa" (ocupa todo el espacio, sin recortes) ─
          Container(
            width: double.infinity,
            height: 420,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  final layout =
                      _computeLoteLayout(canvasSize, _lotes.length);
 
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) {
                      if (layout.cells.isEmpty) return;
                      final tapPos = details.localPosition;
                      int? tappedIndex;
                      for (int idx = 0; idx < layout.cells.length; idx++) {
                        if (_puntoEnPoligono(tapPos, layout.cells[idx])) {
                          tappedIndex = idx;
                          break;
                        }
                      }
                      if (tappedIndex != null) {
                        final tapped = _lotes[tappedIndex];
                        setState(() {
                          _loteSeleccionado =
                              _loteSeleccionado?.idCultivo ==
                                      tapped.idCultivo
                                  ? null
                                  : tapped;
                        });
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── Imagen satelital de fondo (llena todo) ────
                        Image.asset(
                          'assets/images/mapa_satelital.jpg',
                          fit: BoxFit.cover,
                          // Si no tienes la imagen aún, usa un
                          // degradado verde como fallback:
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4a8c2a),
                                  Color(0xFF2d6018),
                                  Color(0xFF1a4010),
                                ],
                              ),
                            ),
                          ),
                        ),
 
                        // ── Capa oscura leve para contraste ───────────
                        Container(color: Colors.black.withOpacity(0.10)),
 
                        // ── Lotes (polígonos) + pines ─────────────────
                        CustomPaint(
                          size: canvasSize,
                          painter: _MapaFincaPainter(
                            lotes: _lotes,
                            selectedIdCultivo: _loteSeleccionado?.idCultivo,
                          ),
                        ),
 
                        // ── Etiqueta superior izquierda ───────────────
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded,
                                    color: Colors.white.withOpacity(0.85),
                                    size: 14),
                                const SizedBox(width: 6),
                                Text('${_lotes.length} lotes',
                                    style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            Colors.white.withOpacity(0.9))),
                              ],
                            ),
                          ),
                        ),
 
                        // ── Controles de zoom (decorativos) ───────────
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Column(
                            children: [
                              _mapControlButton(Icons.add),
                              const SizedBox(height: 6),
                              _mapControlButton(Icons.remove),
                              const SizedBox(height: 6),
                              _mapControlButton(Icons.my_location_rounded),
                            ],
                          ),
                        ),
 
                        // ── Leyenda flotante estilo mapa ──────────────
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _leyendaFlotanteItem(
                                    AppColors.primary, 'Bajo riesgo'),
                                _leyendaFlotanteItem(
                                    _amarilloRiesgoLote, 'Medio riesgo'),
                                _leyendaFlotanteItem(
                                    Colors.red, 'Alto riesgo'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
 
          const SizedBox(height: 16),
 
          // ── Lista de estado por lote + leyenda ────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado por lote',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ..._lotes.map((lote) {
                  final color = _riesgoColor(lote.nivel);
                  final label = lote.nivel == 0
                      ? 'Sin monitoreos'
                      : _riesgoLabel(lote.nivel);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(lote.nombre,
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ]),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _legendaItem(Colors.red, 'Alto'),
                    _legendaItem(_amarilloRiesgoLote, 'Medio'),
                    _legendaItem(AppColors.primary, 'Bajo'),
                    _legendaItem(Colors.grey, 'Sin datos'),
                  ],
                ),
              ],
            ),
          ),
 
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  Widget _mapControlButton(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
        ],
      ),
      child: Icon(icon, size: 16, color: AppColors.textPrimary),
    );
  }
 
  Widget _leyendaFlotanteItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
 
  Widget _mapaPlaceholder(
      {required IconData icon, required String mensaje}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
 
  Widget _legendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
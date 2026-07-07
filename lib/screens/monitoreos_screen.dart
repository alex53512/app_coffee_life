import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import 'login_screen.dart';
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

// ─── Helpers de forma (Voronoi ponderado) — genera regiones irregulares ────
// que encajan entre sí, una por lote, sin depender de coordenadas GPS.

List<Offset> _generarSemillasLotes(Size size, int n) {
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
    if (!seeds.any((s) => (s - p).distance < minDist)) seeds.add(p);
  }
  while (seeds.length < n) {
    seeds.add(puntoAleatorio());
  }
  return seeds;
}

List<double> _generarPesosLotes(Size size, int n) {
  final rnd = math.Random(5000 + n * 97);
  final escala = size.width * size.height / n;
  return List.generate(n, (_) => (rnd.nextDouble() - 0.5) * 2 * escala * 0.5);
}

List<Offset> _clipHalfPlaneLotes(List<Offset> poly, Offset normal, double c) {
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
      out.add(Offset(curr.dx + t * (next.dx - curr.dx),
          curr.dy + t * (next.dy - curr.dy)));
    }
  }
  return out;
}

List<List<Offset>> _calcularCeldasLotes(
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
      poly = _clipHalfPlaneLotes(poly, normal, c);
      if (poly.isEmpty) break;
    }
    cells.add(poly);
  }
  return cells;
}

// ─── Paleta y helpers de color por nivel de riesgo ─────────────────────────

/// (color claro, color oscuro) para el degradado de relleno de cada lote.
(Color, Color) _riesgoGradiente(int nivel, int variacion) => switch (nivel) {
      1 => (const Color(0xFF6FA82B), const Color(0xFF527D1E)),
      2 => variacion.isOdd
          ? (const Color(0xFFD08A20), const Color(0xFFA9660F))
          : (const Color(0xFFF4B24A), const Color(0xFFDE8E1F)),
      3 => (const Color(0xFFE5605C), const Color(0xFFC43B3A)),
      _ => (const Color(0xFFC7C3B6), const Color(0xFFA3A093)),
    };

Color _riesgoPinStroke(int nivel) => switch (nivel) {
      1 => const Color(0xFF3B6D11),
      2 => const Color(0xFF854F0B),
      3 => const Color(0xFFA32D2D),
      _ => const Color(0xFF8A8578),
    };

(Color bg, Color fg) _riesgoChip(int nivel) => switch (nivel) {
      1 => (const Color(0xFFEAF3DE), const Color(0xFF3B5C17)),
      2 => (const Color(0xFFFAEEDA), const Color(0xFF7A4A0E)),
      3 => (const Color(0xFFFCEBEB), const Color(0xFF9A2E2E)),
      _ => (const Color(0xFFEEECE4), const Color(0xFF6B675C)),
    };

/// Forma de pin tipo "gota" (drop pin), igual a la del diseño de referencia.
Path _pinPath(double r) {
  final path = Path();
  path.moveTo(0, -r * 1.3);
  path.cubicTo(r * 0.6, -r * 1.3, r, -r * 0.9, r, -r * 0.35);
  path.cubicTo(r, r * 0.24, 0, r * 1.18, 0, r * 1.18);
  path.cubicTo(0, r * 1.18, -r, r * 0.24, -r, -r * 0.35);
  path.cubicTo(-r, -r * 0.9, -r * 0.6, -r * 1.3, 0, -r * 1.3);
  path.close();
  return path;
}

// ─── Painter principal: mapa profesional de lotes ──────────────────────────

class _MapaProfesionalPainter extends CustomPainter {
  final List<_LoteRiesgo> lotes;

  _MapaProfesionalPainter({required this.lotes});

  void _drawGridTexture(Canvas canvas, Path clip, Size size) {
    canvas.save();
    canvas.clipPath(clip);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.restore();
  }

  void _drawPin(Canvas canvas, Offset center, int nivel,
      {bool grande = false}) {
    final r = grande ? 20.0 : 17.0;
    final strokeColor = _riesgoPinStroke(nivel);

    // Sombra
    canvas.save();
    canvas.translate(center.dx + 2, center.dy + (grande ? 4 : 3));
    canvas.drawCircle(Offset.zero, grande ? 4 : 3,
        Paint()..color = Colors.black.withOpacity(0.2));
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final path = _pinPath(r);

    if (grande) {
      // Pin destacado (nivel de mayor riesgo): relleno de color sólido
      canvas.drawPath(path, Paint()..color = strokeColor);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      canvas.drawCircle(
          Offset(0, -r * 0.35), r * 0.4, Paint()..color = Colors.white);
    } else {
      canvas.drawPath(path, Paint()..color = Colors.white);
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
          Offset(0, -r * 0.35), r * 0.4, Paint()..color = strokeColor);
    }
    canvas.restore();
  }

  void _drawEtiquetaMapa(Canvas canvas, Offset pos, String texto) {
    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(
          color: Color.fromRGBO(255, 255, 255, 0.92),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawBrujula(Canvas canvas, Offset centro) {
    canvas.drawCircle(
        centro, 20, Paint()..color = Colors.white.withOpacity(0.85));
    final path = Path()
      ..moveTo(centro.dx, centro.dy - 13)
      ..lineTo(centro.dx + 4, centro.dy)
      ..lineTo(centro.dx, centro.dy + 13)
      ..lineTo(centro.dx - 4, centro.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF444441));
    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
            color: Color(0xFF444441),
            fontSize: 10,
            fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centro.dx - tp.width / 2, centro.dy - 34));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (lotes.isEmpty) return;
    final n = lotes.length;
    final seeds = _generarSemillasLotes(size, n);
    final weights = _generarPesosLotes(size, n);
    final cells = _calcularCeldasLotes(size, seeds, weights);

    final centros = <Offset>[];

    for (int i = 0; i < cells.length; i++) {
      final poly = cells[i];
      if (poly.length < 3) {
        centros.add(seeds.length > i
            ? seeds[i]
            : Offset(size.width / 2, size.height / 2));
        continue;
      }
      final path = Path()..addPolygon(poly, true);
      final bounds = path.getBounds();
      final (claro, oscuro) = _riesgoGradiente(lotes[i].nivel, i);

      final shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        [claro, oscuro],
      );
      canvas.drawPath(path, Paint()..shader = shader);
      _drawGridTexture(canvas, path, size);

      double cx = 0, cy = 0;
      for (final p in poly) {
        cx += p.dx;
        cy += p.dy;
      }
      centros.add(Offset(cx / poly.length, cy / poly.length));
    }

    // Bordes blancos gruesos entre regiones
    final bordePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    for (final poly in cells) {
      if (poly.length < 3) continue;
      canvas.drawPath(Path()..addPolygon(poly, true), bordePaint);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.black.withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Etiquetas con el nombre real de cada lote
    for (int i = 0; i < centros.length && i < lotes.length; i++) {
      _drawEtiquetaMapa(canvas, centros[i].translate(0, -30), lotes[i].nombre);
    }

    // Pines: el de mayor riesgo se dibuja más grande (llama la atención)
    int? indexMasAlto;
    int maxNivel = -1;
    for (int i = 0; i < lotes.length; i++) {
      if (lotes[i].nivel > maxNivel) {
        maxNivel = lotes[i].nivel;
        indexMasAlto = i;
      }
    }
    for (int i = 0; i < centros.length && i < lotes.length; i++) {
      _drawPin(canvas, centros[i], lotes[i].nivel,
          grande: i == indexMasAlto && maxNivel >= 3);
    }

    _drawBrujula(canvas, Offset(size.width - 30, 30));
  }

  @override
  bool shouldRepaint(covariant _MapaProfesionalPainter old) =>
      old.lotes != lotes;
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

  dynamic _ultimoIdFinca;

  @override
  void initState() {
    super.initState();
    _cargarMonitoreos();
    AppState.instance.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    final nuevoId = _idFincaActiva;
    if (nuevoId != _ultimoIdFinca) {
      _ultimoIdFinca = nuevoId;
      setState(() {
        _busqueda = '';
        _lotes = [];
        _loteSeleccionado = null;
      });
    }
    _cargarMonitoreos();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
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
      debugPrint(
          '📋 Monitoreos recibidos: ${lista.map((m) => m['idMonitoreo'] ?? m['id_monitoreo']).toList()}');
      debugPrint('idFinca usado en query: $idFinca');
      // Filtrar monitoreos del experto (creados aparte con tag [EXPERTO])
      // para evitar duplicados — ahora las recomendaciones se vinculan directo
      final antesExperto = lista.length;
      lista = lista.where((m) {
        final obs = (m['observaciones'] ?? '').toString();
        return !obs.startsWith('[EXPERTO]');
      }).toList();
      debugPrint(
          'Filtro [EXPERTO]: ${antesExperto - lista.length} eliminados');
      if (idFinca != null) {
        final antesFinca = lista.length;
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
        debugPrint(
            'Filtro finca: ${antesFinca - lista.length} eliminados, ${lista.length} restantes');
      }
      lista.sort((a, b) {
        final idA = _toInt(a['idMonitoreo'] ?? a['id_monitoreo']) ?? 0;
        final idB = _toInt(b['idMonitoreo'] ?? b['id_monitoreo']) ?? 0;
        return idB.compareTo(idA);
      });
      debugPrint(
          '📊 IDs ordenados: ${lista.take(20).map((m) => m['idMonitoreo'] ?? m['id_monitoreo']).toList()}...');

      setState(() {
        _monitoreos = lista;
        _cargando = false;
      });
      debugPrint(
          '_monitoreos.length=${_monitoreos.length}, _monitoreosFiltrados.length=${_monitoreosFiltrados.length}, _busqueda="$_busqueda"');
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
    final f = m['fechaMonitoreo'] ?? m['fecha_monitoreo'] ?? m['fechaRegistro'];
    return AppTheme.formatFechaColombia(f);
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
        color: AppColors.headerBg(context),
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
                color: AppColors.cardBg(context).withOpacity(0.25),
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
                  if (_fincaActiva != null)
                    Text(
                      _nombreFincaActiva,
                      style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cardBg(context).withOpacity(0.25),
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
          color: AppColors.cardBg(context),
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
    final esAuth = _error?.contains('401') == true || _error?.contains('Sesión expirada') == true;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(esAuth ? Icons.lock_outline : Icons.error_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(esAuth ? 'Sesión expirada' : 'Error al cargar monitoreos',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: esAuth
                  ? () => ApiService.navigatorKey.currentState?.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      )
                  : _cargarMonitoreos,
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              child: Text(esAuth ? 'Ir al inicio de sesión' : 'Reintentar',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
            onChanged: (v) {
              debugPrint('búsqueda cambió: "$v"');
              setState(() => _busqueda = v);
            },
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
              fillColor: AppColors.inputFill(context),
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
          color: AppColors.cardBg(context),
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

    final nBajo = _lotes.where((l) => l.nivel == 1).length;
    final nMedio = _lotes.where((l) => l.nivel == 2).length;
    final nAlto = _lotes.where((l) => l.nivel == 3).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Chips resumen por estado ─────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (nBajo > 0) _chipResumen(1, '$nBajo bajo'),
                    if (nMedio > 0) _chipResumen(2, '$nMedio medio'),
                    if (nAlto > 0) _chipResumen(3, '$nAlto alto'),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Mapa ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 340,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFEAEAE4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasSize =
                            Size(constraints.maxWidth, constraints.maxHeight);
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              size: canvasSize,
                              painter: _MapaProfesionalPainter(lotes: _lotes),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.terrain_rounded,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 13),
                                    const SizedBox(width: 6),
                                    Text('Vista general del terreno',
                                        style: GoogleFonts.nunito(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white
                                                .withOpacity(0.92))),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF9F1),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 3),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _leyendaIcono(Icons.eco_outlined,
                                        const Color(0xFF3B6D11), 'Bajo'),
                                    _leyendaIcono(Icons.warning_amber_rounded,
                                        const Color(0xFF854F0B), 'Medio'),
                                    _leyendaIcono(Icons.error_outline,
                                        const Color(0xFFA32D2D), 'Alto'),
                                    _leyendaIcono(Icons.help_outline,
                                        const Color(0xFF8A8578), 'Sin datos'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Lista "Estado por lote" ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Text('Estado por lote',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                ..._lotes.map((lote) {
                  final (bg, fg) = _riesgoChip(lote.nivel);
                  final label =
                      lote.nivel == 0 ? 'Sin datos' : _riesgoLabel(lote.nivel);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: Color(0xFFF0EEE6))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _riesgoPinStroke(lote.nivel),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(lote.nombre,
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(label,
                              style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: fg)),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: Color(0xFFC7C3B6)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _chipResumen(int nivel, String texto) {
    final (bg, fg) = _riesgoChip(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(texto,
          style: GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _leyendaIcono(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B2A26))),
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
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
 
class MonitoreoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> monitoreo;
  final int initialTab;

  const MonitoreoDetalleScreen({
    super.key,
    required this.monitoreo,
    this.initialTab = 0,
  });
 
  @override
  State<MonitoreoDetalleScreen> createState() => _MonitoreoDetalleScreenState();
}
 
class _MonitoreoDetalleScreenState extends State<MonitoreoDetalleScreen> {
  int _tabIndex = 0;
  bool _cargando = true;

  Map<String, dynamic>? _monitoreoCompleto;
  Map<String, dynamic>? _analisisIa;

  Map<String, dynamic>? _diagnosticoExperto;

  Map<String, dynamic> get _m => _monitoreoCompleto ?? widget.monitoreo;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
    _cargarDatos();
  }
 
  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final idMonitoreo =
        widget.monitoreo['idMonitoreo'] ?? widget.monitoreo['id_monitoreo'];

    try {
      final rawMonitoreo = await ApiService.get('/monitoreos/$idMonitoreo');
      if (rawMonitoreo is Map) {
        final inner = rawMonitoreo['data'];
        _monitoreoCompleto = Map<String, dynamic>.from(
          (inner is Map) ? inner : rawMonitoreo,
        );
      }
    } catch (_) {}
    print('IMAGENES: ${_monitoreoCompleto?['imagenes']}');

    _analisisIa = await _cargarAnalisisIa(idMonitoreo);

    if (_analisisIa?['_recomendaciones'] == null) {
      final fuente = _monitoreoCompleto ?? widget.monitoreo;
      final parsed = _parsearObservaciones(fuente);
      if (parsed?['_recomendaciones'] != null) {
        _analisisIa ??= {};
        _analisisIa!['_recomendaciones'] = parsed!['_recomendaciones'];
      }
    }

    await _cargarDiagnosticoExperto(idMonitoreoPropio: idMonitoreo);

    if (mounted) setState(() => _cargando = false);
  }
 
  Future<Map<String, dynamic>?> _cargarAnalisisIa(dynamic idMonitoreo) async {
    try {
      final data = await ApiService.get('/analisis_ia?idMonitoreo=$idMonitoreo');
      final lista = data is List ? data : (data['data'] ?? []);
      if ((lista as List).isNotEmpty) return Map<String, dynamic>.from(lista[0]);
    } catch (_) {}
 
    try {
      final data = await ApiService.get('/analisis_ia?id_monitoreo=$idMonitoreo');
      final lista = data is List ? data : (data['data'] ?? []);
      if ((lista as List).isNotEmpty) return Map<String, dynamic>.from(lista[0]);
    } catch (_) {}
 
    try {
      final data = await ApiService.get('/analisis_ia/$idMonitoreo');
      if (data != null) {
        final inner = data['data'] ?? data;
        if (inner is Map && inner.isNotEmpty) return Map<String, dynamic>.from(inner);
      }
    } catch (_) {}
 
    final fuente = _monitoreoCompleto ?? widget.monitoreo;
    return _parsearObservaciones(fuente);
  }
 

  Future<void> _cargarDiagnosticoExperto({required dynamic idMonitoreoPropio}) async {
    try {
      final data = await ApiService.get('/recomendaciones?id_monitoreo=$idMonitoreoPropio');
      final lista = data is List ? data : (data['data'] ?? []);
      if ((lista as List).isEmpty) return;

      final rec = Map<String, dynamic>.from(lista[0]);

      String dosis = '';
      String frecuencia = '';

      final posiblesTratamientos = [
        if (rec['tratamientos'] is List) ...rec['tratamientos'] as List,
        if (rec['tratamiento'] is List) ...rec['tratamiento'] as List,
        if (rec['tratamiento'] is Map) rec['tratamiento'],
      ];
      for (final t in posiblesTratamientos) {
        if (t is Map) {
          final d = t['dosis']?.toString() ?? t['dosis_recomendada']?.toString() ?? '';
          final f = t['frecuencia']?.toString() ?? t['frecuencia_aplicacion']?.toString() ?? '';
          if (d.isNotEmpty && dosis.isEmpty) dosis = d;
          if (f.isNotEmpty && frecuencia.isEmpty) frecuencia = f;
        }
      }
      if (dosis.isEmpty) dosis = (rec['dosis'] ?? rec['dosis_recomendada'] ?? '').toString();
      if (frecuencia.isEmpty) frecuencia = (rec['frecuencia'] ?? rec['frecuencia_aplicacion'] ?? '').toString();

      _diagnosticoExperto = {
        'experto': (rec['experto'] ?? '').toString(),
        'descripcion': (rec['descripcion'] ?? '').toString(),
        'prioridad': (rec['prioridad'] ?? '').toString(),
        'tratamiento': (rec['tratamiento'] ?? '').toString(),
        'fecha_limite': (rec['fecha_limite'] ?? '').toString(),
        'dosis': dosis,
        'frecuencia': frecuencia,
      };
    } catch (_) {}
  }
 
  Map<String, dynamic>? _parsearObservaciones(Map<String, dynamic> m) {
    final obs = (m['observaciones'] ?? '').toString().trim();
    debugPrint('_parsearObservaciones obs: "$obs"');
    if (obs.isEmpty) return null;
 
    if (obs.contains('—')) {
      final partes = obs.split('—').map((p) => p.trim()).toList();
      final resultado = partes.isNotEmpty ? partes[0] : 'Sin resultado';
      double confianza = 0.0;
      if (partes.length > 1) {
        final raw = partes[1]
            .replaceAll('%', '')
            .replaceAll('Confianza:', '')
            .replaceAll('confianza:', '')
            .trim();
        confianza = double.tryParse(raw) ?? 0.0;
      }
      final nombreCientifico = partes.length > 2 ? partes[2] : '';
      String severidad = '';
      for (final p in partes) {
        if (p.startsWith('Severidad:')) {
          severidad = p.replaceAll('Severidad:', '').trim();
          break;
        }
      }
      List<String> recoms = [];
      for (final p in partes) {
        if (p.startsWith('Recomendaciones:')) {
          recoms = p
              .replaceAll('Recomendaciones:', '')
              .split('|')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
          break;
        }
      }
      return {
        'resultado': resultado,
        'confianza': confianza,
        'versionModelo': '1.0',
        'estadoAnalisis': {'nombreEstado': 'Completado'},
        if (nombreCientifico.isNotEmpty) 'nombreCientifico': nombreCientifico,
        if (severidad.isNotEmpty) 'severidad': severidad,
        '_fuenteObservaciones': true,
        if (recoms.isNotEmpty) '_recomendaciones': recoms,
      };
    }
 
    return {
      'resultado': obs,
      'confianza': 0.0,
      'versionModelo': '1.0',
      'estadoAnalisis': {'nombreEstado': 'Completado'},
      '_fuenteObservaciones': true,
    };
  }
 
  String _limpiarResultado(String raw) {
    final t = raw.toLowerCase().trim();
    if (t.startsWith('http://') || t.startsWith('https://')) {
      if (t.contains('roya')) return 'Roya detectada';
      if (t.contains('sana')) return 'Planta sana';
      return 'Resultado del análisis';
    }
    return raw;
  }

  String _fecha() {
    final f = _m['fechaMonitoreo'] ?? _m['fecha_monitoreo'];
    return AppTheme.formatFechaColombia(f);
  }
 
  String _cultivo() {
    final cultivo = _m['cultivo'];
    if (cultivo is Map) {
      return cultivo['nombreCultivo'] ?? cultivo['nombre_cultivo'] ?? cultivo['nombre'] ?? 'Sin cultivo';
    }
    return 'Sin cultivo';
  }
 
  String _finca() {
    final cultivo = _m['cultivo'];
 
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) {
        final nombre = finca['nombreFinca'] ?? finca['nombre_finca'] ?? finca['nombre'];
        if (nombre != null && nombre.toString().isNotEmpty) return nombre.toString();
      }
      final nombreFinca = cultivo['nombreFinca'] ?? cultivo['nombre_finca'];
      if (nombreFinca != null && nombreFinca.toString().isNotEmpty) return nombreFinca.toString();
    }
 
    final fincaRaiz = _m['finca'];
    if (fincaRaiz is Map) {
      final nombre = fincaRaiz['nombreFinca'] ?? fincaRaiz['nombre_finca'] ?? fincaRaiz['nombre'];
      if (nombre != null && nombre.toString().isNotEmpty) return nombre.toString();
    }
 
    if (cultivo is Map) {
      final idFinca = cultivo['idFinca'] ?? cultivo['id_finca'];
      if (idFinca != null) {
        final fincaState = AppState.instance.fincaSeleccionada;
        if (fincaState != null) {
          final idFincaState = fincaState['idFinca'] ?? fincaState['id_finca'];
          if (idFincaState?.toString() == idFinca.toString()) {
            final nombre = fincaState['nombreFinca'] ?? fincaState['nombre_finca'];
            if (nombre != null && nombre.toString().isNotEmpty) return nombre.toString();
          }
        }
      }
    }
 
    final fincaOriginal = widget.monitoreo['finca'];
    if (fincaOriginal is Map) {
      final nombre = fincaOriginal['nombreFinca'] ?? fincaOriginal['nombre_finca'] ?? fincaOriginal['nombre'];
      if (nombre != null && nombre.toString().isNotEmpty) return nombre.toString();
    }
 
    return 'Sin finca';
  }
 
  String _municipio() {
    final cultivo = _m['cultivo'];
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) {
        final mun = finca['municipio'] ?? finca['ciudad'] ?? '';
        final dep = finca['departamento'] ?? finca['estado'] ?? '';
        if (mun.toString().isNotEmpty && dep.toString().isNotEmpty) return '$mun, $dep';
        if (mun.toString().isNotEmpty) return mun.toString();
      }
    }
    return '';
  }
 
  String _experto() {
    final nombre = (_diagnosticoExperto?['experto'] ?? '').toString();
    if (nombre.isNotEmpty) return nombre;

    final exp = _m['experto'];
    if (exp is Map) {
      final nombre   = exp['nombre'] ?? '';
      final apellido = exp['apellido'] ?? '';
      final nombre2  = '$nombre $apellido'.trim();
      if (nombre2.isNotEmpty) return nombre2;
    }

    final fincaCultivo = _m['cultivo']?['finca'];
    if (fincaCultivo is Map) {
      final expAsignado = fincaCultivo['expertoAsignado'];
      if (expAsignado is Map) {
        final n = '${expAsignado['nombre'] ?? ''} ${expAsignado['apellido'] ?? ''}'.trim();
        if (n.isNotEmpty) return n;
      }
    }

    final fincaState = AppState.instance.fincaSeleccionada;
    if (fincaState != null) {
      final expAsignado = fincaState['expertoAsignado'];
      if (expAsignado is Map) {
        final n = '${expAsignado['nombre'] ?? ''} ${expAsignado['apellido'] ?? ''}'.trim();
        if (n.isNotEmpty) return n;
      }
    }

    return 'Sin experto asignado';
  }
 
  String _nivelRoya() {
    final obj = _m['nivelRoya'];
    if (obj is Map) return (obj['nombreNivel'] ?? obj['nombre_nivel'] ?? '').toString();
    if (obj != null && obj.toString().isNotEmpty) return obj.toString();
 
    final obj2 = _m['nivel_roya'];
    if (obj2 != null && obj2.toString().isNotEmpty) return obj2.toString();
 
    if (_analisisIa != null) {
      final sev = (_analisisIa!['severidad'] ?? '').toString().toLowerCase();
      if (sev.contains('alt')) return 'Alto';
      if (sev.contains('med')) return 'Medio';
      if (sev.contains('baj')) return 'Bajo';
      if (sev.contains('ninguna')) return 'Sin riesgo';
      final resultado = (_analisisIa!['resultado'] ?? '').toString().toLowerCase();
      if (resultado.contains('alto') || resultado.contains('roya')) return 'Alto';
      if (resultado.contains('medio')) return 'Medio';
      if (resultado.contains('bajo')) return 'Bajo';
      if (resultado.contains('sano') || resultado.contains('sana')) return 'Sin riesgo';
    }
    return 'Sin análisis';
  }
 
  List _imagenes() {
    final imgs = _m['imagenes'];
    if (imgs is List) return imgs;
    return [];
  }

  String? get _imagenUrlIa {
    if (_analisisIa == null) return null;
    final ruta = _analisisIa!['imagen']?['rutaImagen'] ?? '';
    if (ruta.toString().isEmpty) return null;
    if (ruta.toString().startsWith('http')) return ruta.toString();
    return 'https://coffeelife-api.up.railway.app/$ruta';
  }

  List _imagenesExperto() {
    return _imagenes();
  }
 
  Color _colorNivel() {
    final nivel = _nivelRoya().toLowerCase();
    if (nivel.contains('alt')) return Colors.red;
    if (nivel.contains('med')) return Colors.orange;
    if (nivel.contains('sin')) return Colors.grey;
    return AppColors.primary;
  }
 

  List<_RecomendacionIA> _recomendacionesIa() {
    final backendRecs = _analisisIa?['_recomendaciones'] as List<String>?;
    if (backendRecs != null && backendRecs.isNotEmpty) {
      return backendRecs
          .map((r) => _RecomendacionIA(Icons.check_circle_outlined,
              const Color(0xFF2E7D32), r, ''))
          .toList();
    }
    final resultado = (_analisisIa?['resultado'] ?? '').toString().toLowerCase();
    final esRoya = resultado.contains('roya');

    return esRoya
        ? [
            _RecomendacionIA(Icons.medication_outlined, const Color(0xFF1565C0),
                'Aplicar fungicida recomendado', 'Fungicida Cúprico 250g/200L agua'),
            _RecomendacionIA(Icons.air_outlined, const Color(0xFF2E7D32),
                'Mejorar ventilación del cultivo', 'Poda para mayor aireación'),
            _RecomendacionIA(Icons.delete_outline_rounded, const Color(0xFFE65100),
                'Eliminar hojas afectadas', 'Retirar y destruir hojas con síntomas'),
          ]
        : [
            _RecomendacionIA(Icons.check_circle_outline, AppColors.primary,
                'Planta en buen estado', 'Continúa con el manejo habitual'),
            _RecomendacionIA(Icons.water_drop_outlined, const Color(0xFF1565C0),
                'Mantén el riego adecuado', 'Riega según las condiciones del clima'),
            _RecomendacionIA(Icons.search_outlined, const Color(0xFF388E3C),
                'Monitorea regularmente', 'Revisa las hojas cada 15 días'),
          ];
  }
 
  Widget _buildRecomendacionesIa() {
    final recs = _recomendacionesIa();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recs.asMap().entries.map((e) {
          final rec = e.value;
          final isLast = e.key == recs.length - 1;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: rec.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(rec.icon, color: rec.color, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec.titulo,
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text(rec.subtitulo,
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                const SizedBox(height: 10),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final municipio = _municipio();
 
    return Scaffold(
      body: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF97D340), Color(0xFF388E3C)],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text('Detalle del monitoreo',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _cargarDatos,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(_fecha(),
                                        style: GoogleFonts.nunito(
                                            fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _colorNivel().withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.eco_rounded, size: 13, color: _colorNivel()),
                                      const SizedBox(width: 4),
                                      Text(_nivelRoya(),
                                          style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _colorNivel())),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _seccionTitulo('Cultivo y Finca'),
                            const SizedBox(height: 10),
                            _card(
                              child: Column(
                                children: [
                                  _infoFila(Icons.grass_rounded, 'Cultivo', _cultivo()),
                                  const Divider(height: 20, color: AppColors.border),
                                  _infoFila(Icons.location_on_outlined, 'Finca', _finca()),
                                  if (municipio.isNotEmpty) ...[
                                    const Divider(height: 20, color: AppColors.border),
                                    _infoFila(Icons.map_outlined, 'Ubicación', municipio),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _seccionTitulo('Experto asignado'),
                            const SizedBox(height: 10),
                            _card(
                              child: Row(
                                children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg(context),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.person_outline_rounded,
                                        color: Color(0xFF388E3C), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Experto',
                                            style: GoogleFonts.nunito(
                                                fontSize: 11, color: AppColors.textSecondary)),
                                        Text(_experto(),
                                            style: GoogleFonts.nunito(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg(context),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                              ),
                              child: Row(
                                children: [
                                  _tabItem('Recomendación IA', 0),
                                  _tabItem('Recomendación Experto', 1),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _tabIndex == 0 ? _buildTabIa() : _buildTabExperto(),
                            const SizedBox(height: 20),
                          ],
                        ),
                    ),
                  ),
            ),
          ],
        ),
    );
  }

  Widget _tabItem(String label, int index) {
    final isActive = _tabIndex == index;
    final String? pctStr = index == 0 ? _obtenerPctIa() : null;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textSecondary)),
              if (pctStr != null) ...[
                const SizedBox(width: 4),
                Text(pctStr,
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.white : Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
 
  String? _obtenerPctIa() {
    if (_analisisIa == null) return null;
    final c = _analisisIa!['confianza'] ?? _analisisIa!['porcentajeConfianza'] ?? 0;
    final n = (c is num) ? c.toDouble() : double.tryParse(c.toString()) ?? 0.0;
    final pct = n > 1 ? n / 100 : n;
    return '${(pct * 100).round()}%';
  }

  Widget _buildTabIa() {
    if (_analisisIa == null) {
      return _sinDatos(
        icono: Icons.smart_toy_outlined,
        titulo: 'Sin análisis de IA',
        mensaje: 'Este monitoreo no tiene un análisis de inteligencia artificial registrado.',
      );
    }
 
    final resultado   = _analisisIa!['resultado'] ?? 'Sin resultado';
    final confianza   = _analisisIa!['confianza'] ?? _analisisIa!['porcentajeConfianza'] ?? 0;
    final version     = _analisisIa!['versionModelo'] ?? _analisisIa!['version_modelo'] ?? '1.0';
    final estado      = _analisisIa!['estadoAnalisis']?['nombreEstado'] ??
                        _analisisIa!['estado_analisis']?['nombre_estado'] ?? 'Completado';
    final nombreCient = _analisisIa!['nombreCientifico'] ?? '';
    final severidad   = _analisisIa!['severidad'] ?? '';
    final resultadoLimpio = _limpiarResultado(resultado);
    final esRoya      = resultadoLimpio.toLowerCase().contains('roya');

    final confianzaNum = (confianza is num) ? confianza.toDouble() : double.tryParse(confianza.toString()) ?? 0.0;
    final confianzaPct = confianzaNum > 1 ? confianzaNum / 100 : confianzaNum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imagenUrlIa != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    _imagenUrlIa!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.textSecondary)),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: esRoya ? Colors.red : severidad == 'Media' ? Colors.orange : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(esRoya ? 'Roya detectada' : resultadoLimpio,
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _card(
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resultado', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                    Text(resultadoLimpio, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    if (severidad.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: esRoya ? Colors.red.withOpacity(0.1) : severidad == 'Media' ? Colors.orange.withOpacity(0.1) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Severidad: $severidad',
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700,
                                color: esRoya ? Colors.red : severidad == 'Media' ? Colors.orange : AppColors.primary)),
                      ),
                    ],
                    if (nombreCient.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(nombreCient, style: GoogleFonts.nunito(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Confianza del modelo',
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('${(confianzaPct * 100).round()}%',
                      style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.red)),
                ],
              ),
              if (confianzaPct > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: confianzaPct,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 10,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text('Versión modelo: $version  |  Estado: $estado',
                  style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _seccionTitulo('Recomendaciones'),
        const SizedBox(height: 10),
        _buildRecomendacionesIa(),
      ],
    );
  }
  
  Widget _buildTabExperto() {
    if (_diagnosticoExperto == null) {
      return _sinDatos(
        icono: Icons.person_outline_rounded,
        titulo: 'Sin diagnóstico del experto',
        mensaje: 'El experto aún no ha emitido un diagnóstico para este monitoreo.',
      );
    }

    final d = _diagnosticoExperto!;
    final experto = (d['experto'] ?? '').toString();
    final descripcion = (d['descripcion'] ?? '').toString();
    final prioridad = (d['prioridad'] ?? '').toString();
    final tratamiento = (d['tratamiento'] ?? '').toString();
    final fechaLimite = (d['fecha_limite'] ?? '').toString();
    final dosis = (d['dosis'] ?? '').toString();
    final frecuencia = (d['frecuencia'] ?? '').toString();

    String fechaFormateada = '';
    if (fechaLimite.isNotEmpty) {
      try {
        final dt = DateTime.parse(fechaLimite).toLocal();
        const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
        fechaFormateada = '${dt.day.toString().padLeft(2,'0')} ${meses[dt.month-1]} ${dt.year}';
      } catch (_) { fechaFormateada = fechaLimite; }
    }

    Color colorPrioridad = AppColors.primary;
    if (prioridad.toLowerCase().contains('alt')) colorPrioridad = Colors.red;
    else if (prioridad.toLowerCase().contains('med')) colorPrioridad = Colors.orange;
    else if (prioridad.toLowerCase().contains('baj')) colorPrioridad = AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Diagnóstico del experto',
                            style: GoogleFonts.nunito(
                                fontSize: 11, color: AppColors.textSecondary)),
                        if (experto.isNotEmpty)
                          Text(experto,
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              if (descripcion.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(descripcion,
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
                ),
              ],
              if (prioridad.isNotEmpty) ...[
                const SizedBox(height: 10),
                _infoFilaColor(Icons.flag_outlined, 'Prioridad', prioridad, colorPrioridad),
              ],
              if (dosis.isNotEmpty) ...[
                const SizedBox(height: 10),
                _infoFila(Icons.science_outlined, 'Dosis', dosis),
              ],
              if (frecuencia.isNotEmpty) ...[
                const SizedBox(height: 10),
                _infoFila(Icons.replay_outlined, 'Frecuencia', frecuencia),
              ],
              if (tratamiento.isNotEmpty) ...[
                const SizedBox(height: 10),
                _infoFila(Icons.healing_outlined, 'Tratamiento sugerido', tratamiento),
              ],
              if (fechaFormateada.isNotEmpty) ...[
                const SizedBox(height: 10),
                _infoFila(Icons.calendar_today_outlined, 'Fecha límite', fechaFormateada),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _seccionTitulo('Imágenes (${_imagenesExperto().length})'),
        const SizedBox(height: 10),
        _buildImagenes(imagenes: _imagenesExperto()),
      ],
    );
  }
  
  Widget _buildImagenes({List? imagenes}) {
    final imgs = imagenes ?? _imagenes();
    if (imgs.isEmpty) {
      return _card(
        child: Row(
          children: [
            const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Text('Sin imágenes registradas',
                style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: imgs.length,
      itemBuilder: (_, i) {
        final raw = imgs[i]['rutaImagen'] ?? imgs[i]['urlImagen'] ?? imgs[i]['url_imagen'] ?? imgs[i]['ruta_imagen'] ?? '';
        String url = raw.toString();
        if (url.isNotEmpty && !url.startsWith('http')) {
          url = 'https://coffeelife-api.up.railway.app/$url';
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagenPlaceholder())
              : _imagenPlaceholder(),
        );
      },
    );
  }
 
  Widget _sinDatos({required IconData icono, required String titulo, required String mensaje}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
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
 
  Widget _seccionTitulo(String titulo) {
    return Text(titulo,
        style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary));
  }
 
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: child,
    );
  }
 
  Widget _infoFila(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
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
 
  Widget _infoFilaColor(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
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
 
  Widget _imagenPlaceholder() {
    return Container(
      color: AppColors.successBg(context),
      child: const Center(child: Icon(Icons.eco_outlined, color: Colors.green, size: 40)),
    );
  }
}

class _RecomendacionIA {
  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  const _RecomendacionIA(this.icon, this.color, this.titulo, this.subtitulo);
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
 
class MonitoreoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> monitoreo;
 
  const MonitoreoDetalleScreen({super.key, required this.monitoreo});
 
  @override
  State<MonitoreoDetalleScreen> createState() => _MonitoreoDetalleScreenState();
}
 
class _MonitoreoDetalleScreenState extends State<MonitoreoDetalleScreen> {
  int _tabIndex = 0;
  bool _cargando = true;
 
  Map<String, dynamic>? _monitoreoCompleto;
  Map<String, dynamic>? _analisisIa;
  Map<String, dynamic>? _recomendacionExperto;
 
  Map<String, dynamic> get _m => _monitoreoCompleto ?? widget.monitoreo;
 
  @override
  void initState() {
    super.initState();
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
 
      try {
        final dataIa =
            await ApiService.get('/analisis_ia?id_monitoreo=$idMonitoreo');
        final listaIa =
            dataIa is List ? dataIa : (dataIa['data'] ?? []);
        if ((listaIa as List).isNotEmpty) {
          _analisisIa = Map<String, dynamic>.from(listaIa[0]);
        }
      } catch (_) {}
 
      try {
        final dataRec =
            await ApiService.get('/recomendaciones?id_monitoreo=$idMonitoreo');
        final listaRec =
            dataRec is List ? dataRec : (dataRec['data'] ?? []);
        if ((listaRec as List).isNotEmpty) {
          _recomendacionExperto =
              Map<String, dynamic>.from(listaRec[0]);
        }
      } catch (_) {}
    } catch (_) {}
 
    if (mounted) setState(() => _cargando = false);
  }
 
  // ── Helpers ──────────────────────────────────────────────────────────────
 
  String _fecha() {
    final f = (_m['fechaMonitoreo'] ?? _m['fecha_monitoreo'] ?? '').toString();
    if (f.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(f);
      const meses = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      return '${dt.day.toString().padLeft(2, '0')} de ${meses[dt.month - 1]} de ${dt.year}';
    } catch (_) {
      return f;
    }
  }
 
  String _cultivo() {
    final cultivo = _m['cultivo'];
    if (cultivo is Map) {
      return cultivo['nombreCultivo'] ?? cultivo['nombre_cultivo'] ?? 'Sin cultivo';
    }
    return 'Sin cultivo';
  }
 
  String _finca() {
    final cultivo = _m['cultivo'];
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) {
        return finca['nombreFinca'] ?? finca['nombre_finca'] ?? 'Sin finca';
      }
    }
    return 'Sin finca';
  }
 
  String _municipio() {
    final cultivo = _m['cultivo'];
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) {
        final mun = finca['municipio'] ?? '';
        final dep = finca['departamento'] ?? '';
        if (mun.isNotEmpty && dep.isNotEmpty) return '$mun, $dep';
        if (mun.isNotEmpty) return mun;
      }
    }
    return '';
  }
 
  String _experto() {
    final exp = _m['experto'];
    if (exp is Map) {
      final nombre   = exp['nombre'] ?? '';
      final apellido = exp['apellido'] ?? '';
      final nombre2  = '$nombre $apellido'.trim();
      if (nombre2.isNotEmpty) return nombre2;
    }
    return 'Sin experto asignado';
  }
 
  String _nivelRoya() {
    return (_m['nivelRoya']?['nombreNivel'] ??
            _m['nivelRoya'] ??
            _m['nivel_roya'] ??
            'Sin análisis')
        .toString();
  }
 
  List _imagenes() {
    final imgs = _m['imagenes'];
    if (imgs is List) return imgs;
    return [];
  }
 
  Color _colorNivel() {
    final nivel = _nivelRoya().toLowerCase();
    if (nivel.contains('alt')) return Colors.red;
    if (nivel.contains('med')) return Colors.orange;
    return AppColors.primary;
  }
 
  // ── Lógica de recomendaciones basadas en resultado IA ────────────────────
 
  bool _esRoya(String resultado) {
    final r = resultado.toLowerCase();
    return r.contains('roya') || r.contains('enfermedad') || r.contains('hemileia');
  }
 
  bool _esSana(String resultado) {
    final r = resultado.toLowerCase();
    return r.contains('sana') || r.contains('normal') || r.contains('sin patóg') || r.contains('sin patog');
  }
 
  List<_RecIA> _recomendacionesIA(String resultado, double confianzaPct) {
    if (_esRoya(resultado)) {
      String severidad;
      Color colorSev;
      if (confianzaPct >= 0.75) {
        severidad = 'Alta';
        colorSev  = const Color(0xFFD32F2F);
      } else if (confianzaPct >= 0.45) {
        severidad = 'Media';
        colorSev  = const Color(0xFFE65100);
      } else {
        severidad = 'Baja';
        colorSev  = const Color(0xFF388E3C);
      }
 
      return [
        _RecIA(
          icono: Icons.medication_outlined,
          color: const Color(0xFF1565C0),
          titulo: 'Aplicar fungicida cúprico',
          subtitulo: 'Dosis recomendada: 250 g por 200 L de agua',
          detalle: 'Aplica preventivamente cada 15-21 días. '
              'Asegura buena cobertura en el envés de las hojas.',
        ),
        _RecIA(
          icono: Icons.content_cut_rounded,
          color: const Color(0xFF2E7D32),
          titulo: 'Poda y ventilación',
          subtitulo: 'Mejorar la aireación entre plantas',
          detalle: 'Realiza poda de chupones y ramas improductivas '
              'para reducir la humedad, que favorece el desarrollo de la roya.',
        ),
        _RecIA(
          icono: Icons.delete_outline_rounded,
          color: const Color(0xFFE65100),
          titulo: 'Eliminar hojas afectadas',
          subtitulo: 'Retirar y destruir hojas con síntomas',
          detalle: 'Recoge las hojas caídas y elimínalas fuera del cultivo. '
              'No las dejes en el suelo cerca de las plantas.',
        ),
        _RecIA(
          icono: Icons.warning_amber_rounded,
          color: colorSev,
          titulo: 'Severidad detectada: $severidad',
          subtitulo: 'Confianza del modelo: ${(confianzaPct * 100).round()}%',
          detalle: confianzaPct >= 0.75
              ? 'Resultado muy confiable. Actúa con prioridad alta.'
              : confianzaPct >= 0.45
                  ? 'Resultado moderadamente confiable. Considera confirmación con un agrónomo.'
                  : 'Confianza baja. Se recomienda tomar otra foto con mejor iluminación.',
        ),
      ];
    }
 
    if (_esSana(resultado)) {
      return [
        _RecIA(
          icono: Icons.check_circle_outline,
          color: AppColors.primary,
          titulo: 'Planta en buen estado',
          subtitulo: 'No se detectaron patógenos',
          detalle: 'Continúa con el manejo habitual del cultivo. '
              'Las condiciones actuales son favorables.',
        ),
        _RecIA(
          icono: Icons.water_drop_outlined,
          color: const Color(0xFF1565C0),
          titulo: 'Mantén el riego adecuado',
          subtitulo: 'Riego según condiciones climáticas',
          detalle: 'Evita el exceso de humedad foliar; riega preferiblemente '
              'en la mañana para que las hojas sequen durante el día.',
        ),
        _RecIA(
          icono: Icons.search_outlined,
          color: const Color(0xFF388E3C),
          titulo: 'Monitorea regularmente',
          subtitulo: 'Revisión cada 15 días',
          detalle: 'La detección temprana de roya es clave. '
              'Revisa el envés de las hojas y reporta cualquier mancha amarilla.',
        ),
      ];
    }
 
    // Resultado desconocido
    return [
      _RecIA(
        icono: Icons.help_outline_rounded,
        color: AppColors.textSecondary,
        titulo: 'Resultado no clasificado',
        subtitulo: resultado,
        detalle: 'El modelo no pudo clasificar la imagen con certeza. '
            'Toma una nueva foto de la hoja con buena iluminación y enfoque.',
      ),
    ];
  }
 
  // ── Build ─────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final municipio = _municipio();
 
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF4E7D6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Detalle del monitoreo',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
 
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _cargarDatos,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
 
                            // Fecha + badge nivel
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _fecha(),
                                      style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _colorNivel().withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.eco_rounded,
                                          size: 13, color: _colorNivel()),
                                      const SizedBox(width: 4),
                                      Text(
                                        _nivelRoya(),
                                        style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _colorNivel()),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
 
                            const SizedBox(height: 20),
 
                            // Cultivo y Finca
                            _seccionTitulo('Cultivo y Finca'),
                            const SizedBox(height: 10),
                            _card(
                              child: Column(
                                children: [
                                  _infoFila(
                                      Icons.grass_rounded, 'Cultivo', _cultivo()),
                                  const Divider(
                                      height: 20, color: AppColors.border),
                                  _infoFila(Icons.location_on_outlined, 'Finca',
                                      _finca()),
                                  if (municipio.isNotEmpty) ...[
                                    const Divider(
                                        height: 20, color: AppColors.border),
                                    _infoFila(
                                        Icons.map_outlined, 'Ubicación', municipio),
                                  ],
                                ],
                              ),
                            ),
 
                            const SizedBox(height: 16),
 
                            // Experto asignado
                            _seccionTitulo('Experto asignado'),
                            const SizedBox(height: 10),
                            _card(
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.person_outline_rounded,
                                        color: Color(0xFF388E3C),
                                        size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Experto',
                                            style: GoogleFonts.nunito(
                                                fontSize: 11,
                                                color: AppColors.textSecondary)),
                                        Text(
                                          _experto(),
                                          style: GoogleFonts.nunito(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
 
                            const SizedBox(height: 20),
 
                            // Tabs
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _tabItem('Recomendación IA', 0),
                                  _tabItem('Recomendación Experto', 1),
                                ],
                              ),
                            ),
 
                            const SizedBox(height: 16),
 
                            _tabIndex == 0
                                ? _buildTabIa()
                                : _buildTabExperto(),
 
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ── Tab selector ──────────────────────────────────────────────────────────
 
  Widget _tabItem(String label, int index) {
    final isActive = _tabIndex == index;
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
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
 
  // ── Tab IA ────────────────────────────────────────────────────────────────
 
  Widget _buildTabIa() {
    if (_analisisIa == null) {
      return _sinDatos(
        icono: Icons.smart_toy_outlined,
        titulo: 'Sin análisis de IA',
        mensaje:
            'Este monitoreo no tiene un análisis de inteligencia artificial registrado.',
      );
    }
 
    final resultado   = (_analisisIa!['resultado'] ?? 'Sin resultado').toString();
    final confianza   = _analisisIa!['confianza'] ??
        _analisisIa!['porcentajeConfianza'] ??
        0;
    final version     = (_analisisIa!['versionModelo'] ??
        _analisisIa!['version_modelo'] ??
        '1.0').toString();
    final estado      = (_analisisIa!['estadoAnalisis']?['nombreEstado'] ??
        _analisisIa!['estado_analisis']?['nombre_estado'] ??
        'Completado').toString();
 
    final confianzaNum = (confianza is num)
        ? confianza.toDouble()
        : double.tryParse(confianza.toString()) ?? 0.0;
    final confianzaPct = confianzaNum > 1 ? confianzaNum / 100 : confianzaNum;
 
    // Color del resultado según tipo
    Color colorResultado = AppColors.primary;
    IconData iconoResultado = Icons.smart_toy_outlined;
    if (_esRoya(resultado)) {
      colorResultado = confianzaPct >= 0.75
          ? const Color(0xFFD32F2F)
          : confianzaPct >= 0.45
              ? const Color(0xFFE65100)
              : const Color(0xFF388E3C);
      iconoResultado = Icons.coronavirus_outlined;
    } else if (_esSana(resultado)) {
      colorResultado = AppColors.primary;
      iconoResultado = Icons.eco_outlined;
    }
 
    final recs = _recomendacionesIA(resultado, confianzaPct);
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
 
        // ── Resultado ──────────────────────────────────────────────────────
        _card(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorResultado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconoResultado,
                    color: colorResultado, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resultado',
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: AppColors.textSecondary)),
                    Text(resultado,
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colorResultado)),
                  ],
                ),
              ),
            ],
          ),
        ),
 
        const SizedBox(height: 14),
 
        // ── Barra de confianza ─────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Confianza del modelo',
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(
                    '${(confianzaPct * 100).round()}%',
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorResultado),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: confianzaPct,
                  backgroundColor: AppColors.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorResultado),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Versión modelo: $version  |  Estado: $estado',
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
 
        const SizedBox(height: 14),
 
        // ── Recomendaciones ────────────────────────────────────────────────
        _seccionTitulo('Recomendaciones'),
        const SizedBox(height: 10),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: recs.asMap().entries.map((e) {
              final rec    = e.value;
              final isLast = e.key == recs.length - 1;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: rec.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(rec.icono, color: rec.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec.titulo,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            Text(rec.subtitulo,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: rec.color,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(rec.detalle,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, indent: 52, color: AppColors.border),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
 
        const SizedBox(height: 14),
 
        // ── Imágenes ───────────────────────────────────────────────────────
        _seccionTitulo('Imágenes (${_imagenes().length})'),
        const SizedBox(height: 10),
        _buildImagenes(),
      ],
    );
  }
 
  // ── Tab Experto ───────────────────────────────────────────────────────────
 
  Widget _buildTabExperto() {
    if (_recomendacionExperto == null) {
      return _sinDatos(
        icono: Icons.person_outline_rounded,
        titulo: 'Sin recomendación del experto',
        mensaje:
            'El experto aún no ha registrado una recomendación para este monitoreo.',
      );
    }
 
    final descripcion =
        _recomendacionExperto!['descripcion'] ?? 'Sin descripción';
    final fechaLimite = _recomendacionExperto!['fechaLimite'] ??
        _recomendacionExperto!['fecha_limite'] ??
        '';
 
    final prioridadObj = _recomendacionExperto!['prioridad'];
    final prioridad = (prioridadObj is Map)
        ? (prioridadObj['nombrePrioridad'] ??
            prioridadObj['nombre_prioridad'] ??
            'Normal')
        : 'Normal';
 
    Color colorPrioridad = AppColors.primary;
    if (prioridad.toLowerCase().contains('alt')) {
      colorPrioridad = Colors.red;
    } else if (prioridad.toLowerCase().contains('med')) {
      colorPrioridad = Colors.orange;
    }
 
    String fechaFormateada = fechaLimite;
    try {
      if (fechaLimite.toString().isNotEmpty) {
        final dt = DateTime.parse(fechaLimite.toString());
        const meses = [
          'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
        ];
        fechaFormateada =
            '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
 
    final expertoRec = _recomendacionExperto!['experto'];
    String nombreExperto = '';
    if (expertoRec is Map) {
      final n = expertoRec['nombre'] ?? '';
      final a = expertoRec['apellido'] ?? '';
      nombreExperto = '$n $a'.trim();
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notes_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  descripcion,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
 
        const SizedBox(height: 14),
 
        _card(
          child: Column(
            children: [
              _infoFilaColor(
                  Icons.flag_outlined, 'Prioridad', prioridad, colorPrioridad),
              if (fechaFormateada.toString().isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.border),
                _infoFila(Icons.calendar_today_outlined, 'Fecha límite',
                    fechaFormateada.toString()),
              ],
              if (nombreExperto.isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.border),
                _infoFila(Icons.person_outline_rounded, 'Registrado por',
                    nombreExperto),
              ],
            ],
          ),
        ),
      ],
    );
  }
 
  // ── Imágenes grid ─────────────────────────────────────────────────────────
 
  Widget _buildImagenes() {
    final imagenes = _imagenes();
    if (imagenes.isEmpty) {
      return _card(
        child: Row(
          children: [
            const Icon(Icons.image_not_supported_outlined,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Text('Sin imágenes registradas',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: imagenes.length,
      itemBuilder: (_, i) {
        final url =
            imagenes[i]['urlImagen'] ?? imagenes[i]['url_imagen'] ?? '';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagenPlaceholder(),
                )
              : _imagenPlaceholder(),
        );
      },
    );
  }
 
  // ── Widgets reutilizables ─────────────────────────────────────────────────
 
  Widget _sinDatos({
    required IconData icono,
    required String titulo,
    required String mensaje,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
        ],
      ),
    );
  }
 
  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary),
    );
  }
 
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
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
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _infoFilaColor(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _imagenPlaceholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.eco_outlined, color: Colors.green, size: 40),
      ),
    );
  }
}
 
// ── Modelo interno de recomendación IA ───────────────────────────────────────
 
class _RecIA {
  final IconData icono;
  final Color    color;
  final String   titulo;
  final String   subtitulo;
  final String   detalle;
 
  const _RecIA({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.detalle,
  });
}
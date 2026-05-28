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
 
  // Monitoreo completo traído del endpoint /monitoreos/{id}
  Map<String, dynamic>? _monitoreoCompleto;
 
  Map<String, dynamic>? _analisisIa;
  Map<String, dynamic>? _recomendacionExperto;
 
  // Getter que prioriza el objeto completo y cae al de la lista
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
      // ── 1. Monitoreo completo con todas las relaciones ──────────────────
      final rawMonitoreo = await ApiService.get('/monitoreos/$idMonitoreo');
      if (rawMonitoreo is Map) {
        // El endpoint puede devolver el objeto directo o envuelto en { data: {...} }
        final inner = rawMonitoreo['data'];
        _monitoreoCompleto = Map<String, dynamic>.from(
          (inner is Map) ? inner : rawMonitoreo,
        );
      }
 
      // ── 2. Análisis IA (filtrado por monitoreo vía imágenes en el backend) ─
      try {
        final dataIa =
            await ApiService.get('/analisis_ia?id_monitoreo=$idMonitoreo');
        final listaIa =
            dataIa is List ? dataIa : (dataIa['data'] ?? []);
        if ((listaIa as List).isNotEmpty) {
          _analisisIa = Map<String, dynamic>.from(listaIa[0]);
        }
      } catch (_) {
        // Tab IA mostrará mensaje amigable
      }
 
      // ── 3. Recomendación del experto ────────────────────────────────────
      try {
        final dataRec =
            await ApiService.get('/recomendaciones?id_monitoreo=$idMonitoreo');
        final listaRec =
            dataRec is List ? dataRec : (dataRec['data'] ?? []);
        if ((listaRec as List).isNotEmpty) {
          _recomendacionExperto =
              Map<String, dynamic>.from(listaRec[0]);
        }
      } catch (_) {
        // Tab Experto mostrará mensaje amigable
      }
    } catch (_) {
      // Error general al cargar el monitoreo
    }
 
    if (mounted) setState(() => _cargando = false);
  }
 
  // ── Helpers de datos ────────────────────────────────────────────────────
 
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
 
  // ── Build ────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final municipio = _municipio();
 
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
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
 
            // ── Contenido ───────────────────────────────────────────────────
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
 
                            // ── Fecha + badge nivel ──────────────────
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
 
                            // ── Cultivo y Finca ──────────────────────
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
 
                            // ── Experto asignado ─────────────────────
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
 
                            // ── Tabs ─────────────────────────────────
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
 
                            // ── Contenido del tab ─────────────────────
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
 
  // ── Tab selector ─────────────────────────────────────────────────────────
 
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
 
  // ── Tab IA ───────────────────────────────────────────────────────────────
 
  Widget _buildTabIa() {
    if (_analisisIa == null) {
      return _sinDatos(
        icono: Icons.smart_toy_outlined,
        titulo: 'Sin análisis de IA',
        mensaje:
            'Este monitoreo no tiene un análisis de inteligencia artificial registrado.',
      );
    }
 
    final resultado = _analisisIa!['resultado'] ?? 'Sin resultado';
    final confianza = _analisisIa!['confianza'] ??
        _analisisIa!['porcentajeConfianza'] ??
        0;
    final version = _analisisIa!['versionModelo'] ??
        _analisisIa!['version_modelo'] ??
        '1.0';
    final estado = _analisisIa!['estadoAnalisis']?['nombreEstado'] ??
        _analisisIa!['estado_analisis']?['nombre_estado'] ??
        'Completado';
 
    final confianzaNum = (confianza is num)
        ? confianza.toDouble()
        : double.tryParse(confianza.toString()) ?? 0.0;
    final confianzaPct = confianzaNum > 1 ? confianzaNum / 100 : confianzaNum;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
 
        // Resultado
        _card(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: AppColors.primary, size: 26),
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
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
 
        const SizedBox(height: 14),
 
        // Barra de confianza
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
                        color: AppColors.primary),
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
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
 
        // Imágenes del monitoreo
        _seccionTitulo('Imágenes (${_imagenes().length})'),
        const SizedBox(height: 10),
        _buildImagenes(),
      ],
    );
  }
 
  // ── Tab Experto ──────────────────────────────────────────────────────────
 
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
 
    // Prioridad — puede venir como objeto o como id
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
      if (fechaLimite.isNotEmpty) {
        final dt = DateTime.parse(fechaLimite);
        const meses = [
          'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
        ];
        fechaFormateada =
            '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
 
    // Experto que hizo la recomendación
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
 
        // Descripción
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
 
        // Prioridad, fecha límite y experto
        _card(
          child: Column(
            children: [
              _infoFilaColor(
                  Icons.flag_outlined, 'Prioridad', prioridad, colorPrioridad),
              if (fechaFormateada.isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.border),
                _infoFila(Icons.calendar_today_outlined, 'Fecha límite',
                    fechaFormateada),
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
 
  // ── Imágenes grid ────────────────────────────────────────────────────────
 
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'diagnostic_screen.dart';
 
class DetalleAnalisisIAScreen extends StatefulWidget {
  final Map<String, dynamic> analisis;
  final List monitoreos;
  final List cultivos;
  final List fincas;
  final List tratamientos;
 
  const DetalleAnalisisIAScreen({
    super.key,
    required this.analisis,
    required this.monitoreos,
    required this.cultivos,
    required this.fincas,
    required this.tratamientos,
  });
 
  @override
  State<DetalleAnalisisIAScreen> createState() => _DetalleAnalisisIAScreenState();
}
 
class _DetalleAnalisisIAScreenState extends State<DetalleAnalisisIAScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> analisis;
  bool _cargando = true;
 
  // Estado pestaña experto
  Map<String, dynamic>? _diagnosticoExperto; // monitoreo ya guardado
  bool _modoFormulario = false;
  bool _guardando = false;
 
  // Formulario experto
  String _resultado = 'Roya confirmada';
  String _severidad = 'Media';
  final _obsCtrl = TextEditingController();
  final _recCtrl = TextEditingController();
  Map<String, dynamic>? _tratamientoSeleccionado;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    analisis = widget.analisis;
    _cargarDetalle();
  }
 
  @override
  void dispose() {
    _tabController.dispose();
    _obsCtrl.dispose();
    _recCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _cargarDetalle() async {
    try {
      final idAnalisis = analisis['idAnalisis'] ?? analisis['id_analisis'];
      final detalle = await ApiService.get('/analisis_ia/$idAnalisis');
      final data = detalle is Map ? (detalle['data'] ?? detalle) : detalle;
      if (data is Map<String, dynamic>) {
        setState(() => analisis = data);
      }
    } catch (_) {}
 
    // Buscar si ya existe un monitoreo del experto para este cultivo
    // (identificado por idUsuario=61 en el monitoreo del mismo cultivo)
    try {
      final idMonitoreoIA = analisis['imagen']?['idMonitoreo'] ??
          analisis['imagen']?['id_monitoreo'];
      if (idMonitoreoIA != null) {
        final monitoreoIA = widget.monitoreos.firstWhere(
          (m) => (m['idMonitoreo'] ?? m['id_monitoreo']).toString() ==
              idMonitoreoIA.toString(),
          orElse: () => null,
        );
        if (monitoreoIA != null) {
          final idCultivo = monitoreoIA['idCultivo'] ?? monitoreoIA['id_cultivo'];
          // Buscar monitoreos del experto (con observaciones que contengan [EXPERTO])
          // vinculados al mismo cultivo
          final res = await ApiService.get('/experto/monitoreos');
          final lista = res is List ? res : (res['data'] ?? res['items'] ?? []);
          final diagExperto = lista.firstWhere((m) {
            final obs = (m['observaciones'] ?? '').toString();
            final idC = (m['idCultivo'] ?? m['id_cultivo']).toString();
            return obs.contains('[EXPERTO]') &&
                idC == idCultivo.toString();
          }, orElse: () => null);
          if (diagExperto != null) {
            setState(() => _diagnosticoExperto = diagExperto as Map<String, dynamic>);
          }
        }
      }
    } catch (_) {}
 
    setState(() => _cargando = false);
  }
 
  // ─── Helpers ───────────────────────────────────────────────────────────
 
  Map<String, dynamic>? get _monitoreoIA {
    final idMonitoreo = analisis['imagen']?['idMonitoreo'] ??
        analisis['imagen']?['id_monitoreo'];
    if (idMonitoreo == null) return null;
    final result = widget.monitoreos.firstWhere(
      (m) => (m['idMonitoreo'] ?? m['id_monitoreo']).toString() ==
          idMonitoreo.toString(),
      orElse: () => null,
    );
    return result as Map<String, dynamic>?;
  }
 
  Map<String, dynamic>? get _cultivo {
    final mon = _monitoreoIA;
    if (mon == null) return null;
    final idCultivo = mon['idCultivo'] ?? mon['id_cultivo'];
    if (idCultivo == null) return null;
    final result = widget.cultivos.firstWhere(
      (c) => (c['idCultivo'] ?? c['id_cultivo']).toString() == idCultivo.toString(),
      orElse: () => null,
    );
    return result as Map<String, dynamic>?;
  }
 
  Map<String, dynamic>? get _finca {
    final cult = _cultivo;
    if (cult == null) return null;
    final idFinca = cult['idFinca'] ?? cult['id_finca'];
    if (idFinca == null) return null;
    final result = widget.fincas.firstWhere(
      (f) => (f['idFinca'] ?? f['id_finca']).toString() == idFinca.toString(),
      orElse: () => null,
    );
    return result as Map<String, dynamic>?;
  }
 
  bool get _esRoya {
    final r = (analisis['resultado'] ?? '').toString().toLowerCase();
    return r.contains('roya');
  }
 
  Color get _colorIA {
    if (_esRoya) return Colors.red;
    final r = (analisis['resultado'] ?? '').toString().toLowerCase();
    if (r.contains('sana') || r.contains('sano') || r.contains('hoja_sana')) {
      return AppColors.primary;
    }
    return Colors.orange;
  }
 
  String get _textoResultadoIA {
    final r = (analisis['resultado'] ?? '').toString();
    if (r.toLowerCase().contains('roya')) return 'Roya detectada';
    if (r.toLowerCase().contains('sana') || r.toLowerCase().contains('sano') ||
        r.toLowerCase() == 'hoja_sana') return 'Planta sana';
    return r;
  }
 
  String get _imagenUrl {
    final ruta = analisis['imagen']?['rutaImagen'] ?? '';
    if (ruta.toString().startsWith('http')) return ruta.toString();
    return '';
  }
 
  String _formatFecha(dynamic fecha) {
    return AppTheme.formatFechaColombia(fecha);
  }
 
  // ─── Guardar diagnóstico del experto ───────────────────────────────────
 
  // ─── Usar IA como apoyo ─────────────────────────────────────────────────
 
  void _usarIAComoApoyo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
    );
  }
 
  Future<void> _guardarDiagnosticoExperto() async {
    final monitoreoIA = _monitoreoIA;
    if (monitoreoIA == null) return;
    final idMonitoreoOriginal = monitoreoIA['idMonitoreo'] ?? monitoreoIA['id_monitoreo'];
    if (idMonitoreoOriginal == null) return;

    setState(() => _guardando = true);
    try {
      // Crear recomendación directamente vinculada al monitoreo original
      if (_recCtrl.text.trim().isNotEmpty) {
        final resRec = await ApiService.post('/recomendaciones', {
          'descripcion': _recCtrl.text.trim(),
          'id_monitoreo': idMonitoreoOriginal,
        });

        // Vincular tratamiento si seleccionó uno
        final idTratamiento = _tratamientoSeleccionado?['idTratamiento'] ??
            _tratamientoSeleccionado?['id_tratamiento'];
        if (idTratamiento != null) {
          final idRec = resRec['data']?['idRecomendacion'];
          if (idRec != null) {
            try {
              await ApiService.post('/recomendaciones/$idRec/tratamientos', {
                'id_tratamiento': idTratamiento,
              });
            } catch (_) {}
          }
        }
      }

      // Actualizar estado local
      final ahora = DateTime.now();
      final observaciones =
          '[EXPERTO] $_resultado - Severidad $_severidad - ${_obsCtrl.text.trim()}';
      setState(() {
        _diagnosticoExperto = {
          'observaciones': observaciones,
          'fechaMonitoreo': '${ahora.year}-${ahora.month.toString().padLeft(2,'0')}-${ahora.day.toString().padLeft(2,'0')}',
          'recomendacion': _recCtrl.text.trim(),
          'tratamiento': _tratamientoSeleccionado?['nombre'] ?? '',
        };
        _modoFormulario = false;
        _guardando = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnóstico guardado correctamente',
                style: GoogleFonts.nunito()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
 
  // ─── Build ────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          // ── Toggle IA / Experto ──────────────────────────────────────
          Container(
            color: AppColors.headerBg(context),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Recomendación IA'),
                  Tab(text: 'Recomendación Experto'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabIA(),
                      _buildTabExperto(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context) {
    final cultivo = _cultivo;
    final finca = _finca;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: AppColors.headerBg(context),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detalle del diagnóstico',
                          style: GoogleFonts.nunito(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      if (cultivo != null || finca != null)
                        Text(
                          [
                            finca?['nombreFinca'],
                            cultivo?['nombreCultivo'] ?? cultivo?['nombre_cultivo'],
                          ].where((e) => e != null).join(' · '),
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  // ─── Pestaña IA ────────────────────────────────────────────────────────
 
  Widget _buildTabIA() {
    final monitoreoIA = _monitoreoIA;
    final confianza = analisis['porcentajeConfianza'];
    final confianzaNum = confianza != null
        ? double.tryParse(confianza.toString()) ?? 0.0
        : 0.0;
    final confianzaPct = confianzaNum <= 1.0
        ? (confianzaNum * 100).round()
        : confianzaNum.round();
    final color = _colorIA;
 
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto del caficultor ──────────────────────────────────
          if (_imagenUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    _imagenUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagenPlaceholder(color),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(20)),
                      child: Text(_textoResultadoIA,
                          style: GoogleFonts.nunito(
                              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            )
          else
            _imagenPlaceholder(color),
          const SizedBox(height: 16),
 
          // ── Resultado IA ─────────────────────────────────────────
          _buildCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      _esRoya ? Icons.coronavirus_outlined : Icons.eco_outlined,
                      color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resultado de la IA',
                          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                      Text(_textoResultadoIA,
                          style: GoogleFonts.nunito(
                              fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              _filaDetalle('Fecha', _formatFecha(analisis['fechaRegistro'])),
              const SizedBox(height: 8),
              _filaDetalle('Estado',
                  analisis['estadoAnalisis']?['nombreEstado'] ?? 'Sin estado'),
              if (analisis['nivelRoya'] != null) ...[
                const SizedBox(height: 8),
                _filaDetalle('Nivel de roya',
                    analisis['nivelRoya']['nombreNivel'] ?? '-'),
              ],
            ],
          )),
          const SizedBox(height: 14),
 
          // ── Confianza ─────────────────────────────────────────────
          _buildCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Confianza del modelo',
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(confianza != null ? '$confianzaPct%' : 'N/D',
                      style: GoogleFonts.nunito(
                          fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
              if (confianza != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: confianzaNum <= 1.0 ? confianzaNum : confianzaNum / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  confianzaPct >= 75 ? 'Alta precisión – resultado confiable'
                      : confianzaPct >= 45 ? 'Precisión media – revisar con un experto'
                      : 'Baja precisión – se recomienda nueva foto',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          )),
          const SizedBox(height: 14),
 
          // ── Observaciones del caficultor ──────────────────────────
          if (monitoreoIA != null && (monitoreoIA['observaciones'] ?? '').toString().isNotEmpty)
            _buildCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Observaciones del caficultor',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _filaDetalle('Fecha monitoreo',
                    _formatFecha(monitoreoIA['fechaMonitoreo'] ?? monitoreoIA['fecha_monitoreo'])),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    monitoreoIA['observaciones'].toString(),
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                  ),
                ),
              ],
            )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  // ─── Pestaña Experto ───────────────────────────────────────────────────
 
  Widget _buildTabExperto() {
    if (_diagnosticoExperto != null && !_modoFormulario) {
      return _buildDiagnosticoExpertoGuardado();
    }
    if (_modoFormulario || _diagnosticoExperto == null) {
      return _buildFormularioExperto();
    }
    return _buildFormularioExperto();
  }
 
  Widget _buildDiagnosticoExpertoGuardado() {
    final obs = (_diagnosticoExperto!['observaciones'] ?? '').toString();
    // Parsear observaciones: "[EXPERTO] Resultado - Severidad X - Texto"
    String resultado = '';
    String severidad = '';
    String observaciones = obs;
    if (obs.startsWith('[EXPERTO]')) {
      final partes = obs.replaceFirst('[EXPERTO] ', '').split(' - ');
      if (partes.length >= 3) {
        resultado = partes[0];
        severidad = partes[1].replaceFirst('Severidad ', '');
        observaciones = partes.sublist(2).join(' - ');
      }
    }
    final colorSev = severidad == 'Alta' ? Colors.red
        : severidad == 'Media' ? Colors.orange
        : AppColors.primary;
 
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_outline, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diagnóstico del experto',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text(resultado.isNotEmpty ? resultado : 'Ver detalle',
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border),
              const SizedBox(height: 10),
              if (severidad.isNotEmpty)
                _filaDetalle('Severidad', severidad, colorValor: colorSev),
              if (observaciones.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Observaciones',
                    style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(observaciones,
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                ),
              ],
              if ((_diagnosticoExperto!['recomendacion'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Recomendación',
                    style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_diagnosticoExperto!['recomendacion'].toString(),
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppColors.primary, height: 1.5)),
                ),
              ],
              if ((_diagnosticoExperto!['tratamiento'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _filaDetalle('Tratamiento', _diagnosticoExperto!['tratamiento'].toString()),
              ],
            ],
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _modoFormulario = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('Editar mi diagnóstico',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  Widget _buildFormularioExperto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contexto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Basándote en la foto del caficultor o en tu visita a la finca, agrega tu diagnóstico profesional.',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
 
          // Botón usar IA como apoyo
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _usarIAComoApoyo,
              icon: const Icon(Icons.document_scanner_outlined, size: 20),
              label: Text('Usar IA como apoyo',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toma una foto adicional para que la IA te ayude a confirmar tu diagnóstico',
            style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
 
          // Resultado
          Text('Tu diagnóstico',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['Roya confirmada', 'Planta sana', 'Otra'].map((e) {
              final sel = _resultado == e;
              return GestureDetector(
                onTap: () => setState(() => _resultado = e),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(e,
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
 
          // Severidad
          Text('Severidad',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Baja', 'Media', 'Alta'].map((s) {
              final sel = _severidad == s;
              final color = s == 'Alta' ? Colors.red
                  : s == 'Media' ? Colors.orange
                  : AppColors.primary;
              return GestureDetector(
                onTap: () => setState(() => _severidad = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? color : AppColors.border),
                  ),
                  child: Text(s,
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
 
          // Observaciones
          Text('Observaciones',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _obsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe lo que observaste en el cultivo...',
              filled: true, fillColor: AppColors.inputFill(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
            style: GoogleFonts.nunito(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Recomendación
          Text('Tu recomendación',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _recCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ej: Aplicar fungicida cúprico, mejorar drenaje...',
              filled: true, fillColor: AppColors.inputFill(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
            style: GoogleFonts.nunito(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Tratamiento
          Text('Tratamiento sugerido (opcional)',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (widget.tratamientos.isEmpty)
            Text('No hay tratamientos disponibles',
                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  value: _tratamientoSeleccionado,
                  hint: Text('Selecciona un tratamiento',
                      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary)),
                  items: [
                    DropdownMenuItem<Map<String, dynamic>>(
                      value: null,
                      child: Text('Ninguno',
                          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary)),
                    ),
                    ...widget.tratamientos.map((t) => DropdownMenuItem(
                      value: t as Map<String, dynamic>,
                      child: Text(t['nombre'] ?? 'Tratamiento',
                          style: GoogleFonts.nunito(fontSize: 14)),
                    )),
                  ],
                  onChanged: (val) => setState(() => _tratamientoSeleccionado = val),
                ),
              ),
            ),
          const SizedBox(height: 28),
 
          // Botón guardar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardarDiagnosticoExperto,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _guardando
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Guardar mi diagnóstico',
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          if (_modoFormulario) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => setState(() => _modoFormulario = false),
                child: Text('Cancelar',
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: AppColors.textSecondary)),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  // ─── Widgets reutilizables ─────────────────────────────────────────────
 
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: child,
    );
  }
 
  Widget _filaDetalle(String label, String valor, {Color? colorValor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(valor,
              textAlign: TextAlign.right,
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: colorValor ?? AppColors.textPrimary)),
        ),
      ],
    );
  }
 
  Widget _imagenPlaceholder(Color color) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: color.withOpacity(0.4), size: 40),
          const SizedBox(height: 8),
          Text('Imagen no disponible',
              style: GoogleFonts.nunito(fontSize: 12, color: color.withOpacity(0.5))),
        ],
      ),
    );
  }
}
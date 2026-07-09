import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import 'diagnostic_screen.dart';
import 'detalle_analisis_ia_screen.dart';
 
class DiagnosticoExpertoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const DiagnosticoExpertoScreen({super.key, required this.usuario});
 
  @override
  State<DiagnosticoExpertoScreen> createState() =>
      _DiagnosticoExpertoScreenState();
}
 
class _DiagnosticoExpertoScreenState extends State<DiagnosticoExpertoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
 
  bool _cargando = true;
  List _fincas = [];
  List _cultivos = [];
  List _monitoreos = [];
  List _diagnosticosIA = [];
  List _recomendaciones = [];
  List _tratamientos = [];
 
  Map<String, dynamic>? _fincaSeleccionada;
  Map<String, dynamic>? _cultivoSeleccionado;
 
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
  String _filtroResultado = 'Todos'; 
  String? _filtroCultivo;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
    AppState.instance.addListener(_onAppStateChanged);
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
 
  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {
      _fincaSeleccionada = AppState.instance.fincaSeleccionada;
      _cultivoSeleccionado = AppState.instance.cultivoSeleccionado;
    });
  }
 
  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        ApiService.get('/experto/fincas'),
        ApiService.get('/experto/cultivos'),
        ApiService.get('/experto/monitoreos'),
        ApiService.get('/experto/analisis_ia'),
        ApiService.get('/recomendaciones'),
        ApiService.get('/tratamientos'),
      ]);
 
      List _list(dynamic r) =>
          r is List ? r : (r['data'] ?? r['items'] ?? []);
 
      setState(() {
        _fincas = _list(results[0]);
        _cultivos = _list(results[1]);
        _monitoreos = _list(results[2]);
        _diagnosticosIA = _list(results[3]);
        _recomendaciones = _list(results[4]);
        _tratamientos = _list(results[5]);
 
        _fincaSeleccionada = AppState.instance.fincaSeleccionada ??
            (_fincas.isNotEmpty ? _fincas[0] : null);
        _cultivoSeleccionado = AppState.instance.cultivoSeleccionado;
 
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }
 
  List _aplicarFiltros(List items) {
    return items.where((d) {
      if (_filtroResultado != 'Todos') {
        final res = (d['resultado'] ?? '').toString().toLowerCase();
        if (_filtroResultado == 'Roya' && !res.contains('roya')) return false;
        if (_filtroResultado == 'Sana' &&
            !res.contains('sana') && !res.contains('sano') &&
            !res.contains('hoja_sana')) return false;
      }
 
      if (_filtroCultivo != null) {
        final idMonitoreo = d['imagen']?['idMonitoreo'] ?? d['imagen']?['id_monitoreo'];
        final idCultivoAnalisis = _idCultivoDeMonitoreo(idMonitoreo);
        if (idCultivoAnalisis == null || idCultivoAnalisis != _filtroCultivo) return false;
      }
 
      final fechaStr = d['fechaRegistro'] ?? d['fecha_registro'];
      if (fechaStr != null) {
        try {
          final fecha = DateTime.parse(fechaStr.toString()).toLocal();
          if (_filtroFechaDesde != null && fecha.isBefore(_filtroFechaDesde!)) return false;
          if (_filtroFechaHasta != null && fecha.isAfter(_filtroFechaHasta!.add(const Duration(days: 1)))) return false;
        } catch (_) {}
      }
 
      if (_busqueda.isNotEmpty) {
        final q = _busqueda.toLowerCase();
        final res = (d['resultado'] ?? '').toString().toLowerCase();
        final fecha = (d['fechaRegistro'] ?? '').toString().toLowerCase();
        if (!res.contains(q) && !fecha.contains(q)) return false;
      }
 
      return true;
    }).toList();
  }
 
  Future<void> _seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (esDesde) _filtroFechaDesde = picked;
        else _filtroFechaHasta = picked;
      });
    }
  }
 
  void _limpiarFiltros() {
    setState(() {
      _busqueda = '';
      _searchCtrl.clear();
      _filtroResultado = 'Todos';
      _filtroCultivo = null;
      _filtroFechaDesde = null;
      _filtroFechaHasta = null;
    });
  }
 
  bool get _hayFiltrosActivos =>
      _busqueda.isNotEmpty ||
      _filtroResultado != 'Todos' ||
      _filtroCultivo != null ||
      _filtroFechaDesde != null ||
      _filtroFechaHasta != null;
 
  List _cultivosDeFinca(Map<String, dynamic> finca) {
    final idFinca = finca['idFinca'] ?? finca['id_finca'];
    return _cultivos
        .where((c) =>
            (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString())
        .toList();
  }
 
  Set<String> get _idsCultivosFincaSeleccionada {
    if (_fincaSeleccionada == null) return {};
    return _cultivosDeFinca(_fincaSeleccionada!)
        .map((c) => (c['idCultivo'] ?? c['id_cultivo']).toString())
        .toSet();
  }
 
  String? _idCultivoDeMonitoreo(dynamic idMonitoreo) {
    if (idMonitoreo == null) return null;
    final monitoreo = _monitoreos.firstWhere(
      (m) => (m['idMonitoreo'] ?? m['id_monitoreo']).toString() == idMonitoreo.toString(),
      orElse: () => null,
    );
    if (monitoreo == null) return null;
    final idCultivo = monitoreo['idCultivo'] ?? monitoreo['id_cultivo'];
    return idCultivo?.toString();
  }
 
  List _filtrarMonitoreosPorSeleccion(List items) {
    if (_fincaSeleccionada == null) return items;
    final idsCultivosFinca = _idsCultivosFincaSeleccionada;
 
    return items.where((item) {
      final idCultivoItem = (item['idCultivo'] ?? item['id_cultivo'])?.toString();
      if (idCultivoItem == null) return true; 
 
      if (_cultivoSeleccionado != null) {
        final idCultivoSel =
            (_cultivoSeleccionado!['idCultivo'] ?? _cultivoSeleccionado!['id_cultivo']).toString();
        return idCultivoItem == idCultivoSel;
      }
      return idsCultivosFinca.contains(idCultivoItem);
    }).toList();
  }
 
  List _filtrarAnalisisIAPorSeleccion(List items) {
    if (_fincaSeleccionada == null) return items;
    final idsCultivosFinca = _idsCultivosFincaSeleccionada;
 
    return items.where((analisis) {
      final idMonitoreo = analisis['imagen']?['idMonitoreo'] ??
          analisis['imagen']?['id_monitoreo'];
      final idCultivoAnalisis = _idCultivoDeMonitoreo(idMonitoreo);
 
      if (idCultivoAnalisis == null) return true;
 
      if (_cultivoSeleccionado != null) {
        final idCultivoSel =
            (_cultivoSeleccionado!['idCultivo'] ?? _cultivoSeleccionado!['id_cultivo']).toString();
        return idCultivoAnalisis == idCultivoSel;
      }
      return idsCultivosFinca.contains(idCultivoAnalisis);
    }).toList();
  }
 
 
  void _abrirNuevoDiagnostico() {
    if (_fincas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No tienes fincas asignadas',
            style: GoogleFonts.nunito()), backgroundColor: Colors.red),
      );
      return;
    }
 
    Map<String, dynamic>? finca = _fincaSeleccionada ?? _fincas[0];
    Map<String, dynamic>? cultivo = _cultivoSeleccionado;
    final obsCtrl    = TextEditingController();
    final fechaCtrl  = TextEditingController(
        text: DateTime.now().toString().substring(0, 10));
    String enfermedad = 'Roya';
    String severidad  = 'Media';
    bool guardando    = false;
 
    final List<Map<String, dynamic>> recsLocales = [];
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final cultivosFinca = finca != null ? _cultivosDeFinca(finca!) : [];
 
          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFEFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('Nuevo diagnóstico',
                          style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _labelForm('Finca'),
                        const SizedBox(height: 8),
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
                              value: finca,
                              items: _fincas.map((f) => DropdownMenuItem(
                                value: f as Map<String, dynamic>,
                                child: Text(f['nombreFinca'] ?? 'Finca',
                                    style: GoogleFonts.nunito(fontSize: 14)),
                              )).toList(),
                              onChanged: (val) => setModal(() {
                                finca   = val;
                                cultivo = null;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
 
                        _labelForm('Cultivo'),
                        const SizedBox(height: 8),
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
                              value: cultivosFinca.any((c) =>
                                      (c['idCultivo'] ?? c['id_cultivo']).toString() ==
                                      (cultivo?['idCultivo'] ?? cultivo?['id_cultivo'])?.toString())
                                  ? cultivo
                                  : null,
                              hint: Text('Selecciona un cultivo',
                                  style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary)),
                              items: cultivosFinca.map((c) => DropdownMenuItem(
                                value: c as Map<String, dynamic>,
                                child: Text(c['nombreCultivo'] ?? c['nombre_cultivo'] ?? 'Cultivo',
                                    style: GoogleFonts.nunito(fontSize: 14)),
                              )).toList(),
                              onChanged: (val) => setModal(() => cultivo = val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
 
                        _labelForm('Fecha'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: fechaCtrl,
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: const Icon(Icons.calendar_today_outlined,
                                color: AppColors.primary, size: 20),
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
 
                        _labelForm('Enfermedad detectada'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Roya', 'Planta sana', 'Otra'].map((e) {
                            final sel = enfermedad == e;
                            return GestureDetector(
                              onTap: () => setModal(() => enfermedad = e),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                                ),
                                child: Text(e,
                                    style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: sel ? Colors.white : AppColors.textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
 
                        _labelForm('Severidad'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Baja', 'Media', 'Alta'].map((s) {
                            final sel = severidad == s;
                            final color = s == 'Alta' ? Colors.red
                                : s == 'Media' ? Colors.orange
                                : AppColors.primary;
                            return GestureDetector(
                              onTap: () => setModal(() => severidad = s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? color : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: sel ? color : AppColors.border),
                                ),
                                child: Text(s,
                                    style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: sel ? Colors.white : AppColors.textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
 
                        _labelForm('Observaciones'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: obsCtrl,
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
                        const SizedBox(height: 20),
 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _labelForm('Recomendaciones'),
                            GestureDetector(
                              onTap: () => _agregarRecomendacionLocal(ctx, setModal, recsLocales),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Agregar',
                                        style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (recsLocales.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('Toca "Agregar" para añadir recomendaciones con tratamientos',
                                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary)),
                          )
                        else
                          ...recsLocales.asMap().entries.map((entry) {
                            final i   = entry.key;
                            final rec = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                              color: AppColors.cardBg(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24, height: 24,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text('${i + 1}',
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(rec['descripcion'] ?? '',
                                            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)),
                                      ),
                                      GestureDetector(
                                        onTap: () => setModal(() => recsLocales.removeAt(i)),
                                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  if ((rec['tratamientos'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...(rec['tratamientos'] as List).map((t) => Padding(
                                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.healing_outlined, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(t['nombre'] ?? '',
                                              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    )),
                                  ],
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
 
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: guardando ? null : () async {
                              if (cultivo == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Selecciona un cultivo',
                                      style: GoogleFonts.nunito()), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setModal(() => guardando = true);
                              await _guardarDiagnosticoCompleto(
                                cultivo:         cultivo!,
                                fecha:           fechaCtrl.text.trim(),
                                observaciones:   '${enfermedad} - Severidad ${severidad} - ${obsCtrl.text.trim()}',
                                recomendaciones: recsLocales,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: guardando
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Text('Guardar diagnóstico',
                                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
 
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const DiagnosticScreen(),
                              ));
                            },
                            icon: const Icon(Icons.document_scanner_outlined, size: 20),
                            label: Text('Usar IA como apoyo',
                                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
 
 
  void _agregarRecomendacionLocal(
      BuildContext ctx,
      StateSetter setModal,
      List<Map<String, dynamic>> recsLocales) {
    final descCtrl = TextEditingController();
    final List<Map<String, dynamic>> tratamientosSeleccionados = [];
 
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nueva recomendación',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe la recomendación...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.nunito(fontSize: 13),
                ),
                const SizedBox(height: 16),
                Text('Tratamientos',
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._tratamientos.map((t) {
                  final nombre = t['nombre'] ?? '';
                  final seleccionado = tratamientosSeleccionados
                      .any((s) => s['nombre'] == nombre);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(nombre, style: GoogleFonts.nunito(fontSize: 13)),
                    subtitle: t['descripcion'] != null
                        ? Text(t['descripcion'], style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary))
                        : null,
                    value: seleccionado,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setDialog(() {
                        if (val == true) {
                          tratamientosSeleccionados.add(t as Map<String, dynamic>);
                        } else {
                          tratamientosSeleccionados.removeWhere((s) => s['nombre'] == nombre);
                        }
                      });
                    },
                  );
                }),
                if (_tratamientos.isEmpty)
                  Text('No hay tratamientos disponibles',
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text('Cancelar', style: GoogleFonts.nunito(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (descCtrl.text.trim().isEmpty) return;
                setModal(() {
                  recsLocales.add({
                    'descripcion': descCtrl.text.trim(),
                    'tratamientos': List.from(tratamientosSeleccionados),
                  });
                });
                Navigator.pop(dctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Agregar', style: GoogleFonts.nunito(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
 
 
  Future<void> _guardarDiagnosticoCompleto({
    required Map<String, dynamic> cultivo,
    required String fecha,
    required String observaciones,
    required List<Map<String, dynamic>> recomendaciones,
  }) async {
    try {
      final idCultivo = cultivo['idCultivo'] ?? cultivo['id_cultivo'];
 
      final resMonitoreo = await ApiService.post('/monitoreos', {
        'id_cultivo':      idCultivo,
        'fecha_monitoreo': fecha,
        'observaciones':   observaciones,
      });
      final idMonitoreo = resMonitoreo['data']?['idMonitoreo'] as int?;
 
      for (final rec in recomendaciones) {
        final resRec = await ApiService.post('/recomendaciones', {
          'descripcion':  rec['descripcion'],
          if (idMonitoreo != null) 'id_monitoreo': idMonitoreo,
        });
 
        final idRecomendacion = resRec['data']?['idRecomendacion'] as int?;
 
        if (idRecomendacion != null) {
          for (final t in (rec['tratamientos'] as List)) {
            final idTratamiento = t['idTratamiento'] ?? t['id_tratamiento'];
            if (idTratamiento != null) {
              try {
                await ApiService.post('/recomendaciones/$idRecomendacion/tratamientos', {
                  'id_tratamiento': idTratamiento,
                });
              } catch (_) {}
            }
          }
        }
      }
 
      await _cargarDatos();
      AppState.instance.notifyMonitoreoGuardado();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
 
 
  @override
  Widget build(BuildContext context) {
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
                child: _buildHeader(),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [
              Tab(text: 'Diagnósticos IA'),
              Tab(text: 'Mis visitas'),
            ],
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDiagnosticosIA(),
                      _buildMisDiagnosticos(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildHeader() {
    final nombreFinca = _fincaSeleccionada?['nombreFinca'] ??
        _fincaSeleccionada?['nombre_finca'];
    final nombreCultivo = _cultivoSeleccionado?['nombreCultivo'] ??
        _cultivoSeleccionado?['nombre_cultivo'];
 
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF97D340), Color(0xFF388E3C)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diagnósticos',
                          style: GoogleFonts.nunito(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      if (nombreFinca != null)
                        Text(
                          nombreCultivo != null
                              ? '$nombreFinca · $nombreCultivo'
                              : nombreFinca,
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (_hayFiltrosActivos)
                  TextButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: Text('Limpiar',
                        style: GoogleFonts.nunito(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  onPressed: _cargarDatos,
                ),
              ],
            ),
          ),
 
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _busqueda = v),
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por resultado o fecha...',
                hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _busqueda = '';
                          _searchCtrl.clear();
                        }),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.inputFill(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
 
        ],
      ),
    );
  }
 
 
  Widget _buildDiagnosticosIA() {
    final filtradosPorFinca = _filtrarAnalisisIAPorSeleccion(_diagnosticosIA);
    final filtrados = _aplicarFiltros(filtradosPorFinca);
 
    if (filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _hayFiltrosActivos
                  ? 'No hay diagnósticos con los filtros aplicados'
                  : _diagnosticosIA.isEmpty
                      ? 'No hay diagnósticos de IA aún'
                      : 'No hay diagnósticos de IA para esta selección',
              style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            if (_hayFiltrosActivos) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: Text('Limpiar filtros', style: GoogleFonts.nunito()),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      );
    }
 
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: filtrados.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleAnalisisIAScreen(
                analisis: filtrados[i] as Map<String, dynamic>,
                monitoreos: _monitoreos,
                cultivos: _cultivos,
                fincas: _fincas,
                tratamientos: _tratamientos,
              ),
            ),
          ),
          child: _cardDiagnosticoIA(filtrados[i]),
        ),
      ),
    );
  }
 
  Widget _cardDiagnosticoIA(dynamic d) {
    final resultado = d['resultado'] ?? 'Sin resultado';
    final confianza = d['confianza'] ?? '0';
    final fecha     = _formatFecha(d['fechaRegistro'] ?? d['fecha_registro']);
    final esRoya    = resultado.toString().toLowerCase().contains('roya');
    final color     = esRoya ? Colors.red : AppColors.primary;
 
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              esRoya ? Icons.coronavirus_outlined : Icons.eco_outlined,
              color: color, size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resultado,
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Confianza: $confianza% · $fecha',
                    style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(esRoya ? 'Roya' : 'Sana',
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
 
 
  Widget _buildMisDiagnosticos() {
    final misVisitas = _filtrarMonitoreosPorSeleccion(
      _monitoreos.where((m) {
        final obs = (m['observaciones'] ?? '').toString();
        return obs.contains('[EXPERTO]');
      }).toList(),
    );
 
    if (misVisitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Aún no has registrado visitas',
                style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 15),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Entra a un diagnóstico IA y agrega\ntu criterio profesional',
                style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
 
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: misVisitas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _cardMiVisita(misVisitas[i]),
      ),
    );
  }
 
  Widget _cardMiVisita(dynamic m) {
    final obs = (m['observaciones'] ?? '').toString();
    final fecha = _formatFecha(m['fechaMonitoreo'] ?? m['fecha_monitoreo']);
 
    String resultado = 'Ver detalle';
    String severidad = '';
    String observaciones = '';
    if (obs.startsWith('[EXPERTO]')) {
      final partes = obs.replaceFirst('[EXPERTO] ', '').split(' - ');
      if (partes.length >= 2) {
        resultado = partes[0];
        severidad = partes.length >= 2 ? partes[1].replaceFirst('Severidad ', '') : '';
        observaciones = partes.length >= 3 ? partes.sublist(2).join(' - ') : '';
      }
    }
 
    final esRoya = resultado.toLowerCase().contains('roya');
    final color = severidad == 'Alta' ? Colors.red
        : severidad == 'Media' ? Colors.orange
        : AppColors.primary;
 
    final idCultivo = (m['idCultivo'] ?? m['id_cultivo'])?.toString();
    final cultivo = idCultivo != null
        ? _cultivos.firstWhere(
            (c) => (c['idCultivo'] ?? c['id_cultivo']).toString() == idCultivo,
            orElse: () => null)
        : null;
    final nombreCultivo = cultivo != null
        ? (cultivo['nombreCultivo'] ?? cultivo['nombre_cultivo'] ?? 'Cultivo')
        : 'Cultivo';
 
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  esRoya ? Icons.coronavirus_outlined : Icons.eco_outlined,
                  color: color, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resultado,
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    Text('$nombreCultivo · $fecha',
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (severidad.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(severidad,
                      style: GoogleFonts.nunito(
                          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
            ],
          ),
          if (observaciones.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border),
            const SizedBox(height: 6),
            Text(observaciones,
                style: GoogleFonts.nunito(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
 
  Widget _labelForm(String label) {
    return Text(label,
        style: GoogleFonts.nunito(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }
 
  String _formatFecha(dynamic fecha) {
    return AppTheme.formatFechaColombia(fecha, withTime: false);
  }
}
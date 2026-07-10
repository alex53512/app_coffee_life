import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../services/app_state.dart';

/// Pantalla de detalle de una finca: muestra las recomendaciones que el
/// experto le dio a cada lote/cultivo, y permite llevar el seguimiento
/// d├¡a por d├¡a de si el tratamiento recetado se aplic├│ o no en cada lote.
class FincaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> finca;

  const FincaDetalleScreen({super.key, required this.finca});

  @override
  State<FincaDetalleScreen> createState() => _FincaDetalleScreenState();
}

class _FincaDetalleScreenState extends State<FincaDetalleScreen> {
  bool _cargando = true;
  String? _error;

  List _cultivos = [];

  // Por cada idCultivo: la recomendaci├│n m├ís reciente del experto (o null).
  final Map<int, Map<String, dynamic>?> _recomendacionPorCultivo = {};

  // Por cada idCultivo: el tratamiento recetado (producto/dosis/frecuencia).
  final Map<int, Map<String, dynamic>?> _tratamientoPorCultivo = {};

  // Por cada idCultivo: el progreso d├¡a-a-d├¡a (d├¡a 1..N -> aplicado true/false).
  final Map<int, Map<int, bool>> _progresoPorCultivo = {};

  // ids de cultivo cuyo tratamiento ya fue aceptado por el caficultor.
  final Set<int> _aceptadoPorCultivo = {};

  // Duraci├│n del tratamiento por cultivo (viene del backend o 15 por defecto).
  final Map<int, int> _duracionPorCultivo = {};

  int? get _idFinca =>
      int.tryParse((widget.finca['idFinca'] ?? widget.finca['id_finca'] ?? '').toString());

  String get _nombreFinca =>
      (widget.finca['nombreFinca'] ?? widget.finca['nombre_finca'] ?? 'Mi finca').toString();

  String get _municipioFinca =>
      (widget.finca['municipio'] ?? '').toString();

  String? _lastFincaId;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onEstadoCambiado);
    _cargarTodo();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onEstadoCambiado);
    super.dispose();
  }

  void _onEstadoCambiado() {
    final nueva = AppState.instance.fincaSeleccionada?['idFinca']?.toString();
    if (nueva != _lastFincaId) {
      _lastFincaId = nueva;
      _limpiarDatos();
      _cargarTodo();
    } else {
      _cargarTodo();
    }
  }

  void _limpiarDatos() {
    _cultivos = [];
    _recomendacionPorCultivo.clear();
    _tratamientoPorCultivo.clear();
    _progresoPorCultivo.clear();
    _aceptadoPorCultivo.clear();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // Usamos los cultivos que ya est├ín en AppState (los mismos del Home)
      _cultivos = List.from(AppState.instance.cultivosFinca);

      // Por cada lote: traemos su recomendaci├│n m├ís reciente y su
      // tratamiento recetado (mejor esfuerzo, sin romper si falla).
      for (final c in _cultivos) {
        final idCultivo =
            int.tryParse((c['idCultivo'] ?? c['id_cultivo'] ?? '').toString());
        if (idCultivo == null) continue;

        await _cargarRecomendacionYTratamiento(idCultivo);
        await _cargarProgresoYAceptado(idCultivo);
      }

      if (mounted) setState(() => _cargando = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cargarRecomendacionYTratamiento(int idCultivo) async {
    // ÔöÇÔöÇ Recomendaci├│n del experto para este lote ÔöÇÔöÇ
    try {
      dynamic dataRec;
      try {
        dataRec = await ApiService.get('/recomendaciones?idCultivo=$idCultivo');
      } catch (_) {
        dataRec = await ApiService.get('/recomendaciones?id_cultivo=$idCultivo');
      }
      final listaRec = dataRec is List ? dataRec : (dataRec['data'] ?? []);
      if ((listaRec as List).isNotEmpty) {
        _recomendacionPorCultivo[idCultivo] = Map<String, dynamic>.from(listaRec[0]);
      }
    } catch (_) {
      _recomendacionPorCultivo[idCultivo] = null;
    }

    // ÔöÇÔöÇ Tratamiento recetado (solo si viene embebido en la recomendaci├│n) ÔöÇÔöÇ
    Map<String, dynamic>? trat;
    try {
      final rec = _recomendacionPorCultivo[idCultivo];
      final tratamientosEmbebidos = rec?['tratamientos'] as List?;
      if (tratamientosEmbebidos != null && tratamientosEmbebidos.isNotEmpty) {
        trat = Map<String, dynamic>.from(tratamientosEmbebidos[0]);
      }
    } catch (_) {}

    // Si no vino embebido, buscar desde SharedPreferences
    if (trat == null) {
      final prefs = await SharedPreferences.getInstance();
      final nombre = prefs.getString('trat_nombre_$idCultivo');
      final dosis = prefs.getString('trat_dosis_$idCultivo');
      final frecuencia = prefs.getString('trat_frecuencia_$idCultivo');
      if (nombre != null) {
        trat = <String, dynamic>{
          'nombre': nombre,
          if (dosis != null) 'dosisRecomendada': dosis,
          if (frecuencia != null) 'frecuencia': frecuencia,
        };
      }
    }

    _tratamientoPorCultivo[idCultivo] = trat;
  }

  // ÔöÇÔöÇ Progreso + aceptado desde backend ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
  // Si el backend no responde, cae en SharedPreferences como respaldo.

  String _claveProgreso(int idCultivo) => 'trat_progreso_$idCultivo';
  String _claveAceptado(int idCultivo) => 'trat_aceptado_$idCultivo';
  String _claveDuracion(int idCultivo) => 'trat_duracion_$idCultivo';
  String _claveFechaInicio(int idCultivo) => 'trat_fecha_inicio_$idCultivo';

  Future<void> _cargarProgresoYAceptado(int idCultivo) async {
    final mapa = <int, bool>{};
    bool aceptado = false;
    int duracion = 15;

    // Cargar progreso desde almacenamiento local
    {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_claveProgreso(idCultivo));
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          decoded.forEach((k, v) => mapa[int.parse(k)] = v == true);
        } catch (_) {}
      }
      final aceptadoLocal = prefs.getBool(_claveAceptado(idCultivo));
      if (aceptadoLocal == true) aceptado = true;
      final duracionLocal = prefs.getInt(_claveDuracion(idCultivo));
      if (duracionLocal != null) duracion = duracionLocal;
    }

    // Auto-marcar con X días pasados no marcados
    if (aceptado) {
      final prefs = await SharedPreferences.getInstance();
      final fechaInicioStr = prefs.getString(_claveFechaInicio(idCultivo));
      if (fechaInicioStr != null) {
        final fechaInicio = DateTime.tryParse(fechaInicioStr);
        if (fechaInicio != null) {
          final hoy = DateTime.now();
          bool huboCambio = false;
          for (int dia = 1; dia <= duracion; dia++) {
            final diaFecha = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day + (dia - 1));
            if (diaFecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day)) && !mapa.containsKey(dia)) {
              mapa[dia] = false;
              huboCambio = true;
            }
          }
          if (huboCambio) {
            final encoded = jsonEncode(mapa.map((k, v) => MapEntry(k.toString(), v)));
            await prefs.setString(_claveProgreso(idCultivo), encoded);
          }
        }
      }
    }

    _progresoPorCultivo[idCultivo] = mapa;
    _duracionPorCultivo[idCultivo] = duracion;
    if (aceptado) _aceptadoPorCultivo.add(idCultivo);
  }

  Future<void> _guardarProgreso(int idCultivo) async {
    final mapa = _progresoPorCultivo[idCultivo] ?? {};
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(mapa.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString(_claveProgreso(idCultivo), encoded);
  }

  Future<void> _aceptarTratamiento(int idCultivo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveAceptado(idCultivo), true);
    setState(() => _aceptadoPorCultivo.add(idCultivo));
  }

  void _toggleDia(int idCultivo, int dia) {
    final mapa = _progresoPorCultivo.putIfAbsent(idCultivo, () => {});
    final actual = mapa[dia];
    setState(() {
      // Ciclo: sin marcar -> aplicado (true) -> no aplicado (false) -> sin marcar
      if (actual == null) {
        mapa[dia] = true;
      } else if (actual == true) {
        mapa[dia] = false;
      } else {
        mapa.remove(dia);
      }
    });
    _guardarProgreso(idCultivo);
  }

  String _nombreCultivo(dynamic c) =>
      (c['nombreCultivo'] ?? c['nombre_cultivo'] ?? 'Lote').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      body: Column(
        children: [
          AppHeader.back(context, _nombreFinca,
            subtitle: _municipioFinca.isNotEmpty ? _municipioFinca : null,
            height: 64,
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _cargarTodo,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_idFinca == null)
                                _sinFincaSeleccionada()
                              else if (_cultivos.isEmpty)
                                _sinDatos()
                              else if (_cultivos.every((c) {
                                final id = int.tryParse((c['idCultivo'] ?? c['id_cultivo'] ?? '').toString());
                                return id == null || !_aceptadoPorCultivo.contains(id);
                              }))
                                _sinAceptados()
                              else
                                ..._cultivos.map((c) => _buildLoteSection(c)),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error al cargar la finca',
              style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _cargarTodo,
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
            child: Text('Reintentar', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sinFincaSeleccionada() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text('Selecciona una finca en Inicio',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('para ver el seguimiento de sus lotes',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _sinDatos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text('No hay lotes registrados en esta finca',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _sinAceptados() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text('No hay tratamientos aceptados',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('Ve a Monitoreos, abre un monitoreo con recomendación y toca "Aceptar tratamiento"',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoteSection(dynamic c) {
    final idCultivo = int.tryParse((c['idCultivo'] ?? c['id_cultivo'] ?? '').toString());
    if (idCultivo == null || !_aceptadoPorCultivo.contains(idCultivo)) {
      return const SizedBox.shrink();
    }
    final nombreLote = _nombreCultivo(c);
    final trat = _tratamientoPorCultivo[idCultivo];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.grass_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(nombreLote,
                  style: GoogleFonts.nunito(
                      fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Tratamiento recetado ──
          if (trat != null) ...[
            _buildSeguimientoCard(idCultivo, trat),
          ],
        ],
      ),
    );
  }

  Widget _buildSinRecomendacion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Sin recomendaci├│n del experto para este lote todav├¡a.',
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendacionCard(Map<String, dynamic> rec) {
    final descripcion = (rec['descripcion'] ?? 'Sin descripci├│n').toString();
    final prioridadObj = rec['prioridad'];
    final prioridad = (prioridadObj is Map)
        ? (prioridadObj['nombrePrioridad'] ?? prioridadObj['nombre_prioridad'] ?? 'Normal').toString()
        : (prioridadObj?.toString() ?? 'Normal');

    Color colorPrioridad = AppColors.primary;
    if (prioridad.toLowerCase().contains('alt')) colorPrioridad = Colors.red;
    else if (prioridad.toLowerCase().contains('med')) colorPrioridad = Colors.orange;

    final expertoObj = rec['experto'];
    String nombreExperto = '';
    if (expertoObj is Map) {
      nombreExperto = '${expertoObj['nombre'] ?? ''} ${expertoObj['apellido'] ?? ''}'.trim();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notes_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(descripcion,
                    style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: colorPrioridad.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('Prioridad: $prioridad',
                    style: GoogleFonts.nunito(
                        fontSize: 11, fontWeight: FontWeight.w700, color: colorPrioridad)),
              ),
              if (nombreExperto.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text('┬À $nombreExperto',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAceptarCard(int idCultivo, Map<String, dynamic> trat) {
    final nombre = (trat['nombre'] ?? 'Tratamiento').toString();
    final dosis = (trat['dosisRecomendada'] ?? trat['dosis_recomendada'] ?? '').toString();
    final frecuencia = (trat['frecuencia'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.medication_outlined, color: Color(0xFF1565C0), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    if (dosis.isNotEmpty || frecuencia.isNotEmpty)
                      Text([dosis, frecuencia].where((s) => s.isNotEmpty).join(' ┬À '),
                          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _aceptarTratamiento(idCultivo),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text('Seguir tratamiento',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeguimientoCard(int idCultivo, Map<String, dynamic> trat) {
    final nombre = (trat['nombre'] ?? 'Tratamiento').toString();
    final dosis = (trat['dosisRecomendada'] ?? trat['dosis_recomendada'] ?? '').toString();
    final frecuencia = (trat['frecuencia'] ?? '').toString();

    final progreso = _progresoPorCultivo[idCultivo] ?? {};
    final aplicados = progreso.values.where((v) => v == true).length;

    final totalDias = _duracionPorCultivo[idCultivo] ?? 15;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.medication_outlined, color: Color(0xFF1565C0), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    if (dosis.isNotEmpty || frecuencia.isNotEmpty)
                      Text([dosis, frecuencia].where((s) => s.isNotEmpty).join(' ┬À '),
                          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text('$aplicados/$totalDias d├¡as',
                  style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Text('Toca cada d├¡a: Ô£à aplicado ┬À ÔØî no aplicado ┬À gris = sin marcar',
              style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(totalDias, (i) {
              final dia = i + 1;
              final estado = progreso[dia];
              Color bg;
              Color fg;
              IconData? icono;
              if (estado == true) {
                bg = AppColors.primary;
                fg = Colors.white;
                icono = Icons.check_rounded;
              } else if (estado == false) {
                bg = Colors.red;
                fg = Colors.white;
                icono = Icons.close_rounded;
              } else {
                bg = Colors.grey.shade100;
                fg = AppColors.textSecondary;
                icono = null;
              }
              return GestureDetector(
                onTap: () => _toggleDia(idCultivo, dia),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: icono != null
                        ? Icon(icono, color: fg, size: 18)
                        : Text('$dia',
                            style: GoogleFonts.nunito(
                                fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

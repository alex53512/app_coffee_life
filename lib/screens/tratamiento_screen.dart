import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
 
class TratamientoScreen extends StatefulWidget {
  final int cultivoId;
  final String diagnosisText;
  final String scientificName;
  final double confidence;
 
  const TratamientoScreen({
    super.key,
    required this.cultivoId,
    required this.diagnosisText,
    required this.scientificName,
    required this.confidence,
  });
 
  @override
  State<TratamientoScreen> createState() => _TratamientoScreenState();
}
 
class _TratamientoScreenState extends State<TratamientoScreen> {
  bool _cargando = true;
  List<dynamic> _tratamientos = [];
  Map<String, dynamic>? _seleccionado;
 
  bool _guardando = false;
  bool _guardado = false;
 
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    _cargarTratamientos();
  }
 
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }
 
  // ─── Clasificación de tratamientos por severidad (lista fija en código) ──
  static const Map<String, String> _severidadPorNombre = {
    'Fungicida triazol': 'Alta',
    'Fungicida a base de azoxistrobina': 'Alta',
    'Poda selectiva de ramas afectadas': 'Alta',
    'Aplicación de tebuconazol': 'Alta',
    'Fungicida cobre': 'Media',
    'Fungicida foliar': 'Media',
    'Aplicación de mancozeb': 'Media',
    'Fertilización balanceada': 'Baja',
    'Mejora de sombrío': 'Baja',
  };
 
  String get _severidadActual {
    final pct = (widget.confidence * 100);
    if (pct >= 70) return 'Alta';
    if (pct >= 40) return 'Media';
    return 'Baja';
  }
 
  List<dynamic> _filtrarPorSeveridad(List<dynamic> tratamientos) {
    final severidad = _severidadActual;
    final exactos = tratamientos.where((t) {
      final nombre = (t['nombre'] ?? '').toString();
      return _severidadPorNombre[nombre] == severidad;
    }).toList();
 
    if (exactos.length >= 2) return exactos.take(3).toList();
 
    final sinClasificar = tratamientos.where((t) {
      final nombre = (t['nombre'] ?? '').toString();
      return !_severidadPorNombre.containsKey(nombre);
    }).toList();
 
    return [...exactos, ...sinClasificar].take(3).toList();
  }
 
  Future<void> _cargarTratamientos() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.get('/tratamientos');
      final listaCompleta = data is List ? data : (data['data'] ?? data['tratamientos'] ?? []);
      final lista = _filtrarPorSeveridad(listaCompleta);
      setState(() {
        _tratamientos = lista;
        _seleccionado = lista.isNotEmpty ? lista[0] : null;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error cargando tratamientos: $e');
    }
  }
 
  Future<void> _verDetalle(int id) async {
    try {
      final data = await ApiService.get('/tratamientos/$id');
      setState(() => _seleccionado = data is Map ? data : data['data']);
    } catch (e) {
      _mostrarError('Error cargando detalle: $e');
    }
  }
 
  Future<void> _crearTratamiento() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarError('El nombre es obligatorio');
      return;
    }
    try {
      await ApiService.post('/tratamientos', {
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
      });
      _nombreCtrl.clear();
      _descripcionCtrl.clear();
      Navigator.pop(context);
      await _cargarTratamientos();
      _mostrarExito('Tratamiento creado correctamente');
    } catch (e) {
      _mostrarError('Error creando tratamiento: $e');
    }
  }
 
  Future<void> _editarTratamiento(Map<String, dynamic> tratamiento) async {
    final id = tratamiento['idTratamiento'] ?? tratamiento['id_tratamiento'];
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarError('El nombre es obligatorio');
      return;
    }
    try {
      await ApiService.put('/tratamientos/$id', {
        'nombre': _nombreCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
      });
      _nombreCtrl.clear();
      _descripcionCtrl.clear();
      Navigator.pop(context);
      await _cargarTratamientos();
      _mostrarExito('Tratamiento actualizado correctamente');
    } catch (e) {
      _mostrarError('Error actualizando tratamiento: $e');
    }
  }
 
  Future<void> _eliminarTratamiento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar tratamiento', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro de que deseas eliminar este tratamiento?', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ApiService.delete('/tratamientos/$id');
      await _cargarTratamientos();
      _mostrarExito('Tratamiento eliminado correctamente');
    } catch (e) {
      _mostrarError('Error eliminando tratamiento: $e');
    }
  }
 
  Future<void> _guardarMonitoreo() async {
    if (_guardado || _guardando) return;
    setState(() => _guardando = true);
    try {
      final hoy = DateTime.now();
      final fechaStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      await ApiService.post('/monitoreos', {
        'id_cultivo': widget.cultivoId,
        'fecha_monitoreo': fechaStr,
        'observaciones': '${widget.diagnosisText} — Confianza: ${(widget.confidence * 100).round()}% — ${widget.scientificName}',
      });
      AppState.instance.notifyMonitoreoGuardado();
      if (mounted) {
        setState(() { _guardando = false; _guardado = true; });
        _mostrarExito('Monitoreo guardado correctamente');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _mostrarError('Error al guardar: $e');
      }
    }
  }
 
  void _abrirModalCrear() {
    _nombreCtrl.clear();
    _descripcionCtrl.clear();
    _mostrarFormulario(titulo: 'Nuevo tratamiento', onGuardar: _crearTratamiento);
  }
 
  void _abrirModalEditar(Map<String, dynamic> t) {
    _nombreCtrl.text = t['nombre'] ?? '';
    _descripcionCtrl.text = t['descripcion'] ?? '';
    _mostrarFormulario(titulo: 'Editar tratamiento', onGuardar: () => _editarTratamiento(t));
  }
 
  void _mostrarFormulario({required String titulo, required VoidCallback onGuardar}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreCtrl,
              decoration: InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onGuardar,
                child: Text('Guardar', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
 
  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildBannerSeveridad(),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _tratamientos.isEmpty
                      ? _buildVacio()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildListaTratamientos(),
                              const SizedBox(height: 16),
                              if (_seleccionado != null) ...[
                                _buildProductoCard(),
                                const SizedBox(height: 16),
                                _buildDetallesCard(),
                                const SizedBox(height: 16),
                                _buildNotasCard(),
                                const SizedBox(height: 20),
                              ],
                              ElevatedButton.icon(
                                onPressed: (_guardado || _guardando) ? null : _guardarMonitoreo,
                                icon: _guardando
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check_circle_outline, size: 20),
                                label: Text(_guardando ? 'Guardando...' : _guardado ? 'Guardado' : 'Guardar tratamiento'),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _abrirModalCrear,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: const Color(0xFFF4E7D6),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Text('Tratamientos', textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
 
  Widget _buildBannerSeveridad() {
    final severidad = _severidadActual;
    final color = severidad == 'Alta' ? Colors.red : severidad == 'Media' ? Colors.orange : AppColors.primary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Severidad $severidad (${(widget.confidence * 100).round()}% de confianza) — tratamientos sugeridos para este nivel',
              style: GoogleFonts.nunito(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.healing_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No hay tratamientos disponibles para este nivel de severidad', style: GoogleFonts.nunito(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _abrirModalCrear, icon: const Icon(Icons.add), label: const Text('Agregar tratamiento')),
        ],
      ),
    );
  }
 
  Widget _buildListaTratamientos() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tratamientos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _tratamientos[i];
          final id = t['idTratamiento'] ?? t['id_tratamiento'];
          final nombre = t['nombre'] ?? 'Tratamiento';
          final seleccionado = (_seleccionado?['idTratamiento'] ?? _seleccionado?['id_tratamiento']) == id;
          return GestureDetector(
            onTap: () => _verDetalle(id),
            onLongPress: () => _mostrarOpciones(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: seleccionado ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: seleccionado ? AppColors.primary : Colors.grey.shade300),
              ),
              child: Text(nombre, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: seleccionado ? Colors.white : AppColors.textPrimary)),
            ),
          );
        },
      ),
    );
  }
 
  void _mostrarOpciones(Map<String, dynamic> t) {
    final id = t['idTratamiento'] ?? t['id_tratamiento'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: Text('Editar', style: GoogleFonts.nunito()),
            onTap: () { Navigator.pop(context); _abrirModalEditar(t); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Eliminar', style: GoogleFonts.nunito(color: Colors.red)),
            onTap: () { Navigator.pop(context); _eliminarTratamiento(id); },
          ),
        ],
      ),
    );
  }
 
  Widget _buildProductoCard() {
    final nombre = _seleccionado?['nombre'] ?? 'Sin nombre';
    final descripcion = _seleccionado?['descripcion'] ?? 'Sin descripción';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tratamiento seleccionado', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(nombre, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(descripcion, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
 
  Widget _buildDetallesCard() {
    final tipo = _seleccionado?['tipoTratamiento']?['nombre'] ?? 'General';
    final dosis = _seleccionado?['dosis'];
    final frecuencia = _seleccionado?['frecuencia'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        children: [
          _rowItem(Icons.category_outlined, 'Tipo', tipo),
          if (dosis != null) ...[const Divider(height: 20), _rowItem(Icons.scale_outlined, 'Dosis', dosis.toString())],
          if (frecuencia != null) ...[const Divider(height: 20), _rowItem(Icons.repeat_outlined, 'Frecuencia', frecuencia.toString())],
          const Divider(height: 20),
          _rowItem(Icons.calendar_today_outlined, 'Fecha de registro', _formatFecha(_seleccionado?['fechaRegistro'])),
        ],
      ),
    );
  }
 
  Widget _buildNotasCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notas', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Diagnóstico: ${widget.diagnosisText}\nConfianza: ${(widget.confidence * 100).round()}%\nNombre científico: ${widget.scientificName}',
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
 
  Widget _rowItem(IconData icon, String label, String valor) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary))),
        Text(valor, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
 
  String _formatFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';
    try {
      final dt = DateTime.parse(fecha.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha.toString();
    }
  }
}
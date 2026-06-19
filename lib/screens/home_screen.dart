import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import 'notificaciones_screen.dart';
 
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const HomeScreen({super.key, required this.usuario});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  bool _cargando = true;
  String? _error;
  List _fincas          = [];
  List _monitoreos      = [];
  List _recomendaciones = [];
  List _cultivos        = [];
  int _fincaSeleccionada = 0;
  int? _cultivoSeleccionado;
 
  String? _fotoPerfil;
 
  @override
  void initState() {
    super.initState();
    _fotoPerfil = widget.usuario['fotoPerfil']?.toString();
    _cargarDatos();
    AppState.instance.addListener(_onAppStateChanged);
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }
 
  void _onAppStateChanged() {
    final foto = AppState.instance.fotoPerfil;
    if (foto != null && foto != _fotoPerfil) {
      setState(() => _fotoPerfil = foto);
    }
  }
 
  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = null; });
    final token = await AuthService.getToken();
    print('TOKEN: $token');
    try {
      final data     = await DashboardService.getDashboard();
      final cultivos = await ApiService.get('/cultivos');
 
      try {
        final perfil = await ApiService.get('/mi-perfil');
        final u = perfil is Map ? (perfil['data'] ?? perfil) : perfil;
        if (u is Map && u['fotoPerfil'] != null) {
          final nuevaFoto = u['fotoPerfil'].toString();
          if (nuevaFoto.isNotEmpty) {
            AppState.instance.setFotoPerfil(nuevaFoto);
            setState(() => _fotoPerfil = nuevaFoto);
          }
        }
      } catch (_) {}
 
      setState(() {
        _fincas          = data['fincas']         ?? [];
        _monitoreos      = data['monitoreos']      ?? [];
        _recomendaciones = data['recomendaciones'] ?? [];
        _cultivos        = cultivos is List ? cultivos : (cultivos['data'] ?? []);
        if (_fincaSeleccionada >= _fincas.length) _fincaSeleccionada = 0;
        _cultivoSeleccionado = null;
        _cargando = false;
      });
      if (_fincas.isNotEmpty) {
        AppState.instance.setFinca(_fincas[_fincaSeleccionada], _cultivosFincaActual);
      }
    } catch (e) {
      print('ERROR: $e');
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }
 
  List get _cultivosFincaActual {
    if (_fincas.isEmpty || _fincaSeleccionada >= _fincas.length) return [];
    final fincaActual = _fincas[_fincaSeleccionada];
    final idFinca = fincaActual['idFinca'] ?? fincaActual['id_finca'];
    return _cultivos.where((c) =>
      (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString()
    ).toList();
  }
 
  Map<String, dynamic> _getSaludCultivo() {
    if (_fincas.isEmpty || _fincaSeleccionada >= _fincas.length) {
      return {'texto': 'Buena', 'porcentaje': 0.15, 'nivel': 'Bajo'};
    }
    final fincaActual = _fincas[_fincaSeleccionada];
    final idFinca = fincaActual['idFinca'] ?? fincaActual['id_finca'];
 
    List monitoreosFiltrados;
    if (_cultivoSeleccionado != null) {
      monitoreosFiltrados = _monitoreos.where((m) {
        final idCultivo = m['idCultivo'] ?? m['id_cultivo'];
        return idCultivo.toString() == _cultivoSeleccionado.toString();
      }).toList();
    } else {
      monitoreosFiltrados = _monitoreos.where((m) {
        final idCultivo = m['idCultivo'] ?? m['id_cultivo'];
        final cultivo = _cultivos.where((c) =>
          (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString() &&
          (c['idCultivo'] ?? c['id_cultivo']).toString() == idCultivo.toString()
        ).toList();
        return cultivo.isNotEmpty;
      }).toList();
    }
 
    if (monitoreosFiltrados.isEmpty) return {'texto': 'Buena', 'porcentaje': 0.15, 'nivel': 'Bajo'};
 
    final total   = monitoreosFiltrados.length;
    final conRoya = monitoreosFiltrados.where((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      return obs.contains('roya') || obs.contains('alto') ||
             obs.contains('critico') || obs.contains('crítico') || obs.contains('enfermedad');
    }).length;
 
    final porcentaje = total > 0 ? conRoya / total : 0.0;
    if (porcentaje < 0.3)  return {'texto': 'Buena',   'porcentaje': 0.15,       'nivel': 'Bajo'};
    if (porcentaje <= 0.6) return {'texto': 'Regular',  'porcentaje': porcentaje, 'nivel': 'Medio'};
    return                        {'texto': 'Crítica',  'porcentaje': porcentaje, 'nivel': 'Alto'};
  }
 
  String _calcularNivelRoyaPara(dynamic idCultivo) {
    final monitoreos = _monitoreos.where((m) {
      final id = m['idCultivo'] ?? m['id_cultivo'];
      return id.toString() == idCultivo.toString();
    }).toList();
 
    if (monitoreos.isEmpty) return 'Sin datos';
 
    final total   = monitoreos.length;
    final conRoya = monitoreos.where((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      return obs.contains('roya') || obs.contains('alto') ||
             obs.contains('critico') || obs.contains('crítico') || obs.contains('enfermedad');
    }).length;
 
    final porcentaje = conRoya / total;
    if (porcentaje < 0.3)  return 'Bajo';
    if (porcentaje <= 0.6) return 'Medio';
    return 'Alto';
  }
 
  // ─── Campo de texto reutilizable ─────────────────────────────────────────
 
  Widget _campo(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
 
  // ─── Formulario: Nueva Finca ──────────────────────────────────────────────
 
  void _mostrarFormFinca() {
    final formKey       = GlobalKey<FormState>();
    final nombreCtrl    = TextEditingController();
    final municipioCtrl = TextEditingController();
    final deptoCtrl     = TextEditingController();
    final areaCtrl      = TextEditingController();
    final altitudCtrl   = TextEditingController();
    final latCtrl       = TextEditingController();
    final lonCtrl       = TextEditingController();
    bool guardando      = false;
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFEFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Nueva finca',
                      style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Ingresa los datos de tu finca',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  _campo(nombreCtrl, 'Nombre de la finca *', Icons.park_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
                  const SizedBox(height: 12),
                  _campo(municipioCtrl, 'Municipio *', Icons.location_city_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
                  const SizedBox(height: 12),
                  _campo(deptoCtrl, 'Departamento', Icons.map_outlined),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(areaCtrl, 'Área (ha)', Icons.straighten_outlined, keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(altitudCtrl, 'Altitud (msnm)', Icons.terrain_outlined, keyboard: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(latCtrl, 'Latitud', Icons.my_location_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(lonCtrl, 'Longitud', Icons.my_location_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardando ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModal(() => guardando = true);
                        final idUsuario = widget.usuario['idUsuario']
                            ?? widget.usuario['id_usuario']
                            ?? widget.usuario['id'];
                        try {
                          await ApiService.post('/fincas', {
                            'id_usuario':   idUsuario,
                            'nombre_finca': nombreCtrl.text.trim(),
                            'municipio':    municipioCtrl.text.trim(),
                            'departamento': deptoCtrl.text.trim(),
                            if (areaCtrl.text.isNotEmpty)
                              'area_hectareas': double.tryParse(areaCtrl.text),
                            if (altitudCtrl.text.isNotEmpty)
                              'altitud_msnm': double.tryParse(altitudCtrl.text),
                            if (latCtrl.text.isNotEmpty)
                              'latitud': double.tryParse(latCtrl.text),
                            if (lonCtrl.text.isNotEmpty)
                              'longitud': double.tryParse(lonCtrl.text),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _cargarDatos();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Finca creada correctamente',
                                    style: GoogleFonts.nunito()),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          setModal(() => guardando = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: guardando
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text('Guardar finca',
                              style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  // ─── Opciones al mantener presionado una finca ───────────────────────────
 
  void _mostrarOpcionesFinca(Map<String, dynamic> finca) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: Text('Editar finca', style: GoogleFonts.nunito()),
            onTap: () {
              Navigator.pop(context);
              _mostrarFormEditarFinca(finca);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Eliminar finca',
                style: GoogleFonts.nunito(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _eliminarFinca(finca['idFinca'] ?? finca['id_finca']);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
 
  // ─── Formulario: Editar Finca ─────────────────────────────────────────────
 
  void _mostrarFormEditarFinca(Map<String, dynamic> finca) {
    final formKey       = GlobalKey<FormState>();
    final nombreCtrl    = TextEditingController(text: finca['nombreFinca'] ?? finca['nombre_finca'] ?? '');
    final municipioCtrl = TextEditingController(text: finca['municipio'] ?? '');
    final deptoCtrl     = TextEditingController(text: finca['departamento'] ?? '');
    final areaCtrl      = TextEditingController(text: (finca['areaHectareas'] ?? finca['area_hectareas'] ?? '').toString());
    final altitudCtrl   = TextEditingController(text: (finca['altitudMsnm'] ?? finca['altitud_msnm'] ?? '').toString());
    final latCtrl       = TextEditingController(text: (finca['latitud'] ?? '').toString());
    final lonCtrl       = TextEditingController(text: (finca['longitud'] ?? '').toString());
    bool guardando      = false;
    final idFinca       = finca['idFinca'] ?? finca['id_finca'];
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFEFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Editar finca',
                      style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Actualiza los datos de tu finca',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  _campo(nombreCtrl, 'Nombre de la finca *', Icons.park_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
                  const SizedBox(height: 12),
                  _campo(municipioCtrl, 'Municipio *', Icons.location_city_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
                  const SizedBox(height: 12),
                  _campo(deptoCtrl, 'Departamento', Icons.map_outlined),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(areaCtrl, 'Área (ha)', Icons.straighten_outlined, keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(altitudCtrl, 'Altitud (msnm)', Icons.terrain_outlined, keyboard: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(latCtrl, 'Latitud', Icons.my_location_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(lonCtrl, 'Longitud', Icons.my_location_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardando ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModal(() => guardando = true);
                        try {
                          await ApiService.put('/fincas/$idFinca', {
                            'nombre_finca':  nombreCtrl.text.trim(),
                            'municipio':     municipioCtrl.text.trim(),
                            'departamento':  deptoCtrl.text.trim(),
                            if (areaCtrl.text.isNotEmpty)
                              'area_hectareas': double.tryParse(areaCtrl.text),
                            if (altitudCtrl.text.isNotEmpty)
                              'altitud_msnm': double.tryParse(altitudCtrl.text),
                            if (latCtrl.text.isNotEmpty)
                              'latitud': double.tryParse(latCtrl.text),
                            if (lonCtrl.text.isNotEmpty)
                              'longitud': double.tryParse(lonCtrl.text),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _cargarDatos();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Finca actualizada correctamente',
                                    style: GoogleFonts.nunito()),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          setModal(() => guardando = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: guardando
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text('Actualizar finca',
                              style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  // ─── Eliminar finca ───────────────────────────────────────────────────────
 
  Future<void> _eliminarFinca(dynamic idFinca) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar finca',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text(
            '¿Estás seguro? Se eliminarán también todos los lotes de esta finca.',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
 
    if (confirmar != true) return;
 
    try {
      await ApiService.delete('/fincas/$idFinca');
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Finca eliminada correctamente',
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
 
  // ─── Formulario: Nuevo Lote / Cultivo ────────────────────────────────────
 
  void _mostrarFormLote(dynamic idFinca) {
    final formKey      = GlobalKey<FormState>();
    final nombreCtrl   = TextEditingController();
    String tipoCultivo = 'Café';
    bool guardando     = false;
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFEFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Nuevo lote',
                      style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Agrega un lote a esta finca',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  _campo(nombreCtrl, 'Nombre del lote *', Icons.eco_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
                  const SizedBox(height: 16),
                  Text('Tipo de cultivo',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Café'].map((t) {
                      final sel = tipoCultivo == t;
                      return GestureDetector(
                        onTap: () => setModal(() => tipoCultivo = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(t,
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardando ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModal(() => guardando = true);
                        try {
                          await ApiService.post('/cultivos', {
                            'id_finca':       idFinca,
                            'nombre_cultivo': nombreCtrl.text.trim(),
                            'tipo_cultivo':   tipoCultivo,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _cargarDatos();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lote agregado correctamente',
                                    style: GoogleFonts.nunito()),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          setModal(() => guardando = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: guardando
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text('Guardar lote',
                              style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  // ─── Opciones al mantener presionado un lote ──────────────────────────────
 
  void _mostrarOpcionesCultivo(Map<String, dynamic> cultivo, dynamic idCultivo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: Text('Editar lote', style: GoogleFonts.nunito()),
            onTap: () {
              Navigator.pop(context);
              _mostrarFormEditarLote(cultivo, idCultivo);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Eliminar lote',
                style: GoogleFonts.nunito(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _eliminarCultivo(idCultivo);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
 
  // ─── Formulario: Editar Lote ──────────────────────────────────────────────
 
  void _mostrarFormEditarLote(Map<String, dynamic> cultivo, dynamic idCultivo) {
    final formKey    = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(
        text: cultivo['nombreCultivo'] ?? cultivo['nombre_cultivo'] ?? '');
    String tipoCultivo =
        cultivo['tipoCultivo'] ?? cultivo['tipo_cultivo'] ?? 'Café';
    bool guardando = false;
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFEFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Editar lote',
                      style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 20),
                  _campo(nombreCtrl, 'Nombre del lote *', Icons.eco_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo requerido'
                          : null),
                  const SizedBox(height: 16),
                  Text('Tipo de cultivo',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Café'].map((t) {
                      final sel = tipoCultivo == t;
                      return GestureDetector(
                        onTap: () => setModal(() => tipoCultivo = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(t,
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardando ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModal(() => guardando = true);
                        try {
                          await ApiService.put('/cultivos/$idCultivo', {
                            'nombre_cultivo': nombreCtrl.text.trim(),
                            'tipo_cultivo':   tipoCultivo,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _cargarDatos();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lote actualizado correctamente',
                                    style: GoogleFonts.nunito()),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          setModal(() => guardando = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: guardando
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text('Actualizar lote',
                              style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  // ─── Eliminar cultivo ─────────────────────────────────────────────────────
 
  Future<void> _eliminarCultivo(dynamic idCultivo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar lote',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro de que deseas eliminar este lote?',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
 
    if (confirmar != true) return;
 
    try {
      await ApiService.delete('/cultivos/$idCultivo');
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lote eliminado correctamente',
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
 
  // ─── Build principal ──────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final nombreRaw = (widget.usuario['nombre'] ?? '').toString().trim();
    final nombre = nombreRaw.isNotEmpty ? nombreRaw : 'Caficultor';
 
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: _buildHeader(context, nombre),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildResumenCard(),
                              const SizedBox(height: 16),
                              _buildStatsRow(),
                              const SizedBox(height: 20),
                              _buildFincasSection(context),
                              const SizedBox(height: 20),
                              _buildChart(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
 
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No se pudo conectar al servidor',
              style: GoogleFonts.nunito(
                  fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(_error ?? '',
              style: GoogleFonts.nunito(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context, String nombre) {
    final tieneFoto = _fotoPerfil != null && _fotoPerfil!.isNotEmpty;
 
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4E7D6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            backgroundImage: tieneFoto ? NetworkImage(_fotoPerfil!) : null,
            onBackgroundImageError: tieneFoto
                ? (_, __) => setState(() => _fotoPerfil = null)
                : null,
            child: tieneFoto
                ? null
                : Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $nombre',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color.fromARGB(255, 26, 26, 26),
                    )),
                const SizedBox(height: 2),
                Text('Bienvenido de nuevo',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificacionesScreen()),
            ),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary, size: 28),
                ),
                if (_recomendaciones.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_recomendaciones.length > 9 ? "9+" : _recomendaciones.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildResumenCard() {
    final salud       = _getSaludCultivo();
    final fincaNombre = _fincas.isNotEmpty && _fincaSeleccionada < _fincas.length
        ? (_fincas[_fincaSeleccionada]['nombreFinca'] ?? 'Mi Finca')
        : 'Mi Finca';
    final cultivoNombre = _cultivoSeleccionado != null
        ? _cultivos.firstWhere(
            (c) => (c['idCultivo'] ?? c['id_cultivo']).toString() ==
                _cultivoSeleccionado.toString(),
            orElse: () => {})['nombreCultivo'] ?? 'Cultivo seleccionado'
        : null;
 
    Color colorSalud = const Color(0xFF4F8F1F);
    if (salud['texto'] == 'Regular') colorSalud = Colors.orange;
    if (salud['texto'] == 'Crítica') colorSalud = Colors.red;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen de tu cultivo',
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: colorSalud,
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cultivoNombre ?? fincaNombre,
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text('Salud general del cultivo',
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(salud['texto'],
                            style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.eco_rounded,
                        color: Colors.white, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Índice de riesgo',
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: Colors.white70)),
                        Text(
                            '${((salud['porcentaje'] as double) * 100).round()}%',
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(salud['nivel'],
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: salud['porcentaje'] as double,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _buildStatsRow() {
    final cultivosFinca = _cultivosFincaActual;
    return Row(
      children: [
        _statCard('${_monitoreos.length}', 'Monitoreos\nrealizados', Colors.black),
        const SizedBox(width: 10),
        _statCard('${cultivosFinca.length}', 'Cultivos\nactivos', Colors.black),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const NotificacionesScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alertas\nactivas',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${_recomendaciones.length}',
                          style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.red)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          size: 10, color: Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
 
  Widget _statCard(String value, String label, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: valueColor)),
          ],
        ),
      ),
    );
  }
 
  Widget _buildFincasSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mis Fincas',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            GestureDetector(
              onTap: _mostrarFormFinca,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('Nueva finca',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_fincas.isEmpty)
          GestureDetector(
            onTap: _mostrarFormFinca,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    style: BorderStyle.solid),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_location_alt_outlined,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text('Agrega tu primera finca',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Toca aquí para registrarla',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else ...[
          if (_fincas.length > 1) ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fincas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final finca    = _fincas[i];
                  final selected = i == _fincaSeleccionada;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _fincaSeleccionada   = i;
                        _cultivoSeleccionado = null;
                      });
                      AppState.instance
                          .setFinca(_fincas[i], _cultivosFincaActual);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border),
                      ),
                      child: Text(finca['nombreFinca'] ?? 'Finca ${i + 1}',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_fincaSeleccionada < _fincas.length)
            _buildFincaCard(_fincas[_fincaSeleccionada]),
        ],
      ],
    );
  }
 
  Widget _buildFincaCard(Map<String, dynamic> finca) {
    final cultivos  = _cultivosFincaActual;
    final nombre    = finca['nombreFinca']   ?? 'Mi Finca';
    final municipio = finca['municipio']     ?? 'Sin municipio';
    final area      = finca['areaHectareas'] ?? finca['area_hectareas'] ?? '-';
    final altitud   = finca['altitudMsnm']   ?? finca['altitud_msnm']   ?? '-';
    final idFinca   = finca['idFinca']       ?? finca['id_finca'];
 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _mostrarOpcionesFinca(finca),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.park_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text(municipio,
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _fincaDato(Icons.straighten_outlined, '$area ha', 'Área'),
              Container(width: 1, height: 36, color: AppColors.border),
              _fincaDato(Icons.terrain_outlined, '$altitud msnm', 'Altitud'),
              Container(width: 1, height: 36, color: AppColors.border),
              _fincaDato(Icons.eco_outlined, '${cultivos.length}', 'Cultivos'),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lotes registrados',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => _mostrarFormLote(idFinca),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 3),
                      Text('Agregar lote',
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (cultivos.isEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: Text('Sin lotes registrados aún',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text('(mantén presionado para editar o eliminar)',
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...cultivos.map((c) {
              final idCultivo = c['idCultivo'] ?? c['id_cultivo'];
              final selected  =
                  _cultivoSeleccionado?.toString() == idCultivo.toString();
              final nivel     = selected ? _calcularNivelRoyaPara(idCultivo) : '';
              final nivelColor = nivel == 'Alto'
                  ? Colors.red
                  : nivel == 'Medio'
                      ? Colors.orange
                      : nivel == 'Bajo'
                          ? AppColors.primary
                          : Colors.grey;
 
              return GestureDetector(
                onLongPress: () => _mostrarOpcionesCultivo(c, idCultivo),
                onTap: () {
                  final nuevoId = selected ? null : idCultivo;
                  setState(() => _cultivoSeleccionado = nuevoId);
                  if (nuevoId != null) {
                    final nivelCalculado = _calcularNivelRoyaPara(idCultivo);
                    AppState.instance.setCultivo(c, nivelCalculado);
                  } else {
                    AppState.instance
                        .setCultivo(null, _getSaludCultivo()['nivel']);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 8),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c['nombreCultivo'] ??
                              c['nombre_cultivo'] ??
                              'Cultivo',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                        ),
                      ),
                      if (selected) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: nivelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: nivelColor.withOpacity(0.4)),
                          ),
                          child: Text('Roya: $nivel',
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: nivelColor)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 16),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              c['tipoCultivo'] ??
                                  c['tipo_cultivo'] ??
                                  'Café',
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
 
  Widget _fincaDato(IconData icon, String valor, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(valor,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
 
  Widget _buildChart() {
    final salud        = _getSaludCultivo();
    final colorGrafica = salud['nivel'] == 'Bajo'
        ? AppColors.primary
        : salud['nivel'] == 'Medio'
            ? Colors.orange
            : Colors.red;
 
    final spots = [
      const FlSpot(0, 1200), const FlSpot(1, 1800), const FlSpot(2, 1600),
      const FlSpot(3, 2200), const FlSpot(4, 2000), const FlSpot(5, 2500),
      const FlSpot(6, 2300), const FlSpot(7, 2800), const FlSpot(8, 3000),
      const FlSpot(9, 3200),
    ];
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7EF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Riesgo de roya',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text(salud['nivel'],
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorGrafica)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1000,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1000,
                    reservedSize: 40,
                    getTitlesWidget: (v, m) => Text(
                        '${(v / 1000).toStringAsFixed(0)}k',
                        style: GoogleFonts.nunito(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ),
                ),
                bottomTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: 9, minY: 0, maxY: 4000,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  color: colorGrafica,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorGrafica.withOpacity(0.3),
                        colorGrafica.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}
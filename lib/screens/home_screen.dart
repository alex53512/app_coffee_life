import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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

  final ImagePicker _picker = ImagePicker();

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
    if (!mounted) return;
    final foto = AppState.instance.fotoPerfil;
    if (foto != null && foto != _fotoPerfil) setState(() => _fotoPerfil = foto);
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = null; });
    final token = await AuthService.getToken();
    print('TOKEN: $token');
    if (!mounted) return;
    try {
      final data     = await DashboardService.getDashboard();
      final cultivos = await ApiService.get('/cultivos');
      if (!mounted) return;

      try {
        final perfil = await ApiService.get('/mi-perfil');
        final u = perfil is Map ? (perfil['data'] ?? perfil) : perfil;
        if (u is Map && u['fotoPerfil'] != null) {
          final nuevaFoto = u['fotoPerfil'].toString();
          if (nuevaFoto.isNotEmpty) {
            AppState.instance.setFotoPerfil(nuevaFoto);
            if (mounted) setState(() => _fotoPerfil = nuevaFoto);
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _fincas          = data['fincas']         ?? [];
        _monitoreos      = data['monitoreos']      ?? [];
        _recomendaciones = data['recomendaciones'] ?? [];
        _cultivos        = cultivos is List ? cultivos : (cultivos['data'] ?? []);
        if (_fincaSeleccionada >= _fincas.length) _fincaSeleccionada = 0;
        _cultivoSeleccionado = null;
        _cargando = false;
      });
      for (final f in _fincas) {
        print('FINCA "${f['nombreFinca'] ?? f['nombre_finca']}" -> keys: ${f.keys.toList()}');
        print('   fotoUrl = "${f['fotoUrl']}"  (tipo: ${f['fotoUrl'].runtimeType})');
      }
      if (_fincas.isNotEmpty) {
        AppState.instance.setFinca(_fincas[_fincaSeleccionada], _cultivosFincaActual);
      }
    } catch (e) {
      print('ERROR: $e');
      if (mounted) setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  List get _cultivosFincaActual {
    if (_fincas.isEmpty || _fincaSeleccionada >= _fincas.length) return [];
    final idFinca = _fincas[_fincaSeleccionada]['idFinca'] ?? _fincas[_fincaSeleccionada]['id_finca'];
    return _cultivos.where((c) =>
      (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString()
    ).toList();
  }

  Map<String, dynamic> _getSaludCultivo() {
    if (_fincas.isEmpty || _fincaSeleccionada >= _fincas.length)
      return {'texto': 'Buena', 'porcentaje': 0.15, 'nivel': 'Bajo'};

    final idFinca = _fincas[_fincaSeleccionada]['idFinca'] ?? _fincas[_fincaSeleccionada]['id_finca'];
    List monitoreosFiltrados;

    if (_cultivoSeleccionado != null) {
      monitoreosFiltrados = _monitoreos.where((m) =>
        (m['idCultivo'] ?? m['id_cultivo']).toString() == _cultivoSeleccionado.toString()
      ).toList();
    } else {
      monitoreosFiltrados = _monitoreos.where((m) {
        final idCultivo = m['idCultivo'] ?? m['id_cultivo'];
        return _cultivos.any((c) =>
          (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString() &&
          (c['idCultivo'] ?? c['id_cultivo']).toString() == idCultivo.toString()
        );
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
    final monitoreos = _monitoreos.where((m) =>
      (m['idCultivo'] ?? m['id_cultivo']).toString() == idCultivo.toString()
    ).toList();
    if (monitoreos.isEmpty) return 'Sin datos';
    final total   = monitoreos.length;
    final conRoya = monitoreos.where((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      return obs.contains('roya') || obs.contains('alto') ||
             obs.contains('critico') || obs.contains('crítico') || obs.contains('enfermedad');
    }).length;
    final p = conRoya / total;
    if (p < 0.3)  return 'Bajo';
    if (p <= 0.6) return 'Medio';
    return 'Alto';
  }


  Future<XFile?> _elegirOrigenYSeleccionarImagen() async {
    ImageSource? origen;

    if (kIsWeb) {
      origen = ImageSource.gallery;
    } else {
      origen = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Foto de la finca',
                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Tomar foto', style: GoogleFonts.nunito()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Elegir de galería', style: GoogleFonts.nunito()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    if (origen == null) return null;

    return _picker.pickImage(source: origen, imageQuality: 80, maxWidth: 900);
  }

  Future<void> _subirFotoFincaExistente(dynamic idFinca) async {
    final picked = await _elegirOrigenYSeleccionarImagen();
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() => _cargando = true);
    try {
      final token   = await AuthService.getToken();
      final baseUrl = ApiService.baseUrl;

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/fincas/$idFinca'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'foto_finca',
        bytes,
        filename: picked.name,
      ));

      final response = await request.send();
      final body      = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de la finca actualizada'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Error ${response.statusCode}: $body');
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarFormFinca() {
    final formKey       = GlobalKey<FormState>();
    final nombreCtrl    = TextEditingController();
    final municipioCtrl = TextEditingController();
    final deptoCtrl     = TextEditingController();
    bool guardando      = false;

    XFile?     imagenSeleccionada;
    Uint8List? imagenBytes;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        decoration: const BoxDecoration(color: Color(0xFFFFFEFB), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Form(key: formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Text('Nueva finca', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Ingresa los datos de tu finca', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            Center(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    final picked = await _elegirOrigenYSeleccionarImagen();
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setModal(() {
                        imagenSeleccionada = picked;
                        imagenBytes        = bytes;
                      });
                    }
                  },
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    image: imagenBytes != null
                        ? DecorationImage(image: MemoryImage(imagenBytes!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imagenBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 30),
                            const SizedBox(height: 8),
                            Text('Agregar foto de la finca (opcional)',
                                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _campo(nombreCtrl, 'Nombre de la finca *',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
            const SizedBox(height: 12),
            _campo(municipioCtrl, 'Municipio *',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
            const SizedBox(height: 12),
            _campo(deptoCtrl, 'Departamento'),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: guardando ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setModal(() => guardando = true);
                  final idUsuario = widget.usuario['idUsuario'] ?? widget.usuario['id_usuario'] ?? widget.usuario['id'];
                  try {
                    if (imagenBytes != null) {
                      final token   = await AuthService.getToken();
                      final baseUrl = ApiService.baseUrl;
                      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/fincas'));
                      request.headers['Authorization'] = 'Bearer $token';
                      request.fields['id_usuario']    = idUsuario.toString();
                      request.fields['nombre_finca']  = nombreCtrl.text.trim();
                      request.fields['municipio']     = municipioCtrl.text.trim();
                      request.fields['departamento']  = deptoCtrl.text.trim();
                      request.files.add(http.MultipartFile.fromBytes(
                        'foto_finca', imagenBytes!, filename: imagenSeleccionada!.name,
                      ));
                      final response = await request.send();
                      final body     = await response.stream.bytesToString();
                      if (response.statusCode != 200 && response.statusCode != 201) {
                        throw Exception('Error ${response.statusCode}: $body');
                      }
                    } else {
                      await ApiService.post('/fincas', {
                        'id_usuario': idUsuario, 'nombre_finca': nombreCtrl.text.trim(),
                        'municipio': municipioCtrl.text.trim(), 'departamento': deptoCtrl.text.trim(),
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _cargarDatos();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Finca creada correctamente', style: GoogleFonts.nunito()), backgroundColor: AppColors.primary));
                  } catch (e) {
                    setModal(() => guardando = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: guardando ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Guardar finca', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ))),
      )),
    );
  }

  void _mostrarFormLote(dynamic idFinca) {
    final formKey      = GlobalKey<FormState>();
    final nombreCtrl   = TextEditingController();
    final variedadCtrl = TextEditingController();
    final arbolesCtrl  = TextEditingController();
    String? variedadSel;
    bool guardando = false;
    const variedades = ['Castillo', 'Caturra', 'Colombia', 'Bourbon', 'Typica', 'Tabi', 'Cenicafé 1', 'Gesha'];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        decoration: const BoxDecoration(color: Color(0xFFFFFEFB), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Form(key: formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Text('Nuevo lote', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Agrega un lote a esta finca', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _campo(nombreCtrl, 'Nombre del lote *',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
            const SizedBox(height: 16),
            Text('Variedad de café', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            _dropdownVariedad(variedades, variedadSel, variedadCtrl, (v) => setModal(() { variedadSel = v; variedadCtrl.clear(); })),
            if (variedadSel == '__otra__' || variedadSel == null) ...[
              const SizedBox(height: 10),
              _campoVariedadLibre(variedadCtrl),
            ],
            const SizedBox(height: 16),
            _campo(arbolesCtrl, 'Número de árboles de café', keyboard: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: guardando ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setModal(() => guardando = true);
                  final variedad = (variedadSel != null && variedadSel != '__otra__')
                      ? variedadSel! : variedadCtrl.text.trim();
                  try {
                    await ApiService.post('/cultivos', {
                      'id_finca': idFinca,
                      'nombre_cultivo': nombreCtrl.text.trim(),
                      'tipo_cultivo': variedad.isNotEmpty ? variedad : 'Café',
                      if (arbolesCtrl.text.isNotEmpty) 'numero_arboles': int.tryParse(arbolesCtrl.text),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _cargarDatos();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lote agregado correctamente', style: GoogleFonts.nunito()), backgroundColor: AppColors.primary));
                  } catch (e) {
                    setModal(() => guardando = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: guardando ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Guardar lote', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ))),
      )),
    );
  }

  Future<void> _eliminarLote(dynamic idCultivo, String nombreLote) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar lote', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('¿Estás seguro que quieres eliminar el lote "$nombreLote"?', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.nunito(color: AppColors.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Eliminar', style: GoogleFonts.nunito(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.delete('/cultivos/$idCultivo');
      await _cargarDatos();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lote eliminado correctamente', style: GoogleFonts.nunito()), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
    }
  }

  void _mostrarFormEditarLote(Map<String, dynamic> cultivo) {
    final formKey      = GlobalKey<FormState>();
    final nombreCtrl   = TextEditingController(text: cultivo['nombreCultivo'] ?? cultivo['nombre_cultivo'] ?? '');
    final arbolesCtrl  = TextEditingController(text: (cultivo['numeroArboles'] ?? cultivo['numero_arboles'] ?? '').toString());
    final variedadCtrl = TextEditingController();
    const variedades = ['Castillo', 'Caturra', 'Colombia', 'Bourbon', 'Typica', 'Tabi', 'Cenicafé 1', 'Gesha'];

    final variedadActual = cultivo['tipoCultivo']?.toString() ?? '';
    String? variedadSel = variedades.contains(variedadActual) ? variedadActual
        : (variedadActual.isNotEmpty ? '__otra__' : null);
    if (variedadSel == '__otra__') variedadCtrl.text = variedadActual;

    bool guardando = false;
    final idCultivo = cultivo['idCultivo'] ?? cultivo['id_cultivo'];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        decoration: const BoxDecoration(color: Color(0xFFFFFEFB), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Form(key: formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Text('Editar lote', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Actualiza los datos del lote', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _campo(nombreCtrl, 'Nombre del lote *',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
            const SizedBox(height: 16),
            Text('Variedad de café', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            _dropdownVariedad(variedades, variedadSel, variedadCtrl, (v) => setModal(() {
              variedadSel = v;
              if (v != '__otra__') variedadCtrl.clear();
            })),
            if (variedadSel == '__otra__' || variedadSel == null) ...[
              const SizedBox(height: 10),
              _campoVariedadLibre(variedadCtrl),
            ],
            const SizedBox(height: 16),
            _campo(arbolesCtrl, 'Número de árboles de café', keyboard: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: guardando ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setModal(() => guardando = true);
                  final variedad = (variedadSel != null && variedadSel != '__otra__')
                      ? variedadSel! : variedadCtrl.text.trim();
                  try {
                    await ApiService.put('/cultivos/$idCultivo', {
                      'nombre_cultivo': nombreCtrl.text.trim(),
                      'tipo_cultivo': variedad.isNotEmpty ? variedad : 'Café',
                      if (arbolesCtrl.text.isNotEmpty) 'numero_arboles': int.tryParse(arbolesCtrl.text),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _cargarDatos();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lote actualizado correctamente', style: GoogleFonts.nunito()), backgroundColor: Colors.green));
                  } catch (e) {
                    setModal(() => guardando = false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: guardando ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Guardar cambios', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _eliminarLote(idCultivo, cultivo['nombreCultivo'] ?? cultivo['nombre_cultivo'] ?? 'lote');
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: Text('Eliminar lote',
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ))),
        )),
      );
  }

  Widget _dropdownVariedad(List<String> variedades, String? variedadSel,
      TextEditingController ctrl, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: variedadSel,
      hint: Text('Selecciona una variedad', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
      decoration: InputDecoration(
        filled: true, fillColor: AppColors.inputFill(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
      items: [
        ...variedades.map((v) => DropdownMenuItem(value: v, child: Text(v, style: GoogleFonts.nunito(fontSize: 14)))),
        DropdownMenuItem(value: '__otra__',
            child: Text('Otra variedad...', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _campoVariedadLibre(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Escribe la variedad',
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        filled: true, fillColor: AppColors.inputFill(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String hint, {
    TextInputType keyboard = TextInputType.text, String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboard, validator: validator,
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        filled: true, fillColor: AppColors.inputFill(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreRaw = (widget.usuario['nombre'] ?? '').toString().trim();
    final nombre = nombreRaw.isNotEmpty ? nombreRaw : 'Caficultor';

    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  color: AppColors.primary,
                  child: Column(children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                        child: SafeArea(bottom: false, child: _buildHeader(context, nombre)),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildResumenCard(),
                          const SizedBox(height: 20),
                          _buildFincasSection(context),
                          const SizedBox(height: 20),
                          _buildChart(),
                          const SizedBox(height: 20),
                        ]),
                      ),
                    ),
                  ]),
                ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(BootstrapIcons.wifi_off, size: 60, color: AppColors.textSecondary),
      const SizedBox(height: 16),
      Text('No se pudo conectar al servidor', style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Text(_error ?? '', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: _cargarDatos,
          icon: const Icon(BootstrapIcons.arrow_clockwise),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44))),
    ]));
  }

 Widget _buildHeader(BuildContext context, String nombre) {
  final tieneFoto = _fotoPerfil != null && _fotoPerfil!.isNotEmpty;

  return Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF97D340), 
          Color(0xFF388E3C), 
        ],
      ),
    ),
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
              Text(
                'Hola, $nombre',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF262A24),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bienvenido de nuevo',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificacionesScreen(),
            ),
          ),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  BootstrapIcons.bell,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
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
                          fontWeight: FontWeight.bold,
                        ),
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
    final salud = _getSaludCultivo();
    final fincaNombre = _fincas.isNotEmpty && _fincaSeleccionada < _fincas.length
        ? (_fincas[_fincaSeleccionada]['nombreFinca'] ?? 'Mi Finca') : 'Mi Finca';
    final cultivoNombre = _cultivoSeleccionado != null
        ? _cultivos.firstWhere(
            (c) => (c['idCultivo'] ?? c['id_cultivo']).toString() == _cultivoSeleccionado.toString(),
            orElse: () => {})['nombreCultivo'] ?? 'Cultivo seleccionado'
        : null;

    Color colorSalud = const Color(0xFF4F8F1F);
    if (salud['texto'] == 'Regular') colorSalud = Colors.orange;
    if (salud['texto'] == 'Crítica') colorSalud = Colors.red;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Resumen de tu cultivo', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 10),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colorSalud, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cultivoNombre ?? fincaNombre, style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 2),
            Text('Salud general del cultivo', style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(salud['texto'], style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Índice de riesgo', style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
                Text('${((salud['porcentaje'] as double) * 100).round()}%', style: GoogleFonts.nunito(fontSize: 12, color: Colors.white)),
              ]),
              const SizedBox(height: 4),
              Text(salud['nivel'], style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: salud['porcentaje'] as double,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  )),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildFincasSection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Mis Fincas', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        GestureDetector(
          onTap: _mostrarFormFinca,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(BootstrapIcons.plus, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text('Nueva finca', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      if (_fincas.isEmpty)
        GestureDetector(
          onTap: _mostrarFormFinca,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: Column(children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(BootstrapIcons.geo_alt, color: AppColors.primary, size: 28)),
              const SizedBox(height: 12),
              Text('Agrega tu primera finca', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Toca aquí para registrarla', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ),
        )
      else ...[
        if (_fincas.length > 1) ...[
          SizedBox(height: 46, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: _fincas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final finca = _fincas[i]; final selected = i == _fincaSeleccionada;
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () { setState(() { _fincaSeleccionada = i; _cultivoSeleccionado = null; }); AppState.instance.setFinca(_fincas[i], _cultivosFincaActual); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: selected ? null : Border.all(color: AppColors.border.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? AppColors.primary.withOpacity(0.35)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: selected ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(finca['nombreFinca'] ?? 'Finca ${i + 1}',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.textPrimary)),
                  ),
                ),
              );
            },
          )),
          const SizedBox(height: 12),
        ],
        if (_fincaSeleccionada < _fincas.length) _buildFincaCard(_fincas[_fincaSeleccionada]),
      ],
    ]);
  }

  Widget _buildFincaCard(Map<String, dynamic> finca) {
    final cultivos  = _cultivosFincaActual;
    final nombre    = finca['nombreFinca'] ?? 'Mi Finca';
    final municipio = finca['municipio']   ?? 'Sin municipio';
    final idFinca   = finca['idFinca']     ?? finca['id_finca'];
    final fotoFinca = (finca['fotoUrl'] ??
            finca['fotoFinca'] ??
            finca['foto_finca'] ??
            finca['imagenFinca'] ??
            finca['imagen_finca'] ??
            finca['foto_url'] ??
            finca['foto'] ??
            finca['imagen'])
        ?.toString();
    final tieneFoto = fotoFinca != null && fotoFinca.isNotEmpty;

    final totalArboles = cultivos.fold<int>(0, (sum, c) {
      final n = (c as Map<String, dynamic>)['numeroArboles'] ?? c['numero_arboles'];
      return sum + (int.tryParse(n?.toString() ?? '0') ?? 0);
    });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        if (tieneFoto)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: Image.network(
                  fotoFinca,
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity, height: 130,
                    color: AppColors.primaryLight,
                    child: const Icon(BootstrapIcons.tree, color: AppColors.primary, size: 34),
                  ),
                ),
              ),
            ],
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (!tieneFoto)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _subirFotoFincaExistente(idFinca),
                    child: Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Text(
                          nombre.toString().isNotEmpty ? nombre.toString()[0].toUpperCase() : 'F',
                          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                        )),
                  ),
                ),
              if (!tieneFoto) const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text(municipio, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
              ])),
            ]),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _fincaDato('${cultivos.length}', 'Lotes registrados'),
              Container(width: 1, height: 36, color: AppColors.border),
              _fincaDato('$totalArboles', 'Plantas de café'),
            ]),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Lotes registrados', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => _mostrarFormLote(idFinca),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(BootstrapIcons.plus, color: AppColors.primary, size: 14),
                    const SizedBox(width: 3),
                    Text('Agregar lote', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ),
              ),
            ]),
            if (cultivos.isEmpty) ...[
              const SizedBox(height: 10),
              Center(child: Text('Sin lotes registrados aún', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary))),
            ] else ...[
              const SizedBox(height: 6),
              Text('(toca para ver su salud)', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...cultivos.map((c) {
                final idCultivo = c['idCultivo'] ?? c['id_cultivo'];
                final selected  = _cultivoSeleccionado?.toString() == idCultivo.toString();
                final nivel     = selected ? _calcularNivelRoyaPara(idCultivo) : '';
                final nivelColor = nivel == 'Alto' ? Colors.red : nivel == 'Medio' ? Colors.orange : nivel == 'Bajo' ? AppColors.primary : Colors.grey;

                final plantas = int.tryParse((c['numeroArboles'] ?? c['numero_arboles'] ?? '0').toString()) ?? 0;
                final variedad = c['tipoCultivo']?.toString() ?? '';

                return GestureDetector(
                  onTap: () {
                    final nuevoId = selected ? null : idCultivo;
                    setState(() => _cultivoSeleccionado = nuevoId);
                    if (nuevoId != null) AppState.instance.setCultivo(c, _calcularNivelRoyaPara(idCultivo));
                    else AppState.instance.setCultivo(null, _getSaludCultivo()['nivel']);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: selected ? Border.all(color: AppColors.primary, width: 1.5) : Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['nombreCultivo'] ?? c['nombre_cultivo'] ?? 'Cultivo',
                            style: GoogleFonts.nunito(fontSize: 12,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                                color: selected ? AppColors.primary : AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text('$plantas plantas', style: GoogleFonts.nunito(fontSize: 10,
                              color: selected ? AppColors.primary : AppColors.textSecondary)),
                          if (variedad.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(variedad, style: GoogleFonts.nunito(fontSize: 10,
                                color: selected ? AppColors.primary : AppColors.textSecondary)),
                          ],
                        ]),
                      ])),
                      IconButton(
                        onPressed: () => _mostrarFormEditarLote(c as Map<String, dynamic>),
                        icon: const Icon(BootstrapIcons.pencil, size: 18),
                        color: AppColors.primary, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: nivelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: nivelColor.withOpacity(0.4))),
                          child: Text('Roya: $nivel', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: nivelColor)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(BootstrapIcons.check_circle, color: AppColors.primary, size: 16),
                      ],
                    ]),
                  ),
                );
              }),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _fincaDato(String valor, String label) {
    return Column(children: [
      Text(valor, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  List<FlSpot> _buildChartSpots() {
    List monitoreosFiltrados;
    if (_cultivoSeleccionado != null) {
      monitoreosFiltrados = _monitoreos.where((m) =>
        (m['idCultivo'] ?? m['id_cultivo'])?.toString() == _cultivoSeleccionado.toString()
      ).toList();
    } else if (_fincas.isNotEmpty && _fincaSeleccionada < _fincas.length) {
      final ids = _cultivosFincaActual.map((c) => (c['idCultivo'] ?? c['id_cultivo']).toString()).toSet();
      monitoreosFiltrados = _monitoreos.where((m) => ids.contains((m['idCultivo'] ?? m['id_cultivo'])?.toString())).toList();
    } else {
      monitoreosFiltrados = _monitoreos;
    }

    monitoreosFiltrados.sort((a, b) {
      final ra = a['createdAt'] ?? a['created_at'] ?? a['fecha'] ?? '';
      final rb = b['createdAt'] ?? b['created_at'] ?? b['fecha'] ?? '';
      return ra.toString().compareTo(rb.toString());
    });

    double valorRiesgo(Map m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      if (obs.contains('critico') || obs.contains('crítico')) return 4000;
      if (obs.contains('alto')    || obs.contains('enfermedad')) return 3200;
      if (obs.contains('roya')    || obs.contains('medio'))      return 2000;
      if (obs.contains('bajo'))                                   return 800;
      return 400;
    }

    final base = monitoreosFiltrados.length > 10
        ? monitoreosFiltrados.sublist(monitoreosFiltrados.length - 10) : monitoreosFiltrados;

    List<FlSpot> spots = List.generate(base.length, (i) => FlSpot(i.toDouble(), valorRiesgo(base[i] as Map)));

    if (spots.isEmpty) {
      spots = [const FlSpot(0,400),const FlSpot(1,600),const FlSpot(2,500),const FlSpot(3,700),const FlSpot(4,550),
               const FlSpot(5,650),const FlSpot(6,500),const FlSpot(7,600),const FlSpot(8,550),const FlSpot(9,400)];
    } else if (spots.length < 10) {
      final ultimo = spots.last.y;
      for (int i = spots.length; i < 10; i++) spots.add(FlSpot(i.toDouble(), ultimo));
    }
    return spots;
  }

  Widget _buildChart() {
    final salud = _getSaludCultivo();
    final colorGrafica = salud['nivel'] == 'Bajo' ? AppColors.primary : salud['nivel'] == 'Medio' ? Colors.orange : Colors.red;
    final spots = _buildChartSpots();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Riesgo de roya', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(salud['nivel'], style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: colorGrafica)),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 180, child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1000,
              getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1000, reservedSize: 40,
                getTitlesWidget: (v, m) => Text('${(v/40).round()}%', style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSecondary)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: 9, minY: 0, maxY: 4000,
          lineBarsData: [LineChartBarData(
            spots: spots, isCurved: true, curveSmoothness: 0.4, color: colorGrafica,
            barWidth: 2.5, isStrokeCapRound: true, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [colorGrafica.withOpacity(0.3), colorGrafica.withOpacity(0.0)],
            )),
          )],
        ))),
      ]),
    );
  }
}
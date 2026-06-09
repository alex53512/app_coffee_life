import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/app_state.dart';
import 'login_screen.dart';
 
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
 
  const ProfileScreen({
    super.key,
    required this.usuario,
  });
 
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
 
class _ProfileScreenState extends State<ProfileScreen> {
  bool _cargando = false;
  Map<String, dynamic> _usuarioData = {};
 
  // La finca que se muestra en el perfil siempre viene del AppState.
  // Solo se usa para mostrar info y para editar (PUT /fincas/:id).
  Map<String, dynamic>? get _finca => AppState.instance.fincaSeleccionada;
 
  XFile?     _imagenSeleccionada;
  Uint8List? _imagenBytes;
  String?    _fotoUrl;
 
  final ImagePicker _picker = ImagePicker();
 
  // Campos usuario
  final TextEditingController _nombreController      = TextEditingController();
  final TextEditingController _apellidoController    = TextEditingController();
  final TextEditingController _correoController      = TextEditingController();
  final TextEditingController _telefonoController    = TextEditingController();
  final TextEditingController _cedulaController      = TextEditingController();
 
  // Campos finca
  final TextEditingController _fincaController        = TextEditingController();
  final TextEditingController _municipioController    = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _hectareasController    = TextEditingController();
  final TextEditingController _altitudController      = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    _usuarioData = Map.from(widget.usuario);
    _cargarDatos();
    // Escucha cambios de finca/cultivo para reconstruir la UI
    AppState.instance.addListener(_onEstadoCambiado);
  }
 
  void _onEstadoCambiado() {
    // Actualizar campos de finca cuando cambia en el AppState
    if (mounted) {
      setState(() {
        _actualizarCamposFinca();
      });
    }
  }
 
  void _actualizarCamposFinca() {
    final f = _finca;
    _fincaController.text        = f?['nombreFinca']?.toString() ?? '';
    _municipioController.text    = f?['municipio']?.toString() ?? '';
    _departamentoController.text = f?['departamento']?.toString() ?? '';
    _hectareasController.text    = (f?['areaHectareas'] ?? f?['area_hectareas'])?.toString() ?? '';
    _altitudController.text      = (f?['altitudMsnm'] ?? f?['altitud_msnm'])?.toString() ?? '';
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onEstadoCambiado);
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _fincaController.dispose();
    _municipioController.dispose();
    _departamentoController.dispose();
    _hectareasController.dispose();
    _altitudController.dispose();
    super.dispose();
  }
 
  String _leerRol(Map<String, dynamic> u) {
    final rol = u['rol'];
    if (rol == null) return 'Caficultor';
    if (rol is String) return rol;
    if (rol is Map) return rol['nombreRol'] ?? 'Caficultor';
    return 'Caficultor';
  }
 
  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final raw = await ApiService.get('/mi-perfil');
      final u   = raw is Map ? (raw['data'] ?? raw) : raw;
 
      setState(() {
        _usuarioData = Map<String, dynamic>.from(u is Map ? u : {});
        _fotoUrl     = _usuarioData['fotoPerfil'] as String?;
 
        _nombreController.text   = _usuarioData['nombre']?.toString() ?? '';
        _apellidoController.text = _usuarioData['apellido']?.toString() ?? '';
        _correoController.text   = _usuarioData['correo']?.toString() ?? '';
        _telefonoController.text = _usuarioData['telefono']?.toString() ?? '';
        _cedulaController.text   = _usuarioData['cedula']?.toString() ?? '';
 
        // Campos de finca desde AppState (siempre)
        _actualizarCamposFinca();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }
 
  // ── SELECCIONAR FOTO ──────────────────────────────────────────────────────
 
  Future<void> _seleccionarFoto() async {
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
              Text('Foto de perfil',
                  style: GoogleFonts.nunito(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text('Tomar foto', style: GoogleFonts.nunito()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text('Elegir de galería', style: GoogleFonts.nunito()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
 
    if (origen == null) return;
 
    final picked = await _picker.pickImage(
      source: origen,
      imageQuality: 80,
      maxWidth: 800,
    );
 
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imagenSeleccionada = picked;
        _imagenBytes        = bytes;
      });
      await _subirFoto();
    }
  }
 
  // ── SUBIR FOTO ────────────────────────────────────────────────────────────
 
  Future<void> _subirFoto() async {
    if (_imagenSeleccionada == null || _imagenBytes == null) return;
 
    setState(() => _cargando = true);
    try {
      final token   = await AuthService.getToken();
      final baseUrl = ApiService.baseUrl;
 
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/mi-perfil'),
      );
 
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nombre']         = _nombreController.text;
      request.fields['apellido']       = _apellidoController.text;
      request.fields['telefono']       = _telefonoController.text;
      request.fields['observaciones']  = '';
 
      request.files.add(http.MultipartFile.fromBytes(
        'foto_perfil',
        _imagenBytes!,
        filename: _imagenSeleccionada!.name,
      ));
 
      final response = await request.send();
      final body     = await response.stream.bytesToString();
 
      if (response.statusCode == 200) {
        await _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Error ${response.statusCode}: $body');
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
 
  // ── GUARDAR CAMBIOS ───────────────────────────────────────────────────────
 
  Future<void> _guardarCambios() async {
    setState(() => _cargando = true);
    try {
      await ApiService.put('/mi-perfil', {
        'nombre':        _nombreController.text,
        'apellido':      _apellidoController.text,
        'telefono':      _telefonoController.text,
        'observaciones': '',
      });
 
      final idFinca = _finca?['idFinca'] ?? _finca?['id_finca'];
      if (idFinca != null) {
        await ApiService.put('/fincas/$idFinca', {
          'nombre_finca':   _fincaController.text,
          'municipio':      _municipioController.text,
          'departamento':   _departamentoController.text,
          'area_hectareas': double.tryParse(_hectareasController.text) ?? 0,
          'altitud_msnm':   double.tryParse(_altitudController.text) ?? 0,
        });
      }
 
      setState(() {
        _usuarioData['nombre']   = _nombreController.text;
        _usuarioData['apellido'] = _apellidoController.text;
        _usuarioData['telefono'] = _telefonoController.text;
        _imagenSeleccionada      = null;
        _imagenBytes             = null;
        _cargando                = false;
      });
 
      if (mounted) Navigator.pop(context);
 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _cargando = false);
      _imagenSeleccionada = null;
      _imagenBytes        = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
 
  // ── FORMULARIO EDITAR ─────────────────────────────────────────────────────
 
  void _mostrarFormularioEditar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Editar perfil',
                    style: GoogleFonts.nunito(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Datos personales',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                _campoTexto(_nombreController, 'Nombre'),
                const SizedBox(height: 14),
                _campoTexto(_apellidoController, 'Apellido'),
                const SizedBox(height: 14),
                _campoTexto(_correoController, 'Correo', enabled: false),
                const SizedBox(height: 14),
                _campoTexto(_telefonoController, 'Teléfono',
                    tipo: TextInputType.phone),
                const SizedBox(height: 14),
                _campoTexto(_cedulaController, 'Cédula'),
                const SizedBox(height: 20),
                // Editar la finca actualmente seleccionada en AppState
                if (_finca != null) ...[
                  Row(
                    children: [
                      Text('Finca seleccionada',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _finca?['nombreFinca'] ?? '',
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _campoTexto(_fincaController, 'Nombre de la finca'),
                  const SizedBox(height: 14),
                  _campoTexto(_municipioController, 'Municipio'),
                  const SizedBox(height: 14),
                  _campoTexto(_departamentoController, 'Departamento'),
                  const SizedBox(height: 14),
                  _campoTexto(_hectareasController, 'Área en hectáreas',
                      tipo: TextInputType.number),
                  const SizedBox(height: 14),
                  _campoTexto(_altitudController, 'Altitud msnm',
                      tipo: TextInputType.number),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text('Guardar cambios',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
 
  Widget _campoTexto(
    TextEditingController controller,
    String label, {
    TextInputType tipo = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
    );
  }
 
  // ── CERRAR SESIÓN ─────────────────────────────────────────────────────────
 
  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('¿Estás seguro que quieres cerrar sesión?',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
 
    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }
 
  // ── BUILD ─────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E7D6),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildAvatarSection(),
                          const SizedBox(height: 8),
                          // Banner de finca/cultivo activo
                          _buildFincaCultivoBanner(),
                          const SizedBox(height: 8),
                          _buildInfoSection(),
                          const SizedBox(height: 24),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: OutlinedButton.icon(
                              onPressed: _cerrarSesion,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: Text('Cerrar sesión',
                                  style: GoogleFonts.nunito(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: const Color(0xFFF4E7D6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Mi perfil',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _mostrarFormularioEditar,
          ),
        ],
      ),
    );
  }
 
  /// Banner compacto que muestra la finca y cultivo activo del AppState.
  Widget _buildFincaCultivoBanner() {
    final fincaNombre   = _finca?['nombreFinca']?.toString();
    final cultivoNombre = AppState.instance.cultivoNombre;
    final nivelRoya     = AppState.instance.nivelRoya;
 
    if (fincaNombre == null) return const SizedBox.shrink();
 
    final royaColor = nivelRoya == 'Alto'  ? Colors.red
                    : nivelRoya == 'Medio' ? Colors.orange
                    : nivelRoya == 'Bajo'  ? AppColors.primary
                    : Colors.grey;
 
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.park_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contexto activo',
                    style: GoogleFonts.nunito(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(fincaNombre,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                if (cultivoNombre.isNotEmpty)
                  Text('Cultivo: $cultivoNombre',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (cultivoNombre.isNotEmpty && nivelRoya != 'Sin datos')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: royaColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: royaColor.withOpacity(0.3)),
              ),
              child: Text('Roya: $nivelRoya',
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: royaColor)),
            ),
        ],
      ),
    );
  }
 
  Widget _buildAvatarSection() {
    final nombre   = (_usuarioData['nombre']   ?? widget.usuario['nombre']   ?? '').toString();
    final apellido = (_usuarioData['apellido'] ?? widget.usuario['apellido'] ?? '').toString();
    final correo   = (_usuarioData['correo']   ?? widget.usuario['correo']   ?? '').toString();
    final inicial  = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
 
    ImageProvider? imageProvider;
    if (_imagenBytes != null) {
      imageProvider = MemoryImage(_imagenBytes!);
    } else if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_fotoUrl!);
    }
 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      color: const Color(0xFFF4E7D6),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(inicial,
                        style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold))
                    : null,
              ),
              GestureDetector(
                onTap: _seleccionarFoto,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('$nombre $apellido'.trim(),
              style: GoogleFonts.nunito(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(correo,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _leerRol(_usuarioData),
              style: GoogleFonts.nunito(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildInfoSection() {
    // Muestra siempre la finca activa del AppState
    final finca = _finca;
 
    return Container(
      color: const Color(0xFFF4E7D6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          _rowItem(
            label: 'Mi finca',
            valor: finca?['nombreFinca']?.toString() ?? 'Sin finca registrada',
            icono: Icons.park_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Municipio',
            valor: finca?['municipio']?.toString() ?? 'No registrado',
            icono: Icons.location_on_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Departamento',
            valor: finca?['departamento']?.toString() ?? 'No registrado',
            icono: Icons.location_city_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Área total',
            valor: '${finca?['areaHectareas'] ?? finca?['area_hectareas'] ?? '0'} hectáreas',
            icono: Icons.straighten_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Altitud',
            valor: '${finca?['altitudMsnm'] ?? finca?['altitud_msnm'] ?? '0'} msnm',
            icono: Icons.terrain_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Teléfono',
            valor: _usuarioData['telefono']?.toString() ?? 'No registrado',
            icono: Icons.phone_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Cédula',
            valor: _usuarioData['cedula']?.toString() ?? 'No registrada',
            icono: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }
 
  Widget _rowItem({
    required String label,
    required String valor,
    required IconData icono,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icono, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(valor,
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _divider() {
    return const Divider(
        height: 1, color: Color.fromARGB(255, 202, 200, 200));
  }
}
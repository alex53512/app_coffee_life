import 'dart:io';
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
  Map<String, dynamic>? _finca;
 
  File? _imagenSeleccionada;
  String? _fotoUrl;
 
  final ImagePicker _picker = ImagePicker();
 
  // Campos usuario
  final TextEditingController _nombreController     = TextEditingController();
  final TextEditingController _apellidoController   = TextEditingController();
  final TextEditingController _correoController     = TextEditingController();
  final TextEditingController _telefonoController   = TextEditingController();
  final TextEditingController _cedulaController     = TextEditingController();
 
  // Campos finca
  final TextEditingController _fincaController      = TextEditingController();
  final TextEditingController _municipioController  = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _hectareasController  = TextEditingController();
  final TextEditingController _altitudController    = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    _usuarioData = Map.from(widget.usuario);
    _cargarDatos();
    AppState.instance.addListener(_onFincaCambiada);
  }
 
  void _onFincaCambiada() {
    final finca = AppState.instance.fincaSeleccionada;
    if (finca != null) {
      setState(() {
        _finca = Map<String, dynamic>.from(finca);
        _actualizarCamposFinca();
      });
    }
  }
 
  void _actualizarCamposFinca() {
    _fincaController.text       = _finca?['nombreFinca']?.toString() ?? '';
    _municipioController.text   = _finca?['municipio']?.toString() ?? '';
    _departamentoController.text = _finca?['departamento']?.toString() ?? '';
    _hectareasController.text   = _finca?['areaHectareas']?.toString() ?? '';
    _altitudController.text     = _finca?['altitudMsnm']?.toString() ?? '';
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onFincaCambiada);
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
      final results = await Future.wait([
        ApiService.get('/mi-perfil'),
        ApiService.get('/fincas'),
      ]);
 
      final raw = results[0];
      final u   = raw is Map ? (raw['data'] ?? raw) : raw;
 
      final fincasRaw = results[1];
      final fincas    = fincasRaw is List
          ? fincasRaw
          : (fincasRaw is Map ? (fincasRaw['data'] ?? []) : []);
 
      setState(() {
        _usuarioData = Map<String, dynamic>.from(u is Map ? u : {});
 
        // Usar finca del AppState si hay una seleccionada, si no la primera
        final fincaState = AppState.instance.fincaSeleccionada;
        if (fincaState != null) {
          _finca = Map<String, dynamic>.from(fincaState);
        } else if (fincas is List && fincas.isNotEmpty) {
          _finca = Map<String, dynamic>.from(fincas[0]);
        }
 
        _fotoUrl = _usuarioData['foto_perfil'] as String?;
 
        _nombreController.text   = _usuarioData['nombre']?.toString() ?? '';
        _apellidoController.text = _usuarioData['apellido']?.toString() ?? '';
        _correoController.text   = _usuarioData['correo']?.toString() ?? '';
        _telefonoController.text = _usuarioData['telefono']?.toString() ?? '';
        _cedulaController.text   = _usuarioData['cedula']?.toString() ?? '';
        _actualizarCamposFinca();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }
 
  Future<void> _seleccionarFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
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
 
    if (origen == null) return;
 
    final picked = await _picker.pickImage(
      source: origen,
      imageQuality: 80,
      maxWidth: 800,
    );
 
    if (picked != null) {
      setState(() => _imagenSeleccionada = File(picked.path));
      await _subirFoto();
    }
  }
 
  Future<void> _subirFoto() async {
    if (_imagenSeleccionada == null) return;
 
    setState(() => _cargando = true);
    try {
      final token   = await AuthService.getToken();
      final baseUrl = ApiService.baseUrl;
 
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/mi-perfil'),
      );
 
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nombre']       = _nombreController.text;
      request.fields['apellido']     = _apellidoController.text;
      request.fields['telefono']     = _telefonoController.text;
      request.fields['observaciones'] = '';
 
      request.files.add(await http.MultipartFile.fromPath(
        'foto_perfil',
        _imagenSeleccionada!.path,
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
 
  Future<void> _guardarCambios() async {
    setState(() => _cargando = true);
    try {
      // 1. Guardar datos del usuario
      await ApiService.put('/mi-perfil', {
        'nombre':        _nombreController.text,
        'apellido':      _apellidoController.text,
        'telefono':      _telefonoController.text,
        'observaciones': '',
      });
 
      // 2. Guardar datos de la finca si hay una seleccionada
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
        _cargando = false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
 
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
                Text('Datos de la finca',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
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
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                          _buildInfoSection(),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
      color: AppColors.background,
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
 
  Widget _buildAvatarSection() {
    final nombre  = (_usuarioData['nombre'] ?? widget.usuario['nombre'] ?? '').toString();
    final apellido = (_usuarioData['apellido'] ?? widget.usuario['apellido'] ?? '').toString();
    final correo  = (_usuarioData['correo'] ?? widget.usuario['correo'] ?? '').toString();
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
 
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      color: Colors.white,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary,
                backgroundImage: _imagenSeleccionada != null
                    ? FileImage(_imagenSeleccionada!) as ImageProvider
                    : (_fotoUrl != null && _fotoUrl!.isNotEmpty
                        ? NetworkImage(_fotoUrl!)
                        : null),
                child: (_imagenSeleccionada == null &&
                        (_fotoUrl == null || _fotoUrl!.isEmpty))
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
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          _rowItem(
            label: 'Mi finca',
            valor: _finca?['nombreFinca']?.toString() ?? 'Sin finca registrada',
            icono: Icons.park_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Municipio',
            valor: _finca?['municipio']?.toString() ?? 'No registrado',
            icono: Icons.location_on_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Departamento',
            valor: _finca?['departamento']?.toString() ?? 'No registrado',
            icono: Icons.location_city_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Área total',
            valor: '${_finca?['areaHectareas'] ?? '0'} hectáreas',
            icono: Icons.straighten_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Altitud',
            valor: '${_finca?['altitudMsnm'] ?? '0'} msnm',
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
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }
}
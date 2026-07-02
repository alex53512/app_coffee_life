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
  Map<String, dynamic>? _finca;

  XFile?     _imagenSeleccionada;
  Uint8List? _imagenBytes;
  String?    _fotoUrl;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nombreController      = TextEditingController();
  final TextEditingController _apellidoController    = TextEditingController();
  final TextEditingController _correoController      = TextEditingController();
  final TextEditingController _telefonoController    = TextEditingController();
  final TextEditingController _cedulaController      = TextEditingController();

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
    _fincaController.text        = _finca?['nombreFinca']?.toString() ?? '';
    _municipioController.text    = _finca?['municipio']?.toString() ?? '';
    _departamentoController.text = _finca?['departamento']?.toString() ?? '';
    _hectareasController.text    = _finca?['areaHectareas']?.toString() ?? '';
    _altitudController.text      = _finca?['altitudMsnm']?.toString() ?? '';
  }

  String _leerCedula(Map<String, dynamic> u) {
    final valor = u['cedula'] ??
        u['numero_documento'] ??
        u['numeroDocumento'] ??
        u['identificacion'] ??
        u['documento'] ??
        u['cedula_usuario'];
    return valor?.toString() ?? '';
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
    print('USUARIO DATA: $_usuarioData');
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

        final fincaState = AppState.instance.fincaSeleccionada;
        if (fincaState != null) {
          _finca = Map<String, dynamic>.from(fincaState);
        } else if (fincas is List && fincas.isNotEmpty) {
          _finca = Map<String, dynamic>.from(fincas[0]);
        }

        _fotoUrl = _usuarioData['fotoPerfil'] as String?;

        _nombreController.text   = _usuarioData['nombre']?.toString() ?? '';
        _apellidoController.text = _usuarioData['apellido']?.toString() ?? '';
        _correoController.text   = _usuarioData['correo']?.toString() ?? '';
        _telefonoController.text = _usuarioData['telefono']?.toString() ?? '';
        _cedulaController.text   = _leerCedula(_usuarioData);
        _actualizarCamposFinca();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

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

  Future<void> _guardarCambios() async {
    setState(() => _cargando = true);
    try {
      await ApiService.put('/mi-perfil', {
        'nombre':        _nombreController.text,
        'apellido':      _apellidoController.text,
        'telefono':      _telefonoController.text,
        'cedula':        _cedulaController.text,
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
        _usuarioData['cedula']   = _cedulaController.text;
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

  void _mostrarFormularioEditar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Editar perfil',
                    style: GoogleFonts.nunito(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Guardar cambios',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700, color: Colors.white)),
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
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
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
      backgroundColor: const Color(0xFFF7F8F5),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 16),
                    _buildAvatarCard(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildSettingsCard(),
                    const SizedBox(height: 16),
                    _buildLogoutCard(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text('App versión 1.0',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _iconCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Text('Mi perfil',
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        _iconCircleButton(
          icon: Icons.settings_outlined,
          onTap: _mostrarFormularioEditar,
        ),
      ],
    );
  }

  Widget _iconCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
            ],
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      ),
    );
  }

  Widget _buildAvatarCard() {
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(inicial,
                        style: GoogleFonts.nunito(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w800))
                    : null,
              ),
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _seleccionarFoto,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$nombre $apellido'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(correo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _mostrarFormularioEditar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text('Editar perfil',
                        style: GoogleFonts.nunito(
                            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
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
            label: 'Teléfono',
            valor: _usuarioData['telefono']?.toString() ?? 'No registrado',
            icono: Icons.phone_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Cédula',
            valor: () {
              final cedula = _leerCedula(_usuarioData);
              return cedula.isNotEmpty ? cedula : 'No registrada';
            }(),
            icono: Icons.badge_outlined,
            esUltimo: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _settingsRow(
            icono: Icons.notifications_outlined,
            label: 'Notificaciones',
            onTap: () => _mostrarProximamente('Notificaciones'),
          ),
          _divider(),
          _settingsRow(
            icono: Icons.description_outlined,
            label: 'Términos y condiciones',
            onTap: () => _mostrarProximamente('Términos y condiciones'),
          ),
          _divider(),
          _settingsRow(
            icono: Icons.info_outline_rounded,
            label: 'Acerca de la app',
            onTap: _mostrarAcercaDe,
          ),
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icono,
    required String label,
    String? valor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              if (valor != null) ...[
                Text(valor,
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withOpacity(0.6), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarProximamente(String funcion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$funcion estará disponible pronto', style: GoogleFonts.nunito()),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _mostrarAcercaDe() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Coffee Life',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tecnología para el cultivo del café.\n\n'
              'Diagnostica la roya, monitorea tus lotes y recibe '
              'recomendaciones personalizadas para tu finca.',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            Text('Versión 1.0',
                style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, minimumSize: const Size(0, 40)),
            child: Text('Cerrar', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _cerrarSesion,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Cerrar sesión',
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red)),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.red.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowItem({
    required String label,
    required String valor,
    required IconData icono,
    bool esUltimo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Divider(height: 1, color: Color(0xFFEFEFEF)),
    );
  }
}
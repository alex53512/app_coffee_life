import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/theme_notifier.dart';
import 'ajustes_screen.dart';

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
                    color: AppColors.textPrimary),
                title: Text('Tomar foto', style: GoogleFonts.nunito()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.textPrimary),
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
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantBg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
        fillColor: enabled ? AppColors.inputFill(context) : AppColors.surfaceVariantBg(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF97D340), Color(0xFF388E3C)],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: _buildTopBar(context),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatarCard(),
                        const SizedBox(height: 16),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildSettingsCard(),
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
              ],
            ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        _iconCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        Text('Mi perfil',
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _iconCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(inicial,
                        style: GoogleFonts.nunito(
                            fontSize: 34,
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
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text('$nombre $apellido'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _mostrarFormularioEditar,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(correo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 13, color: AppColors.textSecondary)),
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
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _rowItem(
            label: 'Mi finca',
            valor: _finca?['nombreFinca']?.toString() ?? 'Sin finca registrada',
          ),
          _divider(),
          _rowItem(
            label: 'Municipio',
            valor: _finca?['municipio']?.toString() ?? 'No registrado',
          ),
          _divider(),
          _rowItem(
            label: 'Departamento',
            valor: _finca?['departamento']?.toString() ?? 'No registrado',
          ),
          _divider(),
          _rowItem(
            label: 'Teléfono',
            valor: _usuarioData['telefono']?.toString() ?? 'No registrado',
          ),
          _divider(),
          _rowItem(
            label: 'Cédula',
            valor: () {
              final cedula = _leerCedula(_usuarioData);
              return cedula.isNotEmpty ? cedula : 'No registrada';
            }(),
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
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _settingsRow(
            icono: Icons.info_outline_rounded,
            label: 'Acerca de la app',
            onTap: _mostrarAcercaDe,
          ),
          _divider(),
          _settingsRow(
            icono: Icons.settings_outlined,
            label: 'Ajustes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AjustesScreen())),
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
              Icon(icono, color: AppColors.textPrimary, size: 22),
              const SizedBox(width: 12),
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
            ],
          ),
        ),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coffee Life es una aplicación para caficultores '
                'colombianos. Con ella puedes tomar fotos de las '
                'hojas de café, enviarlas a análisis y recibir un '
                'diagnóstico con recomendaciones para el cuidado '
                'de tus cultivos, todo desde tu celular.',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Text('¿Qué puedes hacer con Coffee Life?',
                  style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _itemAcerca('Diagnóstico de enfermedades',
                  'Toma una foto de una hoja de café, la envías a análisis y recibes el resultado: si tiene roya, qué tan grave está y qué hacer.'),
              _itemAcerca('Historial de tu cultivo',
                  'Todas tus fotos y diagnósticos quedan guardados para que puedas ver cómo ha ido cambiando tu cultivo con el tiempo.'),
              _itemAcerca('Recomendaciones de tratamiento',
                  'Cada diagnóstico incluye recomendaciones de productos, dosis y frecuencia para tratar la enfermedad.'),
              _itemAcerca('Asistente virtual',
                  '¿Tienes una duda sobre tu cultivo? Escribe en el chat y recibes respuesta al instante.'),
              _itemAcerca('Clima de tu finca',
                  'Consulta el clima actual para saber cuándo es mejor aplicar los tratamientos.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.phone_android, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Versión 1.0.0',
                      style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 4),
              Text('© 2026 Coffee Life',
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
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

  Widget _itemAcerca(String titulo, String descripcion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6, height: 6,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(descripcion,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowItem({
    required String label,
    required String valor,
    bool esUltimo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}
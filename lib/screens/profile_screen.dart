import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _fincaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _veredaController = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _cultivoController = TextEditingController();
  final TextEditingController _hectareasController = TextEditingController();
  final TextEditingController _arbolesController = TextEditingController();
  final TextEditingController _altitudController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usuarioData = Map.from(widget.usuario);
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _municipioController.dispose();
    _fincaController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _veredaController.dispose();
    _departamentoController.dispose();
    _cultivoController.dispose();
    _hectareasController.dispose();
    _arbolesController.dispose();
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

      final u = results[0] is Map
          ? results[0]
          : (results[0]['data'] ?? results[0]);

      final fincas = results[1] is List
          ? results[1]
          : (results[1]['data'] ?? []);

      setState(() {
        _usuarioData = Map<String, dynamic>.from(u);
        if (fincas.isNotEmpty) _finca = fincas[0];

        _nombreController.text = _usuarioData['nombre'] ?? '';
        _apellidoController.text = _usuarioData['apellido'] ?? '';
        _correoController.text = _usuarioData['correo'] ?? '';
        _telefonoController.text = _usuarioData['telefono'] ?? '';
        _cedulaController.text = _usuarioData['cedula'] ?? '';
        _municipioController.text = _finca?['municipio'] ?? '';
        _fincaController.text = _finca?['nombreFinca'] ?? '';
        _veredaController.text = _finca?['vereda'] ?? '';
        _departamentoController.text = _finca?['departamento'] ?? '';
        _cultivoController.text = _finca?['cultivoPrincipal'] ?? '';
        _hectareasController.text = _finca?['areaHectareas']?.toString() ?? '';
        _arbolesController.text = _finca?['cantidadArboles']?.toString() ?? '';
        _altitudController.text = _finca?['altitudMsnm']?.toString() ?? '';
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => _cargando = true);
    try {
      await ApiService.put('/mi-perfil', {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'telefono': _telefonoController.text,
        'observaciones': '',
      });

      setState(() {
        _usuarioData['nombre'] = _nombreController.text;
        _usuarioData['apellido'] = _apellidoController.text;
        _usuarioData['telefono'] = _telefonoController.text;
        _cargando = false;
      });

      Navigator.pop(context);

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
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Editar perfil',
                    style: GoogleFonts.nunito(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
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
                const SizedBox(height: 14),
                _campoTexto(_fincaController, 'Nombre de la finca'),
                const SizedBox(height: 14),
                _campoTexto(_municipioController, 'Municipio'),
                const SizedBox(height: 14),
                _campoTexto(_veredaController, 'Vereda'),
                const SizedBox(height: 14),
                _campoTexto(_departamentoController, 'Departamento'),
                const SizedBox(height: 14),
                _campoTexto(_cultivoController, 'Cultivo principal'),
                const SizedBox(height: 14),
                _campoTexto(_hectareasController, 'Área en hectáreas',
                    tipo: TextInputType.number),
                const SizedBox(height: 14),
                _campoTexto(_arbolesController, 'Cantidad de árboles',
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
                          _buildFincaItem(),
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
    final nombre = _usuarioData['nombre'] ?? widget.usuario['nombre'] ?? 'U';
    final apellido = _usuarioData['apellido'] ?? widget.usuario['apellido'] ?? '';
    final correo = _usuarioData['correo'] ?? widget.usuario['correo'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      color: Colors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            child: Text(
              nombre[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          Text('$nombre $apellido',
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

  Widget _buildFincaItem() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: _rowItem(
        label: 'Mi finca',
        valor: _finca?['nombreFinca'] ?? 'Sin finca registrada',
        icono: Icons.park_outlined,
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
            label: 'Municipio',
            valor: _finca?['municipio'] ?? 'No registrado',
            icono: Icons.location_on_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Departamento',
            valor: _finca?['departamento'] ?? 'No registrado',
            icono: Icons.location_city_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Teléfono',
            valor: _usuarioData['telefono'] ?? 'No registrado',
            icono: Icons.phone_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Cédula',
            valor: _usuarioData['cedula'] ?? 'No registrada',
            icono: Icons.badge_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Vereda',
            valor: _finca?['vereda'] ?? 'No registrada',
            icono: Icons.map_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Cultivo principal',
            valor: _finca?['cultivoPrincipal'] ?? 'No registrado',
            icono: Icons.eco_outlined,
          ),
          _divider(),
          _rowItem(
            label: 'Cantidad de árboles',
            valor: '${_finca?['cantidadArboles'] ?? '0'}',
            icono: Icons.forest_outlined,
          ),
        ],
      ),
    );
  }

  Widget _rowItem({
    required String label,
    required String valor,
    required IconData icono,
    bool conFlecha = false,
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
          if (conFlecha)
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }
}
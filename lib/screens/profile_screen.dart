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

  // =========================
  // CONTROLLERS
  // =========================

  final TextEditingController _nombreController =
      TextEditingController();

  final TextEditingController _apellidoController =
      TextEditingController();

  final TextEditingController _correoController =
      TextEditingController();

  final TextEditingController _municipioController =
      TextEditingController();

  final TextEditingController _fincaController =
      TextEditingController();

  final TextEditingController _telefonoController =
      TextEditingController();

  final TextEditingController _cedulaController =
      TextEditingController();

  final TextEditingController _veredaController =
      TextEditingController();

  final TextEditingController _departamentoController =
      TextEditingController();

  final TextEditingController _cultivoController =
      TextEditingController();

  final TextEditingController _hectareasController =
      TextEditingController();

  final TextEditingController _arbolesController =
      TextEditingController();

  final TextEditingController _altitudController =
      TextEditingController();

  final TextEditingController _produccionController =
      TextEditingController();

  final TextEditingController _asociacionController =
      TextEditingController();

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
    _produccionController.dispose();
    _asociacionController.dispose();

    super.dispose();
  }

  String _leerRol(Map<String, dynamic> u) {

    final rol = u['rol'];

    if (rol == null) return 'Campesino';

    if (rol is String) return rol;

    if (rol is Map) {
      return rol['nombreRol'] ?? 'Campesino';
    }

    return 'Campesino';
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

        if (fincas.isNotEmpty) {
          _finca = fincas[0];
        }

        // =========================
        // CARGAR DATOS
        // =========================

        _nombreController.text =
            _usuarioData['nombre'] ?? '';

        _apellidoController.text =
            _usuarioData['apellido'] ?? '';

        _correoController.text =
            _usuarioData['correo'] ?? '';

        _telefonoController.text =
            _usuarioData['telefono'] ?? '';

        _cedulaController.text =
            _usuarioData['cedula'] ?? '';

        _asociacionController.text =
            _usuarioData['asociacion'] ?? '';

        _municipioController.text =
            _finca?['municipio'] ?? '';

        _fincaController.text =
            _finca?['nombreFinca'] ?? '';

        _veredaController.text =
            _finca?['vereda'] ?? '';

        _departamentoController.text =
            _finca?['departamento'] ?? '';

        _cultivoController.text =
            _finca?['cultivoPrincipal'] ?? '';

        _hectareasController.text =
            _finca?['areaHectareas']?.toString() ?? '';

        _arbolesController.text =
            _finca?['cantidadArboles']?.toString() ?? '';

        _altitudController.text =
            _finca?['altitudMsnm']?.toString() ?? '';

        _produccionController.text =
            _finca?['produccionMensual']?.toString() ?? '';

        _cargando = false;
      });

    } catch (e) {

      setState(() => _cargando = false);
    }
  }

  // =========================
  // GUARDAR LOCALMENTE
  // =========================

  Future<void> _guardarCambios() async {

    setState(() {

      _usuarioData['nombre'] =
          _nombreController.text;

      _usuarioData['apellido'] =
          _apellidoController.text;

      _usuarioData['correo'] =
          _correoController.text;

      _usuarioData['telefono'] =
          _telefonoController.text;

      _usuarioData['cedula'] =
          _cedulaController.text;

      _usuarioData['asociacion'] =
          _asociacionController.text;

      if (_finca != null) {

        _finca!['nombreFinca'] =
            _fincaController.text;

        _finca!['municipio'] =
            _municipioController.text;

        _finca!['vereda'] =
            _veredaController.text;

        _finca!['departamento'] =
            _departamentoController.text;

        _finca!['cultivoPrincipal'] =
            _cultivoController.text;

        _finca!['areaHectareas'] =
            _hectareasController.text;

        _finca!['cantidadArboles'] =
            _arbolesController.text;

        _finca!['altitudMsnm'] =
            _altitudController.text;

        _finca!['produccionMensual'] =
            _produccionController.text;
      }
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cambios guardados localmente',
        ),
      ),
    );
  }

  // =========================
  // MODAL EDITAR
  // =========================

  void _mostrarFormularioEditar() {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (context) {

        return Padding(

          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 20,
          ),

          child: SingleChildScrollView(

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                Text(
                  'Editar perfil',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _cedulaController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _fincaController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la finca',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _municipioController,
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _veredaController,
                  decoration: const InputDecoration(
                    labelText: 'Vereda',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _departamentoController,
                  decoration: const InputDecoration(
                    labelText: 'Departamento',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _cultivoController,
                  decoration: const InputDecoration(
                    labelText: 'Cultivo principal',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _hectareasController,
                  decoration: const InputDecoration(
                    labelText: 'Área en hectáreas',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _arbolesController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de árboles',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _altitudController,
                  decoration: const InputDecoration(
                    labelText: 'Altitud msnm',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _produccionController,
                  decoration: const InputDecoration(
                    labelText: 'Producción mensual',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _asociacionController,
                  decoration: const InputDecoration(
                    labelText: 'Asociación campesina',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(

                    onPressed: _guardarCambios,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ),
                    ),

                    child: Text(
                      'Guardar cambios',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  Future<void> _cerrarSesion() async {

    final confirm = await showDialog<bool>(
      context: context,

      builder: (_) => AlertDialog(

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
          ),
        ),

        content: Text(
          '¿Estás seguro que quieres cerrar sesión?',
          style: GoogleFonts.nunito(),
        ),

        actions: [

          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),

            child: Text(
              'Cancelar',
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),

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

          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),

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
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),

                            child: OutlinedButton.icon(

                              onPressed: _cerrarSesion,

                              icon: const Icon(
                                Icons.logout,
                                color: Colors.red,
                              ),

                              label: Text(
                                'Cerrar sesión',
                                style: GoogleFonts.nunito(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.red,
                                ),

                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
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

      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),

      color: AppColors.background,

      child: Row(
        children: [

          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),

            onPressed: () {
              Navigator.pop(context);
            },
          ),

          Expanded(
            child: Text(
              'Mi perfil',

              textAlign: TextAlign.center,

              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
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

    final nombre =
        _usuarioData['nombre'] ??
        widget.usuario['nombre'] ??
        'Usuario';

    final apellido =
        _usuarioData['apellido'] ??
        widget.usuario['apellido'] ??
        '';

    final correo =
        _usuarioData['correo'] ??
        widget.usuario['correo'] ??
        '';

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 28,
      ),

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
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            '$nombre $apellido',

            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            correo,

            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _leerRol(_usuarioData),

            style: GoogleFonts.nunito(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFincaItem() {

    return Container(

      color: Colors.white,

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),

      child: _rowItem(
        label: 'Mi finca',
        valor:
            _finca?['nombreFinca'] ??
            'Sin finca registrada',
        icono: Icons.park_outlined,
      ),
    );
  }

  Widget _buildInfoSection() {

    return Container(

      color: Colors.white,

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),

      child: Column(
        children: [

          _rowItem(
            label: 'Área total',
            valor:
                '${_finca?['areaHectareas'] ?? '0'} hectáreas',
            icono: Icons.straighten_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Altitud',
            valor:
                '${_finca?['altitudMsnm'] ?? '0'} msnm',
            icono: Icons.terrain_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Municipio',
            valor:
                _finca?['municipio'] ??
                'No registrado',
            icono: Icons.location_on_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Teléfono',
            valor:
                _usuarioData['telefono'] ??
                'No registrado',
            icono: Icons.phone_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Cédula',
            valor:
                _usuarioData['cedula'] ??
                'No registrada',
            icono: Icons.badge_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Vereda',
            valor:
                _finca?['vereda'] ??
                'No registrada',
            icono: Icons.map_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Departamento',
            valor:
                _finca?['departamento'] ??
                'No registrado',
            icono: Icons.location_city_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Cultivo principal',
            valor:
                _finca?['cultivoPrincipal'] ??
                'No registrado',
            icono: Icons.eco_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Cantidad de árboles',
            valor:
                '${_finca?['cantidadArboles'] ?? '0'}',
            icono: Icons.forest_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Producción mensual',
            valor:
                '${_finca?['produccionMensual'] ?? '0'} kg',
            icono: Icons.agriculture_outlined,
          ),

          _divider(),

          _rowItem(
            label: 'Asociación',
            valor:
                _usuarioData['asociacion'] ??
                'No registrada',
            icono: Icons.groups_outlined,
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

      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),

      child: Row(
        children: [

          Icon(
            icono,
            color: AppColors.primary,
            size: 22,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  label,

                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                Text(
                  valor,

                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          if (conFlecha)

            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _divider() {

    return const Divider(
      height: 1,
      color: Color(0xFFEEEEEE),
    );
  }
}
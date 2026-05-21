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

                          const SizedBox(height: 16),

                          _buildFincaItem(),

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

      color: const Color.fromARGB(255, 208, 196, 171),

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

            onPressed: () {},
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

      color: const Color.fromARGB(255, 208, 196, 171),

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: Container(

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 6,
        ),

        child: _rowItem(
          label: 'Mi finca',
          valor:
              _finca?['nombreFinca'] ??
              'Sin finca registrada',
          icono: Icons.park_outlined,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: Container(

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

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
      ),
    );
  }

  Widget _rowItem({
    required String label,
    required String valor,
    required IconData icono,
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
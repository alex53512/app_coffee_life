import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const ProfileScreen({super.key, required this.usuario});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _cargando = false;
  Map<String, dynamic> _usuarioData = {};
  Map<String, dynamic>? _finca;

  @override
  void initState() {
    super.initState();
    _usuarioData = Map.from(widget.usuario);
    _cargarDatos();
  }

  String _leerRol(Map<String, dynamic> u) {
    final rol = u['rol'];
    if (rol == null) return 'Cafetero';
    if (rol is String) return rol;
    if (rol is Map) return rol['nombreRol'] ?? 'Cafetero';
    return 'Cafetero';
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        ApiService.get('/mi-perfil'),
        ApiService.get('/fincas'),
      ]);
      final u = results[0] is Map ? results[0] : (results[0]['data'] ?? results[0]);
      final fincas = results[1] is List ? results[1] : (results[1]['data'] ?? []);
      setState(() {
        _usuarioData = Map<String, dynamic>.from(u);
        if (fincas.isNotEmpty) _finca = fincas[0];
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(80, 36)),
            child: Text('Salir', style: GoogleFonts.nunito()),
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
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textPrimary, size: 20),
            onPressed: () {},
          ),
          Expanded(
            child: Text('Mi perfil',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.textPrimary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final nombre   = _usuarioData['nombre']   ?? widget.usuario['nombre']   ?? 'U';
    final apellido = _usuarioData['apellido'] ?? widget.usuario['apellido'] ?? '';
    final correo   = _usuarioData['correo']   ?? widget.usuario['correo']   ?? '';

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
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text('$nombre $apellido',
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(correo,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFincaItem() {
    final nombreFinca = _finca?['nombreFinca'] ?? 'Sin finca registrada';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: _rowItem(
        label: 'Mi finca',
        valor: nombreFinca,
        icono: Icons.park_outlined,
        conFlecha: true,
      ),
    );
  }

  Widget _buildInfoSection() {
    final area     = _finca?['areaHectareas'] != null
        ? '${_finca!['areaHectareas']} hectáreas'
        : '12.5 hectáreas';
    final altitud  = _finca?['altitudMsnm'] != null
        ? '${_finca!['altitudMsnm']} msnm'
        : '1,450 msnm';
    final municipio = _finca?['municipio'] ?? 'No registrado';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          _rowItem(label: 'Área total', valor: area,
              icono: Icons.straighten_outlined),
          _divider(),
          _rowItem(label: 'Árboles totales', valor: '5,000',
              icono: Icons.forest_outlined),
          _divider(),
          _rowItem(label: 'Variedad principal', valor: 'Caturra',
              icono: Icons.eco_outlined),
          _divider(),
          _rowItem(label: 'Altitud', valor: altitud,
              icono: Icons.terrain_outlined),
          _divider(),
          _rowItem(label: 'Municipio', valor: municipio,
              icono: Icons.location_on_outlined),
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

  Widget _divider() => const Divider(height: 1, color: Color(0xFFEEEEEE));
}
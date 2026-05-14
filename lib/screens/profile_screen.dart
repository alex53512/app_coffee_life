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
  final _formKey      = GlobalKey<FormState>();
  bool _isEditing     = false;
  bool _cargando      = false;
  bool _guardando     = false;

  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;

  Map<String, dynamic> _usuarioData = {};

  @override
  void initState() {
    super.initState();
    _usuarioData = Map.from(widget.usuario);
    _initControllers(_usuarioData);
    _cargarPerfil();
  }

  void _initControllers(Map<String, dynamic> u) {
    _nombreController    = TextEditingController(text: u['nombre']   ?? '');
    _apellidoController  = TextEditingController(text: u['apellido'] ?? '');
    _correoController    = TextEditingController(text: u['correo']   ?? '');
    _telefonoController  = TextEditingController(text: u['telefono'] ?? '');
  }

  Future<void> _cargarPerfil() async {
    final id = widget.usuario['id'] ?? widget.usuario['idUsuario'];
    if (id == null) return;
    setState(() => _cargando = true);
    try {
      final data = await ApiService.get('/usuarios/$id');
      final u = data is Map ? data : (data['data'] ?? data);
      setState(() {
        _usuarioData = Map<String, dynamic>.from(u);
        _nombreController.text   = u['nombre']   ?? '';
        _apellidoController.text = u['apellido'] ?? '';
        _correoController.text   = u['correo']   ?? '';
        _telefonoController.text = u['telefono'] ?? '';
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _usuarioData['id'] ?? _usuarioData['idUsuario'];
    setState(() => _guardando = true);
    try {
      await ApiService.put('/usuarios/$id', {
        'nombre':   _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'correo':   _correoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
      });
      setState(() { _isEditing = false; _guardando = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil actualizado ✅',
                style: GoogleFonts.nunito()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e',
                style: GoogleFonts.nunito()),
            backgroundColor: Colors.red,
          ),
        );
      }
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
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
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
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Información personal'),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _nombreController,
                              label: 'Nombre',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _apellidoController,
                              label: 'Apellido',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _correoController,
                              label: 'Correo electrónico',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _telefonoController,
                              label: 'Teléfono',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 28),
                            if (_isEditing)
                              ElevatedButton(
                                onPressed: _guardando ? null : _guardarCambios,
                                child: _guardando
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Guardar cambios'),
                              ),
                            const SizedBox(height: 12),
                            // Botón cerrar sesión
                            OutlinedButton.icon(
                              onPressed: _cerrarSesion,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: Text('Cerrar sesión',
                                  style: GoogleFonts.nunito(
                                      color: Colors.red, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final nombre   = _usuarioData['nombre']   ?? widget.usuario['nombre']   ?? 'U';
    final apellido = _usuarioData['apellido'] ?? widget.usuario['apellido'] ?? '';
    final rol      = _usuarioData['rol']?['nombreRol'] ??
                     widget.usuario['rol']?['nombreRol'] ?? 'Cafetero';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.primary,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              nombre[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$nombre $apellido',
                    style: GoogleFonts.nunito(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text(rol,
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_outlined,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    final correo  = _usuarioData['correo']   ?? widget.usuario['correo']   ?? '';
    final telefono = _usuarioData['telefono'] ?? widget.usuario['telefono'] ?? 'Sin teléfono';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _infoItem(Icons.email_outlined, correo),
          const Divider(height: 16),
          _infoItem(Icons.phone_outlined, telefono),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.nunito(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: _isEditing ? AppColors.surfaceVariant : Colors.grey.shade100,
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
 
class PerfilExpertoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const PerfilExpertoScreen({super.key, required this.usuario});
 
  @override
  State<PerfilExpertoScreen> createState() => _PerfilExpertoScreenState();
}
 
class _PerfilExpertoScreenState extends State<PerfilExpertoScreen> {
  bool _cargando = true;
  bool _guardando = false;
  Map<String, dynamic> _perfil = {};
 
  final _nombreCtrl    = TextEditingController();
  final _apellidoCtrl  = TextEditingController();
  final _correoCtrl    = TextEditingController();
  final _telefonoCtrl  = TextEditingController();
  final _especialidadCtrl = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }
 
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _especialidadCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.get('/mi-perfil');
      final perfil = data is Map ? (data['data'] ?? data) : data;
      setState(() {
        _perfil = Map<String, dynamic>.from(perfil);
        _nombreCtrl.text    = _perfil['nombre']       ?? widget.usuario['nombre']    ?? '';
        _apellidoCtrl.text  = _perfil['apellido']     ?? widget.usuario['apellido']  ?? '';
        _correoCtrl.text    = _perfil['correo']       ?? widget.usuario['correo']    ?? '';
        _telefonoCtrl.text  = _perfil['telefono']     ?? widget.usuario['telefono']  ?? '';
        _especialidadCtrl.text = _perfil['especialidad'] ?? '';
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _perfil = Map<String, dynamic>.from(widget.usuario);
        _nombreCtrl.text   = widget.usuario['nombre']   ?? '';
        _apellidoCtrl.text = widget.usuario['apellido'] ?? '';
        _correoCtrl.text   = widget.usuario['correo']   ?? '';
        _telefonoCtrl.text = widget.usuario['telefono'] ?? '';
        _cargando = false;
      });
    }
  }
 
  Future<void> _guardarPerfil() async {
    setState(() => _guardando = true);
    try {
      await ApiService.put('/mi-perfil', {
        'nombre':       _nombreCtrl.text.trim(),
        'apellido':     _apellidoCtrl.text.trim(),
        'telefono':     _telefonoCtrl.text.trim(),
        if (_especialidadCtrl.text.trim().isNotEmpty)
          'especialidad': _especialidadCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil actualizado correctamente',
                style: GoogleFonts.nunito()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }
 
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cerrar sesión',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('¿Estás seguro que deseas cerrar sesión?',
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
            child: Text('Cerrar sesión', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
 
    if (confirmar == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final nombre = _nombreCtrl.text.isNotEmpty
        ? _nombreCtrl.text
        : widget.usuario['nombre'] ?? 'Experto';
 
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(nombre),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        _buildFormCard(),
                        const SizedBox(height: 20),
                        _buildAccionesCard(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
 
  Widget _buildHeader(String nombre) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.verdeOscuro,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2),
                          blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(nombre,
                    style: GoogleFonts.nunito(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Experto Agrónomo',
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información de cuenta',
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _infoRow(Icons.email_outlined, 'Correo', _correoCtrl.text.isNotEmpty ? _correoCtrl.text : '—'),
          const Divider(height: 20, color: AppColors.border),
          _infoRow(Icons.badge_outlined, 'Rol', 'Experto'),
          const Divider(height: 20, color: AppColors.border),
          _infoRow(Icons.verified_outlined, 'Estado', 'Activo'),
        ],
      ),
    );
  }
 
  Widget _infoRow(IconData icon, String label, String valor) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(valor,
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
 
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editar perfil',
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _campo(_nombreCtrl, 'Nombre', Icons.person_outline),
          const SizedBox(height: 12),
          _campo(_apellidoCtrl, 'Apellido', Icons.person_outline),
          const SizedBox(height: 12),
          _campo(_telefonoCtrl, 'Teléfono', Icons.phone_outlined,
              keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          _campo(_especialidadCtrl, 'Especialidad', Icons.school_outlined),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _guardando
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text('Guardar cambios',
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _campo(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
 
  Widget _buildAccionesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text('Cambiar contraseña',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Próximamente', style: GoogleFonts.nunito())),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('Cerrar sesión',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
            onTap: _cerrarSesion,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const ProfileScreen({super.key, required this.usuario});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _correoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _cedulaController;
  late final TextEditingController _direccionController;

  String _tipoDocumento = 'Cédula de ciudadanía';
  final List<String> _tiposDocumento = [
    'Cédula de ciudadanía',
    'Cédula de extranjería',
    'Pasaporte',
    'NIT',
  ];

  final int _totalTrees = 1250;
  final int _treesWithRust = 85;
  final double _totalArea = 15.0;
  final String _lastSync = 'Hoy, 8:00 AM';

  @override
  void initState() {
    super.initState();
    _nombreController   = TextEditingController(text: widget.usuario['nombre']   ?? '');
    _apellidoController = TextEditingController(text: widget.usuario['apellido'] ?? '');
    _correoController   = TextEditingController(text: widget.usuario['correo']   ?? '');
    _telefonoController = TextEditingController(text: widget.usuario['telefono'] ?? '');
    _cedulaController   = TextEditingController(text: '');
    _direccionController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
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
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _cedulaController,
                        label: 'Número de documento',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _direccionController,
                        label: 'Dirección',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 28),
                      if (_isEditing)
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isEditing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Perfil actualizado')),
                              );
                            }
                          },
                          child: const Text('Guardar cambios'),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.primary,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              (widget.usuario['nombre'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.usuario['nombre'] ?? ''} ${widget.usuario['apellido'] ?? ''}',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.usuario['rol']?['nombreRol'] ?? 'Cafetero',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('$_totalTrees', 'Árboles', Icons.park_outlined),
        const SizedBox(width: 10),
        _buildStatCard('$_treesWithRust', 'Con roya', Icons.bug_report_outlined),
        const SizedBox(width: 10),
        _buildStatCard('${_totalArea}ha', 'Área', Icons.map_outlined),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
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
    );
  }
}
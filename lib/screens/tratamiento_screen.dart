import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class TratamientoScreen extends StatefulWidget {
  const TratamientoScreen({super.key});

  @override
  State<TratamientoScreen> createState() => _TratamientoScreenState();
}

class _TratamientoScreenState extends State<TratamientoScreen> {
  bool _cargando = true;
  Map<String, dynamic>? _tratamiento;

  @override
  void initState() {
    super.initState();
    _cargarTratamiento();
  }

  Future<void> _cargarTratamiento() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.get('/tratamientos');
      final lista = data is List ? data : (data['data'] ?? []);
      setState(() {
        _tratamiento = lista.isNotEmpty ? lista[0] : null;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
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
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildProductoCard(),
                          const SizedBox(height: 16),
                          _buildDetallesCard(),
                          const SizedBox(height: 16),
                          _buildCondicionesCard(),
                          const SizedBox(height: 16),
                          _buildNotasCard(),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Guardar tratamiento'),
                          ),
                          const SizedBox(height: 20),
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
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Tratamiento',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProductoCard() {
    final nombre = _tratamiento?['nombre'] ?? 'Fungicida Cúprico';
    final dosis  = _tratamiento?['dosisRecomendada'] ??
                   _tratamiento?['dosis_recomendada'] ?? '250 g / 200 L de agua';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recomendación de tratamiento',
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(nombre,
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _rowItem(Icons.scale_outlined, 'Dosis', dosis.toString()),
        ],
      ),
    );
  }

  Widget _buildDetallesCard() {
    final frecuencia = _tratamiento?['frecuencia'] ?? 'Cada 15 días';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _rowItem(Icons.repeat_outlined, 'Frecuencia', frecuencia.toString()),
          const Divider(height: 20),
          _rowItem(Icons.calendar_today_outlined, 'Próxima aplicación', '28 May 2024'),
        ],
      ),
    );
  }

  Widget _buildCondicionesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Condiciones ideales',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _rowItem(Icons.thermostat_outlined, 'Temperatura', '15° – 30°C'),
          const Divider(height: 20),
          _rowItem(Icons.water_drop_outlined, 'Humedad', '≤ 85%'),
        ],
      ),
    );
  }

  Widget _buildNotasCard() {
    final ingrediente = _tratamiento?['ingredienteActivo'] ??
                        _tratamiento?['ingrediente_activo'] ?? 'Hidróxido de cobre';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notas',
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Ingrediente activo: $ingrediente\n\n'
            'Aplicar en horas de la mañana y cubrir el envés de las hojas '
            'completamente. Usar equipo de protección personal durante la aplicación.',
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _rowItem(IconData icon, String label, String valor) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(valor,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
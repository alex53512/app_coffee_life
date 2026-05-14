import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  bool _cargando = true;
  List _recomendaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.get('/recomendaciones');
      setState(() {
        _recomendaciones = data is List ? data : (data['data'] ?? []);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  IconData _icono(dynamic r) {
    final tipo = (r['tipoRecomendacion'] ?? r['tipo'] ?? '').toString().toLowerCase();
    if (tipo.contains('riesgo') || tipo.contains('alerta')) return Icons.warning_amber_rounded;
    if (tipo.contains('aplicacion')) return Icons.calendar_today_outlined;
    if (tipo.contains('diagnostico')) return Icons.eco_outlined;
    return Icons.notifications_outlined;
  }

  Color _color(dynamic r) {
    final tipo = (r['tipoRecomendacion'] ?? r['tipo'] ?? '').toString().toLowerCase();
    if (tipo.contains('riesgo') || tipo.contains('alerta')) return Colors.red;
    if (tipo.contains('aplicacion')) return Colors.orange;
    if (tipo.contains('diagnostico')) return AppColors.primary;
    return Colors.blue;
  }

  String _fecha(dynamic r) {
    final f = r['fechaLimite'] ?? r['fecha_limite'] ?? r['fechaRegistro'] ?? '';
    if (f.isEmpty) return '';
    try {
      final dt = DateTime.parse(f);
      const meses = ['Ene','Feb','Mar','Abr','May','Jun',
                     'Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${dt.day} ${meses[dt.month-1]}, '
             '${dt.hour.toString().padLeft(2,'0')}:'
             '${dt.minute.toString().padLeft(2,'0')} '
             '${dt.hour < 12 ? 'AM' : 'PM'}';
    } catch (_) { return f; }
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
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _recomendaciones.isEmpty
                      ? _buildVacio()
                      : RefreshIndicator(
                          onRefresh: _cargarNotificaciones,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _recomendaciones.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _notificacionCard(_recomendaciones[i]),
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
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Notificaciones',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.textPrimary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 60, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('Sin notificaciones',
              style: GoogleFonts.nunito(
                  fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _notificacionCard(dynamic r) {
    final color    = _color(r);
    final icono    = _icono(r);
    final titulo   = r['descripcion'] ?? r['titulo'] ?? 'Notificación';
    final subtitulo = r['finca']?['nombreFinca'] ?? 'Sin finca';
    final fecha    = _fecha(r);
    final leida    = r['leida'] == true || r['leida'] == 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitulo,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (fecha.isNotEmpty)
                  Text(fecha,
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            children: [
              if (!leida)
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
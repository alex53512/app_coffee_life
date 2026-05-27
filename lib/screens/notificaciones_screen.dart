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
  String? _error;
  List _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await ApiService.get('/recomendaciones');
      setState(() {
        _notificaciones = data is List ? data : (data['data'] ?? []);
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las notificaciones';
        _cargando = false;
      });
    }
  }

  String _tipo(dynamic r) =>
      (r['tipoRecomendacion'] ?? r['tipo'] ?? '').toString().toLowerCase();

  IconData _icono(dynamic r) {
    final t = _tipo(r);
    if (t.contains('riesgo') || t.contains('alerta')) return Icons.warning_amber_rounded;
    if (t.contains('aplicacion')) return Icons.calendar_today_outlined;
    if (t.contains('diagnostico')) return Icons.eco_outlined;
    return Icons.notifications_outlined;
  }

  Color _colorIcono(dynamic r) {
    final t = _tipo(r);
    if (t.contains('riesgo') || t.contains('alerta')) return const Color(0xFFE53935);
    if (t.contains('aplicacion')) return const Color(0xFFF4850A);
    if (t.contains('diagnostico')) return AppColors.primary;
    return const Color(0xFF2196F3);
  }

  _BadgeInfo _badge(dynamic r) {
    final t = _tipo(r);
    if (t.contains('riesgo') || t.contains('alerta')) return _BadgeInfo('Alta', const Color(0xFFE53935));
    if (t.contains('aplicacion')) return _BadgeInfo('Programada', const Color(0xFFF4850A));
    return _BadgeInfo('Info', AppColors.primary);
  }

  String _fecha(dynamic r) {
    final f = r['fechaLimite'] ?? r['fecha_limite'] ?? r['fechaRegistro'] ?? '';
    if (f.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(f.toString());
      const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
      final hora = dt.hour.toString().padLeft(2, '0');
      final min  = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '${dt.day} ${meses[dt.month - 1]}, $hora:$min $ampm';
    } catch (_) { return f.toString(); }
  }

  bool _leida(dynamic r) => r['leida'] == true || r['leida'] == 1;

  int get _sinLeer => _notificaciones.where((r) => !_leida(r)).length;

  void _marcarLeida(int index) {
    setState(() => _notificaciones[index]['leida'] = true);
  }

  void _marcarTodasLeidas() {
    setState(() { for (final n in _notificaciones) n['leida'] = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_sinLeer > 0) _buildBannerSinLeer(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: const Color(0xFFF4E7D6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Notificaciones',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          if (_sinLeer > 0)
            TextButton(
              onPressed: _marcarTodasLeidas,
              child: Text('Leer todas',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBannerSinLeer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_unread_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text('$_sinLeer notificación${_sinLeer > 1 ? 'es' : ''} sin leer',
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 54, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarNotificaciones,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Reintentar', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (_notificaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Sin notificaciones',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Aquí aparecerán tus alertas y recordatorios',
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notificaciones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _notificacionCard(i),
      ),
    );
  }

  Widget _notificacionCard(int index) {
    final r      = _notificaciones[index];
    final color  = _colorIcono(r);
    final badge  = _badge(r);
    final titulo = r['descripcion'] ?? r['titulo'] ?? 'Notificación';
    final finca  = r['finca']?['nombreFinca'] ?? r['parcela']?['nombreParcela'] ?? 'Sin finca';
    final fecha  = _fecha(r);
    final leida  = _leida(r);

    return GestureDetector(
      onTap: () => _marcarLeida(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: leida ? null : Border.all(color: color.withOpacity(0.3), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(leida ? 0.04 : 0.08), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(_icono(r), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: badge.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(badge.label,
                        style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: badge.color)),
                  ),
                  const SizedBox(height: 4),
                  Text(titulo,
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: leida ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(child: Text(finca,
                          style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (fecha.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(fecha, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!leida)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 6),
                width: 9, height: 9,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeInfo {
  final String label;
  final Color color;
  const _BadgeInfo(this.label, this.color);
}
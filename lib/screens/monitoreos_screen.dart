import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'monitoreo_detalle_screen.dart';

class MontoreosScreen extends StatefulWidget {
  const MontoreosScreen({super.key});

  @override
  State<MontoreosScreen> createState() => _MontoreosScreenState();
}

class _MontoreosScreenState extends State<MontoreosScreen> {
  int _tabIndex = 0;
  bool _cargando = true;
  String? _error;
  List _monitoreos = [];

  @override
  void initState() {
    super.initState();
    _cargarMonitoreos();
  }

  Future<void> _cargarMonitoreos() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await ApiService.get('/monitoreos');
      setState(() {
        _monitoreos = data is List ? data : (data['data'] ?? []);
        _cargando = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _eliminarMonitoreo(dynamic m) async {
    final id = m['idMonitoreo'] ?? m['id_monitoreo'];
    try {
      await ApiService.delete('/monitoreos/$id');
      setState(() => _monitoreos.removeWhere((item) =>
          (item['idMonitoreo'] ?? item['id_monitoreo']) == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monitoreo eliminado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(dynamic m) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar monitoreo',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            '¿Seguro que quieres eliminar este monitoreo? Esta acción no se puede deshacer.',
            style: GoogleFonts.nunito(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
    if (confirmado == true) _eliminarMonitoreo(m);
  }

  String _labelNivel(dynamic m) {
    final obs = (m['observaciones'] ?? m['cultivo']?['observaciones'] ?? '')
        .toString()
        .toLowerCase();
    if (obs.contains('roya') ||
        obs.contains('alto') ||
        obs.contains('critico') ||
        obs.contains('crítico') ||
        obs.contains('enfermedad')) {
      return 'Alto';
    }
    if (obs.contains('medio') ||
        obs.contains('amarill') ||
        obs.contains('sospech') ||
        obs.contains('manchas')) {
      return 'Medio';
    }
    return 'Bajo';
  }

  Color _colorNivel(dynamic m) {
    final nivel = _labelNivel(m).toLowerCase();
    if (nivel == 'alto') return Colors.red;
    if (nivel == 'medio') return Colors.orange;
    return AppColors.primary;
  }

  String _titulo(dynamic m) {
    final nivel = _labelNivel(m).toLowerCase();
    if (nivel == 'alto') return 'Roya encontrada';
    if (nivel == 'medio') return 'Riesgo medio';
    return 'Sin síntomas';
  }

  String _fecha(dynamic m) {
    final f = m['fechaMonitoreo'] ??
        m['fecha_monitoreo'] ??
        m['fechaRegistro'] ??
        '';
    if (f.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(f);
      const meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return f;
    }
  }

  String _parcela(dynamic m) {
    return m['cultivo']?['finca']?['nombreFinca'] ??
        m['cultivo']?['nombreCultivo'] ??
        m['finca']?['nombreFinca'] ??
        m['nombreFinca'] ??
        'Sin finca';
  }

  String? _imagenUrl(dynamic m) {
    final imagenes = m['imagenes'];
    if (imagenes == null || imagenes is! List || imagenes.isEmpty) return null;
    final ruta = imagenes[0]['rutaImagen'] ?? imagenes[0]['ruta_imagen'];
    if (ruta == null || ruta.toString().isEmpty) return null;
    if (ruta.toString().startsWith('http')) return ruta.toString();
    return 'https://coffeelife-api.up.railway.app/$ruta';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _error != null
                      ? _buildError()
                      : _tabIndex == 0
                          ? _buildHistorial()
                          : _buildMapa(),
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
            child: Text('Monitoreo',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined,
                color: AppColors.textPrimary, size: 22),
            onPressed: _cargarMonitoreos,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            _tabItem('Historial', 0),
            _tabItem('Mapa', 1),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off,
              size: 50, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('Error al cargar monitoreos',
              style: GoogleFonts.nunito(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _cargarMonitoreos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    if (_monitoreos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                size: 60, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('No hay monitoreos registrados',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarMonitoreos,
      color: AppColors.primary,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _monitoreos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _monitoreoCard(_monitoreos[i]),
      ),
    );
  }

  Widget _monitoreoCard(dynamic m) {
    final color = _colorNivel(m);
    final nivel = _labelNivel(m);
    final titulo = _titulo(m);
    final fecha = _fecha(m);
    final parcela = _parcela(m);
    final imgUrl = _imagenUrl(m);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MonitoreoDetalleScreen(
            monitoreo: Map<String, dynamic>.from(m),
          ),
        ),
      ),
      onLongPress: () => _confirmarEliminar(m),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imgUrl != null
                  ? Image.network(
                      imgUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconoFallback(color),
                    )
                  : _iconoFallback(color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fecha,
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(titulo,
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Row(
                    children: [
                      const Icon(Icons.landscape_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(parcela,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(nivel,
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _iconoFallback(Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.eco_rounded, color: color, size: 26),
    );
  }

  Widget _buildMapa() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mapa de riesgo',
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFE8F5E9),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _MapaPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Leyenda',
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendaItem(Colors.red, 'Alto riesgo'),
              const SizedBox(width: 16),
              _legendaItem(Colors.orange, 'Medio riesgo'),
              const SizedBox(width: 16),
              _legendaItem(AppColors.primary, 'Bajo riesgo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendaItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MapaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = const Color(0xFF658C21).withOpacity(0.6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.05, size.height * 0.05,
                size.width * 0.4, size.height * 0.4),
            const Radius.circular(8)),
        paint);
    paint.color = Colors.orange.withOpacity(0.6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.5, size.height * 0.1,
                size.width * 0.4, size.height * 0.35),
            const Radius.circular(8)),
        paint);
    paint.color = Colors.red.withOpacity(0.6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.2, size.height * 0.55,
                size.width * 0.55, size.height * 0.35),
            const Radius.circular(8)),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
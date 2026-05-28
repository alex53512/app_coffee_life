import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import 'monitoreo_detalle_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
 
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
    AppState.instance.addListener(_onFincaCambiada);
  }
 
  void _onFincaCambiada() => _cargarMonitoreos();
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onFincaCambiada);
    super.dispose();
  }
 
  Future<void> _cargarMonitoreos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
 
    try {
      final data = await ApiService.get('/monitoreos');
      final todos = data is List ? data : (data['data'] ?? []);
 
      setState(() {
        _monitoreos = todos is List ? List.from(todos) : [];
        _cargando   = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }
 
  Future<void> _eliminarMonitoreo(dynamic m) async {
    final id = m['idMonitoreo'] ?? m['id_monitoreo'];
    try {
      await ApiService.delete('/monitoreos/$id');
      setState(() {
        _monitoreos.removeWhere(
          (item) => (item['idMonitoreo'] ?? item['id_monitoreo']) == id,
        );
      });
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
          style: GoogleFonts.nunito(color: AppColors.textSecondary),
        ),
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
 
    // ✅ Busca 'roya' en general (detectada, detectado, etc.)
    if (obs.contains('roya') ||
        obs.contains('alto') ||
        obs.contains('critico') ||
        obs.contains('enfermedad')) {
      return 'Alto';
    }
 
    if (obs.contains('medio') ||
        obs.contains('manchas') ||
        obs.contains('sospechosas') ||
        obs.contains('observación') ||
        obs.contains('observacion')) {
      return 'Medio';
    }
 
    return 'Bajo';
  }
 
  Color _colorNivel(dynamic m) {
    final nivel = _labelNivel(m).toLowerCase();
    if (nivel.contains('alt')) return Colors.red;
    if (nivel.contains('med')) return Colors.orange;
    return AppColors.primary;
  }
 
  String _titulo(dynamic m) {
    final nivel = _labelNivel(m).toLowerCase();
    if (nivel.contains('alt')) return 'Roya encontrada';
    if (nivel.contains('med')) return 'Riesgo medio';
    return 'Riesgo bajo';
  }
 
  String _fecha(dynamic m) {
    final f = m['fechaMonitoreo'] ??
        m['fecha_monitoreo'] ??
        m['fechaRegistro'] ??
        '';
    if (f.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(f.toString());
      const meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return f.toString();
    }
  }
 
  String _parcela(dynamic m) {
    return m['cultivo']?['finca']?['nombreFinca'] ??
        m['finca']?['nombreFinca'] ??
        m['nombreFinca'] ??
        m['cultivo']?['nombreCultivo'] ??
        'Sin finca';
  }
 
  String? _imagenUrl(dynamic m) {
    final imagenes = m['imagenes'];
    if (imagenes == null || imagenes is! List || imagenes.isEmpty) return null;
    final ruta = imagenes[0]['urlImagen'] ??
        imagenes[0]['rutaImagen'] ??
        imagenes[0]['ruta_imagen'];
    if (ruta == null || ruta.toString().isEmpty) return null;
    if (ruta.toString().startsWith('http')) return ruta.toString();
    return 'https://coffeelife-api.up.railway.app/$ruta';
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
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
                      child: CircularProgressIndicator(color: AppColors.primary))
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
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E7D6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Monitoreo',
                  style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),
            GestureDetector(
              onTap: _cargarMonitoreos,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Filtrar',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
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
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
          ],
        ),
        child: Row(children: [
          _tabItem('Historial', 0),
          _tabItem('Mapa', 1),
        ]),
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
                  color: isActive ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
 
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error al cargar monitoreos',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _cargarMonitoreos,
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
            child: Text('Reintentar',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
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
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_outlined,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No hay monitoreos registrados',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Realiza un diagnóstico para crear uno',
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
 
    return RefreshIndicator(
      onRefresh: _cargarMonitoreos,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _monitoreos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _monitoreoCard(_monitoreos[i]),
      ),
    );
  }
 
  Widget _monitoreoCard(dynamic m) {
    final color   = _colorNivel(m);
    final nivel   = _labelNivel(m);
    final titulo  = _titulo(m);
    final fecha   = _fecha(m);
    final parcela = _parcela(m);
    final imgUrl  = _imagenUrl(m);
 
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
                color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imgUrl != null
                  ? Image.network(imgUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _colorFallback(color))
                  : _colorFallback(color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fecha,
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(titulo,
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Text(parcela,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
          ],
        ),
      ),
    );
  }
 
  Widget _colorFallback(Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
 
  Widget _buildMapa() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mapa de riesgo',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(5.0689, -75.5174),
                    initialZoom: 8.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.coffeelife.app',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8),
                ],
              ),
              child: Column(
                children: [
                  _legendaItem(Colors.red, 'Alto riesgo'),
                  const SizedBox(height: 10),
                  _legendaItem(Colors.orange, 'Medio riesgo'),
                  const SizedBox(height: 10),
                  _legendaItem(AppColors.primary, 'Bajo riesgo'),
                ],
              ),
            ),
          ],
        ),
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
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
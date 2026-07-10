import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/websocket_service.dart';
import 'home_screen.dart';
import 'diagnostic_screen.dart';
import 'fincaDetalleScreen.dart';
import 'monitoreos_screen.dart';
import 'profile_screen.dart';
import 'asistente_screen.dart';

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const MainNavigation({super.key, required this.usuario});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _homeRefreshKey = 0;

  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onFincaCambiada);
    AppState.instance.iniciarPolling();
    WebSocketService.instance.on('*', _onNotificacion);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onFincaCambiada);
    WebSocketService.instance.off('*', _onNotificacion);
    _fabController.dispose();
    super.dispose();
  }

  void _onFincaCambiada() {
    setState(() {});
    _mostrarNuevasNotificaciones();
  }

  void _onNotificacion(Map<String, dynamic> data) {
    AppState.instance.agregarNotificacion(data);
    final tipo = (data['tipoRecomendacion'] ?? data['tipo'] ?? data['type'] ?? '').toString();
    if (tipo.toLowerCase().contains('experto')) {
      AppState.instance.refrescarFincaActual();
    }
  }

  void _mostrarNuevasNotificaciones() {
    final notif = AppState.instance.ultimaNotificacionNueva;
    final nuevas = AppState.instance.nuevasDesdeUltimoAviso;
    if (notif == null || nuevas <= 0 || !mounted) return;
    AppState.instance.reiniciarContadorAvisos();
    final tipo =
        (notif['tipoRecomendacion'] ?? notif['tipo'] ?? '').toString();
    final esExperto = tipo.toLowerCase().contains('diagnostico');
    final titulo = esExperto
        ? 'Nueva notificación del experto'
        : 'Nueva notificación';
    final mensaje = notif['mensaje'] ?? notif['message'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              esExperto ? Icons.eco : Icons.notifications_outlined,
              color: esExperto ? AppColors.primary : const Color(0xFF2196F3),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(mensaje.isNotEmpty ? mensaje : 'Tienes una nueva notificación'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppState.instance.marcarNotificacionesLeidas();
              setState(() => _currentIndex = 3);
            },
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }

  String get _nombreFincaActual =>
      AppState.instance.fincaSeleccionada?['nombreFinca'] ?? 'Mi Finca';

  List<Widget> get _screens => [
        HomeScreen(usuario: widget.usuario, key: ValueKey('home$_homeRefreshKey')),
        const DiagnosticScreen(),
        FincaDetalleScreen(finca: AppState.instance.fincaSeleccionada ?? {}),
        const MontoreosScreen(),
        ProfileScreen(usuario: widget.usuario),
      ];

  void _abrirAsistente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AsistenteScreen(
        genero: widget.usuario['genero']?.toString() ?? 'femenino',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) {
          _fabController.reverse();
          _abrirAsistente();
        },
        onTapCancel: () => _fabController.reverse(),
        child: ScaleTransition(
          scale: _fabScale,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6DBF67), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded,             Icons.home_outlined,             'Inicio'),
              _navItem(1, Icons.document_scanner_rounded, Icons.document_scanner_outlined, 'Diagnóstico'),
              _navItem(2, Icons.fact_check_rounded,        Icons.fact_check_outlined,        'Seguimiento'),
              _navItem(3, Icons.bar_chart_rounded,        Icons.bar_chart_outlined,        'Monitoreos'),
              _navItem(4, Icons.person_rounded,           Icons.person_outline_rounded,    'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) _homeRefreshKey++;
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                scale: isActive ? 1.25 : 1.0,
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? const Color(0xFF97D340) : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? const Color(0xFF97D340) : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
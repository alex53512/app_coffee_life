import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/websocket_service.dart';
import 'home_screen.dart';
import 'diagnostic_screen.dart';
import 'clima_screen.dart';
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

  void _onFincaCambiada() => setState(() {});

  void _onNotificacion(Map<String, dynamic> data) {
    AppState.instance.agregarNotificacion(data);
    final titulo = data['titulo'] ?? data['title'] ?? 'Novedad';
    final mensaje = data['mensaje'] ?? data['message'] ?? '';
    final idMonitoreo = data['idMonitoreo'] ?? data['id_monitoreo'];
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$titulo${mensaje.isNotEmpty ? ': $mensaje' : ''}'),
        behavior: SnackBarBehavior.floating,
        action: idMonitoreo != null
            ? SnackBarAction(
                label: 'Ver',
                onPressed: () {
                  AppState.instance.marcarNotificacionesLeidas();
                  setState(() => _currentIndex = 3);
                },
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String get _nombreFincaActual =>
      AppState.instance.fincaSeleccionada?['nombreFinca'] ?? 'Mi Finca';

  List<Widget> get _screens => [
        HomeScreen(usuario: widget.usuario, key: ValueKey('home$_homeRefreshKey')),
        const DiagnosticScreen(),
        const ClimaScreen(),
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
              _navItem(2, Icons.wb_cloudy_rounded,        Icons.wb_cloudy_outlined,        'Clima'),
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
    final badge = index == 3 ? AppState.instance.notificacionesNoLeidas : 0;
    return GestureDetector(
      onTap: () {
        if (index == 3) AppState.instance.marcarNotificacionesLeidas();
        if (index == 0) _homeRefreshKey++;
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : inactiveIcon,
                    color: isActive ? AppColors.primary : AppColors.textSecondary, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
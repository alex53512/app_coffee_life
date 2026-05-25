import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'home_screen.dart';
import 'diagnostic_screen.dart';
import 'clima_screen.dart';
import 'monitoreos_screen.dart';
import 'aprender_screen.dart';
import 'profile_screen.dart';
 
class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const MainNavigation({super.key, required this.usuario});
 
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}
 
class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
 
  @override
  void initState() {
    super.initState();
    // Reconstruir cuando cambie la finca para actualizar ClimaScreen
    AppState.instance.addListener(_onFincaCambiada);
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onFincaCambiada);
    super.dispose();
  }
 
  void _onFincaCambiada() => setState(() {});
 
  String get _nombreFincaActual =>
      AppState.instance.fincaSeleccionada?['nombreFinca'] ?? 'Mi Finca';
 
  List<Widget> get _screens => [
    HomeScreen(usuario: widget.usuario),          // 0 - Inicio
    const DiagnosticScreen(),                     // 1 - Diagnóstico
    ClimaScreen(nombreFinca: _nombreFincaActual), // 2 - Clima ← NUEVO
    const MontoreosScreen(),                      // 3 - Monitoreos
    const AprenderScreen(),                       // 4 - Aprender
    ProfileScreen(usuario: widget.usuario),        // 5 - Perfil
  ];
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
 
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded,
                  Icons.home_outlined, 'Inicio'),
              _navItem(1, Icons.document_scanner_rounded,
                  Icons.document_scanner_outlined, 'Diagnóstico'),
              _navItem(2, Icons.wb_cloudy_rounded,
                  Icons.wb_cloudy_outlined, 'Clima'),        // ← NUEVO
              _navItem(3, Icons.bar_chart_rounded,
                  Icons.bar_chart_outlined, 'Monitoreos'),
              _navItem(4, Icons.menu_book_rounded,
                  Icons.menu_book_outlined, 'Aprender'),
              _navItem(5, Icons.person_rounded,
                  Icons.person_outline_rounded, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _navItem(int index, IconData activeIcon,
      IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56, // un poco más angosto para caber 6 tabs
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_experto_screen.dart';
import 'diagnostico_experto_screen.dart';
import 'clima_screen.dart';
import 'monitoreos_screen.dart';
import 'perfil_experto_screen.dart';
 
class MainNavigationExperto extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const MainNavigationExperto({super.key, required this.usuario});
 
  @override
  State<MainNavigationExperto> createState() => _MainNavigationExpertoState();
}
 
class _MainNavigationExpertoState extends State<MainNavigationExperto>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
 
  late AnimationController _fabController;
  late Animation<double> _fabScale;
 
  @override
  void initState() {
    super.initState();
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
    _fabController.dispose();
    super.dispose();
  }
 
  List<Widget> get _screens => [
        HomeExpertoScreen(usuario: widget.usuario),
        DiagnosticoExpertoScreen(usuario: widget.usuario),
        const ClimaScreen(),
        const MontoreosScreen(),
        PerfilExpertoScreen(usuario: widget.usuario),
      ];
 
  void _abrirAsistente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFEFB),
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: AppColors.primary, size: 52),
              ),
              const SizedBox(height: 20),
              Text('Asistente CoffeeLife',
                  style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Tu asistente inteligente está en camino',
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
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
 
      // ── Botón flotante asistente ──────────────────────────────────────
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
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 28),
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
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Inicio'),
              _navItem(1, Icons.assignment_rounded,
                  Icons.assignment_outlined, 'Diagnóstico'),
              _navItem(2, Icons.wb_cloudy_rounded,
                  Icons.wb_cloudy_outlined, 'Clima'),
              _navItem(3, Icons.bar_chart_rounded,
                  Icons.bar_chart_outlined, 'Monitoreos'),
              _navItem(4, Icons.person_rounded,
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
        width: 64,
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
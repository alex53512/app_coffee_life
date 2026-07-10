import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_header.dart';
import 'login_screen.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _recordatorioOn = false;
  int _recordatorioDias = 7;
  bool _modoOffline = false;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  Future<void> _cargarAjustes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recordatorioOn = prefs.getBool('recordatorio_on') ?? false;
      _recordatorioDias = prefs.getInt('recordatorio_dias') ?? 7;
      _modoOffline = prefs.getBool('modo_offline') ?? false;
    });
  }

  Future<void> _guardar(String key, dynamic valor) async {
    final prefs = await SharedPreferences.getInstance();
    if (valor is bool) await prefs.setBool(key, valor);
    if (valor is int) await prefs.setInt(key, valor);
  }


  void _dialogRecordatorio() {
    bool on = _recordatorioOn;
    int dias = _recordatorioDias;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Recordatorio de monitoreo', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text('Activar recordatorio', style: GoogleFonts.nunito())),
                Switch(value: on, activeColor: AppColors.primary, onChanged: (v) => setDlg(() => on = v)),
              ],
            ),
            if (on) ...[
              const SizedBox(height: 12),
              Text('Cada:', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _opcionDias(7, dias, (v) => setDlg(() => dias = v)),
                const SizedBox(width: 8),
                _opcionDias(15, dias, (v) => setDlg(() => dias = v)),
                const SizedBox(width: 8),
                _opcionDias(30, dias, (v) => setDlg(() => dias = v)),
              ]),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.nunito())),
          ElevatedButton(
            onPressed: () {
              setState(() { _recordatorioOn = on; _recordatorioDias = dias; });
              _guardar('recordatorio_on', on);
              _guardar('recordatorio_dias', dias);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Guardar', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      )),
    );
  }

  Widget _opcionDias(int n, int actual, void Function(int) onTap) {
    final selected = n == actual;
    return GestureDetector(
      onTap: () => onTap(n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$n días', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.primary)),
      ),
    );
  }

  void _dialogConexion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modo conexión', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _opcionConexion(false, 'En línea', 'Los diagnósticos se suben al servidor inmediatamente'),
            const SizedBox(height: 8),
            _opcionConexion(true, 'Fuera de línea', 'Los diagnósticos se guardan localmente y se suben cuando hay conexión'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cerrar', style: GoogleFonts.nunito())),
        ],
      ),
    );
  }

  Widget _opcionConexion(bool offline, String titulo, String desc) {
    final selected = _modoOffline == offline;
    return GestureDetector(
      onTap: () {
        setState(() => _modoOffline = offline);
        _guardar('modo_offline', offline);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: AppColors.primary) : null,
        ),
        child: Row(
          children: [
            Icon(offline ? Icons.wifi_off : Icons.wifi,
                color: selected ? AppColors.primary : AppColors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(desc, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cerrar sesión', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('¿Estás seguro de que quieres cerrar sesión?', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: GoogleFonts.nunito())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cerrar sesión', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader.back(context, 'Ajustes', height: 52),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _fila(Icons.notifications_outlined, 'Recordatorio de monitoreo', _dialogRecordatorio),
                _fila(Icons.cloud_outlined, 'Modo conexión', _dialogConexion),
                const SizedBox(height: 24),
                _fila(Icons.logout_rounded, 'Cerrar sesión', _cerrarSesion, rojo: true),
                _fila(Icons.account_circle_outlined, 'Cambiar de cuenta', () async {
                  await AuthService.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(IconData icono, String label, VoidCallback onTap, {bool rojo = false}) {
    final color = rojo ? Colors.red : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 14),
              Text(label, style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
 
class MonitoreoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> monitoreo;
 
  const MonitoreoDetalleScreen({super.key, required this.monitoreo});
 
  @override
  State<MonitoreoDetalleScreen> createState() => _MonitoreoDetalleScreenState();
}
 
class _MonitoreoDetalleScreenState extends State<MonitoreoDetalleScreen> {
  int _tabSeleccionada = 0; // 0 = IA, 1 = Experto
 
  String _fecha() {
    final f = (widget.monitoreo['fechaMonitoreo'] ?? widget.monitoreo['fecha_monitoreo'] ?? '').toString();
    if (f.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(f);
      const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                     'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
      return '${dt.day.toString().padLeft(2,'0')} de ${meses[dt.month-1]} de ${dt.year}';
    } catch (_) { return f; }
  }
 
  String _cultivo() {
    final cultivo = widget.monitoreo['cultivo'];
    if (cultivo is Map) return cultivo['nombreCultivo'] ?? 'Sin cultivo';
    return 'Sin cultivo';
  }
 
  String _finca() {
    final cultivo = widget.monitoreo['cultivo'];
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) return finca['nombreFinca'] ?? 'Sin finca';
    }
    return 'Sin finca';
  }
 
  String _municipio() {
    final cultivo = widget.monitoreo['cultivo'];
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) {
        final mun = finca['municipio'] ?? '';
        final dep = finca['departamento'] ?? '';
        if (mun.isNotEmpty && dep.isNotEmpty) return '$mun, $dep';
        if (mun.isNotEmpty) return mun;
      }
    }
    return '';
  }
 
  String _observaciones() {
    return widget.monitoreo['observaciones'] ?? 'Sin observaciones registradas';
  }
 
  String _experto() {
    final exp = widget.monitoreo['experto'];
    if (exp is Map) {
      final nombre   = exp['nombre'] ?? '';
      final apellido = exp['apellido'] ?? '';
      return '$nombre $apellido'.trim();
    }
    return 'Sin experto asignado';
  }
 
  String _recomendacionExperto() {
    return widget.monitoreo['recomendacionExperto'] ??
           widget.monitoreo['recomendacion_experto'] ??
           'El experto aún no ha registrado recomendaciones para este monitoreo.';
  }
 
  Color _colorNivel() {
    final nivel = (widget.monitoreo['nivelRoya'] ?? widget.monitoreo['nivel_roya'] ?? '').toString().toLowerCase();
    if (nivel.contains('alt')) return Colors.red;
    if (nivel.contains('med')) return Colors.orange;
    return AppColors.primary;
  }
 
  @override
  Widget build(BuildContext context) {
    final municipio = _municipio();
 
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Detalle del monitoreo',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
 
            // ── Contenido ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
 
                    // Fecha + badge nivel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fecha(),
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _colorNivel().withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.monitoreo['nivelRoya'] ??
                                widget.monitoreo['nivel_roya'] ??
                                'Sin análisis',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _colorNivel(),
                            ),
                          ),
                        ),
                      ],
                    ),
 
                    const SizedBox(height: 20),
 
                    // ── Tarjeta: Cultivo y Finca ─────────────────
                    _seccionTitulo('Cultivo y Finca'),
                    const SizedBox(height: 10),
                    _card(
                      child: Column(
                        children: [
                          _infoFila('Cultivo', _cultivo()),
                          const Divider(height: 20, color: AppColors.border),
                          _infoFila('Finca', _finca()),
                          if (municipio.isNotEmpty) ...[
                            const Divider(height: 20, color: AppColors.border),
                            _infoFila('Ubicación', municipio),
                          ],
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 16),
 
                    // ── Tarjeta: Experto asignado ─────────────────
                    _seccionTitulo('Experto asignado'),
                    const SizedBox(height: 10),
                    _card(child: _infoFila('Experto', _experto())),
 
                    const SizedBox(height: 24),
 
                    // ── Toggle: Recomendaciones IA | Experto ──────
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _botonTab(label: 'Recomendaciones IA', index: 0),
                          _botonTab(label: 'Recomendaciones Experto', index: 1),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 16),
 
                    // ── Contenido del tab ─────────────────────────
                    _tabSeleccionada == 0
                        ? _contenidoIA()
                        : _contenidoExperto(),
 
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
 
  Widget _botonTab({required String label, required int index}) {
    final isActive = _tabSeleccionada == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabSeleccionada = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _contenidoIA() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis de IA',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Text(
            _observaciones(),
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _contenidoExperto() {
    final experto = _experto();
    final sinExperto = experto == 'Sin experto asignado';
 
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sinExperto ? 'Sin experto asignado' : experto,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: sinExperto ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (!sinExperto) ...[
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Text(
              _recomendacionExperto(),
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ] else
            Text(
              'Aún no hay un experto asignado a este monitoreo.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
 
  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
 
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
 
  Widget _infoFila(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
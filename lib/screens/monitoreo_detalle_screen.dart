import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MonitoreoDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> monitoreo;

  const MonitoreoDetalleScreen({super.key, required this.monitoreo});

  String _fecha() {
    final f = (monitoreo['fechaMonitoreo'] ?? monitoreo['fecha_monitoreo'] ?? '').toString();
    if (f.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(f);
      const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                     'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
      return '${dt.day.toString().padLeft(2,'0')} de ${meses[dt.month-1]} de ${dt.year}';
    } catch (_) { return f; }
  }

  String _cultivo() {
    final cultivo = monitoreo['cultivo'];
    if (cultivo is Map) return cultivo['nombreCultivo'] ?? 'Sin cultivo';
    return 'Sin cultivo';
  }

  String _finca() {
    final cultivo = monitoreo['cultivo'];
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) return finca['nombreFinca'] ?? 'Sin finca';
    }
    return 'Sin finca';
  }

  String _municipio() {
    final cultivo = monitoreo['cultivo'];
    if (cultivo is Map) {
      final finca = cultivo['finca'];
      if (finca is Map) {
        final mun  = finca['municipio'] ?? '';
        final dep  = finca['departamento'] ?? '';
        if (mun.isNotEmpty && dep.isNotEmpty) return '$mun, $dep';
        if (mun.isNotEmpty) return mun;
      }
    }
    return '';
  }

  String _observaciones() {
    return monitoreo['observaciones'] ?? 'Sin observaciones registradas';
  }

  String _experto() {
    final exp = monitoreo['experto'];
    if (exp is Map) {
      final nombre   = exp['nombre'] ?? '';
      final apellido = exp['apellido'] ?? '';
      return '$nombre $apellido'.trim();
    }
    return 'Sin experto asignado';
  }

  List _imagenes() {
    final imgs = monitoreo['imagenes'];
    if (imgs is List) return imgs;
    return [];
  }

  Color _colorNivel() {
    final nivel = (monitoreo['nivelRoya'] ?? monitoreo['nivel_roya'] ?? '').toString().toLowerCase();
    if (nivel.contains('alt')) return Colors.red;
    if (nivel.contains('med')) return Colors.orange;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = _imagenes();
    final municipio = _municipio();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text('Detalle del monitoreo',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 48),
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

                    // Fecha + badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(_fecha(),
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _colorNivel().withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.eco_rounded,
                                  size: 13, color: _colorNivel()),
                              const SizedBox(width: 4),
                              Text(
                                monitoreo['nivelRoya'] ??
                                    monitoreo['nivel_roya'] ??
                                    'Sin análisis',
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _colorNivel()),
                              ),
                            ],
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
                          _infoFila(
                              Icons.grass_rounded, 'Cultivo', _cultivo()),
                          const Divider(height: 20, color: AppColors.border),
                          _infoFila(
                              Icons.location_on_outlined, 'Finca', _finca()),
                          if (municipio.isNotEmpty) ...[
                            const Divider(height: 20, color: AppColors.border),
                            _infoFila(Icons.map_outlined, 'Ubicación',
                                municipio),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tarjeta: Observaciones ────────────────────
                    _seccionTitulo('Observaciones / Diagnóstico'),
                    const SizedBox(height: 10),
                    _card(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notes_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _observaciones(),
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tarjeta: Experto ──────────────────────────
                    _seccionTitulo('Experto asignado'),
                    const SizedBox(height: 10),
                    _card(
                      child: _infoFila(
                          Icons.person_outline_rounded, 'Experto', _experto()),
                    ),

                    const SizedBox(height: 16),

                    // ── Imágenes ──────────────────────────────────
                    _seccionTitulo('Imágenes (${imagenes.length})'),
                    const SizedBox(height: 10),
                    imagenes.isEmpty
                        ? _card(
                            child: Row(
                              children: [
                                const Icon(Icons.image_not_supported_outlined,
                                    color: AppColors.textSecondary, size: 20),
                                const SizedBox(width: 10),
                                Text('Sin imágenes registradas',
                                    style: GoogleFonts.nunito(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: imagenes.length,
                            itemBuilder: (_, i) {
                              final url = imagenes[i]['urlImagen'] ??
                                  imagenes[i]['url_imagen'] ?? '';
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: url.isNotEmpty
                                    ? Image.network(url, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _imagenPlaceholder())
                                    : _imagenPlaceholder(),
                              );
                            },
                          ),

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

  Widget _seccionTitulo(String titulo) {
    return Text(titulo,
        style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary));
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }

  Widget _infoFila(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagenPlaceholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.eco_outlined, color: Colors.green, size: 40),
      ),
    );
  }
}
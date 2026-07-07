import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../config/env_config.dart';
import '../screens/monitoreo_detalle_screen.dart';

String labelNivel(dynamic m) {
  final nivelRoyaObj = m['nivelRoya'] ?? m['nivel_roya'];
  if (nivelRoyaObj != null) {
    String nombre = '';
    if (nivelRoyaObj is Map) {
      nombre = (nivelRoyaObj['nombreNivel'] ??
              nivelRoyaObj['nombre_nivel'] ??
              '')
          .toString()
          .toLowerCase();
    } else {
      nombre = nivelRoyaObj.toString().toLowerCase();
    }
    if (nombre.contains('alt') ||
        nombre.contains('crít') ||
        nombre.contains('critico')) {
      return 'Alto';
    }
    if (nombre.contains('med')) return 'Medio';
    if (nombre.contains('baj') ||
        nombre.contains('sano') ||
        nombre.contains('normal')) {
      return 'Bajo';
    }
  }
  final obs =
      (m['observaciones'] ?? m['cultivo']?['observaciones'] ?? '')
          .toString()
          .toLowerCase();
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

Color colorNivel(dynamic m) {
  final nivel = labelNivel(m).toLowerCase();
  if (nivel.contains('alt')) return Colors.red;
  if (nivel.contains('med')) return const Color(0xFFF3B33D);
  return AppColors.primary;
}

String tituloMonitoreo(dynamic m) {
  final nivel = labelNivel(m).toLowerCase();
  if (nivel.contains('alt')) return 'Roya encontrada';
  if (nivel.contains('med')) return 'Riesgo medio';
  return 'Riesgo bajo';
}

String fechaMonitoreo(dynamic m) {
  final f = m['fechaMonitoreo'] ?? m['fecha_monitoreo'] ?? m['fechaRegistro'];
  return AppTheme.formatFechaColombia(f);
}

String parcelaMonitoreo(dynamic m) {
  final fincaNombre = m['cultivo']?['finca']?['nombreFinca'] ??
      m['cultivo']?['finca']?['nombre_finca'] ??
      m['cultivo']?['finca']?['nombre'];
  if (fincaNombre != null && fincaNombre.toString().isNotEmpty) {
    return fincaNombre.toString();
  }
  final fincaEnCultivo =
      m['cultivo']?['nombreFinca'] ?? m['cultivo']?['nombre_finca'];
  if (fincaEnCultivo != null && fincaEnCultivo.toString().isNotEmpty) {
    return fincaEnCultivo.toString();
  }
  final fincaRaiz = m['finca']?['nombreFinca'] ??
      m['finca']?['nombre_finca'] ??
      m['nombreFinca'] ??
      m['nombre_finca'];
  if (fincaRaiz != null && fincaRaiz.toString().isNotEmpty) {
    return fincaRaiz.toString();
  }
  final cultivo =
      m['cultivo']?['nombreCultivo'] ?? m['cultivo']?['nombre_cultivo'];
  if (cultivo != null && cultivo.toString().isNotEmpty) {
    return cultivo.toString();
  }
  return 'Sin finca';
}

String? imagenUrlMonitoreo(dynamic m) {
  final imagenes = m['imagenes'];
  if (imagenes == null || imagenes is! List || imagenes.isEmpty) return null;
  final ruta = imagenes[0]['urlImagen'] ??
      imagenes[0]['url_imagen'] ??
      imagenes[0]['rutaImagen'] ??
      imagenes[0]['ruta_imagen'];
  if (ruta == null || ruta.toString().isEmpty) return null;
  if (ruta.toString().startsWith('http')) return ruta.toString();
  return '${EnvConfig.cdnBaseUrl}/$ruta';
}

class MonitoreoCard extends StatelessWidget {
  final dynamic monitoreo;
  final VoidCallback? onLongPress;

  const MonitoreoCard({super.key, required this.monitoreo, this.onLongPress});

  static Widget _colorFallback(Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = monitoreo;
    final color = colorNivel(m);
    final nivel = labelNivel(m);
    final fecha = fechaMonitoreo(m);
    final parcela = parcelaMonitoreo(m);
    final imgUrl = imagenUrlMonitoreo(m);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonitoreoDetalleScreen(
              monitoreo: Map<String, dynamic>.from(m),
            ),
          ),
        ),
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imgUrl != null
                    ? CachedNetworkImage(imageUrl: imgUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _colorFallback(color),
                        placeholder: (_, __) => _colorFallback(color))
                    : _colorFallback(color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(fecha,
                              style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(nivel,
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(parcela,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MonitoreoDetalleScreen(
                              monitoreo: Map<String, dynamic>.from(m),
                              initialTab: 1,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_search_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('Ver Diagnóstico del Experto',
                                  style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

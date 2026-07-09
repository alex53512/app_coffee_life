import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class FincaCard extends StatelessWidget {
  final Map<String, dynamic> finca;
  final List<dynamic> cultivos;
  final dynamic cultivoSeleccionado;
  final List<dynamic> monitoreos;
  final void Function(dynamic idFinca) onAgregarLote;
  final void Function(Map<String, dynamic> cultivo) onEditarLote;
  final void Function(dynamic idCultivo, String nombreLote) onEliminarLote;
  final bool cargandoMas;
  final bool hasMore;
  final VoidCallback? onCargarMas;
  final void Function(Map<String, dynamic> cultivo) onSeleccionarCultivo;
  final void Function() onDeseleccionarCultivo;

  const FincaCard({
    super.key,
    required this.finca,
    required this.cultivos,
    this.cultivoSeleccionado,
    required this.monitoreos,
    required this.onAgregarLote,
    required this.onEditarLote,
    required this.onEliminarLote,
    this.cargandoMas = false,
    this.hasMore = false,
    this.onCargarMas,
    required this.onSeleccionarCultivo,
    required this.onDeseleccionarCultivo,
  });

  String _calcNivel(dynamic idCultivo) {
    final logs = monitoreos.where((m) =>
      (m['idCultivo'] ?? m['id_cultivo']).toString() == idCultivo.toString()
    ).toList();
    if (logs.isEmpty) return 'Sin datos';
    final total = logs.length;
    final conRoya = logs.where((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      return obs.contains('roya') || obs.contains('alto') ||
             obs.contains('critico') || obs.contains('crítico') ||
             obs.contains('enfermedad');
    }).length;
    final p = conRoya / total;
    if (p < 0.3) return 'Bajo';
    if (p <= 0.6) return 'Medio';
    return 'Alto';
  }

  @override
  Widget build(BuildContext context) {
    final nombre = finca['nombreFinca'] ?? 'Mi Finca';
    final municipio = finca['municipio'] ?? 'Sin municipio';
    final idFinca = finca['idFinca'] ?? finca['id_finca'];
    final fotoFinca = (finca['fotoUrl'] ??
            finca['fotoFinca'] ??
            finca['foto_finca'] ??
            finca['imagenFinca'] ??
            finca['imagen_finca'] ??
            finca['foto_url'] ??
            finca['foto'] ??
            finca['imagen'])
        ?.toString();
    final tieneFoto = fotoFinca != null && fotoFinca.isNotEmpty;

    final totalArboles = cultivos.fold<int>(0, (sum, c) {
      final n = (c as Map<String, dynamic>)['numeroArboles'] ??
          c['numero_arboles'];
      return sum + (int.tryParse(n?.toString() ?? '0') ?? 0);
    });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tieneFoto)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: fotoFinca,
                width: double.infinity,
                height: 130,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 130,
                  color: AppColors.primaryLight,
                  child: const Icon(
                    Icons.eco_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                placeholder: (_, __) => Container(
                  width: double.infinity,
                  height: 130,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          municipio,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dato(
                      Icons.grid_view_rounded,
                      '${cultivos.length}',
                      'Lotes registrados',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.border,
                    ),
                    _dato(
                      Icons.eco_outlined,
                      '$totalArboles',
                      'Plantas de café',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lotes registrados',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onAgregarLote(idFinca),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Agregar lote',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (cultivos.isEmpty) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Sin lotes registrados aún',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    '(toca para ver su salud)',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...cultivos.map((c) {
                    final idCultivo = c['idCultivo'] ?? c['id_cultivo'];
                    final selected = cultivoSeleccionado?.toString() ==
                        idCultivo.toString();
                    final nivel = selected ? _calcNivel(idCultivo) : '';
                    final nivelColor = nivel == 'Alto'
                        ? Colors.red
                        : nivel == 'Medio'
                            ? Colors.orange
                            : nivel == 'Bajo'
                                ? AppColors.primary
                                : Colors.grey;
                    return GestureDetector(
                      onTap: () {
                        if (selected) {
                          onDeseleccionarCultivo();
                        } else {
                          onSeleccionarCultivo(c as Map<String, dynamic>);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryLight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(
                                  color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                        child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['nombreCultivo'] ??
                                      c['nombre_cultivo'] ??
                                      'Cultivo',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                onEditarLote(c as Map<String, dynamic>),
              icon: const Icon(
                Icons.edit_outlined,
                              size: 18,
                            ),
                            color: AppColors.primary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => onEliminarLote(
                              idCultivo,
                              c['nombreCultivo'] ??
                                  c['nombre_cultivo'] ??
                                  'Cultivo',
                            ),
              icon: const Icon(
                Icons.delete_outline,
                              size: 18,
                            ),
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: nivelColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: nivelColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Roya: $nivel',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: nivelColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ],
                        ]),
                      ),
                    );
                  }),
                  if (hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: cargandoMas
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: onCargarMas,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.expand_circle_down_outlined,
                                        color: AppColors.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Cargar más lotes',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dato(IconData icon, String valor, String label) {
    return Column(children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(height: 4),
      Text(
        valor,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    ]);
  }
}

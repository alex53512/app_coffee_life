import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class DashboardChart extends StatelessWidget {
  final List<dynamic> monitoreos;
  final String? cultivoSeleccionado;
  final int fincaSeleccionada;
  final List<dynamic> fincas;
  final List<dynamic> cultivosFincaActual;

  const DashboardChart({
    super.key,
    required this.monitoreos,
    this.cultivoSeleccionado,
    required this.fincaSeleccionada,
    required this.fincas,
    required this.cultivosFincaActual,
  });

  String _getSaludNivel() {
    if (cultivoSeleccionado != null) {
      final nivel = _calcularNivelPara(cultivoSeleccionado);
      return nivel;
    }
    final niveles = monitoreos.map((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      if (obs.contains('critico') || obs.contains('crítico')) return 3;
      if (obs.contains('alto') || obs.contains('enfermedad')) return 2;
      if (obs.contains('medio')) return 1;
      return 0;
    }).toList();
    if (niveles.any((n) => n >= 3)) return 'Crítico';
    if (niveles.any((n) => n >= 2)) return 'Alto';
    if (niveles.any((n) => n >= 1)) return 'Medio';
    return 'Bajo';
  }

  String _calcularNivelPara(String? idCultivo) {
    final logs = monitoreos.where((m) =>
      (m['idCultivo'] ?? m['id_cultivo'])?.toString() == idCultivo
    ).toList();
    if (logs.isEmpty) return 'Bajo';
    final ultimo = logs.last;
    final obs = (ultimo['observaciones'] ?? '').toString().toLowerCase();
    if (obs.contains('critico') || obs.contains('crítico')) return 'Crítico';
    if (obs.contains('alto') || obs.contains('enfermedad')) return 'Alto';
    if (obs.contains('medio')) return 'Medio';
    return 'Bajo';
  }

  List<FlSpot> _buildSpots() {
    List<dynamic> filtrados;
    if (cultivoSeleccionado != null) {
      filtrados = monitoreos.where((m) =>
        (m['idCultivo'] ?? m['id_cultivo'])?.toString() == cultivoSeleccionado
      ).toList();
    } else if (fincas.isNotEmpty && fincaSeleccionada < fincas.length) {
      final ids = cultivosFincaActual
          .map((c) => (c['idCultivo'] ?? c['id_cultivo']).toString())
          .toSet();
      filtrados = monitoreos
          .where((m) => ids.contains((m['idCultivo'] ?? m['id_cultivo'])?.toString()))
          .toList();
    } else {
      filtrados = List.from(monitoreos);
    }

    filtrados.sort((a, b) {
      final ra = a['createdAt'] ?? a['created_at'] ?? a['fecha'] ?? '';
      final rb = b['createdAt'] ?? b['created_at'] ?? b['fecha'] ?? '';
      return ra.toString().compareTo(rb.toString());
    });

    double valorRiesgo(Map m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      if (obs.contains('critico') || obs.contains('crítico')) return 4000;
      if (obs.contains('alto') || obs.contains('enfermedad')) return 3200;
      if (obs.contains('roya') || obs.contains('medio')) return 2000;
      if (obs.contains('bajo')) return 800;
      return 400;
    }

    final base = filtrados.length > 10
        ? filtrados.sublist(filtrados.length - 10)
        : filtrados;

    List<FlSpot> spots = List.generate(
      base.length,
      (i) => FlSpot(i.toDouble(), valorRiesgo(base[i] as Map)),
    );

    if (spots.isEmpty) {
      spots = const [
        FlSpot(0, 400), FlSpot(1, 600), FlSpot(2, 500), FlSpot(3, 700),
        FlSpot(4, 550), FlSpot(5, 650), FlSpot(6, 500), FlSpot(7, 600),
        FlSpot(8, 550), FlSpot(9, 400),
      ];
    } else if (spots.length < 10) {
      final ultimo = spots.last.y;
      for (int i = spots.length; i < 10; i++) {
        spots.add(FlSpot(i.toDouble(), ultimo));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final nivel = _getSaludNivel();
    final color = nivel == 'Bajo'
        ? AppColors.primary
        : nivel == 'Medio'
            ? Colors.orange
            : Colors.red;
    final spots = _buildSpots();

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riesgo de roya',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                nivel,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1000,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(
                        '${(v / 40).round()}%',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 9,
                minY: 0,
                maxY: 4000,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

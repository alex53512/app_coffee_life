import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
 
class DetalleFincaExpertoScreen extends StatefulWidget {
  final Map<String, dynamic> finca;
  final List cultivos; // cultivos de TODAS las fincas (se filtra dentro)
  final List monitoreos; // monitoreos de TODAS las fincas (se filtra dentro)
 
  const DetalleFincaExpertoScreen({
    super.key,
    required this.finca,
    required this.cultivos,
    required this.monitoreos,
  });
 
  @override
  State<DetalleFincaExpertoScreen> createState() => _DetalleFincaExpertoScreenState();
}
 
class _DetalleFincaExpertoScreenState extends State<DetalleFincaExpertoScreen> {
  int? _cultivoSeleccionadoId;
 
  // ─── Helpers de datos ──────────────────────────────────────────────────
 
  List get _cultivosDeFinca {
    final idFinca = widget.finca['idFinca'] ?? widget.finca['id_finca'];
    return widget.cultivos
        .where((c) =>
            (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString())
        .toList();
  }
 
  List _monitoreosDeCultivo(dynamic idCultivo) {
    return widget.monitoreos.where((m) {
      final id = m['idCultivo'] ?? m['id_cultivo'];
      return id.toString() == idCultivo.toString();
    }).toList();
  }
 
  List get _monitoreosDeFinca {
    final idsCultivos = _cultivosDeFinca
        .map((c) => (c['idCultivo'] ?? c['id_cultivo']).toString())
        .toSet();
    return widget.monitoreos.where((m) {
      final idCultivo = (m['idCultivo'] ?? m['id_cultivo']).toString();
      return idsCultivos.contains(idCultivo);
    }).toList();
  }
 
  Map<String, dynamic> _getSaludActual() {
    List monitoreosFiltrados;
    if (_cultivoSeleccionadoId != null) {
      monitoreosFiltrados = _monitoreosDeCultivo(_cultivoSeleccionadoId);
    } else {
      monitoreosFiltrados = _monitoreosDeFinca;
    }
 
    if (monitoreosFiltrados.isEmpty) {
      return {'texto': 'Buena', 'porcentaje': 0.15, 'nivel': 'Bajo'};
    }
 
    final total = monitoreosFiltrados.length;
    final conRoya = monitoreosFiltrados.where((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      return obs.contains('roya') ||
          obs.contains('alto') ||
          obs.contains('alta') ||
          obs.contains('critico') ||
          obs.contains('crítico') ||
          obs.contains('enfermedad');
    }).length;
 
    final porcentaje = total > 0 ? conRoya / total : 0.0;
    if (porcentaje < 0.3) {
      return {'texto': 'Buena', 'porcentaje': 0.15, 'nivel': 'Bajo'};
    }
    if (porcentaje <= 0.6) {
      return {'texto': 'Regular', 'porcentaje': porcentaje, 'nivel': 'Medio'};
    }
    return {'texto': 'Crítica', 'porcentaje': porcentaje, 'nivel': 'Alto'};
  }
 
  String _calcularNivelRoyaPara(dynamic idCultivo) {
    final monitoreos = _monitoreosDeCultivo(idCultivo);
    if (monitoreos.isEmpty) return 'Sin datos';
 
    final total = monitoreos.length;
    final conRoya = monitoreos.where((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      return obs.contains('roya') ||
          obs.contains('alto') ||
          obs.contains('alta') ||
          obs.contains('critico') ||
          obs.contains('crítico') ||
          obs.contains('enfermedad');
    }).length;
 
    final porcentaje = conRoya / total;
    if (porcentaje < 0.3) return 'Bajo';
    if (porcentaje <= 0.6) return 'Medio';
    return 'Alto';
  }
 
  // ─── Build ────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final nombre = widget.finca['nombreFinca'] ?? 'Finca';
    final municipio = widget.finca['municipio'] ?? 'Sin municipio';
    final fotoUrl = (widget.finca['fotoUrl'] ?? '').toString();
 
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: Column(
        children: [
          _buildHeader(context, nombre, municipio),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fotoUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        fotoUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fotoPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildCultivosSection(),
                  if (_cultivoSeleccionadoId != null) ...[
                    const SizedBox(height: 20),
                    _buildSaludCard(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _fotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.park_outlined, color: AppColors.primary, size: 48),
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context, String nombre, String municipio) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(0xFFF4E7D6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: GoogleFonts.nunito(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text(municipio,
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildSaludCard() {
    final salud = _getSaludActual();
    final cultivoNombre = _cultivoSeleccionadoId != null
        ? (widget.cultivos.firstWhere(
            (c) => (c['idCultivo'] ?? c['id_cultivo']).toString() ==
                _cultivoSeleccionadoId.toString(),
            orElse: () => {})['nombreCultivo'] ?? 'Cultivo seleccionado')
        : (widget.finca['nombreFinca'] ?? 'Finca');
 
    Color colorSalud = const Color(0xFF4F8F1F);
    if (salud['texto'] == 'Regular') colorSalud = Colors.orange;
    if (salud['texto'] == 'Crítica') colorSalud = Colors.red;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Salud del cultivo',
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: colorSalud, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cultivoNombre,
                            style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text('Salud general',
                            style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(salud['texto'],
                            style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Índice de riesgo',
                            style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
                        Text('${((salud['porcentaje'] as double) * 100).round()}%',
                            style: GoogleFonts.nunito(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(salud['nivel'],
                        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: salud['porcentaje'] as double,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _buildCultivosSection() {
    final cultivos = _cultivosDeFinca;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cultivos',
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        if (cultivos.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Center(
              child: Text('Sin cultivos registrados',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7EF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('(toca un cultivo para ver su nivel de roya)',
                    style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ...cultivos.map((c) {
                  final idCultivo = c['idCultivo'] ?? c['id_cultivo'];
                  final selected = _cultivoSeleccionadoId?.toString() == idCultivo.toString();
                  final nivel = selected ? _calcularNivelRoyaPara(idCultivo) : '';
                  final nivelColor = nivel == 'Alto'
                      ? Colors.red
                      : nivel == 'Medio'
                          ? Colors.orange
                          : nivel == 'Bajo'
                              ? AppColors.primary
                              : Colors.grey;
 
                  return GestureDetector(
                    onTap: () {
                      final esElMismo = selected;
                      setState(() {
                        _cultivoSeleccionadoId = esElMismo ? null : idCultivo;
                      });
                      if (!esElMismo) {
                        final nivelCalculado = _calcularNivelRoyaPara(idCultivo);
                        AppState.instance.setCultivo(c as Map<String, dynamic>, nivelCalculado);
                      } else {
                        AppState.instance.setCultivo(null, _getSaludActual()['nivel']);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: selected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                              color: selected ? AppColors.primary : AppColors.textSecondary, size: 8),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c['nombreCultivo'] ?? c['nombre_cultivo'] ?? 'Cultivo',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                                  color: selected ? AppColors.primary : AppColors.textPrimary),
                            ),
                          ),
                          if (selected) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: nivelColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: nivelColor.withOpacity(0.4)),
                              ),
                              child: Text('Roya: $nivel',
                                  style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: nivelColor)),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(c['tipoCultivo'] ?? c['tipo_cultivo'] ?? 'Café',
                                  style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
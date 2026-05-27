import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
 
class ClimaScreen extends StatefulWidget {
  final String nombreFinca;
  const ClimaScreen({super.key, this.nombreFinca = 'Finca El Paraíso'});
 
  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}
 
class _ClimaScreenState extends State<ClimaScreen> {
  bool _cargando = true;
  Map<String, dynamic> _clima = {};
  String _ciudadActual = 'Cargando ubicación...';
 
  @override
  void initState() {
    super.initState();
    _cargarClima();
    // Escuchar cambios de finca/cultivo para reconstruir recomendaciones
    AppState.instance.addListener(_onEstadoCambiado);
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onEstadoCambiado);
    super.dispose();
  }
 
  void _onEstadoCambiado() => setState(() {});
 
  Future<void> _cargarClima() async {
    setState(() => _cargando = true);
    try {
      const apiKey = '27cc92d850e34ed4923194316261905';
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { _usarDatosSimulados(); return; }
 
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _usarDatosSimulados(); return;
      }
 
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
 
      final ciudad = 'Popayan,Cauca,Colombia';
      final url = 'https://api.weatherapi.com/v1/forecast.json'
          '?key=$apiKey&q=$ciudad&days=4&lang=es&aqi=no&alerts=no';
 
      final response = await http.get(Uri.parse(url));
      final data     = jsonDecode(response.body);
 
      if (response.statusCode == 200) {
        final current     = data['current'];
        final location    = data['location'];
        final forecastDays = data['forecast']['forecastday'] as List;
        setState(() {
          _ciudadActual = '${location['name']}, ${location['region']}';
          _clima = {
            'temp':       current['temp_c'].round(),
            'descripcion': current['condition']['text'],
            'humedad':    current['humidity'],
            'viento':     current['wind_kph'].round(),
            'lluvia':     current['precip_mm'] > 1,
            'icono':      _getEmojiFromCode(current['condition']['code'], current['is_day']),
            'pronostico': forecastDays.asMap().entries.map((e) {
              final dias = ['Hoy', 'Mañana', 'Pasado', 'En 3 días'];
              final day  = e.value['day'];
              return {
                'dia':    dias[e.key],
                'icono':  _getIconFromCode(day['condition']['code']),
                'max':    day['maxtemp_c'].round(),
                'min':    day['mintemp_c'].round(),
                'lluvia': day['daily_will_it_rain'] == 1,
              };
            }).toList(),
          };
          _cargando = false;
        });
      } else {
        _usarDatosSimulados();
      }
    } catch (e) {
      print('ERROR CLIMA: $e');
      _usarDatosSimulados();
    }
  }
 
  void _usarDatosSimulados() {
    setState(() {
      _ciudadActual = 'Popayán, Colombia';
      _clima = {
        'temp': 23, 'descripcion': 'Parcialmente nublado',
        'humedad': 60, 'viento': 9, 'lluvia': false, 'icono': '⛅',
        'pronostico': [
          {'dia': 'Hoy',      'icono': Icons.cloud_rounded,    'max': 24, 'min': 17, 'lluvia': false},
          {'dia': 'Mañana',   'icono': Icons.wb_sunny_rounded,  'max': 26, 'min': 18, 'lluvia': false},
          {'dia': 'Pasado',   'icono': Icons.grain_rounded,     'max': 22, 'min': 16, 'lluvia': true},
          {'dia': 'En 3 días','icono': Icons.cloud_rounded,    'max': 24, 'min': 17, 'lluvia': false},
        ],
      };
      _cargando = false;
    });
  }
 
  String _getEmojiFromCode(int code, int isDay) {
    if (code == 1000) return isDay == 1 ? '☀️' : '🌙';
    if (code == 1003) return '⛅';
    if (code <= 1009) return '☁️';
    if (code <= 1030) return '🌫️';
    if (code <= 1087) return '⛈️';
    if (code <= 1282) return '🌧️';
    return '⛅';
  }
 
  IconData _getIconFromCode(int code) {
    if (code == 1000) return Icons.wb_sunny_rounded;
    if (code == 1003) return Icons.cloud_queue_rounded;
    if (code <= 1009) return Icons.cloud_rounded;
    if (code <= 1087) return Icons.thunderstorm_rounded;
    if (code <= 1282) return Icons.grain_rounded;
    return Icons.cloud_rounded;
  }
 
  // ─────────────────────────────────────────────────────────────────────────
  // Recomendaciones combinadas: CLIMA + NIVEL DE ROYA del cultivo seleccionado
  // ─────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _getRecomendaciones() {
    final temp    = (_clima['temp']    ?? 22) as int;
    final humedad = (_clima['humedad'] ?? 70) as int;
    final lluvia  = (_clima['lluvia']  ?? false) as bool;
 
    // Datos del cultivo desde AppState
    final nivelRoya     = AppState.instance.nivelRoya;       // Bajo | Medio | Alto | Sin datos
    final cultivoNombre = AppState.instance.cultivoNombre;   // nombre o ''
    final tieneCultivo  = cultivoNombre.isNotEmpty;
 
    List<Map<String, dynamic>> recs = [];
 
    // ── 1. ALERTA DE ROYA (prioridad máxima si hay cultivo seleccionado) ──
    if (tieneCultivo) {
      if (nivelRoya == 'Alto') {
        recs.add({
          'icono': Icons.coronavirus_outlined,
          'color': Colors.red,
          'titulo': '🚨 Roya CRÍTICA en $cultivoNombre',
          'descripcion': 'Tu cultivo tiene alto nivel de roya. '
              '${lluvia ? "La lluvia y " : ""}${humedad > 70 ? "la humedad elevada ($humedad%) agravan la situación. " : ""}'
              'Aplica fungicida cúprico URGENTE y retira las hojas infectadas.',
        });
      } else if (nivelRoya == 'Medio') {
        recs.add({
          'icono': Icons.coronavirus_outlined,
          'color': Colors.orange,
          'titulo': '⚠️ Roya moderada en $cultivoNombre',
          'descripcion': 'Se detectó roya en nivel medio. '
              '${humedad > 70 ? "La humedad actual ($humedad%) favorece su avance. " : ""}'
              'Monitorea frecuentemente y considera fungicidas preventivos.',
        });
      } else if (nivelRoya == 'Bajo') {
        recs.add({
          'icono': Icons.coronavirus_outlined,
          'color': AppColors.primary,
          'titulo': '✅ Roya bajo control en $cultivoNombre',
          'descripcion': 'El nivel de roya es bajo. '
              '${humedad > 80 ? "Ojo: la humedad alta ($humedad%) puede aumentar el riesgo. Monitorea seguido." : "Continúa con el monitoreo periódico para mantenerlo así."}',
        });
      } else {
        recs.add({
          'icono': Icons.info_outline_rounded,
          'color': Colors.grey,
          'titulo': 'ℹ️ Sin datos de roya para $cultivoNombre',
          'descripcion': 'No hay monitoreos registrados para este cultivo. '
              'Realiza un diagnóstico para conocer su estado.',
        });
      }
    }
 
    // ── 2. RIEGO ──
    if (lluvia) {
      recs.add({
        'icono': Icons.water_drop_outlined,
        'color': Colors.red,
        'titulo': '❌ No riegues hoy',
        'descripcion': 'Está lloviendo actualmente. El suelo ya tiene suficiente agua '
            'y regar podría causar hongos o pudrición en las raíces.',
      });
    } else {
      recs.add({
        'icono': Icons.water_drop_outlined,
        'color': Colors.green,
        'titulo': '✅ Buen momento para regar',
        'descripcion': 'El clima está estable y sin lluvia. '
            'La humedad actual favorece la absorción del agua.',
      });
    }
 
    // ── 3. FUNGICIDAS (combinado con roya y humedad) ──
    if (humedad > 80 && (nivelRoya == 'Alto' || nivelRoya == 'Medio')) {
      recs.add({
        'icono': Icons.science_outlined,
        'color': Colors.red,
        'titulo': '🚨 Aplica fungicida ahora',
        'descripcion': 'Humedad alta ($humedad%) con roya $nivelRoya detectada. '
            'Condición ideal para propagación. Aplica fungicida sin demora.',
      });
    } else if (humedad > 80) {
      recs.add({
        'icono': Icons.science_outlined,
        'color': Colors.orange,
        'titulo': '⚠️ Riesgo de hongos por humedad',
        'descripcion': 'La humedad alta ($humedad%) favorece la roya y otros hongos. '
            'Considera fungicidas preventivos y mejora la ventilación.',
      });
    } else {
      recs.add({
        'icono': Icons.science_outlined,
        'color': Colors.green,
        'titulo': '✅ Condiciones estables',
        'descripcion': 'El ambiente no presenta alto riesgo de enfermedades '
            '${tieneCultivo ? "para $cultivoNombre" : ""}.',
      });
    }
 
    // ── 4. COSECHA ──
    if (lluvia) {
      recs.add({
        'icono': Icons.agriculture_outlined,
        'color': Colors.red,
        'titulo': '❌ Evita cosechar',
        'descripcion': 'La lluvia afecta la calidad del café y dificulta el secado.',
      });
    } else if (nivelRoya == 'Alto') {
      recs.add({
        'icono': Icons.agriculture_outlined,
        'color': Colors.orange,
        'titulo': '⚠️ Cosecha con precaución',
        'descripcion': 'El clima es favorable para cosechar, pero el nivel de roya es alto. '
            'Selecciona solo frutos sanos y desecha los afectados.',
      });
    } else {
      recs.add({
        'icono': Icons.agriculture_outlined,
        'color': Colors.green,
        'titulo': '✅ Buen clima para cosecha',
        'descripcion': 'Las condiciones son favorables para recolectar café.',
      });
    }
 
    // ── 5. TEMPERATURA ──
    if (temp >= 18 && temp <= 24) {
      recs.add({
        'icono': Icons.thermostat_outlined,
        'color': Colors.green,
        'titulo': '✅ Temperatura ideal',
        'descripcion': 'La temperatura actual ($temp°C) es óptima para el desarrollo del cafeto.',
      });
    } else if (temp > 28) {
      recs.add({
        'icono': Icons.thermostat_outlined,
        'color': Colors.orange,
        'titulo': '⚠️ Mucho calor ($temp°C)',
        'descripcion': 'El calor intenso puede estresar el cultivo y acelerar la propagación de plagas.',
      });
    } else if (temp < 14) {
      recs.add({
        'icono': Icons.thermostat_outlined,
        'color': Colors.blue,
        'titulo': '⚠️ Temperatura muy baja ($temp°C)',
        'descripcion': 'El frío puede afectar el desarrollo de la planta. Protege los cultivos jóvenes.',
      });
    }
 
    return recs;
  }
 
  @override
  Widget build(BuildContext context) {
    final fincaNombre   = AppState.instance.fincaSeleccionada?['nombreFinca'] ?? widget.nombreFinca;
    final cultivoNombre = AppState.instance.cultivoNombre;
    final nivelRoya     = AppState.instance.nivelRoya;
 
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(fincaNombre, cultivoNombre, nivelRoya),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _cargarClima,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildClimaCard(),
                            const SizedBox(height: 16),
                            _buildPronosticoCard(),
                            const SizedBox(height: 16),
                            _buildRecomendacionesHeader(cultivoNombre, nivelRoya),
                            const SizedBox(height: 12),
                            _buildRecomendacionesCard(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildHeader(String fincaNombre, String cultivoNombre, String nivelRoya) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E7D6),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_cloudy_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clima · $fincaNombre',
                    style: GoogleFonts.nunito(
                        fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                if (cultivoNombre.isNotEmpty)
                  Row(
                    children: [
                      Text('Cultivo: $cultivoNombre',
                          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      _royaBadge(nivelRoya),
                    ],
                  )
                else
                  Text('Selecciona un cultivo en Inicio para ver recomendaciones personalizadas',
                      style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _royaBadge(String nivel) {
    final color = nivel == 'Alto'   ? Colors.red
                : nivel == 'Medio'  ? Colors.orange
                : nivel == 'Bajo'   ? AppColors.primary
                : Colors.grey;
    if (nivel == 'Sin datos') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('Roya: $nivel',
          style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
 
  Widget _buildClimaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(_ciudadActual, style: GoogleFonts.nunito(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Text(_clima['icono'] ?? '⛅', style: const TextStyle(fontSize: 60)),
          Text('${_clima['temp'] ?? '--'}°C',
              style: GoogleFonts.nunito(fontSize: 52, fontWeight: FontWeight.w800)),
          Text(_clima['descripcion'] ?? '', style: GoogleFonts.nunito()),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _climaDato(Icons.water_drop_outlined, '${_clima['humedad'] ?? '--'}%', 'Humedad'),
              const SizedBox(width: 24),
              _climaDato(Icons.air, '${_clima['viento'] ?? '--'} km/h', 'Vel. del viento'),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _climaDato(IconData icon, String valor, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 2),
        Text(valor, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
 
  Widget _buildPronosticoCard() {
    final pronostico = _clima['pronostico'] as List? ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: pronostico.map<Widget>((p) {
          return Column(
            children: [
              Text(p['dia'], style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Icon(p['icono'], color: AppColors.primary),
              const SizedBox(height: 8),
              Text('${p['max']}°/${p['min']}°',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700)),
              if (p['lluvia'] == true)
                Text('🌧️', style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }
 
  Widget _buildRecomendacionesHeader(String cultivoNombre, String nivelRoya) {
    return Row(
      children: [
        Text('Recomendaciones',
            style: GoogleFonts.nunito(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const Spacer(),
        if (cultivoNombre.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Text(cultivoNombre,
                style: GoogleFonts.nunito(
                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          )
        else
          Text('Finca completa',
              style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
 
  Widget _buildRecomendacionesCard() {
    final recs = _getRecomendaciones();
    return Column(
      children: recs.map((rec) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: (rec['color'] as Color).withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (rec['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(rec['icono'], color: rec['color'], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec['titulo'],
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(rec['descripcion'],
                        style: GoogleFonts.nunito(
                            color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
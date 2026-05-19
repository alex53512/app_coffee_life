import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class ClimaScreen extends StatefulWidget {
  final String nombreFinca;
  const ClimaScreen({super.key, this.nombreFinca = 'Finca El Paraíso'});

  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}

class _ClimaScreenState extends State<ClimaScreen> {
  bool _cargando = true;
  Map<String, dynamic> _clima = {};

  @override
  void initState() {
    super.initState();
    _cargarClima();
  }

  Future<void> _cargarClima() async {
    setState(() => _cargando = true);
    try {
      const apiKey = '27cc92d850e34ed4923194316261905';
      const ciudad = '2.4419,-76.6063';

      final url = 'https://api.weatherapi.com/v1/forecast.json'
          '?key=$apiKey&q=$ciudad&days=4&lang=es&aqi=no&alerts=no';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final current = data['current'];
        final forecastDays = data['forecast']['forecastday'] as List;

        setState(() {
          _clima = {
            'temp': current['temp_c'].round(),
            'descripcion': current['condition']['text'],
            'humedad': current['humidity'],
            'viento': current['wind_kph'].round(),
            'lluvia': current['precip_mm'] > 0,
            'icono': _getEmojiFromCode(
                current['condition']['code'], current['is_day']),
            'iconCode':
                '${current['condition']['code']}_${current['is_day']}',
            'pronostico': forecastDays.asMap().entries.map((e) {
              final dias = ['Hoy', 'Mañana', 'Pasado', 'En 3 días'];
              final day = e.value['day'];
              return {
                'dia': dias[e.key],
                'icono': _getIconFromCode(day['condition']['code']),
                'max': day['maxtemp_c'].round(),
                'min': day['mintemp_c'].round(),
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
      print('Error clima: $e');
      _usarDatosSimulados();
    }
  }

  void _usarDatosSimulados() {
    setState(() {
      _clima = {
        'temp': 26,
        'descripcion': 'Nublado',
        'humedad': 50,
        'viento': 8,
        'lluvia': false,
        'icono': '☁️',
        'iconCode': '1006_1',
        'pronostico': [
          {'dia': 'Hoy',     'icono': Icons.cloud_rounded, 'max': 26, 'min': 16, 'lluvia': false},
          {'dia': 'Mañana',  'icono': Icons.grain_rounded, 'max': 27, 'min': 16, 'lluvia': true},
          {'dia': 'Pasado',  'icono': Icons.grain_rounded, 'max': 24, 'min': 16, 'lluvia': true},
          {'dia': 'En 3 días','icono': Icons.grain_rounded,'max': 25, 'min': 16, 'lluvia': true},
        ],
      };
      _cargando = false;
    });
  }

  String _getEmojiFromCode(int code, int isDay) {
    if (code == 1000) return isDay == 1 ? '☀️' : '🌙';
    if (code <= 1009) return '⛅';
    if (code <= 1030) return '🌫️';
    if (code <= 1087) return '⛈️';
    if (code <= 1117) return '❄️';
    if (code <= 1135) return '🌫️';
    if (code <= 1225) return '❄️';
    if (code <= 1237) return '🌨️';
    if (code <= 1282) return '🌧️';
    return '⛅';
  }

  IconData _getIconFromCode(int code) {
    if (code == 1000) return Icons.wb_sunny_rounded;
    if (code <= 1009) return Icons.cloud_rounded;
    if (code <= 1030) return Icons.cloud_rounded;
    if (code <= 1087) return Icons.thunderstorm_rounded;
    if (code <= 1282) return Icons.grain_rounded;
    return Icons.cloud_rounded;
  }

  List<Map<String, dynamic>> _getRecomendaciones() {
    final temp = _clima['temp'] ?? 22;
    final humedad = _clima['humedad'] ?? 70;
    final lluvia = _clima['lluvia'] ?? false;
    final iconCode = _clima['iconCode'] ?? '1006_1';
    final isDay = iconCode.endsWith('_1');
    final code = int.tryParse(iconCode.split('_')[0]) ?? 1006;
    final solFuerte = code == 1000 && isDay && temp > 28;
    final nubladoSinLluvia = !lluvia && !solFuerte;

    List<Map<String, dynamic>> recs = [];

    // ── RIEGO ──────────────────────────────────────────────
    if (lluvia) {
      recs.add({
        'icono': Icons.water_drop_outlined,
        'color': Colors.blue,
        'titulo': '❌ No riegues hoy',
        'descripcion':
            'Hay lluvia activa — el suelo ya absorbió suficiente agua. '
            'Regar en este momento puede provocar encharcamiento, '
            'asfixia radicular y proliferación de hongos en las raíces del cafeto.',
        'tipo': 'prohibido',
      });
    } else if (solFuerte) {
      recs.add({
        'icono': Icons.water_drop_outlined,
        'color': Colors.orange,
        'titulo': '⚠️ Riega solo en la mañana o al atardecer',
        'descripcion':
            'Con sol fuerte (${temp}°C), el agua se evapora rápidamente y puede '
            'quemar las hojas del cafeto por efecto lupa. '
            'Riega entre 5am y 8am o después de las 5pm. '
            'Así el agua llega bien a las raíces sin pérdidas por evaporación.',
        'tipo': 'precaucion',
      });
    } else if (nubladoSinLluvia) {
      recs.add({
        'icono': Icons.water_drop_outlined,
        'color': Colors.green,
        'titulo': '✅ Condiciones ideales para regar',
        'descripcion':
            'Cielo nublado sin lluvia (${temp}°C, humedad ${humedad}%) — '
            'el agua penetra mejor en el suelo sin evaporarse. '
            'Riega de forma uniforme en la base de la planta. '
            'Evita mojar las hojas para no favorecer el desarrollo de hongos.',
        'tipo': 'permitido',
      });
    }

    // ── FUNGICIDAS ──────────────────────────────────────────
    if (lluvia) {
      recs.add({
        'icono': Icons.science_outlined,
        'color': Colors.red,
        'titulo': '❌ No apliques fungicidas',
        'descripcion':
            'La lluvia lava los fungicidas antes de que actúen, '
            'haciendo la aplicación inefectiva y costosa. '
            'Espera al menos 24 horas después de la última lluvia. '
            'Aplica cuando el follaje esté seco y no haya lluvia prevista.',
        'tipo': 'prohibido',
      });
    } else if (solFuerte) {
      recs.add({
        'icono': Icons.science_outlined,
        'color': Colors.orange,
        'titulo': '⚠️ Aplica fungicidas temprano en la mañana',
        'descripcion':
            'El calor intenso (${temp}°C) degrada los ingredientes activos '
            'de los fungicidas y puede quemar el follaje. '
            'Aplica antes de las 8am o después de las 4pm. '
            'Cubre bien el envés de las hojas donde se aloja la roya.',
        'tipo': 'precaucion',
      });
    } else {
      recs.add({
        'icono': Icons.science_outlined,
        'color': Colors.green,
        'titulo': '✅ Momento ideal para fungicidas',
        'descripcion':
            'Temperatura y humedad óptimas para aplicar fungicidas. '
            'El producto se adhiere mejor al follaje y actúa con mayor eficacia. '
            'Cubre completamente el envés y haz de las hojas. '
            'Usa equipo de protección personal durante la aplicación.',
        'tipo': 'permitido',
      });
    }

    // ── RIESGO DE ROYA ──────────────────────────────────────
    if (lluvia && humedad > 85) {
      recs.add({
        'icono': Icons.bug_report_outlined,
        'color': Colors.red,
        'titulo': '🚨 Riesgo muy alto de roya',
        'descripcion':
            'Lluvia + humedad ${humedad}% = condiciones perfectas para Hemileia vastatrix. '
            'La lluvia dispersa las esporas de planta en planta. '
            'Inspecciona el envés de las hojas buscando manchas amarillas. '
            'Aplica fungicidas preventivos en cuanto pare la lluvia.',
        'tipo': 'prohibido',
      });
    } else if (humedad > 75 && temp >= 18 && temp <= 26) {
      recs.add({
        'icono': Icons.bug_report_outlined,
        'color': Colors.orange,
        'titulo': '⚠️ Riesgo moderado de roya',
        'descripcion':
            'Temperatura ${temp}°C y humedad ${humedad}% favorecen el desarrollo '
            'de la roya del café. Monitorea al menos 2 veces por semana. '
            'Revisa el envés de las hojas en las plantas más expuestas. '
            'Considera fungicida preventivo si hay historial de roya en tu finca.',
        'tipo': 'precaucion',
      });
    } else {
      recs.add({
        'icono': Icons.bug_report_outlined,
        'color': Colors.green,
        'titulo': '✅ Riesgo bajo de roya',
        'descripcion':
            'Las condiciones actuales no son favorables para el desarrollo de roya. '
            'Continúa con el monitoreo rutinario una vez por semana. '
            'Revisa el envés de las hojas de plantas representativas de cada parcela.',
        'tipo': 'permitido',
      });
    }

    // ── FERTILIZACIÓN ───────────────────────────────────────
    if (lluvia) {
      recs.add({
        'icono': Icons.eco_outlined,
        'color': Colors.red,
        'titulo': '❌ No fertilices con lluvia',
        'descripcion':
            'La lluvia lava los nutrientes del suelo antes de que las raíces '
            'los absorban — especialmente nitrógeno y potasio. '
            'Fertiliza 1 o 2 días después cuando el suelo esté húmedo pero no saturado.',
        'tipo': 'prohibido',
      });
    } else if (solFuerte) {
      recs.add({
        'icono': Icons.eco_outlined,
        'color': Colors.orange,
        'titulo': '⚠️ Fertiliza con precaución',
        'descripcion':
            'Con calor intenso (${temp}°C) el suelo seco puede quemar las raíces '
            'al aplicar fertilizantes concentrados. '
            'Riega primero, espera 30 minutos y luego fertiliza. '
            'Prefiere fertilizantes foliares en horas frescas.',
        'tipo': 'precaucion',
      });
    } else {
      recs.add({
        'icono': Icons.eco_outlined,
        'color': Colors.green,
        'titulo': '✅ Buen momento para fertilizar',
        'descripcion':
            'Suelo con humedad adecuada y temperatura de ${temp}°C — '
            'las raíces absorben mejor los nutrientes. '
            'Aplica cerca de la base del tallo sin tocar el tronco. '
            'Haz análisis de suelo periódicamente para fertilizar según la necesidad real.',
        'tipo': 'permitido',
      });
    }

    // ── COSECHA ─────────────────────────────────────────────
    if (lluvia) {
      recs.add({
        'icono': Icons.agriculture_outlined,
        'color': Colors.red,
        'titulo': '❌ No coseches con lluvia',
        'descripcion':
            'Los granos mojados fermentan de forma irregular durante el despulpado, '
            'afectando gravemente la calidad y el sabor del café. '
            'La lluvia también dificulta el secado posterior. '
            'Espera que pare y que los granos estén secos al tacto.',
        'tipo': 'prohibido',
      });
    } else if (solFuerte) {
      recs.add({
        'icono': Icons.agriculture_outlined,
        'color': Colors.green,
        'titulo': '✅ Excelente día para cosechar',
        'descripcion':
            'Sol fuerte (${temp}°C) — ideal para cosechar y secar el café. '
            'Los granos maduros se identifican mejor con buena luz. '
            'Aprovecha para extender el café en las eras de secado. '
            'Recuerda la cosecha selectiva: solo granos completamente rojos.',
        'tipo': 'permitido',
      });
    } else if (nubladoSinLluvia) {
      recs.add({
        'icono': Icons.agriculture_outlined,
        'color': Colors.green,
        'titulo': '✅ Se puede cosechar',
        'descripcion':
            'Clima nublado sin lluvia — buenas condiciones para cosechar. '
            'El secado puede ser más lento que con sol directo. '
            'Si tienes secadero mecánico aprovecha para usarlo. '
            'Selecciona solo los granos maduros de color rojo uniforme.',
        'tipo': 'permitido',
      });
    }

    // ── TEMPERATURA ─────────────────────────────────────────
    if (temp > 28) {
      recs.add({
        'icono': Icons.thermostat_outlined,
        'color': Colors.red,
        'titulo': '🌡️ Estrés térmico en el cafeto',
        'descripcion':
            'A ${temp}°C el cafeto reduce su fotosíntesis y puede sufrir quema foliar. '
            'Evita labores que estresen la planta como podas o aplicaciones químicas. '
            'Si es posible usa sombrío temporal. '
            'Asegúrate de que las plantas tengan suficiente agua disponible.',
        'tipo': 'prohibido',
      });
    } else if (temp >= 18 && temp <= 24) {
      recs.add({
        'icono': Icons.thermostat_outlined,
        'color': Colors.green,
        'titulo': '✅ Temperatura ideal para el café',
        'descripcion':
            'Entre 18°C y 24°C el cafeto crece en condiciones óptimas. '
            'La fotosíntesis, floración y llenado de grano ocurren de forma eficiente. '
            'Aprovecha para realizar cualquier labor agronómica necesaria.',
        'tipo': 'permitido',
      });
    } else if (temp < 15) {
      recs.add({
        'icono': Icons.thermostat_outlined,
        'color': Colors.red,
        'titulo': '🥶 Temperatura muy baja',
        'descripcion':
            'A ${temp}°C el cafeto puede sufrir daños en sus frutos y flores. '
            'Evita aplicar agua fría directamente a las plantas. '
            'Las heladas pueden quemar el follaje y los frutos en desarrollo. '
            'Monitorea de cerca las plantas más jóvenes y expuestas.',
        'tipo': 'prohibido',
      });
    }

    return recs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(
                      color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _cargarClima,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildClimaCard(),
                            const SizedBox(height: 16),
                            _buildPronosticoCard(),
                            const SizedBox(height: 16),
                            _buildRecomendacionesCard(),
                            const SizedBox(height: 20),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: AppColors.background,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text('Clima',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildClimaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              Text('Popayán, Colombia',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_clima['icono'] ?? '⛅',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(width: 16),
              Text('${_clima['temp']}°C',
                  style: GoogleFonts.nunito(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ],
          ),
          Text(
            (_clima['descripcion'] ?? '').toString().isNotEmpty
                ? (_clima['descripcion'].toString()[0].toUpperCase() +
                    _clima['descripcion'].toString().substring(1))
                : '',
            style: GoogleFonts.nunito(
                fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _climaDato(Icons.water_drop_outlined,
                  'Humedad', '${_clima['humedad']}%'),
              Container(width: 1, height: 40, color: AppColors.border),
              _climaDato(Icons.air_outlined,
                  'Viento', '${_clima['viento']} km/h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _climaDato(IconData icon, String label, String valor) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(valor,
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildPronosticoCard() {
    final pronostico = _clima['pronostico'] as List? ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pronóstico',
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: pronostico.map<Widget>((p) {
              return Column(
                children: [
                  Text(p['dia'],
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Icon(p['icono'] as IconData,
                      color: AppColors.primary, size: 32),
                  const SizedBox(height: 4),
                  if (p['lluvia'] == true)
                    Text('🌧️', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${p['max']}°/${p['min']}°',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendacionesCard() {
    final recs = _getRecomendaciones();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Recomendaciones para tu cultivo',
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Basadas en el clima actual de Popayán',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...recs.asMap().entries.map((e) {
            final rec = e.value;
            final isLast = e.key == recs.length - 1;
            final color = rec['color'] as Color;
            final tipo = rec['tipo'] as String;

            Color bgColor;
            if (tipo == 'permitido') {
              bgColor = Colors.green.withOpacity(0.08);
            } else if (tipo == 'prohibido') {
              bgColor = Colors.red.withOpacity(0.08);
            } else {
              bgColor = Colors.orange.withOpacity(0.08);
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(rec['icono'] as IconData,
                          color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec['titulo'],
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(rec['descripcion'],
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );
  }
}
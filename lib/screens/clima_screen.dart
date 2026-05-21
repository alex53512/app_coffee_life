import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';

class ClimaScreen extends StatefulWidget {
  final String nombreFinca;

  const ClimaScreen({
    super.key,
    this.nombreFinca = 'Finca El Paraíso',
  });

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
  }

  Future<void> _cargarClima() async {
    setState(() => _cargando = true);

    try {
      const apiKey = '27cc92d850e34ed4923194316261905';

      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _usarDatosSimulados();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _usarDatosSimulados();
        return;
      }

      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lon = position.longitude;

      final ciudad = 'Popayan,Cauca,Colombia';

      final url =
          'https://api.weatherapi.com/v1/forecast.json'
          '?key=$apiKey'
          '&q=$ciudad'
          '&days=4'
          '&lang=es'
          '&aqi=no'
          '&alerts=no';

      final response =
          await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final current = data['current'];

        final location = data['location'];

        final forecastDays =
            data['forecast']['forecastday'] as List;

        setState(() {
        _ciudadActual = '${location['name']}, ${location['region']}, ${location['country']}';

          _clima = {
            'temp': current['temp_c'].round(),

            'descripcion':
                current['condition']['text'],

            'humedad': current['humidity'],

            'viento':
                current['wind_kph'].round(),

            'lluvia':
                current['precip_mm'] > 1,

            'icono': _getEmojiFromCode(
              current['condition']['code'],
              current['is_day'],
            ),

            'iconCode':
                '${current['condition']['code']}_${current['is_day']}',

            'pronostico':
                forecastDays.asMap().entries.map((e) {
              final dias = [
                'Hoy',
                'Mañana',
                'Pasado',
                'En 3 días'
              ];

              final day = e.value['day'];

              return {
                'dia': dias[e.key],

                'icono': _getIconFromCode(
                  day['condition']['code'],
                ),

                'max':
                    day['maxtemp_c'].round(),

                'min':
                    day['mintemp_c'].round(),

                'lluvia':
                    day['daily_will_it_rain'] == 1,
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
        'temp': 23,
        'descripcion': 'Parcialmente nublado',
        'humedad': 60,
        'viento': 9,
        'lluvia': false,
        'icono': '⛅',
        'iconCode': '1003_1',
        'pronostico': [
          {
            'dia': 'Hoy',
            'icono': Icons.cloud_rounded,
            'max': 24,
            'min': 17,
            'lluvia': false,
          },
          {
            'dia': 'Mañana',
            'icono': Icons.wb_sunny_rounded,
            'max': 26,
            'min': 18,
            'lluvia': false,
          },
          {
            'dia': 'Pasado',
            'icono': Icons.grain_rounded,
            'max': 22,
            'min': 16,
            'lluvia': true,
          },
          {
            'dia': 'En 3 días',
            'icono': Icons.cloud_rounded,
            'max': 24,
            'min': 17,
            'lluvia': false,
          },
        ],
      };

      _cargando = false;
    });
  }

  String _getEmojiFromCode(
    int code,
    int isDay,
  ) {
    if (code == 1000) {
      return isDay == 1 ? '☀️' : '🌙';
    }

    if (code == 1003) return '⛅';

    if (code <= 1009) return '☁️';

    if (code <= 1030) return '🌫️';

    if (code <= 1087) return '⛈️';

    if (code <= 1282) return '🌧️';

    return '⛅';
  }

  IconData _getIconFromCode(int code) {
    if (code == 1000) {
      return Icons.wb_sunny_rounded;
    }

    if (code == 1003) {
      return Icons.cloud_queue_rounded;
    }

    if (code <= 1009) {
      return Icons.cloud_rounded;
    }

    if (code <= 1087) {
      return Icons.thunderstorm_rounded;
    }

    if (code <= 1282) {
      return Icons.grain_rounded;
    }

    return Icons.cloud_rounded;
  }

  List<Map<String, dynamic>> _getRecomendaciones() {
    final temp = _clima['temp'] ?? 22;

    final humedad =
        _clima['humedad'] ?? 70;

    final lluvia =
        _clima['lluvia'] ?? false;

    List<Map<String, dynamic>> recs = [];

    // RIEGO

    if (lluvia) {
      recs.add({
        'icono':
            Icons.water_drop_outlined,
        'color': Colors.red,
        'titulo':
            '❌ No riegues hoy',
        'descripcion':
            'Está lloviendo actualmente. '
                'El suelo ya tiene suficiente agua y '
                'regar podría causar hongos '
                'o pudrición en las raíces.',
      });
    } else {
      recs.add({
        'icono':
            Icons.water_drop_outlined,
        'color': Colors.green,
        'titulo':
            '✅ Buen momento para regar',
        'descripcion':
            'El clima está estable y sin lluvia. '
                'La humedad actual favorece '
                'la absorción del agua.',
      });
    }

    // FUNGICIDAS

    if (humedad > 80) {
      recs.add({
        'icono':
            Icons.science_outlined,
        'color': Colors.orange,
        'titulo':
            '⚠️ Riesgo de hongos',
        'descripcion':
            'La humedad alta favorece '
                'la roya y otros hongos. '
                'Monitorea las hojas y '
                'considera fungicidas preventivos.',
      });
    } else {
      recs.add({
        'icono':
            Icons.science_outlined,
        'color': Colors.green,
        'titulo':
            '✅ Condiciones estables',
        'descripcion':
            'El ambiente no presenta '
                'alto riesgo de enfermedades.',
      });
    }

    // COSECHA

    if (lluvia) {
      recs.add({
        'icono':
            Icons.agriculture_outlined,
        'color': Colors.red,
        'titulo':
            '❌ Evita cosechar',
        'descripcion':
            'La lluvia afecta la calidad '
                'del café y dificulta el secado.',
      });
    } else {
      recs.add({
        'icono':
            Icons.agriculture_outlined,
        'color': Colors.green,
        'titulo':
            '✅ Buen clima para cosecha',
        'descripcion':
            'Las condiciones son favorables '
                'para recolectar café.',
      });
    }

    // TEMPERATURA

    if (temp >= 18 && temp <= 24) {
      recs.add({
        'icono':
            Icons.thermostat_outlined,
        'color': Colors.green,
        'titulo':
            '✅ Temperatura ideal',
        'descripcion':
            'La temperatura actual es óptima '
                'para el desarrollo del cafeto.',
      });
    } else if (temp > 28) {
      recs.add({
        'icono':
            Icons.thermostat_outlined,
        'color': Colors.orange,
        'titulo':
            '⚠️ Mucho calor',
        'descripcion':
            'El calor intenso puede '
                'estresar el cultivo.',
      });
    }

    return recs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: _cargando
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          _cargarClima,

                      color:
                          AppColors.primary,

                      child:
                          SingleChildScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),

                        padding:
                            const EdgeInsets.all(
                                20),

                        child: Column(
                          children: [
                            _buildClimaCard(),

                            const SizedBox(
                                height: 16),

                            _buildPronosticoCard(),

                            const SizedBox(
                                height: 16),

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

  Widget _buildHeader(
      BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
            ),
            onPressed: () =>
                Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Clima',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.nunito(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildClimaCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _ciudadActual,
            style:
                GoogleFonts.nunito(),
          ),

          const SizedBox(height: 20),

          Text(
            _clima['icono'],
            style:
                const TextStyle(
                    fontSize: 60),
          ),

          Text(
            '${_clima['temp']}°C',
            style:
                GoogleFonts.nunito(
              fontSize: 52,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          Text(
            _clima['descripcion'],
            style:
                GoogleFonts.nunito(),
          ),
        ],
      ),
    );
  }

  Widget _buildPronosticoCard() {
    final pronostico =
        _clima['pronostico']
                as List? ??
            [];

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceAround,
        children:
            pronostico.map<Widget>((p) {
          return Column(
            children: [
              Text(p['dia']),
              const SizedBox(height: 8),
              Icon(
                p['icono'],
                color:
                    AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                  '${p['max']}°/${p['min']}°'),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecomendacionesCard() {
    final recs =
        _getRecomendaciones();

    return Column(
      children: recs.map((rec) {
        return Container(
          width: double.infinity,
          margin:
              const EdgeInsets.only(
                  bottom: 12),
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
                    18),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                rec['icono'],
                color: rec['color'],
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      rec['titulo'],
                      style:
                          GoogleFonts.nunito(
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                        height: 6),

                    Text(
                      rec['descripcion'],
                      style:
                          GoogleFonts.nunito(
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
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
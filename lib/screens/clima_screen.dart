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
      const apiKey = '56f9853eb9fa28e7eeb94df978d7b5db';
      const lat = 2.9273;
      const lon = -75.2819;

      final url = 'https://api.openweathermap.org/data/2.5/forecast'
          '?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=es&cnt=4';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final current = data['list'][0];
        final pronostico = (data['list'] as List).take(4).toList();

        setState(() {
          _clima = {
            'temp': current['main']['temp'].round(),
            'descripcion': current['weather'][0]['description'],
            'humedad': current['main']['humidity'],
            'viento': (current['wind']['speed'] * 3.6).round(),
            'icono': _getEmoji(current['weather'][0]['icon']),
            'pronostico': pronostico.asMap().entries.map((e) {
              final dias = ['Hoy', 'Mañana', 'Jue', 'Vie'];
              final p = e.value;
              return {
                'dia': dias[e.key],
                'icono': _getIcon(p['weather'][0]['icon']),
                'max': p['main']['temp_max'].round(),
                'min': p['main']['temp_min'].round(),
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
        'temp': 22,
        'descripcion': 'Parcialmente nublado',
        'humedad': 78,
        'viento': 8,
        'icono': '⛅',
        'pronostico': [
          {'dia': 'Hoy',    'icono': Icons.wb_sunny_rounded,    'max': 22, 'min': 16},
          {'dia': 'Mañana', 'icono': Icons.cloud_rounded,       'max': 23, 'min': 17},
          {'dia': 'Jue',    'icono': Icons.thunderstorm_rounded, 'max': 24, 'min': 16},
          {'dia': 'Vie',    'icono': Icons.thunderstorm_rounded, 'max': 23, 'min': 17},
        ],
      };
      _cargando = false;
    });
  }

  String _getEmoji(String icon) {
    if (icon.contains('01')) return '☀️';
    if (icon.contains('02') || icon.contains('03')) return '⛅';
    if (icon.contains('04')) return '☁️';
    if (icon.contains('09') || icon.contains('10')) return '🌧️';
    if (icon.contains('11')) return '⛈️';
    return '⛅';
  }

  IconData _getIcon(String icon) {
    if (icon.contains('01')) return Icons.wb_sunny_rounded;
    if (icon.contains('02') || icon.contains('03')) return Icons.cloud_rounded;
    if (icon.contains('09') || icon.contains('10')) return Icons.grain_rounded;
    if (icon.contains('11')) return Icons.thunderstorm_rounded;
    return Icons.cloud_rounded;
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
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
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
              Text(widget.nombreFinca,
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
            (_clima['descripcion'] ?? '').toString().toUpperCase().substring(0, 1) +
            (_clima['descripcion'] ?? '').toString().substring(1),
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
                  const SizedBox(height: 8),
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
}
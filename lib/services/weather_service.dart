import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import 'cache_service.dart';

class WeatherResult {
  final Map<String, dynamic> data;
  final bool isOffline;
  WeatherResult({required this.data, this.isOffline = false});
}

class WeatherService {
  static Future<WeatherResult> getWeather({required double lat, required double lon}) async {
    final query = '$lat,$lon';
    final cacheKey = 'weather_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

    try {
      final url = '${EnvConfig.weatherApiUrl}/forecast.json?key=${EnvConfig.weatherApiKey}&q=$query&days=4&lang=es&aqi=no&alerts=no';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final parsed = _parseResponse(data);
        CacheService.set(cacheKey, parsed, ttl: const Duration(minutes: 30));
        return WeatherResult(data: parsed);
      }
      final cached = CacheService.get(cacheKey);
      if (cached != null) return WeatherResult(data: Map<String, dynamic>.from(cached), isOffline: true);
      throw Exception(data['error']?['message'] ?? 'Error ${response.statusCode}');
    } catch (e) {
      final cached = CacheService.get(cacheKey);
      if (cached != null) return WeatherResult(data: Map<String, dynamic>.from(cached), isOffline: true);
      rethrow;
    }
  }

  static IconData iconoActual(Map<String, dynamic>? clima) {
    if (clima == null) return Icons.wb_cloudy_outlined;
    final code = clima['code'] as int? ?? 1003;
    final isDay = clima['isDay'] as int? ?? 1;
    return _getIconFromCode(code, isDay);
  }

  static IconData iconoPronostico(Map<String, dynamic> p) {
    final code = p['code'] as int?;
    if (code == null) return Icons.cloud_rounded;
    return _getIconFromCode(code);
  }

  static Map<String, dynamic> _parseResponse(Map<String, dynamic> data) {
    final current = data['current'];
    final location = data['location'];
    final forecastDays = data['forecast']['forecastday'] as List;
    return {
      'ciudad': '${location['name']}, ${location['region']}',
      'temp': current['temp_c'].round(),
      'descripcion': current['condition']['text'],
      'humedad': current['humidity'],
      'viento': current['wind_kph'].round(),
      'lluvia': current['precip_mm'] > 1,
      'code': current['condition']['code'],
      'isDay': current['is_day'],
      'pronostico': forecastDays.asMap().entries.map((e) {
        final dias = ['Hoy', 'Mañana', 'Pasado', 'En 3 días'];
        final day = e.value['day'];
        return {
          'dia': dias[e.key],
          'code': day['condition']['code'],
          'max': day['maxtemp_c'].round(),
          'min': day['mintemp_c'].round(),
          'lluvia': day['daily_will_it_rain'] == 1,
        };
      }).toList(),
    };
  }

  static IconData _getIconFromCode(int code, [int isDay = 1]) {
    if (code == 1000) return isDay == 1 ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    if (code == 1003) return Icons.cloud_queue_rounded;
    if (code <= 1009) return Icons.cloud_rounded;
    if (code <= 1030) return Icons.blur_on_rounded;
    if (code <= 1087) return Icons.thunderstorm_rounded;
    if (code <= 1282) return Icons.grain_rounded;
    return Icons.cloud_rounded;
  }
}

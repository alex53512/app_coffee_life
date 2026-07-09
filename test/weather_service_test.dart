import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_coffee_life/services/weather_service.dart';

void main() {
  group('WeatherService.iconoActual', () {
    test('retorna IconData desde code + isDay', () {
      final clima = <String, dynamic>{'code': 1000, 'isDay': 1};
      expect(WeatherService.iconoActual(clima), Icons.wb_sunny_rounded);
    });

    test('retorna luna cuando es de noche', () {
      final clima = <String, dynamic>{'code': 1000, 'isDay': 0};
      expect(WeatherService.iconoActual(clima), Icons.nightlight_round);
    });

    test('retorna fallback cuando clima es null', () {
      expect(WeatherService.iconoActual(null), Icons.wb_cloudy_outlined);
    });
  });

  group('WeatherService.iconoPronostico', () {
    test('retorna IconData desde code', () {
      final p = <String, dynamic>{'code': 1000};
      expect(WeatherService.iconoPronostico(p), Icons.wb_sunny_rounded);
    });

    test('retorna sol parcial cuando code es 1003', () {
      final p = <String, dynamic>{'code': 1003};
      expect(WeatherService.iconoPronostico(p), Icons.cloud_queue_rounded);
    });

    test('retorna fallback cuando code es null', () {
      final p = <String, dynamic>{};
      expect(WeatherService.iconoPronostico(p), Icons.cloud_rounded);
    });
  });

  group('WeatherResult', () {
    test('crea resultado con datos', () {
      final result = WeatherResult(data: {'temp': 25});
      expect(result.data['temp'], 25);
      expect(result.isOffline, false);
    });

    test('crea resultado offline', () {
      final result = WeatherResult(data: {'temp': 25}, isOffline: true);
      expect(result.isOffline, true);
    });
  });
}

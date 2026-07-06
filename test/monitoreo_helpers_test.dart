import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_coffee_life/theme/app_theme.dart';
import 'package:app_coffee_life/widgets/monitoreo_card.dart';

void main() {
  group('labelNivel', () {
    test('retorna Alto cuando nivelRoya contiene "alto"', () {
      final m = {'nivelRoya': {'nombreNivel': 'Alto'}};
      expect(labelNivel(m), 'Alto');
    });

    test('retorna Alto cuando nivelRoya contiene "critico"', () {
      final m = {'nivelRoya': 'critico'};
      expect(labelNivel(m), 'Alto');
    });

    test('retorna Medio cuando nivelRoya contiene "medio"', () {
      final m = {'nivelRoya': {'nombre_nivel': 'Medio'}};
      expect(labelNivel(m), 'Medio');
    });

    test('retorna Bajo cuando nivelRoya contiene "bajo"', () {
      final m = {'nivelRoya': {'nombreNivel': 'Bajo'}};
      expect(labelNivel(m), 'Bajo');
    });

    test('retorna Bajo cuando nivelRoya es "sano"', () {
      final m = {'nivelRoya': 'sano'};
      expect(labelNivel(m), 'Bajo');
    });

    test('retorna Alto cuando observaciones contiene "roya"', () {
      final m = {'observaciones': 'Se encontró roya en las hojas'};
      expect(labelNivel(m), 'Alto');
    });

    test('retorna Bajo por defecto', () {
      final m = {'observaciones': 'Todo normal'};
      expect(labelNivel(m), 'Bajo');
    });

    test('retorna Bajo cuando no hay datos', () {
      expect(labelNivel({}), 'Bajo');
    });
  });

  group('colorNivel', () {
    test('retorna rojo para nivel Alto', () {
      final m = {'nivelRoya': {'nombreNivel': 'Alto'}};
      expect(colorNivel(m), Colors.red);
    });

    test('retorna verde para nivel Bajo', () {
      final m = {'nivelRoya': {'nombreNivel': 'Bajo'}};
      expect(colorNivel(m), AppColors.primary);
    });
  });

  group('tituloMonitoreo', () {
    test('retorna "Roya encontrada" para nivel Alto', () {
      final m = {'nivelRoya': {'nombreNivel': 'Alto'}};
      expect(tituloMonitoreo(m), 'Roya encontrada');
    });

    test('retorna "Riesgo bajo" para nivel Bajo', () {
      final m = {'nivelRoya': {'nombreNivel': 'Bajo'}};
      expect(tituloMonitoreo(m), 'Riesgo bajo');
    });
  });

  group('parcelaMonitoreo', () {
    test('retorna nombre de finca desde cultivo.finca', () {
      final m = {
        'cultivo': {
          'finca': {'nombreFinca': 'Finca Test'}
        }
      };
      expect(parcelaMonitoreo(m), 'Finca Test');
    });

    test('retorna "Sin finca" cuando no hay datos', () {
      expect(parcelaMonitoreo({}), 'Sin finca');
    });
  });

  group('imagenUrlMonitoreo', () {
    test('retorna null cuando no hay imagenes', () {
      expect(imagenUrlMonitoreo({}), isNull);
    });

    test('retorna null cuando imagenes es lista vacia', () {
      expect(imagenUrlMonitoreo({'imagenes': []}), isNull);
    });
  });
}

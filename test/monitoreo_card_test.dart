import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_coffee_life/widgets/monitoreo_card.dart';

Widget createTestApp(Widget widget) {
  return MaterialApp(home: Scaffold(body: widget));
}

void main() {
  group('MonitoreoCard', () {
    testWidgets('renderiza fecha y diagnostico', (tester) async {
      final monitoreo = {
        'fechaMonitoreo': '2024-01-15',
        'observaciones': 'Alto — 95% — Hemileia vastatrix',
        'cultivo': {
          'finca': {'nombreFinca': 'Finca Test'}
        },
      };

      await tester.pumpWidget(createTestApp(
        MonitoreoCard(monitoreo: monitoreo),
      ));

      expect(find.text('2024-01-15'), findsOneWidget);
      expect(find.text('Alto'), findsNWidgets(2));
      expect(find.text('95%'), findsOneWidget);
    });

    testWidgets('renderiza nivel Bajo por defecto', (tester) async {
      final monitoreo = {
        'fechaMonitoreo': '2024-06-01',
        'observaciones': '',
        'cultivo': {
          'finca': {'nombreFinca': 'Otra Finca'}
        },
      };

      await tester.pumpWidget(createTestApp(
        MonitoreoCard(monitoreo: monitoreo),
      ));

      expect(find.text('Otra Finca'), findsOneWidget);
      expect(find.text('Riesgo bajo'), findsOneWidget);
    });
  });
}

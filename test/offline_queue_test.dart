import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_coffee_life/services/offline_queue_service.dart';

void main() {
  setUpAll(() async {
    Hive.init('test/.hive_test');
    await OfflineQueueService.init();
  });

  tearDown(() async {
    await OfflineQueueService.clear();
  });

  group('OfflineQueueService', () {
    test('pendienteCount empieza en 0', () {
      expect(OfflineQueueService.pendingCount.value, 0);
    });

    test('enqueueDiagnostico agrega un item', () async {
      final id = await OfflineQueueService.enqueueDiagnostico(
        idCultivo: 1,
        imagenBytes: null,
        imagenFilename: 'test.jpg',
        observaciones: 'Roya detectada',
        resultado: 'Roya',
        confianza: '85',
        severidad: 'Alta',
        nombreCientifico: 'Hemileia vastatrix',
        recomendaciones: [],
      );
      expect(id, isNotEmpty);
      expect(OfflineQueueService.pendingCount.value, 1);
    });

    test('getAll retorna items en orden', () async {
      await OfflineQueueService.enqueueDiagnostico(
        idCultivo: 1,
        imagenBytes: null,
        imagenFilename: 'a.jpg',
        observaciones: 'Primero',
        resultado: 'Roya',
        confianza: '80',
        severidad: 'Alta',
        nombreCientifico: '',
        recomendaciones: [],
      );
      await Future.delayed(const Duration(milliseconds: 5));
      await OfflineQueueService.enqueueDiagnostico(
        idCultivo: 2,
        imagenBytes: null,
        imagenFilename: 'b.jpg',
        observaciones: 'Segundo',
        resultado: 'Sano',
        confianza: '95',
        severidad: 'Baja',
        nombreCientifico: '',
        recomendaciones: [],
      );
      final items = OfflineQueueService.getAll();
      expect(items.length, 2);
      expect(items[0].data['observaciones'], 'Primero');
      expect(items[1].data['observaciones'], 'Segundo');
    });

    test('remove elimina un item', () async {
      final id = await OfflineQueueService.enqueueDiagnostico(
        idCultivo: 1,
        imagenBytes: null,
        imagenFilename: 'test.jpg',
        observaciones: 'Test',
        resultado: 'Roya',
        confianza: '80',
        severidad: 'Media',
        nombreCientifico: '',
        recomendaciones: [],
      );
      expect(OfflineQueueService.pendingCount.value, 1);
      await OfflineQueueService.remove(id);
      expect(OfflineQueueService.pendingCount.value, 0);
      expect(OfflineQueueService.getAll(), isEmpty);
    });

    test('clear elimina todos los items', () async {
      await OfflineQueueService.enqueueDiagnostico(
        idCultivo: 1,
        imagenBytes: null,
        imagenFilename: 'a.jpg',
        observaciones: 'Uno',
        resultado: 'Roya',
        confianza: '80',
        severidad: 'Alta',
        nombreCientifico: '',
        recomendaciones: [],
      );
      await OfflineQueueService.enqueueDiagnostico(
        idCultivo: 2,
        imagenBytes: null,
        imagenFilename: 'b.jpg',
        observaciones: 'Dos',
        resultado: 'Sano',
        confianza: '90',
        severidad: 'Baja',
        nombreCientifico: '',
        recomendaciones: [],
      );
      expect(OfflineQueueService.pendingCount.value, 2);
      await OfflineQueueService.clear();
      expect(OfflineQueueService.pendingCount.value, 0);
      expect(OfflineQueueService.getAll(), isEmpty);
    });

    test('enqueueDiagnostico con imagenBytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final id = await OfflineQueueService.enqueueDiagnostico(
        idCultivo: 1,
        imagenBytes: bytes,
        imagenFilename: 'photo.jpg',
        observaciones: 'Con imagen',
        resultado: 'Roya',
        confianza: '85',
        severidad: 'Alta',
        nombreCientifico: 'Hemileia vastatrix',
        recomendaciones: [
          {'titulo': 'Aplicar fungicida', 'descripcion': 'Cada 15 días'},
        ],
      );
      expect(id, isNotEmpty);
      final items = OfflineQueueService.getAll();
      expect(items.length, 1);
      expect(items[0].data['imagenBytes'], isNotNull);
      expect(items[0].data['recomendaciones'].length, 1);
    });
  });
}

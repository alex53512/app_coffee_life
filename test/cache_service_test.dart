import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_coffee_life/services/cache_service.dart';

void main() {
  setUpAll(() async {
    Hive.init('test/.hive_test');
    await CacheService.init();
  });

  tearDownAll(() async {
    await CacheService.clear();
    Hive.deleteBoxFromDisk('api_cache');
  });

  setUp(() async {
    await CacheService.clear();
  });

  group('CacheService', () {
    test('guarda y recupera datos', () async {
      await CacheService.set('/test', {'key': 'value'});
      final result = CacheService.get('/test');
      expect(result, {'key': 'value'});
    });

    test('retorna null para clave inexistente', () {
      expect(CacheService.get('/no-existe'), isNull);
    });

    test('has retorna true si existe y no expiro', () async {
      await CacheService.set('/test', 'data');
      expect(CacheService.has('/test'), isTrue);
    });

    test('has retorna false si no existe', () {
      expect(CacheService.has('/no-existe'), isFalse);
    });

    test('clear elimina todos los datos', () async {
      await CacheService.set('/a', 1);
      await CacheService.set('/b', 2);
      await CacheService.clear();
      expect(CacheService.get('/a'), isNull);
      expect(CacheService.get('/b'), isNull);
    });

    test('TTL expira los datos', () async {
      await CacheService.set('/test', 'valor', ttl: Duration(milliseconds: 1));
      await Future.delayed(Duration(milliseconds: 10));
      expect(CacheService.get('/test'), isNull);
    });
  });
}

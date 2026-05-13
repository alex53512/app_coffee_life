import 'api_service.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final results = await Future.wait([
        ApiService.get('/fincas'),
        ApiService.get('/monitoreos'),
        ApiService.get('/recomendaciones'),
      ]);

      // El backend devuelve el array directo, sin wrapper 'data'
      final fincas = results[0] is List ? results[0] : 
                     (results[0]['data'] ?? []);
      final monitoreos = results[1] is List ? results[1] : 
                         (results[1]['data'] ?? []);
      final recomendaciones = results[2] is List ? results[2] : 
                              (results[2]['data'] ?? []);

      return {
        'fincas':          fincas,
        'monitoreos':      monitoreos,
        'recomendaciones': recomendaciones,
      };
    } catch (e) {
      throw Exception('Error cargando dashboard: $e');
    }
  }
}
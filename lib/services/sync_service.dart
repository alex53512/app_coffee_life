import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_queue_service.dart';

class SyncService {
  static bool _syncing = false;

  static Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;

    try {
      final items = OfflineQueueService.getAll();
      if (items.isEmpty) return;

      final token = await AuthService.getToken();
      if (token == null) return;

      for (final item in items) {
        try {
          await _replay(item);
          await OfflineQueueService.remove(item.id);
        } catch (_) {
          break;
        }
      }
    } finally {
      _syncing = false;
    }
  }

  static Future<void> _replay(OfflineQueueItem item) async {
    final data = item.data;
    final fechaStr = _fechaActual();

    final observaciones = data['observaciones'] as String? ?? '';

    final resMonitoreo = await ApiService.post('/monitoreos', {
      'id_cultivo': data['idCultivo'],
      'fecha_monitoreo': fechaStr,
      'observaciones': observaciones,
    });
    final idMonitoreo = resMonitoreo['data']?['idMonitoreo'] as int?;

    int? idImagen;
    final imagenB64 = data['imagenBytes'] as String?;
    if (idMonitoreo != null && imagenB64 != null && imagenB64.isNotEmpty) {
      idImagen = await _uploadImagen(
        idMonitoreo: idMonitoreo,
        bytes: base64Decode(imagenB64),
        filename: data['imagenFilename'] as String? ?? 'imagen.jpg',
      );
    }

    final recomendaciones = (data['recomendaciones'] as List?)
            ?.map((r) => r is Map<String, dynamic>
                ? r
                : {'titulo': r.toString(), 'descripcion': ''})
            .toList() ??
        [];

    await ApiService.post('/analisis_ia', {
      'resultado': data['resultado'],
      'confianza': data['confianza'],
      'severidad': data['severidad'],
      'nombre_cientifico': data['nombreCientifico'],
      'id_estado_analisis': 1,
      'recomendaciones': recomendaciones,
      if (idImagen != null) 'id_imagen': idImagen,
    });
  }

  static String _fechaActual() {
    final hoy = DateTime.now();
    return '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}'
        'T${hoy.hour.toString().padLeft(2, '0')}:${hoy.minute.toString().padLeft(2, '0')}:00.000Z';
  }

  static Future<int?> _uploadImagen({
    required int idMonitoreo,
    required Uint8List bytes,
    required String filename,
  }) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${EnvConfig.apiBaseUrl}/imagenes'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['id_monitoreo'] = idMonitoreo.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'imagen',
        bytes,
        filename: filename,
      ),
    );
    final streamed = await request.send().timeout(const Duration(minutes: 2));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201) {
      final jsonData = jsonDecode(res.body);
      return jsonData['data']?['idImagen'] as int?;
    }
    throw Exception('Error subiendo imagen: ${res.statusCode}');
  }
}

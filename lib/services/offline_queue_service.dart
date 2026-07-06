import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineQueueItem {
  final String id;
  final String tipo;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  OfflineQueueItem({
    required this.id,
    required this.tipo,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'tipo': tipo,
        'data': data,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory OfflineQueueItem.fromMap(Map<String, dynamic> map) =>
      OfflineQueueItem(
        id: map['id'] as String,
        tipo: map['tipo'] as String,
        data: Map<String, dynamic>.from(map['data'] as Map),
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
}

class OfflineQueueService {
  static const String _boxName = 'offline_queue';
  static late Box<String> _box;
  static final ValueNotifier<int> pendingCount = ValueNotifier(0);

  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    pendingCount.value = _box.length;
  }

  static Future<String> enqueueDiagnostico({
    required int? idCultivo,
    required Uint8List? imagenBytes,
    required String imagenFilename,
    required String observaciones,
    required String resultado,
    required String confianza,
    required String severidad,
    required String nombreCientifico,
    required List<Map<String, dynamic>> recomendaciones,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = OfflineQueueItem(
      id: id,
      tipo: 'diagnostico',
      data: {
        'idCultivo': idCultivo,
        'imagenBytes':
            imagenBytes != null ? base64Encode(imagenBytes) : null,
        'imagenFilename': imagenFilename,
        'observaciones': observaciones,
        'resultado': resultado,
        'confianza': confianza,
        'severidad': severidad,
        'nombreCientifico': nombreCientifico,
        'recomendaciones': recomendaciones,
      },
      timestamp: DateTime.now(),
    );
    await _box.put(id, jsonEncode(item.toMap()));
    pendingCount.value = _box.length;
    return id;
  }

  static List<OfflineQueueItem> getAll() {
    final items = <OfflineQueueItem>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        items.add(OfflineQueueItem.fromMap(
            Map<String, dynamic>.from(jsonDecode(raw) as Map)));
      } catch (_) {}
    }
    items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return items;
  }

  static Future<void> remove(String id) async {
    await _box.delete(id);
    pendingCount.value = _box.length;
  }

  static Future<void> clear() async {
    await _box.clear();
    pendingCount.value = 0;
  }
}

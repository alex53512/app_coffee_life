import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'api_cache';
  static const Duration _defaultTtl = Duration(minutes: 15);

  static late Box<String> _box;

  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  static bool get isInitialized => _box.isOpen;

  static String _key(String endpoint) => 'get:$endpoint';

  static Future<void> set(String endpoint, dynamic data, {Duration? ttl}) async {
    final expiry = DateTime.now().add(ttl ?? _defaultTtl).millisecondsSinceEpoch;
    await _box.put(_key(endpoint), jsonEncode({
      'data': data,
      'expiry': expiry,
    }));
  }

  static dynamic get(String endpoint) {
    final raw = _box.get(_key(endpoint));
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map;
      final expiry = entry['expiry'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiry) {
        _box.delete(_key(endpoint));
        return null;
      }
      return entry['data'];
    } catch (_) {
      _box.delete(_key(endpoint));
      return null;
    }
  }

  static bool has(String endpoint) => get(endpoint) != null;

  static Future<void> clear() async => _box.clear();

  static Future<void> clearExpired() async {
    final keys = _box.keys.toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final k in keys) {
      final raw = _box.get(k);
      if (raw == null) continue;
      try {
        final entry = jsonDecode(raw) as Map;
        if ((entry['expiry'] as int) < now) {
          await _box.delete(k);
        }
      } catch (_) {
        await _box.delete(k);
      }
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_service.dart';

class WebSocketService extends ChangeNotifier {
  static final WebSocketService instance = WebSocketService._();
  WebSocketService._();

  io.Socket? _socket;
  bool _connected = false;
  int? _idUsuario;

  bool get connected => _connected;

  Future<void> connect() async {
    if (_connected) return;

    final usuario = await AuthService.getUsuario();
    _idUsuario = usuario?['idUsuario'] as int?;
    if (_idUsuario == null) return;

    _socket = io.io(
      'https://backend-coffe-lifee-production-191b.up.railway.app',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      _socket!.emit('unirse', _idUsuario);
      debugPrint('Socket.IO conectado como usuario $_idUsuario');
      notifyListeners();
    });

    _socket!.on('notificacion', (data) {
      debugPrint('Notificación recibida: $data');
      _onNotificacion(data);
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      debugPrint('Socket.IO desconectado');
      notifyListeners();
    });

    _socket!.onError((error) {
      debugPrint('Socket.IO error: $error');
    });

    _socket!.connect();
  }

  void _onNotificacion(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final tipo = map['tipo'] ?? map['type'] ?? 'notificacion';
    final callbacks = _listeners[tipo] ?? [];
    for (final cb in callbacks) {
      cb(map);
    }
    final callbacksGenericos = _listeners['*'] ?? [];
    for (final cb in callbacksGenericos) {
      cb(map);
    }
  }

  final Map<String, List<void Function(Map<String, dynamic>)>> _listeners = {};

  void on(String event, void Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, void Function(Map<String, dynamic>) callback) {
    _listeners[event]?.remove(callback);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _idUsuario = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _listeners.clear();
    super.dispose();
  }
}

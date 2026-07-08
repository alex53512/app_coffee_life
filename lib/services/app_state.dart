import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  Map<String, dynamic>? _fincaSeleccionada;
  List _cultivosFinca = [];
  Map<String, dynamic>? _cultivoSeleccionado;
  String _nivelRoya = 'Sin datos';
  String? _fotoPerfil;
  final List<Map<String, dynamic>> _notificacionesPendientes = [];
  int _notificacionesNoLeidas = 0;
  int _ultimoConteoServer = -1;
  int _nuevasDesdeUltimoAviso = 0;
  Map<String, dynamic>? _ultimaNotificacionNueva;

  Timer? _pollTimer;

  /// Cuántas notificaciones nuevas no han sido mostradas aún en diálogo.
  int get nuevasDesdeUltimoAviso => _nuevasDesdeUltimoAviso;

  /// Última notificación nueva (para mostrar en el diálogo).
  Map<String, dynamic>? get ultimaNotificacionNueva => _ultimaNotificacionNueva;

  void reiniciarContadorAvisos() {
    _nuevasDesdeUltimoAviso = 0;
  }

  void iniciarPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _verificarNotificaciones();
    });
    _verificarNotificaciones();
  }

  void detenerPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _verificarNotificaciones() async {
    if (_fincaSeleccionada == null) return;
    try {
      final data = await ApiService.get('/recomendaciones');
      final lista = data is List ? data : (data['data'] ?? []);
      final int noLeidas =
          lista.where((r) => r['leida'] != true && r['leida'] != 1).length;
      if (_ultimoConteoServer == -1) {
        _ultimoConteoServer = noLeidas;
        _notificacionesNoLeidas = noLeidas;
        notifyListeners();
        return;
      }
      if (noLeidas > _ultimoConteoServer) {
        final int nuevas = noLeidas - _ultimoConteoServer;
        _notificacionesNoLeidas += nuevas;
        _nuevasDesdeUltimoAviso += nuevas;
        if (lista.isNotEmpty) {
          _ultimaNotificacionNueva =
              Map<String, dynamic>.from(lista[0] as Map);
        }
        for (var i = 0; i < nuevas && i < lista.length; i++) {
          _notificacionesPendientes
              .add(Map<String, dynamic>.from(lista[i] as Map));
        }
      }
      _ultimoConteoServer = noLeidas;
      notifyListeners();
    } catch (_) {}
  }

  Map<String, dynamic>? get fincaSeleccionada => _fincaSeleccionada;
  List get cultivosFinca => List.unmodifiable(_cultivosFinca);
  Map<String, dynamic>? get cultivoSeleccionado => _cultivoSeleccionado;
  String get nivelRoya => _nivelRoya;
  String? get fotoPerfil => _fotoPerfil;
 
  String get cultivoNombre =>
      _cultivoSeleccionado?['nombreCultivo'] ??
      _cultivoSeleccionado?['nombre_cultivo'] ??
      '';
 
  dynamic get idFincaSeleccionada =>
      _fincaSeleccionada?['idFinca'] ?? _fincaSeleccionada?['id_finca'];
 
  dynamic get idCultivoSeleccionado =>
      _cultivoSeleccionado?['idCultivo'] ?? _cultivoSeleccionado?['id_cultivo'];
 
  List get idsCultivosFinca =>
      _cultivosFinca.map((c) => c['idCultivo'] ?? c['id_cultivo']).toList();

  List<Map<String, dynamic>> get notificacionesPendientes =>
      List.unmodifiable(_notificacionesPendientes);
  int get notificacionesNoLeidas => _notificacionesNoLeidas;

  void agregarNotificacion(Map<String, dynamic> notif) {
    _notificacionesPendientes.add(Map.from(notif));
    _notificacionesNoLeidas++;
    _nuevasDesdeUltimoAviso++;
    _ultimaNotificacionNueva = Map.from(notif);
    notifyListeners();
  }

  void marcarNotificacionesLeidas() {
    _notificacionesNoLeidas = 0;
    _ultimoConteoServer = -1;
    notifyListeners();
  }

 
  void setFinca(Map<String, dynamic> finca, List cultivos) {
    _fincaSeleccionada   = Map<String, dynamic>.from(finca);
    _cultivosFinca       = List.from(cultivos);
    _cultivoSeleccionado = null;
    _nivelRoya           = 'Sin datos';
    _notificacionesPendientes.clear();
    _notificacionesNoLeidas = 0;
    _nuevasDesdeUltimoAviso = 0;
    _ultimoConteoServer = -1;
    _ultimaNotificacionNueva = null;
    _verificarNotificaciones();
    notifyListeners();
  }
 
  void setCultivo(Map<String, dynamic>? cultivo, String nivelRoya) {
    _cultivoSeleccionado = cultivo != null
        ? Map<String, dynamic>.from(cultivo)
        : null;
    _nivelRoya = nivelRoya;
    notifyListeners();
  }
 
  void setFotoPerfil(String url) {
    _fotoPerfil = url;
    notifyListeners();
  }
 
  void notifyMonitoreoGuardado() {
    notifyListeners();
  }
  void reset() {
    detenerPolling();
    _fincaSeleccionada   = null;
    _cultivosFinca       = [];
    _cultivoSeleccionado = null;
    _nivelRoya           = 'Sin datos';
    _fotoPerfil          = null;
    _notificacionesPendientes.clear();
    _notificacionesNoLeidas = 0;
    _ultimoConteoServer = -1;
    notifyListeners();
  }
}
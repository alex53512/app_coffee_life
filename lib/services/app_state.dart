import 'package:flutter/foundation.dart';
 
/// Singleton global que comparte finca, cultivo y nivel de roya entre pantallas.
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

  // ── Getters ────────────────────────────────────────────────
  Map<String, dynamic>? get fincaSeleccionada => _fincaSeleccionada;
  List get cultivosFinca => List.unmodifiable(_cultivosFinca);
  Map<String, dynamic>? get cultivoSeleccionado => _cultivoSeleccionado;
  String get nivelRoya => _nivelRoya;
  String? get fotoPerfil => _fotoPerfil;
 
  String get cultivoNombre =>
      _cultivoSeleccionado?['nombreCultivo'] ??
      _cultivoSeleccionado?['nombre_cultivo'] ??
      '';
 
  /// ID de la finca seleccionada actualmente (null si ninguna).
  dynamic get idFincaSeleccionada =>
      _fincaSeleccionada?['idFinca'] ?? _fincaSeleccionada?['id_finca'];
 
  /// ID del cultivo seleccionado actualmente (null si ninguno).
  dynamic get idCultivoSeleccionado =>
      _cultivoSeleccionado?['idCultivo'] ?? _cultivoSeleccionado?['id_cultivo'];
 
  /// IDs de todos los cultivos de la finca activa.
  List get idsCultivosFinca =>
      _cultivosFinca.map((c) => c['idCultivo'] ?? c['id_cultivo']).toList();

  // ── Notificaciones ─────────────────────────────────────────
  List<Map<String, dynamic>> get notificacionesPendientes =>
      List.unmodifiable(_notificacionesPendientes);
  int get notificacionesNoLeidas => _notificacionesNoLeidas;

  void agregarNotificacion(Map<String, dynamic> notif) {
    _notificacionesPendientes.add(Map.from(notif));
    _notificacionesNoLeidas++;
    notifyListeners();
  }

  void marcarNotificacionesLeidas() {
    _notificacionesNoLeidas = 0;
    notifyListeners();
  }

  // ── Setters ────────────────────────────────────────────────
 
  /// Llamar desde HomeScreen cuando cambia la finca.
  void setFinca(Map<String, dynamic> finca, List cultivos) {
    _fincaSeleccionada   = Map<String, dynamic>.from(finca);
    _cultivosFinca       = List.from(cultivos);
    _cultivoSeleccionado = null;
    _nivelRoya           = 'Sin datos';
    notifyListeners();
  }
 
  /// Llamar desde HomeScreen cuando el usuario toca un cultivo.
  void setCultivo(Map<String, dynamic>? cultivo, String nivelRoya) {
    _cultivoSeleccionado = cultivo != null
        ? Map<String, dynamic>.from(cultivo)
        : null;
    _nivelRoya = nivelRoya;
    notifyListeners();
  }
 
  /// Llamar desde ProfileScreen cuando el usuario sube una foto nueva.
  void setFotoPerfil(String url) {
    _fotoPerfil = url;
    notifyListeners();
  }
 
  /// Llamar desde DiagnosticScreen después de guardar un monitoreo.
  void notifyMonitoreoGuardado() {
    notifyListeners();
  }
  /// Limpiar todo al cerrar sesión o cambiar de usuario.
void reset() {
  _fincaSeleccionada   = null;
  _cultivosFinca       = [];
  _cultivoSeleccionado = null;
  _nivelRoya           = 'Sin datos';
  _fotoPerfil          = null;
  _notificacionesPendientes.clear();
  _notificacionesNoLeidas = 0;
  notifyListeners();
}
}
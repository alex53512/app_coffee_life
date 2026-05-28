import 'package:flutter/foundation.dart';

/// Singleton global que comparte finca, cultivo y nivel de roya entre pantallas.
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  Map<String, dynamic>? _fincaSeleccionada;
  List _cultivosFinca = [];
  Map<String, dynamic>? _cultivoSeleccionado;
  String _nivelRoya = 'Sin datos';
  String? _fotoPerfil; // ← NUEVO

  // ── Getters ────────────────────────────────────────────────
  Map<String, dynamic>? get fincaSeleccionada => _fincaSeleccionada;
  List get cultivosFinca => List.unmodifiable(_cultivosFinca);
  Map<String, dynamic>? get cultivoSeleccionado => _cultivoSeleccionado;
  String get nivelRoya => _nivelRoya;
  String? get fotoPerfil => _fotoPerfil; // ← NUEVO

  String get cultivoNombre =>
      _cultivoSeleccionado?['nombreCultivo'] ??
      _cultivoSeleccionado?['nombre_cultivo'] ??
      '';

  // ── Setters ────────────────────────────────────────────────

  /// Llamar desde HomeScreen cuando cambia la finca.
  void setFinca(Map<String, dynamic> finca, List cultivos) {
    _fincaSeleccionada    = Map<String, dynamic>.from(finca);
    _cultivosFinca        = List.from(cultivos);
    _cultivoSeleccionado  = null;
    _nivelRoya            = 'Sin datos';
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

  /// Llamar desde ProfileScreen cuando el usuario sube una foto nueva. ← NUEVO
  void setFotoPerfil(String url) {
    _fotoPerfil = url;
    notifyListeners();
  }

  /// Llamar desde DiagnosticScreen después de guardar un monitoreo.
  /// Hace que MontoreosScreen recargue la lista automáticamente.
  void notifyMonitoreoGuardado() {
    notifyListeners();
  }
}
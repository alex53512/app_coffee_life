import 'package:flutter/foundation.dart';
 
/// Singleton global que comparte finca, cultivo y nivel de roya entre pantallas.
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();
 
  Map<String, dynamic>? _fincaSeleccionada;
  List _cultivosFinca = [];
  Map<String, dynamic>? _cultivoSeleccionado;
  String _nivelRoya = 'Sin datos';
 
  // ── Getters ────────────────────────────────────────────────
  Map<String, dynamic>? get fincaSeleccionada => _fincaSeleccionada;
  List get cultivosFinca => List.unmodifiable(_cultivosFinca);
  Map<String, dynamic>? get cultivoSeleccionado => _cultivoSeleccionado;
  String get nivelRoya => _nivelRoya;
 
  String get cultivoNombre =>
      _cultivoSeleccionado?['nombreCultivo'] ??
      _cultivoSeleccionado?['nombre_cultivo'] ??
      '';
 
  // ── Setters ────────────────────────────────────────────────
 
  /// Llamar desde HomeScreen cuando cambia la finca.
  /// Resetea el cultivo seleccionado automáticamente.
  void setFinca(Map<String, dynamic> finca, List cultivos) {
    _fincaSeleccionada    = Map<String, dynamic>.from(finca);
    _cultivosFinca        = List.from(cultivos);
    _cultivoSeleccionado  = null;
    _nivelRoya            = 'Sin datos';
    notifyListeners();
  }
 
  /// Llamar desde HomeScreen cuando el usuario toca un cultivo.
  /// [cultivo] = null cuando se deselecciona.
  /// [nivelRoya] = 'Bajo' | 'Medio' | 'Alto' | 'Sin datos'
  void setCultivo(Map<String, dynamic>? cultivo, String nivelRoya) {
    _cultivoSeleccionado = cultivo != null
        ? Map<String, dynamic>.from(cultivo)
        : null;
    _nivelRoya = nivelRoya;
    notifyListeners();
  }
}



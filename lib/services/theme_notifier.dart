import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _oscuro = false;

  bool get oscuro => _oscuro;

  ThemeNotifier() {
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    _oscuro = prefs.getBool('modo_oscuro') ?? false;
    notifyListeners();
  }

  Future<void> toggle(bool valor) async {
    _oscuro = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modo_oscuro', valor);
    notifyListeners();
  }
}

class ThemeProvider extends InheritedWidget {
  final ThemeNotifier notifier;

  const ThemeProvider({
    super.key,
    required this.notifier,
    required super.child,
  });

  static ThemeProvider? watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  static ThemeProvider? read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ThemeProvider>();
    return scope;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) => oldWidget.notifier != notifier;
}

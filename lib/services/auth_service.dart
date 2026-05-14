import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3333';
  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'auth_user';

  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token']);
      await prefs.setString(_userKey, jsonEncode(data['usuario'] ?? data['data']));
      return {'success': true, 'data': data['usuario'] ?? data['data']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Error al iniciar sesión'};
    }
  }

  static Future<Map<String, dynamic>> registrarCafetero({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String telefono,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cafeteros'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre, 'apellido': apellido,
        'correo': correo, 'password': password, 'telefono': telefono,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {'success': true, 'data': data['usuario'] ?? data['data']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Error al registrarse'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
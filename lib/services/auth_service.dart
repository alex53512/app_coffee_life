import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'websocket_service.dart';

class AuthService {
 static const String baseUrl = 'https://backend-coffe-lifee-production-191b.up.railway.app';

  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'auth_user';

  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        AppState.instance.reset();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        await prefs.setString(_userKey, jsonEncode(data['usuario'] ?? data['data']));
        WebSocketService.instance.connect();
        return {'success': true, 'data': data['usuario'] ?? data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Correo o contraseña incorrectos'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'El servidor no responde. Intenta de nuevo.'};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor. Verifica tu conexión a internet.'};
    }
  }

  static Future<Map<String, dynamic>> registrarCafetero({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required String telefono,
    required String cedula,
    required String tipoDocumento,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombre':        nombre,
              'apellido':      apellido,
              'correo':        correo,
              'password':      password,
              'telefono':      telefono,
              'cedula':        cedula,
              'tipoDocumento': tipoDocumento,
              'idRol':         3,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        AppState.instance.reset();
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al registrarse'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'El servidor no responde. Intenta de nuevo.'};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor. Verifica tu conexión a internet.'};
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
    WebSocketService.instance.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    AppState.instance.reset();
  }

  static Future<Map<String, dynamic>> recuperarPassword({
    required String correo,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/recuperar-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo}),
          )
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al procesar solicitud'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'El servidor está tardando mucho. Revisa tu correo en unos segundos o intenta de nuevo.'};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor. Verifica tu conexión a internet.'};
    }
  }

  static Future<Map<String, dynamic>> verificarToken({
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verificar-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Código inválido'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'El servidor no responde. Intenta de nuevo.'};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor. Verifica tu conexión a internet.'};
    }
  }

  static Future<Map<String, dynamic>> restablecerPassword({
    required String token,
    required String nuevaPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/restablecer-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'nuevaPassword': nuevaPassword}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al restablecer contraseña'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'El servidor no responde. Intenta de nuevo.'};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor. Verifica tu conexión a internet.'};
    }
  }
}
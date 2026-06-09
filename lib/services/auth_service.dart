import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
 
class AuthService {
 static const String baseUrl = 'https://backend-coffe-lifee-production.up.railway.app';
 
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
    required String cedula,
    required String tipoDocumento,
  }) async {
    // Probamos los dos formatos de nombre de campo más comunes
    // (snake_case y camelCase) para que funcione sin importar cómo
    // esté configurado el backend.
    final body = {
      'nombre':         nombre,
      'apellido':       apellido,
      'correo':         correo,
      'password':       password,
      'telefono':       telefono,
 
      // Cédula — enviamos ambos nombres por si el backend usa uno u otro
      'cedula':         cedula,
      'numero_documento': cedula,
 
      // Tipo de documento — ídem
      'tipoDocumento':  tipoDocumento,
      'tipo_documento': tipoDocumento,
 
      // Rol fijo de caficultor
      'idRol':          4,
      'id_rol':         4,
    };
 
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
 
      // Intentar decodificar la respuesta
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Si el cuerpo no es JSON mostramos el texto crudo
        return {
          'success': false,
          'message': 'Error del servidor: ${response.body}',
        };
      }
 
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? data};
      }
 
      // 409 = correo ya registrado
      if (response.statusCode == 409) {
        return {
          'success': false,
          'message': 'Este correo ya está registrado. Intenta iniciar sesión.',
        };
      }
 
      // Cualquier otro error — mostramos el mensaje real del servidor
      final mensajeServidor = data['message'] ??
          data['error'] ??
          data['errors']?.toString() ??
          'Error ${response.statusCode}';
 
      return {'success': false, 'message': mensajeServidor};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor: $e'};
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
 
  static Future<Map<String, dynamic>> recuperarPassword({
    required String correo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al procesar solicitud'};
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }
 
  static Future<Map<String, dynamic>> verificarToken({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verificar-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Código inválido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }
 
  static Future<Map<String, dynamic>> restablecerPassword({
    required String token,
    required String nuevaPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/restablecer-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'nuevaPassword': nuevaPassword}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al restablecer contraseña'};
      }
    } catch (e) {
      return {'success': false, 'message': 'No se pudo conectar al servidor'};
    }
  }
}
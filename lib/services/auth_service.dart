import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:3333';

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
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'password': password,
        'telefono': telefono,
      }),
    );
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }
}
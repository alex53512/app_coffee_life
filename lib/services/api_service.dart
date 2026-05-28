import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
 
class ApiService {
static const String baseUrl = 'http://localhost:3333';
 
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
 
  static Future<dynamic> get(String endpoint) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
 
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
 
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
 
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
 
  static Future<dynamic> delete(String endpoint) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : {};
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }
 
  /// Sube una imagen al backend vinculada a un monitoreo.
  /// Devuelve el idImagen creado, o null si falla.
  static Future<int?> uploadImagen({
    required int idMonitoreo,
    required Uint8List bytes,
    required String filename,
  }) async {
    final token = await AuthService.getToken();
 
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/imagenes'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['id_monitoreo'] = idMonitoreo.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'imagen',
        bytes,
        filename: filename.isNotEmpty ? filename : 'imagen.jpg',
      ),
    );
 
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
 
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return data['data']?['idImagen'] as int?;
    }
    throw Exception('Error subiendo imagen ${res.statusCode}: ${res.body}');
  }
}
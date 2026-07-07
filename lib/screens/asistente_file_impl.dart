import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Copia HTML + GLB al directorio temporal y devuelve la ruta del HTML.
/// Se usa en iOS donde loadFile sí soporta XHR a file:// correctamente.
Future<String> copiarAvatarAssetsATemp() async {
  final dir = await getTemporaryDirectory();
  final avatarDir = Directory('${dir.path}/coffee_avatar');
  if (!await avatarDir.exists()) {
    await avatarDir.create(recursive: true);
  }

  final htmlFile = File('${avatarDir.path}/asistente.html');
  final glbFile = File('${avatarDir.path}/avatar.glb');

    final htmlData = await rootBundle.load('assets/html/asistente.html');
    await htmlFile.writeAsBytes(htmlData.buffer.asUint8List());
    if (!await glbFile.exists()) {
      final glbData = await rootBundle.load('assets/html/avatar.glb');
      await glbFile.writeAsBytes(glbData.buffer.asUint8List());
    }

    return htmlFile.path;
}

/// Servidor HTTP local en 127.0.0.1 para servir assets del avatar.
/// Se usa en Android porque file:// XHR está bloqueado (Android 11+).
class LocalAvatarServer {
  HttpServer? _server;

  Future<String> start() async {
    final dir = await getTemporaryDirectory();
    final basePath = '${dir.path}/coffee_avatar';
    final avatarDir = Directory(basePath);
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final htmlFile = File('$basePath/asistente.html');
    final glbFile = File('$basePath/avatar.glb');

      final htmlData = await rootBundle.load('assets/html/asistente.html');
      await htmlFile.writeAsBytes(htmlData.buffer.asUint8List());
      if (!await glbFile.exists()) {
        final glbData = await rootBundle.load('assets/html/avatar.glb');
        await glbFile.writeAsBytes(glbData.buffer.asUint8List());
      }

      _server = await HttpServer.bind('127.0.0.1', 0);
    final port = _server!.port;

    _server!.listen((HttpRequest request) {
      final path = request.uri.path;
      if (path == '/asistente.html' || path == '/avatar.glb') {
        final file = File('$basePath$path');
        if (file.existsSync()) {
          request.response.statusCode = 200;
          if (path.endsWith('.html')) {
            request.response.headers.contentType = ContentType.html;
          } else if (path.endsWith('.glb')) {
            request.response.headers.contentType =
                ContentType('model', 'gltf-binary');
          }
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          request.response.add(file.readAsBytesSync());
          request.response.close();
          return;
        }
      }
      request.response.statusCode = 404;
      request.response.close();
    });

    return 'http://127.0.0.1:$port/asistente.html';
  }

  void stop() {
    _server?.close(force: true);
    _server = null;
  }
}

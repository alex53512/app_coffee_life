// asistente_web_impl.dart
// Este archivo SOLO se compila cuando el target es web.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class AvatarWebHandler {
  html.IFrameElement? _iframe;

  void register() {
    ui.platformViewRegistry.registerViewFactory(
      'avatar-view',
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'assets/html/asistente.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'autoplay';
        _iframe = iframe;
        return iframe;
      },
    );
  }

  void postMessage(String msg) {
    _iframe?.contentWindow?.postMessage(msg, '*');
  }

  Widget buildView() {
    return const HtmlElementView(viewType: 'avatar-view');
  }

  /// Convierte una URL tipo "blob:http://localhost/xxxx" (lo que devuelve
  /// el paquete `record` al grabar en el navegador) en los bytes reales
  /// del audio, para poder enviarlos por HTTP (multipart) al backend.
  Future<Uint8List> blobUrlToBytes(String blobUrl) async {
    final xhr = await html.HttpRequest.request(
      blobUrl,
      responseType: 'arraybuffer',
    );
    final buffer = xhr.response as ByteBuffer;
    return buffer.asUint8List();
  }
}
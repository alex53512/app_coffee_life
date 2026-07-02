// asistente_web_stub.dart
// Este archivo se usa en Android/iOS donde dart:html no existe.
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AvatarWebHandler {
  void register() {}
  void postMessage(String msg) {}
  Widget buildView() => const SizedBox.shrink();

  // No se usa en Android/iOS (solo se llama dentro de `if (kIsWeb)`
  // en asistente_screen.dart), pero debe existir para que compile.
  Future<Uint8List> blobUrlToBytes(String blobUrl) async {
    return Uint8List(0);
  }
}
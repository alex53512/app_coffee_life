import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

// dart:html y dart:ui_web SOLO en web
import 'asistente_web_stub.dart'
    if (dart.library.html) 'asistente_web_impl.dart';

// dart:io SOLO en mobile/desktop (para copiar assets a temp)
import 'asistente_file_stub.dart'
    if (dart.library.io) 'asistente_file_impl.dart';

class AsistenteScreen extends StatefulWidget {
  final String genero;

  const AsistenteScreen({super.key, this.genero = 'femenino'});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen>
    with TickerProviderStateMixin {

  static const String _baseUrl =
      'https://chatbot-ia-production.up.railway.app';

  final AudioRecorder _recorder    = AudioRecorder();
  final AudioPlayer   _audioPlayer = AudioPlayer();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  StreamSubscription? _playerSub;
  late WebViewController _webViewController;

  bool _grabando     = false;
  bool _procesando   = false;
  bool _hablando     = false;
  bool _webViewListo = false;
  String? _rutaAudio;

  final List<Map<String, dynamic>> _mensajes = [];
  final List<String> _colaMensajes = [];

  late AnimationController _ondaCtrl;

  // Manejador web (iframe) — solo activo en web
  late final AvatarWebHandler _webHandler;

  // Servidor HTTP local (solo Android) para evitar restricciones file://
  LocalAvatarServer? _server;

  bool get _esMasculino => widget.genero.toLowerCase() == 'masculino';
  String get _nombreAsistente  => _esMasculino ? 'Yimmi' : 'Valentina';
  String get _saludoBienvenida => _esMasculino
      ? 'Hola, soy Yimmi, tu asistente de CoffeeLife. ¿En qué puedo ayudarte?'
      : 'Hola, soy Valentina, tu asistente de CoffeeLife. ¿En qué puedo ayudarte?';

  @override
  void initState() {
    super.initState();

    _ondaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (kIsWeb) {
      _webHandler = AvatarWebHandler();
      _webHandler.register();
    } else {
      _server = LocalAvatarServer();
      _iniciarWebView();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1500));
      await _hablarBienvenida();
    });
  }

  // ── WebView (Android / iOS) ──
  Future<void> _iniciarWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setOnConsoleMessage((message) {
        debugPrint('WEBVIEW-JS [${message.level.name}]: ${message.message}');
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          setState(() => _webViewListo = true);
          _ejecutarColaMensajes();
          _iniciarCargaAvatar();
        },
        onWebResourceError: (error) {
          debugPrint(
              'WEBVIEW-ERROR: ${error.errorCode} ${error.description} '
              '(url: ${error.url})');
        },
      ));

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.windows) {
      // Android 11+ y Windows bloquean XHR a file:// → usamos servidor HTTP local
      final url = await _server!.start();
      await _webViewController.loadRequest(Uri.parse(url));
    } else {
      // iOS: WKWebView maneja file:// XHR correctamente
      final htmlPath = await copiarAvatarAssetsATemp();
      if (htmlPath.isNotEmpty) {
        await _webViewController.loadFile(htmlPath);
      } else {
        await _webViewController.loadFlutterAsset('assets/html/asistente.html');
      }
    }
  }

  void _ejecutarColaMensajes() {
    for (final msg in _colaMensajes) {
      _webViewController.runJavaScript('window.recibirMensaje("$msg")');
    }
    _colaMensajes.clear();
  }

  void _iniciarCargaAvatar() {
    _webViewController.runJavaScript('window._deferredLoad()');
  }

  // ── Enviar mensaje al avatar ──
  void _enviarMensajeWebView(String mensaje) {
    if (kIsWeb) {
      _webHandler.postMessage(mensaje);
      return;
    }
    if (!_webViewListo) {
      _colaMensajes.add(mensaje);
      return;
    }
    _webViewController.runJavaScript('window.recibirMensaje("$mensaje")');
  }

  Future<void> _enviarTexto() async {
    final texto = _textCtrl.text.trim();
    if (texto.isEmpty) return;
    _textCtrl.clear();
    _agregarMensaje(texto, true);
    setState(() => _procesando = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': texto}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final respuesta = data['response'] as String;
        _agregarMensaje(respuesta, false);
        // Intentar reproducir con voz
        try {
          final tts = await http.post(
            Uri.parse('$_baseUrl/chatbot/tts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': respuesta}),
          );
          if (mounted && tts.statusCode == 200) {
            final ct = tts.headers['content-type'] ?? '';
            if (ct.startsWith('audio/mpeg')) {
              setState(() => _hablando = true);
              _enviarMensajeWebView('hablar');
              await _reproducirAudio(tts.bodyBytes);
            }
          }
        } catch (_) {}
      } else {
        _agregarMensaje('Lo siento, no pude procesar tu mensaje.', false);
      }
    } catch (e) {
      if (!mounted) return;
      _agregarMensaje('Error de conexión. Intenta de nuevo.', false);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _server?.stop();
    _ondaCtrl.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Bienvenida ──
  Future<void> _hablarBienvenida() async {
    if (!mounted) return;
    setState(() => _procesando = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': _saludoBienvenida}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final ct = response.headers['content-type'] ?? '';
        if (ct.startsWith('audio/mpeg')) {
          setState(() { _procesando = false; _hablando = true; });
          _enviarMensajeWebView('hablar');
          await _reproducirAudio(response.bodyBytes);
        } else {
          setState(() => _procesando = false);
          _agregarMensaje(_saludoBienvenida, false);
        }
      } else {
        setState(() => _procesando = false);
        _agregarMensaje(_saludoBienvenida, false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      _agregarMensaje(_saludoBienvenida, false);
    }
  }

  // ── Grabación ──
  Future<void> _iniciarGrabacion() async {
    try {
      final permiso = await _recorder.hasPermission();
      if (!permiso) {
        _mostrarError('No se otorgó permiso para el micrófono.');
        return;
      }

      if (kIsWeb) {
        // En la web no existe sistema de archivos real: el paquete `record`
        // graba en memoria y usa MediaRecorder del navegador, que solo
        // soporta bien el códec Opus (no aacLc). El "path" que se le pasa
        // aquí es solo un nombre simbólico, no se usa como archivo real.
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: 'audio_web.webm',
        );
      } else {
        final dir = await getTemporaryDirectory();
        _rutaAudio =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _rutaAudio!,
        );
      }

      if (!mounted) return;
      setState(() => _grabando = true);
      _ondaCtrl.repeat(reverse: true);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('No se pudo iniciar la grabación: $e');
      setState(() => _grabando = false);
    }
  }

  Future<void> _detenerGrabacion() async {
    final path = await _recorder.stop();
    _ondaCtrl.stop();
    if (!mounted) return;
    setState(() { _grabando = false; _procesando = true; });
    if (path != null) await _enviarAudio(path);
  }

  Future<void> _enviarAudio(String path) async {
    try {
      final uri = Uri.parse('$_baseUrl/chatbot/audio');
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        final bytes = await _webHandler.blobUrlToBytes(path);
        request.files.add(http.MultipartFile.fromBytes(
          'file', bytes, filename: 'audio_web.webm',
        ));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('file', path));
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 30));

      if (kIsWeb) {
        final response = await http.Response.fromStream(streamed);
        if (!mounted) return;
        if (response.statusCode == 200) {
          final ct = response.headers['content-type'] ?? '';
          if (ct.startsWith('audio/mpeg')) {
            _agregarMensaje('(audio enviado)', true);
            setState(() { _procesando = false; _hablando = true; });
            _enviarMensajeWebView('hablar');
            await _reproducirAudio(response.bodyBytes);
          } else {
            final data = jsonDecode(response.body);
            _agregarMensaje(data['transcription'] ?? '', true);
            _agregarMensaje(data['response'], false);
            setState(() => _procesando = false);
          }
        } else {
          _mostrarError('Error del servidor: ${response.statusCode}');
          setState(() => _procesando = false);
        }
      } else {
        final response = await http.Response.fromStream(streamed);
        if (!mounted) return;
        if (response.statusCode == 200) {
          final ct = response.headers['content-type'] ?? '';
          if (ct.startsWith('audio/mpeg')) {
            _agregarMensaje('(audio enviado)', true);
            setState(() { _procesando = false; _hablando = true; });
            _enviarMensajeWebView('hablar');
            await _reproducirAudio(response.bodyBytes);
          } else {
            final data = jsonDecode(response.body);
            _agregarMensaje(data['transcription'] ?? '', true);
            _agregarMensaje(data['response'], false);
            setState(() => _procesando = false);
          }
        } else {
          _mostrarError('Error del servidor: ${response.statusCode}');
          setState(() => _procesando = false);
        }
      }
    } on TimeoutException {
      if (!mounted) return;
      _mostrarError('El servidor tardó demasiado.');
      setState(() => _procesando = false);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error de conexión: $e');
      setState(() => _procesando = false);
    }
  }

  void _agregarMensaje(String texto, bool esUsuario) {
    if (texto.isEmpty) return;
    setState(() {
      _mensajes.add({'texto': texto, 'esUsuario': esUsuario});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _reproducirAudio(Uint8List bytes) async {
    _playerSub?.cancel();
    await _audioPlayer.play(BytesSource(bytes));
    _playerSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _hablando = false);
        _enviarMensajeWebView('parar');
      }
    });
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String get _textoEstado {
    if (_grabando)   return 'Escuchando...';
    if (_procesando) return 'Procesando...';
    if (_hablando)   return 'Respondiendo...';
    return 'Mantén presionado para hablar';
  }

  Color get _colorEstado {
    if (_grabando)                return Colors.red;
    if (_procesando || _hablando) return AppColors.primary;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFEFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(_nombreAsistente,
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text('Asistente CoffeeLife',
              style: GoogleFonts.nunito(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),

          // ── Avatar 3D ──
          Container(
            width: 160,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hablando
                    ? AppColors.primary
                    : const Color(0xFFD4A96A),
                width: _hablando ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withOpacity(_hablando ? 0.4 : 0.15),
                  blurRadius: _hablando ? 20 : 10,
                  spreadRadius: _hablando ? 4 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: kIsWeb
                  ? _webHandler.buildView()
                  : _webViewListo
                      ? WebViewWidget(controller: _webViewController)
                      : Container(
                          color: const Color(0xFFF5F0E8),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  BootstrapIcons.person_circle,
                                  size: 60,
                                  color: AppColors.primary.withOpacity(0.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cargando...',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_grabando)
                AnimatedBuilder(
                  animation: _ondaCtrl,
                  builder: (_, __) => Row(
                    children: List.generate(3, (i) {
                      final h = 6.0 +
                          ((_ondaCtrl.value + i * 0.3) % 1.0) * 14.0;
                      return Container(
                        width: 4, height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              if (_procesando)
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              if (_grabando || _procesando) const SizedBox(width: 8),
              Text(_textoEstado,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _colorEstado)),
            ],
          ),
          if (_mensajes.isEmpty) const Spacer(),

          // ── Mensajes ──
          if (_mensajes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mensajes.length,
                itemBuilder: (context, i) {
                  final msg = _mensajes[i];
                  final esUsuario = msg['esUsuario'] as bool;
                  return Align(
                    alignment: esUsuario
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints:
                          BoxConstraints(maxWidth: 260),
                      decoration: BoxDecoration(
                        color: esUsuario
                            ? AppColors.primary.withOpacity(0.15)
                            : const Color(0xFFF5F0E8),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: esUsuario
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                          bottomRight: esUsuario
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        msg['texto'] as String,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Input de texto ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviarTexto(),
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    style: GoogleFonts.nunito(fontSize: 13),
                  ),
                ),
                if (!_procesando && !_grabando && !_hablando)
                  IconButton(
                    icon: Icon(BootstrapIcons.send,
                        size: 20, color: AppColors.primary),
                    onPressed: _enviarTexto,
                  ),
              ],
            ),
          ),

          // ── Botón micrófono ──
          GestureDetector(
            onTapDown: (_) async {
              if (!_procesando && !_hablando) await _iniciarGrabacion();
            },
            onTapUp: (_) async {
              if (_grabando) await _detenerGrabacion();
            },
            onTapCancel: () async {
              if (_grabando) await _detenerGrabacion();
            },
            child: Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _grabando
                      ? [Colors.red.shade400, Colors.red]
                      : [const Color(0xFF6DBF67), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_grabando ? Colors.red : AppColors.primary)
                        .withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _grabando
                    ? BootstrapIcons.stop_circle
                    : BootstrapIcons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';

class AsistenteScreen extends StatefulWidget {
  final String genero;

  const AsistenteScreen({super.key, this.genero = 'femenino'});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen>
    with TickerProviderStateMixin {

  static const String _baseUrl = 'http://127.0.0.1:8000';

  final AudioRecorder _recorder    = AudioRecorder();
  final AudioPlayer   _audioPlayer = AudioPlayer();

  bool _grabando   = false;
  bool _procesando = false;
  bool _hablando   = false;
  String? _rutaAudio;

  late AnimationController _pulsoCtrl;
  late Animation<double>   _pulsoAnim;
  late AnimationController _ondaCtrl;

  bool get _esMasculino => widget.genero.toLowerCase() == 'masculino';
  String get _nombreAsistente => _esMasculino ? 'Yimmi' : 'Valentina';
  String get _imagenAsistente => _esMasculino
      ? 'assets/images/asistente_yimmi.png'
      : 'assets/images/modelo_personaje_valentina.png';
  String get _saludoBienvenida => _esMasculino
      ? 'Hola, soy Yimmi, tu asistente de CoffeeLife. ¿En qué puedo ayudarte?'
      : 'Hola, soy Valentina, tu asistente de CoffeeLife. ¿En qué puedo ayudarte?';

  @override
  void initState() {
    super.initState();

    _pulsoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulsoAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulsoCtrl, curve: Curves.easeInOut),
    );

    _ondaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      await _hablarBienvenida();
    });
  }

  @override
  void dispose() {
    _pulsoCtrl.dispose();
    _ondaCtrl.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

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
        setState(() { _procesando = false; _hablando = true; });
        await _reproducirAudio(response.bodyBytes);
      } else {
        setState(() => _procesando = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
    }
  }

  Future<void> _iniciarGrabacion() async {
    final permiso = await _recorder.hasPermission();
    if (!permiso) {
      _mostrarError('No se otorgó permiso para el micrófono.');
      return;
    }

    _rutaAudio = '/tmp/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: _rutaAudio!,
    );

    if (!mounted) return;
    setState(() => _grabando = true);
    _ondaCtrl.repeat(reverse: true);
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
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chatbot/audio'));
      request.files.add(await http.MultipartFile.fromPath('file', path));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final audioBytes = response.bodyBytes;
        setState(() { _procesando = false; _hablando = true; });
        await _reproducirAudio(audioBytes);
      } else {
        _mostrarError('Error del servidor: ${response.statusCode}');
        setState(() => _procesando = false);
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

  Future<void> _reproducirAudio(Uint8List bytes) async {
    await _audioPlayer.play(BytesSource(bytes));
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _hablando = false);
    });
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String get _textoEstado {
    if (_grabando)              return 'Escuchando...';
    if (_procesando)            return 'Procesando...';
    if (_hablando)              return 'Respondiendo...';
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
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(_nombreAsistente,
              style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text('Asistente CoffeeLife',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _pulsoAnim,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hablando ? AppColors.primary : const Color(0xFFD4A96A),
                  width: _hablando ? 4 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(_hablando ? 0.4 : 0.15),
                    blurRadius: _hablando ? 20 : 10,
                    spreadRadius: _hablando ? 4 : 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  _imagenAsistente,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_grabando)
                AnimatedBuilder(
                  animation: _ondaCtrl,
                  builder: (_, __) => Row(
                    children: List.generate(3, (i) {
                      final h = 6.0 + ((_ondaCtrl.value + i * 0.3) % 1.0) * 14.0;
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              if (_grabando || _procesando) const SizedBox(width: 8),
              Text(_textoEstado,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _colorEstado)),
            ],
          ),
          const Spacer(),
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
                    color: (_grabando ? Colors.red : AppColors.primary).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _grabando ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
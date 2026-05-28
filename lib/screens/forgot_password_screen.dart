import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 0 = ingresar correo, 1 = verificar código, 2 = nueva contraseña
  int _paso = 0;

  bool _cargando = false;
  String? _error;
  String _correoEnviado = '';

  // Controladores
  final _correoController       = TextEditingController();
  final _codigoController       = TextEditingController();
  final _nuevaPassController    = TextEditingController();
  final _confirmarPassController = TextEditingController();

  bool _verNueva    = false;
  bool _verConfirma = false;

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    _nuevaPassController.dispose();
    _confirmarPassController.dispose();
    super.dispose();
  }

  // ── PASO 1: enviar correo ──────────────────────────────────────────────────
  Future<void> _enviarCodigo() async {
    final correo = _correoController.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }

    setState(() { _cargando = true; _error = null; });

    final result = await AuthService.recuperarPassword(correo: correo);

    setState(() => _cargando = false);

    if (result['success'] == true) {
      setState(() {
        _correoEnviado = correo;
        _paso = 1;
      });
    } else {
      setState(() => _error = result['message']);
    }
  }

  // ── PASO 2: verificar código ───────────────────────────────────────────────
  Future<void> _verificarCodigo() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != 6) {
      setState(() => _error = 'El código debe tener 6 dígitos');
      return;
    }

    setState(() { _cargando = true; _error = null; });

    final result = await AuthService.verificarToken(token: codigo);

    setState(() => _cargando = false);

    if (result['success'] == true) {
      setState(() => _paso = 2);
    } else {
      setState(() => _error = result['message']);
    }
  }

  // ── PASO 3: restablecer contraseña ─────────────────────────────────────────
  Future<void> _restablecerPassword() async {
    final nueva    = _nuevaPassController.text;
    final confirma = _confirmarPassController.text;

    if (nueva.length < 6) {
      setState(() => _error = 'Mínimo 6 caracteres');
      return;
    }
    if (nueva != confirma) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() { _cargando = true; _error = null; });

    final result = await AuthService.restablecerPassword(
      token:         _codigoController.text.trim(),
      nuevaPassword: nueva,
    );

    setState(() => _cargando = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Contraseña restablecida! Ya puedes iniciar sesión'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // volver al login
      }
    } else {
      setState(() => _error = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: Column(
        children: [
          // ── CABECERA VERDE ─────────────────────────────────────────────────
          ClipPath(
            clipper: _OvalBottomClipper(),
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4F8F1F),
                    Color(0xFF4F8F1F),
                    Color.fromARGB(255, 24, 66, 30),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Botón atrás
                    Positioned(
                      top: 0,
                      left: 4,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          if (_paso > 0) {
                            setState(() { _paso--; _error = null; });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    // Ícono + título
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_reset,
                                color: Colors.white, size: 34),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Recuperar contraseña',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── INDICADOR DE PASOS ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: Row(
              children: [
                _indicadorPaso(0, 'Correo'),
                _lineaPaso(0),
                _indicadorPaso(1, 'Código'),
                _lineaPaso(1),
                _indicadorPaso(2, 'Nueva clave'),
              ],
            ),
          ),

          // ── CONTENIDO DEL PASO ACTUAL ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_paso == 0) _buildPaso0(),
                  if (_paso == 1) _buildPaso1(),
                  if (_paso == 2) _buildPaso2(),

                  // Error general
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: GoogleFonts.lato(
                                    color: Colors.red, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _accionPaso,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F8F1F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _textBoton(),
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PASO 0: ingresar correo ────────────────────────────────────────────────
  Widget _buildPaso0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Olvidaste tu contraseña?',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A3A1E))),
        const SizedBox(height: 6),
        Text(
          'Ingresa tu correo y te enviaremos un código de 6 dígitos para recuperarla.',
          style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 28),
        _fieldLabel('CORREO ELECTRÓNICO'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _correoController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
              hint: 'correo@ejemplo.com', icon: Icons.email_outlined),
          style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
        ),
      ],
    );
  }

  // ── PASO 1: verificar código ───────────────────────────────────────────────
  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Revisa tu correo',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A3A1E))),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600),
            children: [
              const TextSpan(text: 'Enviamos un código de 6 dígitos a '),
              TextSpan(
                text: _correoEnviado,
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D6E35)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _fieldLabel('CÓDIGO DE VERIFICACIÓN'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          decoration: _inputDecoration(
            hint: '● ● ● ● ● ●',
            icon: Icons.pin_outlined,
          ).copyWith(
            counterText: '',
            hintStyle: GoogleFonts.lato(
                color: Colors.grey.shade400,
                fontSize: 18,
                letterSpacing: 8),
          ),
          style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A3A1E),
              letterSpacing: 10),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _cargando ? null : _enviarCodigo,
            child: Text(
              '¿No recibiste el código? Reenviar',
              style: GoogleFonts.lato(
                  color: const Color(0xFF2D6E35),
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ── PASO 2: nueva contraseña ───────────────────────────────────────────────
  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nueva contraseña',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A3A1E))),
        const SizedBox(height: 6),
        Text('Elige una contraseña segura de al menos 6 caracteres.',
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 28),
        _fieldLabel('NUEVA CONTRASEÑA'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nuevaPassController,
          obscureText: !_verNueva,
          decoration: _inputDecoration(
            hint: '••••••••',
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                  _verNueva ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF3A7A42), size: 20),
              onPressed: () => setState(() => _verNueva = !_verNueva),
            ),
          ),
          style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
        ),
        const SizedBox(height: 16),
        _fieldLabel('CONFIRMAR CONTRASEÑA'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmarPassController,
          obscureText: !_verConfirma,
          decoration: _inputDecoration(
            hint: '••••••••',
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                  _verConfirma ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF3A7A42), size: 20),
              onPressed: () => setState(() => _verConfirma = !_verConfirma),
            ),
          ),
          style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
        ),
      ],
    );
  }

  void _accionPaso() {
    setState(() => _error = null);
    switch (_paso) {
      case 0: _enviarCodigo();       break;
      case 1: _verificarCodigo();    break;
      case 2: _restablecerPassword(); break;
    }
  }

  String _textBoton() {
    switch (_paso) {
      case 0: return 'ENVIAR CÓDIGO';
      case 1: return 'VERIFICAR CÓDIGO';
      case 2: return 'RESTABLECER CONTRASEÑA';
      default: return 'CONTINUAR';
    }
  }

  // ── WIDGETS AUXILIARES ─────────────────────────────────────────────────────
  Widget _indicadorPaso(int numeroPaso, String etiqueta) {
    final activo   = _paso == numeroPaso;
    final completo = _paso > numeroPaso;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completo
                  ? const Color(0xFF4F8F1F)
                  : activo
                      ? const Color(0xFF4F8F1F)
                      : Colors.grey.shade200,
            ),
            child: Center(
              child: completo
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${numeroPaso + 1}',
                      style: TextStyle(
                        color: activo ? Colors.white : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(etiqueta,
              style: GoogleFonts.lato(
                  fontSize: 10,
                  color: activo || completo
                      ? const Color(0xFF4F8F1F)
                      : Colors.grey.shade400,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _lineaPaso(int index) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: _paso > index
            ? const Color(0xFF4F8F1F)
            : Colors.grey.shade200,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.lato(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: const Color(0xFF2D5A34), letterSpacing: 1),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lato(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF3A7A42), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF2F7F2),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFDAEEDD), width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF3A7A42), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }
}

// ── CURVA OVAL HACIA ABAJO ─────────────────────────────────────────────────
class _OvalBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height + 50, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_OvalBottomClipper old) => false;
}
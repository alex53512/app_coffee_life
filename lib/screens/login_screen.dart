import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _verPassword = false;
  bool _cargando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorGeneral = null;
    });

    try {
      final result = await AuthService.login(
        correo: _correoController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigation(usuario: result['data']),
          ),
        );
      } else {
        setState(() => _errorGeneral = result['message']);
      }
    } catch (e) {
      setState(() => _errorGeneral = 'No se pudo conectar al servidor');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      body: Column(
        children: [
          // ── SECCIÓN SUPERIOR VERDE CON HOJAS Y CURVA ──
          ClipPath(
            clipper: _OvalBottomClipper(),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4F8F1F),
                    Color(0xFF4F8F1F),
                    Color(0xFF071509),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // TEXTO CENTRADO
                  SafeArea(
                    child: Align(
                      alignment: const Alignment(0, -0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo_cafe.png',
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                          Transform.translate(
  offset: const Offset(0, -40), // ← sube más el texto
  child: Text(
    'Coffee Life',
    style: GoogleFonts.playfairDisplay(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: const Color.fromARGB(255, 14, 15, 14),
      letterSpacing: 1,
    ),
  ),
),
                         
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── SECCIÓN INFERIOR BLANCA ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SALUDO
                    Text(
                      '¡Hola!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A3A1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inicia sesión para continuar',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color.fromARGB(255, 19, 19, 19),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // EMAIL
                    _fieldLabel('CORREO ELECTRÓNICO'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: 'correo@ejemplo.com',
                        icon: Icons.email_outlined,
                      ),
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 21, 21, 21),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD
                    _fieldLabel('CONTRASEÑA'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_verPassword,
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _verPassword = !_verPassword),
                          icon: Icon(
                            _verPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF3A7A42),
                            size: 20,
                          ),
                        ),
                      ),
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: const Color(0xFF1A3A1E),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),

                    // ERROR
                    if (_errorGeneral != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _errorGeneral!,
                          style: GoogleFonts.lato(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF2D6E35),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // BOTÓN LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F8F1F),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _cargando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'INGRESAR',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // DIVIDER
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o continúa con',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // SOCIAL BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(Icons.g_mobiledata_rounded, const Color(0xFFC0392B)),
                        const SizedBox(width: 16),
                        _socialButton(Icons.apple, Colors.black87),
                        const SizedBox(width: 16),
                        _socialButton(Icons.facebook_rounded, const Color(0xFF1877F2)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // REGISTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta?',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF7A9A7E),
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Regístrate',
                            style: GoogleFonts.lato(
                              color: const Color(0xFF2D6E35),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2D5A34),
        letterSpacing: 1,
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDAEEDD), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3A7A42), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDE8DE), width: 1.5),
        color: const Color(0xFFF6FAF6),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildLeaf(double width, double height, Color color, double angle) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(width, height),
        painter: _LeafPainter(color),
      ),
    );
  }
}

// ── CURVA OVAL HACIA ABAJO ──
class _OvalBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 60,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_OvalBottomClipper old) => false;
}

// ── PINTOR DE HOJAS ──
class _LeafPainter extends CustomPainter {
  final Color color;
  const _LeafPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width, size.height * 0.3, size.width * 0.5, size.height)
      ..quadraticBezierTo(0, size.height * 0.3, size.width * 0.5, 0)
      ..close();
    canvas.drawPath(path, paint);

    final veinPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.1)
        ..lineTo(size.width * 0.5, size.height * 0.9),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color;
}
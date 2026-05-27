import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey                   = GlobalKey<FormState>();
  final _nombreController          = TextEditingController();
  final _apellidoController        = TextEditingController();
  final _telefonoController        = TextEditingController();
  final _correoController          = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _verPassword  = false;
  bool _verConfirm   = false;
  bool _acceptTerms  = false;
  bool _cargando     = false;
  String? _errorGeneral;
  String? _tipoDocumento;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acepta los términos y condiciones')),
      );
      return;
    }

    setState(() { _cargando = true; _errorGeneral = null; });

    try {
      final result = await AuthService.registrarCafetero(
        nombre:   _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        correo:   _correoController.text.trim(),
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada! Inicia sesión')),
        );
        Navigator.pop(context);
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
      body: Stack(
        children: [
          // ── FONDO VERDE COMPLETO CON HOJAS ──
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4F8F1F),
                  Color(0xFF071509),
                  Color(0xFF4F8F1F),
                ],
              ),
            ),
            
          ),

          // ── CONTENIDO ──
          SafeArea(
            child: Column(
              children: [
                // CABECERA VERDE
                SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      // BOTÓN ATRÁS
                      Positioned(
                        top: 0,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Color(0xFFE8F5E0),
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // LOGO Y TÍTULO
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Image.asset(
                              'assets/images/logo_CoffeLife_SinFondo.png',
                              width: 65,
                              height: 65,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Únete a Coffee Life',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE8F5E0),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CREA TU CUENTA',
                              style: GoogleFonts.lato(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF9DC49E),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── TARJETA BLANCA CON ÓVALO ARRIBA ──
                Expanded(
                  child: ClipPath(
                    clipper: _OvalTopClipper(),
                    child: Container(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola!',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A3A1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Únete y empieza a cuidar tu cultivo',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: const Color(0xFF7A9A7E),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // TIPO DOCUMENTO
                              _fieldLabel('TIPO DE DOCUMENTO'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _tipoDocumento,
                                decoration: _inputDecoration(
                                  hint: 'Selecciona tu documento',
                                  icon: Icons.badge_outlined,
                                ),
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: const Color(0xFF1A3A1E),
                                ),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(value: 'CC', child: Text('Cédula de ciudadanía')),
                                  DropdownMenuItem(value: 'CE', child: Text('Cédula de extranjería')),
                                  DropdownMenuItem(value: 'PA', child: Text('Pasaporte')),
                                ],
                                onChanged: (v) => setState(() => _tipoDocumento = v),
                                validator: (v) => v == null ? 'Selecciona el tipo de documento' : null,
                              ),
                              const SizedBox(height: 16),

                              // NOMBRE
                              _fieldLabel('NOMBRE'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nombreController,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(hint: 'Tu nombre', icon: Icons.person_outline),
                                style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
                                validator: (v) => v!.trim().isEmpty ? 'Ingresa tu nombre' : null,
                              ),
                              const SizedBox(height: 16),

                              // APELLIDO
                              _fieldLabel('APELLIDO'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _apellidoController,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(hint: 'Tu apellido', icon: Icons.person_outline),
                                style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
                                validator: (v) => v!.trim().isEmpty ? 'Ingresa tu apellido' : null,
                              ),
                              const SizedBox(height: 16),

                              // TELÉFONO
                              _fieldLabel('TELÉFONO'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _telefonoController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(hint: '3001234567', icon: Icons.phone_outlined),
                                style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
                                validator: (v) => v!.trim().isEmpty ? 'Ingresa tu teléfono' : null,
                              ),
                              const SizedBox(height: 16),

                              // CORREO
                              _fieldLabel('CORREO ELECTRÓNICO'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _correoController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(hint: 'correo@ejemplo.com', icon: Icons.email_outlined),
                                style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
                                validator: (v) {
                                  if (v!.trim().isEmpty) return 'Ingresa tu correo';
                                  if (!v.contains('@')) return 'Correo no válido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // CONTRASEÑA
                              _fieldLabel('CONTRASEÑA'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_verPassword,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _verPassword ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF3A7A42),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _verPassword = !_verPassword),
                                  ),
                                ),
                                style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
                                validator: (v) {
                                  if (v!.isEmpty) return 'Ingresa tu contraseña';
                                  if (v.length < 8) return 'Mínimo 8 caracteres';
                                  if (!v.contains(RegExp(r'[0-9]'))) return 'Debe contener al menos un número';
                                  if (!v.contains(RegExp(r'[a-zA-Z]'))) return 'Debe contener al menos una letra';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // CONFIRMAR CONTRASEÑA
                              _fieldLabel('CONFIRMAR CONTRASEÑA'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_verConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _registrar(),
                                decoration: _inputDecoration(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _verConfirm ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF3A7A42),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _verConfirm = !_verConfirm),
                                  ),
                                ),
                                style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1A3A1E)),
                                validator: (v) =>
                                    v != _passwordController.text ? 'Las contraseñas no coinciden' : null,
                              ),

                              // ERROR GENERAL
                              if (_errorGeneral != null) ...[
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
                                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorGeneral!,
                                          style: GoogleFonts.lato(color: Colors.red, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // TÉRMINOS
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptTerms,
                                    activeColor: const Color(0xFF2D6E35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) => setState(() => _acceptTerms = v!),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.lato(
                                          fontSize: 13,
                                          color: const Color(0xFF7A9A7E),
                                        ),
                                        children: [
                                          const TextSpan(text: 'Acepto los '),
                                          TextSpan(
                                            text: 'Términos y condiciones',
                                            style: GoogleFonts.lato(
                                              color: const Color(0xFF2D6E35),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // BOTÓN REGISTRAR
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _cargando ? null : _registrar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2D6E35),
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
                                          'CREAR CUENTA',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // YA TENGO CUENTA
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿Ya tienes cuenta?',
                                    style: GoogleFonts.lato(
                                      color: const Color(0xFF7A9A7E),
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Inicia sesión',
                                      style: GoogleFonts.lato(
                                        color: const Color(0xFF2D6E35),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

// ── ÓVALO CONVEXO HACIA ARRIBA (en el borde superior de la tarjeta blanca) ──
class _OvalTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Empieza desde abajo izquierda
    path.moveTo(0, size.height);
    path.lineTo(0, 60);
    // Curva convexa hacia arriba
    path.quadraticBezierTo(
      size.width / 2,
      -40,
      size.width,
      60,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_OvalTopClipper old) => false;
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'main_navigation.dart';  // ✅ agrega esta línea

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _correoController   = TextEditingController();
  final _passwordController = TextEditingController();
  bool _verPassword = false;
  bool _cargando    = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _errorGeneral = null; });

    try {
      final result = await AuthService.login(
        correo: _correoController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

    if (result['success'] == true) {
  final usuario = result['data'];
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => MainNavigation(usuario: usuario)), // ✅
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
      backgroundColor: AppTheme.crema,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCabecera(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Iniciar sesión',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bienvenido de nuevo a CoffeeLife',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Correo ────────────────────────────
                      _label('Correo electrónico'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'tucorreo@ejemplo.com',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppTheme.textoSecundario),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // ── Contraseña ────────────────────────
                      _label('Contraseña'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_verPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _iniciarSesion(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppTheme.textoSecundario),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _verPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textoSecundario,
                            ),
                            onPressed: () =>
                                setState(() => _verPassword = !_verPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),

                      // ── Error general ─────────────────────
                      if (_errorGeneral != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorGeneral!,
                                  style: GoogleFonts.inter(
                                      color: AppTheme.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.verdePrincipal,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Botón ingresar ────────────────────
                      ElevatedButton(
                        onPressed: _cargando ? null : _iniciarSesion,
                        child: _cargando
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Ingresar'),
                      ),

                      const SizedBox(height: 14),

                      // ── Registrarse ───────────────────────
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text('Registrarse'),
                      ),

                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          'Tu asistente inteligente para\ncuidar tus plantas de café 🌿',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textoSecundario,
                            height: 1.6,
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
    );
  }

  Widget _buildCabecera() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.verdeOscuro, AppTheme.verdePrincipal],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo_CoffeLife_SinFondo.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 12),
          Text(
            '¡Hola! Soy Coffee AI 🌿',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu asistente inteligente para el café',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String texto) {
    return Text(
      texto,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.textoPrincipal,
      ),
    );
  }
}
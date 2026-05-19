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
        final usuario = result['data'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigation(
              usuario: usuario,
            ),
          ),
        );
      } else {
        setState(() {
          _errorGeneral = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorGeneral = 'No se pudo conectar al servidor';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Stack(
        children: [

          // ===================================================
          // FONDO DECORATIVO
          // ===================================================

          _buildBackground(),

          // ===================================================
          // CONTENIDO
          // ===================================================

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  // HEADER
                  _buildCabecera(),

                  // CARD LOGIN
                  Transform.translate(
                    offset: const Offset(0, -28),

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),

                      child: Container(
                        padding: const EdgeInsets.all(24),

                        decoration: BoxDecoration(
                          color: AppColors.card,

                          borderRadius:
                              BorderRadius.circular(28),

                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),

                        child: Form(
                          key: _formKey,

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              // TITULO
                              Text(
                                'Iniciar sesión',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      AppColors.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Bienvenido de nuevo a CoffeeLife',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      AppColors.textSecondary,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // ===================================================
                              // CORREO
                              // ===================================================

                              _label(
                                  'Correo electrónico'),

                              const SizedBox(height: 8),

                              TextFormField(
                                controller:
                                    _correoController,

                                keyboardType:
                                    TextInputType
                                        .emailAddress,

                                decoration:
                                    InputDecoration(
                                  hintText:
                                      'tucorreo@ejemplo.com',

                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: AppColors
                                        .textSecondary,
                                  ),
                                ),

                                validator: (v) {
                                  if (v == null ||
                                      v.trim().isEmpty) {
                                    return 'Ingresa tu correo';
                                  }

                                  if (!v.contains('@')) {
                                    return 'Correo inválido';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // ===================================================
                              // PASSWORD
                              // ===================================================

                              _label('Contraseña'),

                              const SizedBox(height: 8),

                              TextFormField(
                                controller:
                                    _passwordController,

                                obscureText:
                                    !_verPassword,

                                decoration:
                                    InputDecoration(
                                  hintText: '••••••••',

                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppColors
                                        .textSecondary,
                                  ),

                                  suffixIcon:
                                      IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _verPassword =
                                            !_verPassword;
                                      });
                                    },

                                    icon: Icon(
                                      _verPassword
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,

                                      color: AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ),

                                validator: (v) {
                                  if (v == null ||
                                      v.isEmpty) {
                                    return 'Ingresa tu contraseña';
                                  }

                                  if (v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }

                                  return null;
                                },
                              ),

                              // ===================================================
                              // ERROR
                              // ===================================================

                              if (_errorGeneral !=
                                  null) ...[
                                const SizedBox(height: 16),

                                Container(
                                  width:
                                      double.infinity,

                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color: AppColors
                                        .error
                                        .withOpacity(
                                            0.08),

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                14),

                                    border: Border.all(
                                      color: AppColors
                                          .error
                                          .withOpacity(
                                              0.18),
                                    ),
                                  ),

                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .error_outline,
                                        color:
                                            AppColors
                                                .error,
                                        size: 18,
                                      ),

                                      const SizedBox(
                                          width: 10),

                                      Expanded(
                                        child: Text(
                                          _errorGeneral!,
                                          style:
                                              GoogleFonts
                                                  .inter(
                                            color:
                                                AppColors
                                                    .error,
                                            fontSize:
                                                13,
                                            fontWeight:
                                                FontWeight
                                                    .w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // ===================================================
                              // OLVIDASTE PASSWORD
                              // ===================================================

                              Align(
                                alignment:
                                    Alignment.centerRight,

                                child: TextButton(
                                  onPressed: () {},

                                  style:
                                      TextButton.styleFrom(
                                    foregroundColor:
                                        AppColors
                                            .primary,
                                  ),

                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style:
                                        GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ===================================================
                              // BOTÓN LOGIN
                              // ===================================================

                              SizedBox(
                                width: double.infinity,

                                child: ElevatedButton(
                                  onPressed: _cargando
                                      ? null
                                      : _iniciarSesion,

                                  child: _cargando
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child:
                                              CircularProgressIndicator(
                                            color:
                                                Colors
                                                    .white,
                                            strokeWidth:
                                                2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Ingresar',
                                        ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ===================================================
                              // BOTÓN REGISTER
                              // ===================================================

                              SizedBox(
                                width: double.infinity,

                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },

                                  child: const Text(
                                    'Registrarse',
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildCabecera() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        24,
        50,
        24,
        90,
      ),

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),

        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
      ),

      child: Column(
        children: [

          // LOGO
          Container(
            width: 120,
            height: 120,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),

              shape: BoxShape.circle,
            ),

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Image.asset(
                'assets/images/logo_CoffeLife_SinFondo.png',
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'CoffeeLife',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Cuida tus cultivos con inteligencia',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FONDO DECORATIVO
  // =========================================================

  Widget _buildBackground() {
    return Stack(
      children: [

        // FONDO BASE
        Container(
          color: AppColors.background,
        ),

        // OLA GRANDE
        Positioned(
          bottom: -120,
          left: -60,
          right: -60,

          child: Container(
            height: 240,

            decoration: BoxDecoration(
              color: AppColors.wave,

              borderRadius:
                  BorderRadius.circular(220),
            ),
          ),
        ),

        // CÍRCULO IZQUIERDO
        Positioned(
          bottom: -60,
          left: -50,

          child: Container(
            width: 220,
            height: 220,

            decoration: const BoxDecoration(
              color: AppColors.waveLight,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // CÍRCULO DERECHO
        Positioned(
          bottom: 80,
          right: -70,

          child: Container(
            width: 170,
            height: 170,

            decoration: const BoxDecoration(
              color: AppColors.waveLight,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LABEL
  // =========================================================

  Widget _label(String texto) {
    return Text(
      texto,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
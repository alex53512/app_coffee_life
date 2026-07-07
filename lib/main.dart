import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/theme_notifier.dart';

void main() {
  runApp(CoffeeLifeApp(themeNotifier: ThemeNotifier()));
}

class CoffeeLifeApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const CoffeeLifeApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return ThemeProvider(
          notifier: themeNotifier,
          child: MaterialApp(
            navigatorKey: ApiService.navigatorKey,
            title: 'Coffee Life',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.oscuro ? ThemeMode.dark : ThemeMode.light,
            home: const SplashRouter(),
          ),
        );
      },
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter>
    with TickerProviderStateMixin {
  // Entrada (fade + scale inicial del logo)
  late AnimationController _entryController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _entryScaleAnimation;

  // Barra de progreso (0.0 -> 1.0 en 5 segundos)
  late AnimationController _progressController;

  // Fade-out de toda la pantalla antes de navegar
  late AnimationController _exitController;
  late Animation<double> _exitOpacityAnimation;

  static const Duration _splashDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    // --- Entrada del logo ---
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    _entryScaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );

    // --- Barra de progreso ---
    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );

    // --- Fade-out final ---
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitOpacityAnimation = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOut,
    );

    // Precargamos el logo ANTES de iniciar el fade-in, así el logo y el
    // nombre de la app aparecen exactamente juntos, sin que el logo
    // "llegue tarde" mientras el texto ya se ve.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await precacheImage(
        const AssetImage('assets/images/logo_cafe.png'),
        context,
      );
      if (!mounted) return;
      _entryController.forward();
    });

    _progressController.forward();

    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    await Future.delayed(_splashDuration);

    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    // Hacemos el fade-out de toda la pantalla
    await _exitController.forward();

    if (!mounted) return;

    if (loggedIn) {
      final usuario = await AuthService.getUsuario();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, anim, __) => MainNavigation(
            usuario: usuario ?? {},
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, anim, __) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitOpacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _exitOpacityAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF97D340),
                Color(0xFF2E7D32),
              ],
            ),
          ),
          child: Stack(
            children: [
              // --- Hojas decorativas transparentes en las esquinas ---
              _buildHoja(
                top: -30,
                left: -30,
                size: 160,
                angle: -0.3,
                opacity: 0.10,
              ),
              _buildHoja(
                top: -20,
                right: -40,
                size: 140,
                angle: 0.5,
                opacity: 0.08,
              ),
              _buildHoja(
                bottom: -40,
                left: -20,
                size: 180,
                angle: 0.8,
                opacity: 0.09,
              ),
              _buildHoja(
                bottom: -30,
                right: -30,
                size: 150,
                angle: -0.6,
                opacity: 0.10,
              ),

              // --- Contenido principal ---
              SafeArea(
                child: Stack(
                  children: [
                    // Logo + nombre, perfectamente centrados en toda la pantalla
                    Center(
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: ScaleTransition(
                          scale: _entryScaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/logo_cafe.png',
                                width: 200,
                                height: 200,
                              ),
                              // Subimos el bloque de texto para compensar el
                              // espacio transparente que trae el PNG del logo.
                              // Ajusta el valor (-55) para subir más o menos.
                              Transform.translate(
                                offset: const Offset(0, -55),
                                child: Column(
                                  children: [
                                    Text(
                                      'Coffee Life',
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Granos de café + versión, anclados abajo
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return _buildGranosCafe(
                                  _progressController.value,
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            Text(
                              "Versión 1.0",
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fila de granos de café que se "encienden" en secuencia
  /// conforme avanza el progreso (0.0 -> 1.0).
  Widget _buildGranosCafe(double progress) {
    const int totalGranos = 5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalGranos, (index) {
        // Cada grano tiene su propio "tramo" dentro del progreso total.
        final double inicio = index / totalGranos;
        final double fin = (index + 1) / totalGranos;

        // Qué tan "encendido" está este grano (0.0 a 1.0) según el progreso.
        double encendido =
            ((progress - inicio) / (fin - inicio)).clamp(0.0, 1.0);

        final double opacidad = 0.25 + (encendido * 0.75);
        final double escala = 1.0 + (encendido * 0.35);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Transform.scale(
            scale: escala,
            child: Opacity(
              opacity: opacidad,
              child: Container(
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: encendido > 0.7
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Container(
                    width: 1.5,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32)
                          .withOpacity(0.4 + (encendido * 0.4)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Hoja decorativa muy transparente para decorar las esquinas.
  Widget _buildHoja({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double angle,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.eco,
            size: size,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
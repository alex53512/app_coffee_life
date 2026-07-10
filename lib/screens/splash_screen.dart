import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/animated_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1B5E20),
        ),
        child: const Center(
          child: AnimatedLogo(
            size: AnimatedLogoSize.lg,
            showTagline: true,
            textColor: Colors.white,
            textAccentColor: Color(0xFF81C784),
          ),
        ),
      ),
    );
  }
}
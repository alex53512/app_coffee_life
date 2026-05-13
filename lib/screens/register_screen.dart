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
      backgroundColor: AppTheme.crema,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCabecera(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crear cuenta',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Únete y empieza a cuidar tu cultivo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Tipo de documento ─────────────────
                      _label('Tipo de documento'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _tipoDocumento,
                        decoration: const InputDecoration(
                          hintText: 'Selecciona tu documento',
                          prefixIcon: Icon(Icons.badge_outlined,
                              color: AppTheme.textoSecundario),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'CC',
                              child: Text('Cédula de ciudadanía')),
                          DropdownMenuItem(
                              value: 'CE',
                              child: Text('Cédula de extranjería')),
                          DropdownMenuItem(
                              value: 'PA', child: Text('Pasaporte')),
                        ],
                        onChanged: (v) => setState(() => _tipoDocumento = v),
                        validator: (v) => v == null
                            ? 'Selecciona el tipo de documento'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Nombre ────────────────────────────
                      _label('Nombre'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nombreController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Tu nombre',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppTheme.textoSecundario),
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Apellido ──────────────────────────
                      _label('Apellido'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _apellidoController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Tu apellido',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppTheme.textoSecundario),
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Ingresa tu apellido' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Teléfono ──────────────────────────
                      _label('Teléfono'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: '3001234567',
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: AppTheme.textoSecundario),
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Ingresa tu teléfono' : null,
                      ),
                      const SizedBox(height: 16),

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
                          if (v!.trim().isEmpty) return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Contraseña ────────────────────────
                      _label('Contraseña'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_verPassword,
                        textInputAction: TextInputAction.next,
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
                          if (v!.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 8) return 'Mínimo 8 caracteres';
                          if (!v.contains(RegExp(r'[0-9]'))) {
                            return 'Debe contener al menos un número';
                          }
                          if (!v.contains(RegExp(r'[a-zA-Z]'))) {
                            return 'Debe contener al menos una letra';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Confirmar contraseña ──────────────
                      _label('Confirmar contraseña'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_verConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _registrar(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppTheme.textoSecundario),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _verConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textoSecundario,
                            ),
                            onPressed: () =>
                                setState(() => _verConfirm = !_verConfirm),
                          ),
                        ),
                        validator: (v) => v != _passwordController.text
                            ? 'Las contraseñas no coinciden'
                            : null,
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

                      const SizedBox(height: 16),

                      // ── Términos ──────────────────────────
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            activeColor: AppTheme.verdePrincipal,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) =>
                                setState(() => _acceptTerms = v!),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textoSecundario),
                                children: [
                                  const TextSpan(text: 'Acepto los '),
                                  TextSpan(
                                    text: 'Términos y condiciones',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.verdePrincipal,
                                      fontWeight: FontWeight.w600,
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

                      // ── Botón registrar ───────────────────
                      ElevatedButton(
                        onPressed: _cargando ? null : _registrar,
                        child: _cargando
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Crear cuenta'),
                      ),

                      const SizedBox(height: 16),

                      // ── Ya tengo cuenta ───────────────────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '¿Ya tienes cuenta? ',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textoSecundario,
                                  fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.verdePrincipal,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Inicia sesión',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildCabecera(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Image.asset(
            'assets/images/logo_CoffeLife_SinFondo.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 10),
          Text(
            'Únete a CoffeeLife',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
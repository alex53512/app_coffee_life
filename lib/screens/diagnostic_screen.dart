import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'tratamiento_screen.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  String _stage = 'idle';
  final _picker = ImagePicker();
  String? _imagenPath;

  // Cultivos
  List _cultivos = [];
  int? _cultivoSeleccionado;
  bool _cargandoCultivos = false;

  // Resultado análisis (hardcoded por ahora, luego vendrá de la IA real)
  static const _diagnosisText  = 'Roya encontrada';
  static const _scientificName = 'Hemileia vastatrix';
  static const double _confidence = 0.92;
  static const _severity      = 'Alta';
  static const _severityColor = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _cargarCultivos();
  }

  Future<void> _cargarCultivos() async {
    setState(() => _cargandoCultivos = true);
    try {
      final data = await ApiService.get('/cultivos');
      setState(() {
        _cultivos = data is List ? data : (data['data'] ?? []);
        if (_cultivos.isNotEmpty) {
          _cultivoSeleccionado = _cultivos[0]['idCultivo'];
        }
        _cargandoCultivos = false;
      });
    } catch (e) {
      setState(() => _cargandoCultivos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 229, 219),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _stage == 'result'
                    ? _buildResultView()
                    : _stage == 'analyzing'
                        ? _buildAnalyzingView()
                        : _buildIdleView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 208, 196, 171),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () {
              if (_stage != 'idle') {
                setState(() { _stage = 'idle'; _imagenPath = null; });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Text('Diagnóstico',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: AppColors.textSecondary, size: 22),
            onPressed: () => _showModelInfoDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleView() {
    return SingleChildScrollView(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildIntro(),
          const SizedBox(height: 20),
          _buildCultivoSelector(),
          const SizedBox(height: 20),
          _buildViewfinder(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _cultivoSeleccionado == null ? null : _onTakePhoto,
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text('Tomar foto'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cultivoSeleccionado == null ? null : _onSelectGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: Text('Seleccionar de galería',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          _buildFileSizeNote(),
        ],
      ),
    );
  }

  Widget _buildCultivoSelector() {
    if (_cargandoCultivos) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_cultivos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE65100), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No tienes cultivos registrados. Registra uno primero.',
                style: GoogleFonts.nunito(
                    fontSize: 13, color: const Color(0xFFE65100)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecciona el cultivo',
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6)
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _cultivoSeleccionado,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textPrimary),
              items: _cultivos.map<DropdownMenuItem<int>>((c) {
                final id     = c['idCultivo'] as int;
                final nombre = c['nombreCultivo'] ?? 'Cultivo $id';
                final finca  = c['finca']?['nombreFinca'] ?? '';
                return DropdownMenuItem<int>(
                  value: id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(nombre,
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      if (finca.isNotEmpty)
                        Text(finca,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => _cultivoSeleccionado = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(
              color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.biotech_outlined,
              color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 14),
        Text('Diagnostica la roya\nde tu planta',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2)),
        const SizedBox(height: 8),
        Text('Toma una foto de la hoja de café para\nidentificar si tiene síntomas de roya.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4)),
      ],
    );
  }

  Widget _buildViewfinder() {
    return GestureDetector(
      onTap: _cultivoSeleccionado == null ? null : _onTakePhoto,
      child: Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E19),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            _corner(top: true, left: true),
            _corner(top: true, left: false),
            _corner(top: false, left: true),
            _corner(top: false, left: false),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 10),
                  Text('Toca para capturar',
                      style: GoogleFonts.nunito(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    return Positioned(
      top: top ? 14 : null,
      bottom: top ? null : 14,
      left: left ? 14 : null,
      right: left ? null : 14,
      child: SizedBox(
        width: 22, height: 22,
        child: CustomPaint(painter: _CornerPainter(top: top, left: left)),
      ),
    );
  }

  Widget _buildFileSizeNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFE65100), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La imagen debe tener un tamaño máximo de 3 KB para garantizar el análisis correcto.',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: const Color(0xFFE65100)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      key: const ValueKey('analyzing'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 28),
            Text('Analizando imagen...',
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text('El modelo de IA está procesando la hoja.\nEsto tomará unos segundos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildImagePreview(),
          const SizedBox(height: 20),
          _buildDiagnosisCard(),
          const SizedBox(height: 16),
          _buildConfidenceCard(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TratamientoScreen()),
            ),
            icon: const Icon(Icons.healing_outlined, size: 20),
            label: const Text('Ver tratamiento completo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _stage = 'idle';
              _imagenPath = null;
            }),
            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
            label: Text('Nuevo diagnóstico',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _imagenPath != null
              ? Image.network(
                  _imagenPath!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImage(),
                )
              : _placeholderImage(),
        ),
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _severityColor,
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text('Riesgo $_severity',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: const BoxDecoration(color: Color(0xFF2D5E2B)),
      child: const Center(
        child: Icon(Icons.eco_outlined, color: Colors.white24, size: 64),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.coronavirus_outlined,
                    color: _severityColor, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diagnóstico',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  Text(_diagnosisText,
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _severityColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),
          _detailRow('Agente causal', _scientificName, isItalic: true),
          const SizedBox(height: 8),
          _detailRow('Severidad', _severity, valueColor: _severityColor),
          const SizedBox(height: 8),
          _detailRow('Estado', 'Activo'),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Confianza del modelo',
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('${(_confidence * 100).round()}%',
                  style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _confidence,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text('Alta precisión – resultado confiable',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recs = [
      _Rec(Icons.medication_outlined, const Color(0xFF1565C0),
          'Aplicar fungicida recomendado', 'Fungicida Cúprico 250g/200L agua'),
      _Rec(Icons.air_outlined, const Color(0xFF2E7D32),
          'Mejorar ventilación del cultivo', 'Poda para mayor aireación'),
      _Rec(Icons.delete_outline_rounded, const Color(0xFFE65100),
          'Eliminar hojas afectadas', 'Retirar y destruir hojas con síntomas'),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recomendaciones',
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...recs.asMap().entries.map((e) {
            final rec    = e.value;
            final isLast = e.key == recs.length - 1;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                          color: rec.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(rec.icon, color: rec.color, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rec.title,
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          Text(rec.subtitle,
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, indent: 50, color: AppColors.border),
                  const SizedBox(height: 10),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _detailRow(String label, String value,
      {Color? valueColor, bool isItalic = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            )),
      ],
    );
  }

  void _onTakePhoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (foto != null) {
      setState(() => _imagenPath = foto.path);
      _startAnalysis();
    }
  }

  void _onSelectGallery() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (foto != null) {
      setState(() => _imagenPath = foto.path);
      _startAnalysis();
    }
  }

  Future<void> _startAnalysis() async {
    setState(() => _stage = 'analyzing');

    try {
      await Future.delayed(const Duration(seconds: 2));

      final hoy = DateTime.now();
      final fechaStr =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

      print('>>> Intentando crear monitoreo...');
      print('>>> id_cultivo: $_cultivoSeleccionado');
      print('>>> fecha: $fechaStr');

      // 1. Crear el monitoreo y capturar su ID
      final monitoreoResp = await ApiService.post('/monitoreos', {
        'id_cultivo': _cultivoSeleccionado,
        'fecha_monitoreo': fechaStr,
        'observaciones': '$_diagnosisText — Confianza: ${(_confidence * 100).round()}% — $_scientificName',
      });

      print('>>> Respuesta monitoreo: $monitoreoResp');

      final idMonitoreo = monitoreoResp['data']?['idMonitoreo'];
      print('>>> idMonitoreo capturado: $idMonitoreo');

      // 2. Guardar el análisis IA relacionado al monitoreo
      await ApiService.post('/analisis_ia', {
        'resultado': _diagnosisText,
        'confianza': (_confidence * 100).round(),
        'version_modelo': '1.0',
        'id_estado_analisis': 1,
        if (idMonitoreo != null) 'id_monitoreo': idMonitoreo,
      });

      print('>>> Todo guardado correctamente ✓');

    } catch (e) {
      print('>>> ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }

    if (mounted) setState(() => _stage = 'result');
  }

  void _showModelInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sobre el modelo de IA',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
          'El modelo está entrenado con imágenes representativas de plantas con roya (Hemileia vastatrix). '
          'Se actualiza continuamente con nuevos datos para mejorar su precisión. '
          'Los resultados son orientativos; consulta con un agrónomo para decisiones críticas.',
          style: GoogleFonts.nunito(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: Text('Entendido', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
  }
}

class _Rec {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _Rec(this.icon, this.color, this.title, this.subtitle);
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
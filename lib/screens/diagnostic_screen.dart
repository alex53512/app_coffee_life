import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import 'tratamiento_screen.dart';
 
// ─────────────────────────────────────────────────────────────
// Clases que devuelve el modelo de Yimmy
// ─────────────────────────────────────────────────────────────
enum _IaClase { roya, hojaSana, arbolCafe, desconocida }
 
_IaClase _parsearClase(String raw) {
  switch (raw.trim()) {
    case 'Enfermedad_ROYA':
      return _IaClase.roya;
    case 'Hoja_Sana':
      return _IaClase.hojaSana;
    case 'arbol_cafe':
      return _IaClase.arbolCafe;
    default:
      return _IaClase.desconocida;
  }
}
 
class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});
 
  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}
 
class _DiagnosticScreenState extends State<DiagnosticScreen> {
  String _stage = 'idle'; // idle | analyzing | result | invalid
  final _picker = ImagePicker();
  XFile? _imagenFile;
  Uint8List? _imagenBytes;
 
  List _cultivos = [];
  int? _cultivoSeleccionado;
 
  // ── Resultados IA ─────────────────────────────────────────
  static const String _iaBaseUrl = 'http://192.168.137.21:8000';
 
  // Resultado válido (roya / hoja sana)
  String _diagnosisText  = '';
  String _scientificName = '';
  double _confidence     = 0.0;
  String _severity       = '';
  Color  _severityColor  = AppColors.primary;
  List<Map<String, dynamic>> _detections = [];
  _IaClase _claseDetectada = _IaClase.desconocida;
 
  // Resultado inválido (árbol, imagen rara, etc.)
  String _invalidTitle      = '';
  String _invalidMessage    = '';
  String _invalidSuggestion = '';
 
  @override
  void initState() {
    super.initState();
    _cargarDesdeAppState();
    AppState.instance.addListener(_onFincaCambiada);
  }
 
  @override
  void dispose() {
    AppState.instance.removeListener(_onFincaCambiada);
    super.dispose();
  }
 
  void _onFincaCambiada() => _cargarDesdeAppState();
 
  void _cargarDesdeAppState() {
    final cultivos = AppState.instance.cultivosFinca;
    setState(() {
      _cultivos = List.from(cultivos);
      _cultivoSeleccionado = _cultivos.isNotEmpty
          ? (_cultivos[0]['idCultivo'] ?? _cultivos[0]['id_cultivo'])
          : null;
      _stage = 'idle';
      _imagenFile = null;
      _imagenBytes = null;
    });
  }
 
  String get _nombreFinca =>
      AppState.instance.fincaSeleccionada?['nombreFinca'] ?? 'Mi Finca';
 
  // ── Lógica central: procesar lo que devuelve la IA ────────
  void _procesarDetecciones(List detections) {
    _detections = List<Map<String, dynamic>>.from(detections);
 
    if (detections.isEmpty) {
      _claseDetectada  = _IaClase.desconocida;
      _invalidTitle    = 'Imagen no reconocida';
      _invalidMessage  =
          'El modelo no pudo identificar ningún elemento relacionado '
          'con el cultivo de café en esta imagen.';
      _invalidSuggestion =
          'Toma una foto clara de la hoja del café, de frente y con '
          'buena iluminación, para obtener un diagnóstico preciso.';
      return;
    }
 
    final top   = detections[0];
    final conf  = (top['confidence'] as num).toDouble();
    final clase = _parsearClase(top['class'] as String);
    _claseDetectada = clase;
    _confidence     = conf;
 
    switch (clase) {
      case _IaClase.roya:
        _diagnosisText  = 'Roya detectada';
        _scientificName = 'Hemileia vastatrix';
        if (conf >= 0.75) {
          _severity      = 'Alta';
          _severityColor = const Color(0xFFD32F2F);
        } else if (conf >= 0.45) {
          _severity      = 'Media';
          _severityColor = const Color(0xFFE65100);
        } else {
          _severity      = 'Baja';
          _severityColor = const Color(0xFF388E3C);
        }
        break;
 
      case _IaClase.hojaSana:
        _diagnosisText  = 'Planta sana';
        _scientificName = 'Sin patógenos detectados';
        _severity       = 'Ninguna';
        _severityColor  = AppColors.primary;
        break;
 
      case _IaClase.arbolCafe:
        _invalidTitle    = 'Se detectó un árbol de café';
        _invalidMessage  =
            'La foto muestra el árbol completo, pero para detectar '
            'roya necesito ver la hoja de cerca.';
        _invalidSuggestion =
            'Acércate a una hoja y fotografíala de frente, mostrando '
            'el haz o el envés. La roya se detecta mejor en hojas '
            'individuales con buena iluminación.';
        break;
 
      case _IaClase.desconocida:
        _invalidTitle    = 'Imagen no válida';
        _invalidMessage  =
            'La imagen no corresponde a una hoja de café o a un '
            'árbol reconocible por el modelo.';
        _invalidSuggestion =
            'Asegúrate de fotografiar exclusivamente la hoja del '
            'cafeto y que esté bien iluminada y enfocada.';
        break;
    }
  }
 
  bool get _esResultadoValido =>
      _claseDetectada == _IaClase.roya ||
      _claseDetectada == _IaClase.hojaSana;
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Color de Alexander
      backgroundColor: const Color(0xFFFFFEFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (_stage) {
                  'result'    => _esResultadoValido
                                    ? _buildResultView()
                                    : _buildInvalidView(),
                  'analyzing' => _buildAnalyzingView(),
                  _           => _buildIdleView(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildHeader(BuildContext context) {
    return Container(
      // ✅ Color de Alexander
      color: const Color(0xFFF4E7D6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () {
              if (_stage != 'idle') {
                setState(() {
                  _stage = 'idle';
                  _imagenFile = null;
                  _imagenBytes = null;
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Diagnóstico',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text(_nombreFinca,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
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
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  Widget _buildIntro() {
    return Column(
      children: [
        const SizedBox(height: 14),
        Text('Diagnostica la roya\nde tu planta',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.2)),
        const SizedBox(height: 8),
        Text('Toma una foto de la hoja de café para\nidentificar si tiene síntomas de roya.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4)),
      ],
    );
  }
 
  Widget _buildCultivoSelector() {
    if (_cultivos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: Text('Esta finca no tiene cultivos registrados.',
            style: GoogleFonts.dmSans(
                fontSize: 13, color: const Color(0xFFE65100))),
      );
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecciona el cultivo',
            style: GoogleFonts.dmSans(
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
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _cultivoSeleccionado,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
              items: _cultivos.map<DropdownMenuItem<int>>((c) {
                final id = (c['idCultivo'] ?? c['id_cultivo']) as int;
                final nombre = c['nombreCultivo'] ?? c['nombre_cultivo'] ?? 'Cultivo $id';
                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(nombre,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _cultivoSeleccionado = val),
            ),
          ),
        ),
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
                      style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Fotografía solo la hoja del cafeto',
                        style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11)),
                  ),
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
                style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text('El modelo de IA está procesando la hoja.\nEsto tomará unos segundos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
 
  // ── Result válido (roya o hoja sana) ──────────────────────
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
          // Solo mostrar "Ver tratamiento" si hay roya
          if (_claseDetectada == _IaClase.roya)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
               MaterialPageRoute(
  builder: (_) => TratamientoScreen(
    cultivoId:      _cultivoSeleccionado!,
    diagnosisText:  _diagnosisText,
    scientificName: _scientificName,
    confidence:     _confidence,
  ),
),
              ),
              icon: const Icon(Icons.healing_outlined, size: 20),
              label: const Text('Ver tratamiento completo'),
            ),
          if (_claseDetectada == _IaClase.roya) const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _stage = 'idle';
              _imagenFile = null;
              _imagenBytes = null;
            }),
            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
            label: Text('Nuevo diagnóstico',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  // ── Invalid (árbol, imagen no reconocida, etc.) ───────────
  Widget _buildInvalidView() {
    return SingleChildScrollView(
      key: const ValueKey('invalid'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_imagenBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                _imagenBytes!,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.orange.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_outlined,
                      color: Color(0xFFE65100), size: 30),
                ),
                const SizedBox(height: 14),
                Text(_invalidTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(_invalidMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    color: Color(0xFF388E3C), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Cómo tomar la foto correcta?',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32))),
                      const SizedBox(height: 4),
                      Text(_invalidSuggestion,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF388E3C),
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildPhotoGuide(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _onTakePhoto,
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text('Intentar de nuevo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _onSelectGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: Text('Seleccionar otra foto',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
 
  Widget _buildPhotoGuide() {
    return Row(
      children: [
        Expanded(child: _photoGuideItem(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF388E3C),
          bgColor: const Color(0xFFF1F8E9),
          title: 'Correcto',
          desc: 'Hoja individual,\nenfocada, de cerca',
        )),
        const SizedBox(width: 12),
        Expanded(child: _photoGuideItem(
          icon: Icons.cancel_outlined,
          color: const Color(0xFFD32F2F),
          bgColor: const Color(0xFFFFEBEE),
          title: 'Incorrecto',
          desc: 'Árbol completo o\nfoto borrosa/lejana',
        )),
      ],
    );
  }
 
  Widget _photoGuideItem({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(title,
              style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: color.withOpacity(0.8), height: 1.4)),
        ],
      ),
    );
  }
 
  Widget _buildImagePreview() {
    final bool esRoya = _claseDetectada == _IaClase.roya;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _imagenBytes != null
              ? Image.memory(_imagenBytes!,
                  width: double.infinity, height: 190, fit: BoxFit.cover)
              : _placeholderImage(),
        ),
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _severityColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              esRoya ? 'Riesgo $_severity' : 'Planta sana',
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
 
  Widget _placeholderImage() {
    return Container(
      width: double.infinity, height: 190,
      decoration: const BoxDecoration(color: Color(0xFF2D5E2B)),
      child: const Center(
          child: Icon(Icons.eco_outlined, color: Colors.white24, size: 64)),
    );
  }
 
  Widget _buildDiagnosisCard() {
    final bool esRoya = _claseDetectada == _IaClase.roya;
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
                child: Icon(
                  esRoya ? Icons.coronavirus_outlined : Icons.eco_outlined,
                  color: _severityColor, size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diagnóstico',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  Text(_diagnosisText,
                      style: GoogleFonts.dmSans(
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
          _detailRow('Agente causal', _scientificName, isItalic: esRoya),
          const SizedBox(height: 8),
          _detailRow('Severidad', _severity, valueColor: esRoya ? _severityColor : null),
          const SizedBox(height: 8),
          _detailRow('Finca', _nombreFinca),
          const SizedBox(height: 8),
          _detailRow('Estado', esRoya ? 'Activo' : 'Sin novedad'),
        ],
      ),
    );
  }
 
  Widget _buildConfidenceCard() {
    final pct = (_confidence * 100).round();
    final label = pct >= 75
        ? 'Alta precisión – resultado confiable'
        : pct >= 45
            ? 'Precisión media – revisar con un experto'
            : 'Baja precisión – se recomienda nueva foto';
 
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Confianza del modelo',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('$pct%',
                  style: GoogleFonts.dmSans(
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
              valueColor: AlwaysStoppedAnimation<Color>(_severityColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
 
  Widget _buildRecommendationsCard() {
    final bool esRoya = _claseDetectada == _IaClase.roya;
    final recs = esRoya
        ? [
            _Rec(Icons.medication_outlined, const Color(0xFF1565C0),
                'Aplicar fungicida recomendado', 'Fungicida Cúprico 250g/200L agua'),
            _Rec(Icons.air_outlined, const Color(0xFF2E7D32),
                'Mejorar ventilación del cultivo', 'Poda para mayor aireación'),
            _Rec(Icons.delete_outline_rounded, const Color(0xFFE65100),
                'Eliminar hojas afectadas', 'Retirar y destruir hojas con síntomas'),
          ]
        : [
            _Rec(Icons.check_circle_outline, AppColors.primary,
                'Planta en buen estado', 'Continúa con el manejo habitual'),
            _Rec(Icons.water_drop_outlined, const Color(0xFF1565C0),
                'Mantén el riego adecuado', 'Riega según las condiciones del clima'),
            _Rec(Icons.search_outlined, const Color(0xFF388E3C),
                'Monitorea regularmente', 'Revisa las hojas cada 15 días'),
          ];
 
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recomendaciones',
              style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...recs.asMap().entries.map((e) {
            final rec = e.value;
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
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          Text(rec.subtitle,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: AppColors.textSecondary)),
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
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.dmSans(
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
      final bytes = await foto.readAsBytes();
      setState(() { _imagenFile = foto; _imagenBytes = bytes; });
      _startAnalysis(foto, bytes);
    }
  }
 
  void _onSelectGallery() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() { _imagenFile = foto; _imagenBytes = bytes; });
      _startAnalysis(foto, bytes);
    }
  }
 
  Future<void> _startAnalysis(XFile foto, Uint8List bytes) async {
    setState(() => _stage = 'analyzing');
 
    // ── 1) Llamada a la IA ───────────────────────────────────
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_iaBaseUrl/predict'));
      request.files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: foto.name.isNotEmpty ? foto.name : 'imagen.jpg',
      ));
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      debugPrint('Respuesta IA: ${res.body}');
      final jsonData = jsonDecode(res.body);
      if (jsonData['success'] == true) {
        _procesarDetecciones(jsonData['detections'] ?? []);
      } else {
        _procesarDetecciones([]);
      }
    } catch (e) {
      debugPrint('❌ Error llamando a la IA: $e');
      _procesarDetecciones([]);
    }
 
    // ── 2) Guardar en backend SOLO si la imagen es válida ────
    if (_esResultadoValido) {
      try {
        final hoy = DateTime.now();
        final fechaStr =
            '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
        await ApiService.post('/monitoreos', {
          'id_cultivo': _cultivoSeleccionado,
          'fecha_monitoreo': fechaStr,
          'observaciones':
              '$_diagnosisText — Confianza: ${(_confidence * 100).round()}% — $_scientificName',
        });
        await ApiService.post('/analisis_ia', {
          'resultado': _diagnosisText,
          'confianza': (_confidence * 100).round(),
          'version_modelo': '1.0',
          'id_estado_analisis': 1,
        });
      } catch (e) {
        debugPrint('⚠️ Error guardando en backend (no afecta diagnóstico): $e');
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
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800)),
        content: Text(
          'El modelo reconoce tres estados: roya activa (Hemileia vastatrix), '
          'hoja sana y árbol de café completo. '
          'Para un diagnóstico preciso, fotografía una hoja individual con buena iluminación. '
          'Los resultados son orientativos; consulta con un agrónomo para decisiones críticas.',
          style: GoogleFonts.dmSans(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: Text('Entendido', style: GoogleFonts.dmSans()),
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
      path.moveTo(0, size.height); path.lineTo(0, 0); path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }
 
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
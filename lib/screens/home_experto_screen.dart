import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import 'detalle_finca_experto_screen.dart';
 
class HomeExpertoScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const HomeExpertoScreen({super.key, required this.usuario});
 
  @override
  State<HomeExpertoScreen> createState() => _HomeExpertoScreenState();
}
 
class _HomeExpertoScreenState extends State<HomeExpertoScreen> {
  bool _cargando = true;
  String? _error;
 
  List _fincas = [];
  List _cultivos = [];
  List _monitoreos = [];
 
  int _fincaSeleccionada = 0;
  int? _cultivoSeleccionadoId;
  final _searchCtrl = TextEditingController();
  String _busqueda = '';
 
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.get('/experto/fincas'),
        ApiService.get('/experto/cultivos'),
        ApiService.get('/experto/monitoreos'),
      ]);
 
      List _list(dynamic r) => r is List ? r : (r['data'] ?? r['items'] ?? []);
 
      final fincas = _list(results[0]);
      final cultivos = _list(results[1]);
      final monitoreos = _list(results[2]);
 
      setState(() {
        _fincas = fincas;
        _cultivos = cultivos;
        _monitoreos = monitoreos;
        if (_fincaSeleccionada >= _fincas.length) _fincaSeleccionada = 0;
        _cultivoSeleccionadoId = null;
        _cargando = false;
      });
 
      if (_fincas.isNotEmpty) {
        AppState.instance.setFinca(_fincas[_fincaSeleccionada], _cultivosFincaActual);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }
 
 
  List get _cultivosFincaActual {
    if (_fincas.isEmpty || _fincaSeleccionada >= _fincas.length) return [];
    final fincaActual = _fincas[_fincaSeleccionada];
    final idFinca = fincaActual['idFinca'] ?? fincaActual['id_finca'];
    return _cultivos
        .where((c) =>
            (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString())
        .toList();
  }
 
  List get _fincasFiltradas {
    if (_busqueda.isEmpty) return _fincas;
    final q = _busqueda.toLowerCase();
    return _fincas.where((f) {
      final nombre = (f['nombreFinca'] ?? '').toString().toLowerCase();
      final municipio = (f['municipio'] ?? '').toString().toLowerCase();
      final depto = (f['departamento'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || municipio.contains(q) || depto.contains(q);
    }).toList();
  }
 
  List _monitoreosDeCultivo(dynamic idCultivo) {
    return _monitoreos.where((m) {
      final id = m['idCultivo'] ?? m['id_cultivo'];
      return id.toString() == idCultivo.toString();
    }).toList();
  }
 
  String _calcularNivelRoyaPara(dynamic idCultivo) {
    final monitoreos = _monitoreosDeCultivo(idCultivo);
    if (monitoreos.isEmpty) return 'Sin datos';
 
    final total = monitoreos.length;
    final conRoya = monitoreos.where((m) {
      final obs = (m['observaciones'] ?? '').toString().toLowerCase();
      return obs.contains('roya') ||
          obs.contains('alto') ||
          obs.contains('alta') ||
          obs.contains('critico') ||
          obs.contains('crítico') ||
          obs.contains('enfermedad');
    }).length;
 
    final porcentaje = conRoya / total;
    if (porcentaje < 0.3) return 'Bajo';
    if (porcentaje <= 0.6) return 'Medio';
    return 'Alto';
  }
 
  int _contarAlertasFinca(Map<String, dynamic> finca) {
    final idFinca = finca['idFinca'] ?? finca['id_finca'];
    final cultivosFinca = _cultivos.where((c) =>
        (c['idFinca'] ?? c['id_finca']).toString() == idFinca.toString());
    int alertas = 0;
    for (final c in cultivosFinca) {
      final idCultivo = c['idCultivo'] ?? c['id_cultivo'];
      if (_calcularNivelRoyaPara(idCultivo) == 'Alto') alertas++;
    }
    return alertas;
  }
 
  int get _totalAlertas {
    int total = 0;
    for (final f in _fincas) {
      total += _contarAlertasFinca(f as Map<String, dynamic>);
    }
    return total;
  }
 
 
  @override
  Widget build(BuildContext context) {
    final nombre = widget.usuario['nombre'] ?? 'Experto';
 
    return Scaffold(
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      _buildHeader(nombre),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBusqueda(),
                              const SizedBox(height: 16),
                              _buildFincasSection(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
 
  Widget _buildHeader(String nombre) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.verdeOscuro,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hola, $nombre',
                          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('Panel del Experto',
                          style: GoogleFonts.nunito(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Experto',
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _buildBusqueda() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() {
        _busqueda = v;
        _fincaSeleccionada = 0;
        _cultivoSeleccionadoId = null;
      }),
      style: GoogleFonts.nunito(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar finca por nombre o municipio...',
        hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
        suffixIcon: _busqueda.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _busqueda = '';
                    _fincaSeleccionada = 0;
                    _cultivoSeleccionadoId = null;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.inputFill(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
 
 
  Widget _buildFincasSection() {
    final fincas = _fincasFiltradas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mis Fincas',
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            if (_busqueda.isNotEmpty)
              Text('${fincas.length} resultado${fincas.length != 1 ? 's' : ''}',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        if (fincas.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Center(
            child: Text(
                _busqueda.isNotEmpty
                    ? 'No se encontraron fincas con "$_busqueda"'
                    : 'No tienes fincas asignadas aún',
                style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          if (fincas.length > 1) ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fincas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final selected = i == _fincaSeleccionada;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _fincaSeleccionada = i;
                        _cultivoSeleccionadoId = null;
                      });
                      AppState.instance.setFinca(fincas[i], _cultivosFincaActual);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(fincas[i]['nombreFinca'] ?? 'Finca ${i + 1}',
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_fincaSeleccionada < fincas.length)
            _buildFincaCard(fincas[_fincaSeleccionada]),
        ],
      ],
    );
  }
 
  Widget _buildFincaCard(Map<String, dynamic> finca) {
    final nombre = finca['nombreFinca'] ?? 'Finca';
    final municipio = finca['municipio'] ?? 'Sin municipio';
    final area = finca['areaHectareas'] ?? finca['area_hectareas'] ?? '-';
    final altitud = finca['altitudMsnm'] ?? finca['altitud_msnm'] ?? '-';
    final fotoUrl = (finca['fotoUrl'] ?? '').toString();
    final cultivos = _cultivosFincaActual;
    final monitoreos = _monitoreos.where((m) {
      final idsCultivosFinca = cultivos.map((c) => (c['idCultivo'] ?? c['id_cultivo']).toString()).toSet();
      final idCultivo = (m['idCultivo'] ?? m['id_cultivo']).toString();
      return idsCultivosFinca.contains(idCultivo);
    }).toList();
    final alertas = _contarAlertasFinca(finca);
 
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: fotoUrl.isNotEmpty
                    ? Image.network(
                        fotoUrl,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fotoPlaceholder(),
                      )
                    : _fotoPlaceholder(),
              ),
              if ((finca['activo'] ?? 1) == 1)
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('Activa',
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
 
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(municipio, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _tagFinca('$altitud msnm'),
                    _tagFinca('$area ha'),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _fincaDato(Icons.eco_outlined, '${cultivos.length}', 'Cultivos'),
                    Container(width: 1, height: 36, color: AppColors.border),
                    _fincaDato(Icons.bar_chart_outlined, '${monitoreos.length}', 'Monitoreos'),
                    Container(width: 1, height: 36, color: AppColors.border),
                    _fincaDato(
                      Icons.warning_amber_rounded,
                      '$alertas',
                      'Alertas',
                      colorValor: alertas > 0 ? Colors.red : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleFincaExpertoScreen(
                          finca: finca,
                          cultivos: _cultivos,
                          monitoreos: _monitoreos,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.eco_outlined, size: 18),
                    label: Text('Ver cultivos de la finca',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
 
  Widget _fotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.park_outlined, color: AppColors.primary, size: 40),
      ),
    );
  }
 
  Widget _tagFinca(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.inputFill(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto,
          style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
 
  Widget _fincaDato(IconData icon, String valor, String label, {Color? colorValor}) {
    return Column(
      children: [
        Icon(icon, color: colorValor ?? AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(valor, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: colorValor ?? AppColors.textPrimary)),
        Text(label, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
 
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No se pudo conectar', style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
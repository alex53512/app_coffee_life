import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AprenderScreen extends StatefulWidget {
  const AprenderScreen({super.key});

  @override
  State<AprenderScreen> createState() => _AprenderScreenState();
}

class _AprenderScreenState extends State<AprenderScreen> {
  final _searchController = TextEditingController();
  String _categoriaSeleccionada = 'Todos';

  final List<String> _categorias = [
    'Todos', 'Roya', 'Manejo', 'Nutrición', 'Cosecha'
  ];

  final List<Map<String, dynamic>> _articulos = [
    {
      'titulo': '¿Qué es la roya del café?',
      'subtitulo': 'Conoce todo sobre esta enfermedad y cómo identificarla.',
      'categoria': 'Roya',
      'color': Colors.red,
      'icono': Icons.bug_report_outlined,
      'tiempo': '5 min',
      'destacado': true,
    },
    {
      'titulo': 'Cómo aplicar fungicidas correctamente',
      'subtitulo': 'Guía práctica para el control químico de enfermedades.',
      'categoria': 'Manejo',
      'color': Colors.orange,
      'icono': Icons.science_outlined,
      'tiempo': '8 min',
      'destacado': true,
    },
    {
      'titulo': 'Nutrición del cafeto en floración',
      'subtitulo': 'Los nutrientes clave para maximizar tu cosecha.',
      'categoria': 'Nutrición',
      'color': AppColors.primary,
      'icono': Icons.eco_outlined,
      'tiempo': '6 min',
      'destacado': false,
    },
    {
      'titulo': 'Señales tempranas de roya',
      'subtitulo': 'Aprende a detectar la roya antes de que se propague.',
      'categoria': 'Roya',
      'color': Colors.red,
      'icono': Icons.search_outlined,
      'tiempo': '4 min',
      'destacado': false,
    },
    {
      'titulo': 'Cosecha selectiva vs mecanizada',
      'subtitulo': 'Ventajas y desventajas de cada método de recolección.',
      'categoria': 'Cosecha',
      'color': Colors.brown,
      'icono': Icons.agriculture_outlined,
      'tiempo': '7 min',
      'destacado': false,
    },
    {
      'titulo': 'Control biológico de plagas',
      'subtitulo': 'Alternativas naturales para proteger tu cultivo.',
      'categoria': 'Manejo',
      'color': Colors.teal,
      'icono': Icons.nature_outlined,
      'tiempo': '5 min',
      'destacado': false,
    },
  ];

  List<Map<String, dynamic>> get _articulosFiltrados {
    return _articulos.where((a) {
      final matchCategoria = _categoriaSeleccionada == 'Todos' ||
          a['categoria'] == _categoriaSeleccionada;
      final matchBusqueda = _searchController.text.isEmpty ||
          a['titulo']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchCategoria && matchBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBuscador(),
            _buildCategorias(),
            Expanded(child: _buildListaArticulos()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Aprender',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar contenido...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorias() {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categorias[index];
          final isSelected = _categoriaSeleccionada == cat;
          return GestureDetector(
            onTap: () => setState(() => _categoriaSeleccionada = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaArticulos() {
    final destacados =
        _articulosFiltrados.where((a) => a['destacado'] == true).toList();
    final resto =
        _articulosFiltrados.where((a) => a['destacado'] != true).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (destacados.isNotEmpty) ...[
          Text(
            'Artículos destacados',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...destacados.map((a) => _articuloDestacado(a)),
          const SizedBox(height: 20),
        ],
        if (resto.isNotEmpty) ...[
          Text(
            'Más artículos',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...resto.map((a) => _articuloSimple(a)),
        ],
      ],
    );
  }

  Widget _articuloDestacado(Map<String, dynamic> a) {
    return GestureDetector(
      onTap: () => _abrirArticulo(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (a['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a['icono'] as IconData,
                  color: a['color'] as Color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['titulo'],
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a['subtitulo'],
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (a['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          a['categoria'],
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: a['color'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        a['tiempo'],
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _articuloSimple(Map<String, dynamic> a) {
    return GestureDetector(
      onTap: () => _abrirArticulo(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (a['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(a['icono'] as IconData,
                  color: a['color'] as Color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['titulo'],
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${a['categoria']} · ${a['tiempo']}',
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _abrirArticulo(Map<String, dynamic> articulo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ArticuloScreen(articulo: articulo),
      ),
    );
  }
}

// ── Pantalla detalle del artículo ─────────────────────────────────────────
class _ArticuloScreen extends StatelessWidget {
  final Map<String, dynamic> articulo;
  const _ArticuloScreen({required this.articulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: (articulo['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        articulo['icono'] as IconData,
                        size: 80,
                        color: (articulo['color'] as Color).withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (articulo['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            articulo['categoria'],
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: articulo['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          articulo['tiempo'],
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      articulo['titulo'],
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'La roya del café (Hemileia vastatrix) es la enfermedad más importante del cultivo. '
                      'Se presenta como manchas amarillas en el haz de la hoja y pústulas anaranjadas en el envés.\n\n'
                      'Síntomas:\n'
                      '• Manchas amarillas en el haz de la hoja\n'
                      '• Pústulas anaranjadas en el envés\n'
                      '• Caída prematura de hojas\n\n'
                      'La enfermedad se desarrolla con mayor rapidez en condiciones de alta humedad '
                      '(superior al 85%) y temperaturas entre 21°C y 25°C.\n\n'
                      'Control:\n'
                      '• Aplicar fungicidas cúpricos preventivamente\n'
                      '• Mejorar ventilación del cultivo\n'
                      '• Eliminar hojas infectadas\n'
                      '• Monitorear regularmente las parcelas',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Artículo',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
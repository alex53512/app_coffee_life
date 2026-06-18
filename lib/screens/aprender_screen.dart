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
    'Todos',
    'Roya',
    'Manejo',
    'Nutrición',
    'Cosecha'
  ];

  final List<Map<String, dynamic>> _articulos = [
    {
      'titulo': '¿Qué es la roya del café?',
      'subtitulo': 'Conoce todo sobre esta enfermedad y cómo identificarla.',
      'categoria': 'Roya',
      'color': Colors.red,
      'imagen': 'assets/images/roya_cafe.jpg',
      'tiempo': '5 min',
      'destacado': true,
      'contenido':
          'La roya del café es una enfermedad causada por un hongo que afecta las hojas del cafeto.',
    },
    {
      'titulo': 'Cómo aplicar fungicidas correctamente',
      'subtitulo': 'Guía práctica para el control químico de enfermedades.',
      'categoria': 'Manejo',
      'color': Colors.orange,
      'imagen': 'assets/images/fungicida.jpg',
      'tiempo': '8 min',
      'destacado': true,
      'contenido':
          'Los fungicidas ayudan a prevenir y controlar enfermedades en el cultivo.',
    },
    {
      'titulo': 'Nutrición del cafeto en floración',
      'subtitulo': 'Los nutrientes clave para maximizar tu cosecha.',
      'categoria': 'Nutrición',
      'color': AppColors.primary,
      'imagen': 'assets/images/nutricion.jpg',
      'tiempo': '6 min',
      'destacado': false,
      'contenido':
          'La nutrición adecuada mejora la producción y calidad del café.',
    },
    {
      'titulo': 'Señales tempranas de roya',
      'subtitulo': 'Aprende a detectar la roya antes de que se propague.',
      'categoria': 'Roya',
      'color': Colors.red,
      'imagen': 'assets/images/roya2.jpg',
      'tiempo': '4 min',
      'destacado': false,
      'contenido':
          'Detectar la roya temprano evita daños graves en el cultivo.',
    },
    {
      'titulo': 'Cosecha selectiva vs mecanizada',
      'subtitulo': 'Ventajas y desventajas de cada método.',
      'categoria': 'Cosecha',
      'color': Colors.brown,
      'imagen': 'assets/images/cosecha.jpg',
      'tiempo': '7 min',
      'destacado': false,
      'contenido':
          'La forma de cosecha afecta la calidad del café producido.',
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
      backgroundColor: const Color(0xFFF4E7D6),
      body: Column(
        children: [
          // ── HEADER ──
          SafeArea(
            bottom: false,
            child: _buildHeader(),
          ),

          // BUSCADOR
          _buildBuscador(),

          const SizedBox(height: 4),

          // CATEGORÍAS
          _buildCategorias(),

          const SizedBox(height: 18),

          // CONTENEDOR REDONDEADO
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFBF7EF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildListaArticulos(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF4E7D6),
            const Color(0xFFF4E7D6).withOpacity(0.88),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.22),
                    AppColors.primary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 6),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aprender',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tips y guías para tu cultivo',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar contenido...',
            hintStyle:
                GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () => setState(() => _searchController.clear()),
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorias() {
    return SizedBox(
      height: 50,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          Color.lerp(AppColors.primary, Colors.black, 0.15) ??
                              AppColors.primary,
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.border.withOpacity(0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.35)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                cat,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          ...resto.map((a) => _articuloSimple(a)),
        ],
      ],
    );
  }

  Widget _articuloDestacado(Map<String, dynamic> a) {
    final color = a['color'] as Color;
    return GestureDetector(
      onTap: () => _abrirArticulo(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.asset(
                    a['imagen'],
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 170,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.18),
                            color.withOpacity(0.06),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        size: 60,
                        color: color,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      a['categoria'],
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          a['tiempo'],
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
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
                  Text(
                    a['titulo'],
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a['subtitulo'],
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Leer artículo',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward, size: 12, color: color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _articuloSimple(Map<String, dynamic> a) {
    final color = a['color'] as Color;
    return GestureDetector(
      onTap: () => _abrirArticulo(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                a['imagen'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.18),
                        color.withOpacity(0.06),
                      ],
                    ),
                  ),
                  child: Icon(Icons.image_outlined, color: color),
                ),
              ),
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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          a['categoria'],
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.schedule,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        a['tiempo'],
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 11,
                color: AppColors.primary,
              ),
            ),
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

class _ArticuloScreen extends StatelessWidget {
  final Map<String, dynamic> articulo;

  const _ArticuloScreen({required this.articulo});

  @override
  Widget build(BuildContext context) {
    final color = articulo['color'] as Color;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4E7D6),
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Artículo',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  articulo['imagen'],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.18),
                          color.withOpacity(0.06),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: color,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          articulo['categoria'],
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Container(width: 1, height: 10, color: Colors.white54),
                        const SizedBox(width: 6),
                        Text(
                          articulo['tiempo'],
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    articulo['titulo'],
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.border.withOpacity(0.7)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      articulo['contenido'],
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        height: 1.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
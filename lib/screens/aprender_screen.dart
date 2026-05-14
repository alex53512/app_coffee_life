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
      'imagen': 'assets/images/roya_cafe.jpg',
      'tiempo': '5 min',
      'destacado': true,
      'contenido':
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
          'Los fungicidas son herramientas clave para el control de enfermedades en el café.\n\n'
          'Tipos de fungicidas:\n'
          '• Cúpricos: preventivos, amplio espectro\n'
          '• Sistémicos: curativos, penetran en la planta\n'
          '• Biológicos: base de microorganismos\n\n'
          'Recomendaciones:\n'
          '• Aplicar en las horas de menor temperatura\n'
          '• Usar equipo de protección personal\n'
          '• Respetar los períodos de carencia\n'
          '• Rotar productos para evitar resistencia',
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
          'La etapa de floración es crítica para el cafeto.\n\n'
          'Nutrientes esenciales:\n'
          '• Nitrógeno (N): promueve el crecimiento vegetativo\n'
          '• Fósforo (P): favorece el desarrollo de raíces y flores\n'
          '• Potasio (K): mejora la calidad del grano\n'
          '• Boro (B): esencial para la polinización\n\n'
          'Recomendaciones:\n'
          '• Realizar análisis de suelo antes de fertilizar\n'
          '• Aplicar fertilizantes fraccionados\n'
          '• Mantener el pH del suelo entre 5.5 y 6.5',
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
          'Detectar la roya en sus etapas iniciales es fundamental.\n\n'
          'Señales tempranas:\n'
          '• Pequeñas manchas amarillo pálido en el haz\n'
          '• Polvo anaranjado en el envés (esporas)\n'
          '• Las hojas afectadas caen prematuramente\n\n'
          'Cómo monitorear:\n'
          '• Revisar las hojas inferiores de la planta\n'
          '• Inspeccionar al menos 10 plantas por lote\n'
          '• Registrar el porcentaje de hojas afectadas',
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
          'La elección del método de cosecha impacta la calidad del café.\n\n'
          'Cosecha selectiva:\n'
          '• Solo se recolectan los frutos maduros\n'
          '• Mayor calidad del grano\n'
          '• Mayor costo de mano de obra\n\n'
          'Cosecha mecanizada:\n'
          '• Se recolectan todos los frutos a la vez\n'
          '• Menor costo operativo\n'
          '• Puede incluir frutos verdes',
    },
    {
      'titulo': 'Control biológico de plagas',
      'subtitulo': 'Alternativas naturales para proteger tu cultivo.',
      'categoria': 'Manejo',
      'color': Colors.teal,
      'imagen': 'assets/images/plagas.jpg',
      'tiempo': '5 min',
      'destacado': false,
      'contenido':
          'El control biológico usa organismos vivos para reducir plagas.\n\n'
          'Métodos principales:\n'
          '• Uso de hongos entomopatógenos\n'
          '• Liberación de parasitoides naturales\n'
          '• Fomento de depredadores naturales\n\n'
          'Ventajas:\n'
          '• Menor impacto ambiental\n'
          '• Sin residuos químicos en el grano\n'
          '• Sostenible a largo plazo',
    },
  ];

  List<Map<String, dynamic>> get _articulosFiltrados {
    return _articulos.where((a) {
      final matchCategoria = _categoriaSeleccionada == 'Todos' ||
          a['categoria'] == _categoriaSeleccionada;
      final matchBusqueda = _searchController.text.isEmpty ||
          a['titulo'].toLowerCase().contains(_searchController.text.toLowerCase());
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
          Text('Aprender',
              style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
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
              child: Text(cat,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaArticulos() {
    final destacados = _articulosFiltrados.where((a) => a['destacado'] == true).toList();
    final resto = _articulosFiltrados.where((a) => a['destacado'] != true).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (destacados.isNotEmpty) ...[
          Text('Artículos destacados',
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...destacados.map((a) => _articuloDestacado(a)),
          const SizedBox(height: 20),
        ],
        if (resto.isNotEmpty) ...[
          Text('Más artículos',
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: Image.asset(
                a['imagen'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: (a['color'] as Color).withOpacity(0.1),
                  child: Icon(Icons.image_outlined,
                      size: 60, color: a['color'] as Color),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['titulo'],
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(a['subtitulo'],
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                a['imagen'],
                width: 60, height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60, height: 60,
                  color: (a['color'] as Color).withOpacity(0.1),
                  child: Icon(Icons.image_outlined,
                      color: a['color'] as Color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['titulo'],
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('${a['categoria']} · ${a['tiempo']}',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: AppColors.textSecondary)),
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
      MaterialPageRoute(builder: (_) => _ArticuloScreen(articulo: articulo)),
    );
  }
}

class _ArticuloScreen extends StatelessWidget {
  final Map<String, dynamic> articulo;
  const _ArticuloScreen({required this.articulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      articulo['imagen'],
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: (articulo['color'] as Color).withOpacity(0.1),
                        child: Icon(Icons.image_outlined,
                            size: 80, color: articulo['color'] as Color),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(articulo['titulo'],
                              style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(articulo['subtitulo'],
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 20),
                          Text(articulo['contenido'] ?? '',
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.8)),
                        ],
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
            child: Text('Artículo',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
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
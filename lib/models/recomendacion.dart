class RecomendacionDetalle {
  final String titulo;
  final String descripcion;
  final String detalleGeneral;
  final List<Tratamiento> tratamientos;

  const RecomendacionDetalle({
    required this.titulo,
    required this.descripcion,
    required this.detalleGeneral,
    this.tratamientos = const [],
  });

  factory RecomendacionDetalle.fromJson(Map<String, dynamic> json) =>
      RecomendacionDetalle(
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        detalleGeneral: json['detalle_general'] as String? ?? '',
        tratamientos: (json['tratamientos'] as List?)
                ?.map((t) => Tratamiento.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class Tratamiento {
  final int paso;
  final String titulo;
  final String descripcion;
  final String detalle;
  final String consejo;
  final String precaucion;

  const Tratamiento({
    required this.paso,
    required this.titulo,
    required this.descripcion,
    required this.detalle,
    required this.consejo,
    required this.precaucion,
  });

  factory Tratamiento.fromJson(Map<String, dynamic> json) => Tratamiento(
        paso: json['paso'] as int? ?? 0,
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        detalle: json['detalle'] as String? ?? '',
        consejo: json['consejo'] as String? ?? '',
        precaucion: json['precaucion'] as String? ?? '',
      );
}

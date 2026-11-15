class Noticia {
  final int id;
  final String titulo;
  final String? resumen;
  final String? contenido;
  final String? imagenUrl;
  final Set<String> etiquetas;

  /// Codigos de las intolerancias relacionadas con la noticia.
  final Set<String> intolerancias;
  final DateTime fechaPublicacion;

  Noticia({
    required this.id,
    required this.titulo,
    this.resumen,
    this.contenido,
    this.imagenUrl,
    required this.etiquetas,
    this.intolerancias = const {},
    required this.fechaPublicacion,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) => Noticia(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        resumen: json['resumen'],
        contenido: json['contenido'],
        imagenUrl: json['imagenUrl'],
        etiquetas: ((json['etiquetas'] as List?) ?? []).map((e) => e.toString()).toSet(),
        intolerancias: ((json['intolerancias'] as List?) ?? []).map((e) => e.toString()).toSet(),
        fechaPublicacion:
            DateTime.tryParse(json['fechaPublicacion'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'resumen': resumen,
        'contenido': contenido,
        'imagenUrl': imagenUrl,
        'etiquetas': etiquetas.toList(),
        'intolerancias': intolerancias.toList(),
      };
}

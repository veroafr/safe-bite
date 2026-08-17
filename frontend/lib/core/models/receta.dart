class Receta {
  final int id;
  final String titulo;
  final String? descripcion;
  final int? tiempoPreparacionMinutos;
  final String? dificultad;
  final String? imagenUrl;
  final bool esTip;
  final Set<String> etiquetas;
  final List<String> ingredientes;
  final List<String> pasos;

  Receta({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.tiempoPreparacionMinutos,
    this.dificultad,
    this.imagenUrl,
    required this.esTip,
    required this.etiquetas,
    required this.ingredientes,
    required this.pasos,
  });

  factory Receta.fromJson(Map<String, dynamic> json) => Receta(
        id: json['id'],
        titulo: json['titulo'] ?? '',
        descripcion: json['descripcion'],
        tiempoPreparacionMinutos: json['tiempoPreparacionMinutos'],
        dificultad: json['dificultad'],
        imagenUrl: json['imagenUrl'],
        esTip: json['esTip'] ?? false,
        etiquetas: ((json['etiquetas'] as List?) ?? []).map((e) => e.toString()).toSet(),
        ingredientes: ((json['ingredientes'] as List?) ?? []).map((e) => e.toString()).toList(),
        pasos: ((json['pasos'] as List?) ?? []).map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'tiempoPreparacionMinutos': tiempoPreparacionMinutos,
        'dificultad': dificultad,
        'imagenUrl': imagenUrl,
        'esTip': esTip,
        'etiquetas': etiquetas.toList(),
        'ingredientes': ingredientes,
        'pasos': pasos,
      };
}

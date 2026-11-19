import '../../core/i18n/i18n.dart';
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

  /// MANUAL (la cargó el administrador) o RSS (importada de un medio).
  final String origen;

  /// Medio que la publicó (solo las importadas).
  final String? fuente;

  /// Enlace a la noticia original (solo las importadas).
  final String? urlOriginal;

  /// UY o BR (solo las importadas).
  final String? pais;

  bool get esImportada => origen == 'RSS';

  String? get nombrePais => pais == 'UY' ? tr('Uruguay') : pais == 'BR' ? tr('Brasil') : null;

  Noticia({
    required this.id,
    required this.titulo,
    this.resumen,
    this.contenido,
    this.imagenUrl,
    required this.etiquetas,
    this.intolerancias = const {},
    required this.fechaPublicacion,
    this.origen = 'MANUAL',
    this.fuente,
    this.urlOriginal,
    this.pais,
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
        origen: json['origen'] ?? 'MANUAL',
        fuente: json['fuente'],
        urlOriginal: json['urlOriginal'],
        pais: json['pais'],
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

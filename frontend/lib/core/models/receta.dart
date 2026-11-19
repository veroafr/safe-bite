class Receta {
  final int id;
  final String titulo;
  final String? descripcion;
  final int? tiempoPreparacionMinutos;
  final String? dificultad;
  final String? imagenUrl;
  final bool esTip;
  final Set<String> etiquetas;

  /// Codigos de intolerancias para las que la receta es apta ("libre de").
  final Set<String> libreDe;
  final List<String> ingredientes;
  final List<String> pasos;

  /// ADMIN, USUARIO o SPOONACULAR.
  final String origen;
  /// PENDIENTE, APROBADA o RECHAZADA.
  final String estado;
  final String? motivoRechazo;
  final String? autorNombre;
  final int? externoId;
  final String? tituloOriginal;
  final String? fuenteUrl;
  final String? creditos;
  final int? porciones;
  /// Intolerancias que SafeBite encontró en los ingredientes.
  final Set<String> detectados;
  /// Detectadas que contradicen "libre de" (aviso para el admin).
  final Set<String> conflictos;
  final bool traducida;
  final String? aviso;
  final DateTime? fecha;

  bool get esSpoonacular => origen == 'SPOONACULAR';
  bool get esDeUsuario => origen == 'USUARIO';
  bool get pendiente => estado == 'PENDIENTE';
  bool get rechazada => estado == 'RECHAZADA';

  Receta({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.tiempoPreparacionMinutos,
    this.dificultad,
    this.imagenUrl,
    required this.esTip,
    required this.etiquetas,
    this.libreDe = const {},
    required this.ingredientes,
    required this.pasos,
    this.origen = 'ADMIN',
    this.estado = 'APROBADA',
    this.motivoRechazo,
    this.autorNombre,
    this.externoId,
    this.tituloOriginal,
    this.fuenteUrl,
    this.creditos,
    this.porciones,
    this.detectados = const {},
    this.conflictos = const {},
    this.traducida = false,
    this.aviso,
    this.fecha,
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
        libreDe: ((json['libreDe'] as List?) ?? []).map((e) => e.toString()).toSet(),
        ingredientes: ((json['ingredientes'] as List?) ?? []).map((e) => e.toString()).toList(),
        pasos: ((json['pasos'] as List?) ?? []).map((e) => e.toString()).toList(),
        origen: json['origen'] ?? 'ADMIN',
        estado: json['estado'] ?? 'APROBADA',
        motivoRechazo: json['motivoRechazo'],
        autorNombre: json['autorNombre'],
        externoId: json['externoId'],
        tituloOriginal: json['tituloOriginal'],
        fuenteUrl: json['fuenteUrl'],
        creditos: json['creditos'],
        porciones: json['porciones'],
        detectados: ((json['detectados'] as List?) ?? []).map((e) => e.toString()).toSet(),
        conflictos: ((json['conflictos'] as List?) ?? []).map((e) => e.toString()).toSet(),
        traducida: json['traducida'] ?? false,
        aviso: json['aviso'],
        fecha: DateTime.tryParse(json['fechaPublicacion'] ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'tiempoPreparacionMinutos': tiempoPreparacionMinutos,
        'dificultad': dificultad,
        'imagenUrl': imagenUrl,
        'esTip': esTip,
        'etiquetas': etiquetas.toList(),
        'libreDe': libreDe.toList(),
        'ingredientes': ingredientes,
        'pasos': pasos,
      };
}

/// Resultado de búsqueda en Spoonacular (panel admin).
class RecetaExterna {
  final int externoId;
  final String titulo;
  final String tituloOriginal;
  final String? imagenUrl;
  final bool yaImportada;

  RecetaExterna({
    required this.externoId,
    required this.titulo,
    required this.tituloOriginal,
    this.imagenUrl,
    this.yaImportada = false,
  });

  factory RecetaExterna.fromJson(Map<String, dynamic> json) => RecetaExterna(
        externoId: json['externoId'],
        titulo: json['titulo'] ?? '',
        tituloOriginal: json['tituloOriginal'] ?? '',
        imagenUrl: json['imagenUrl'],
        yaImportada: json['yaImportada'] ?? false,
      );
}

class BusquedaExterna {
  final List<RecetaExterna> resultados;
  final List<String> sinFiltroEnFuente;
  final String? consultaEnIngles;
  final num? cuotaRestante;

  BusquedaExterna({required this.resultados, this.sinFiltroEnFuente = const [], this.consultaEnIngles, this.cuotaRestante});

  factory BusquedaExterna.fromJson(Map<String, dynamic> json) => BusquedaExterna(
        resultados: ((json['resultados'] as List?) ?? []).map((e) => RecetaExterna.fromJson(e)).toList(),
        sinFiltroEnFuente: ((json['sinFiltroEnFuente'] as List?) ?? []).map((e) => e.toString()).toList(),
        consultaEnIngles: json['consultaEnIngles'],
        cuotaRestante: (json['cuota'] as Map?)?['cuotaRestante'],
      );
}

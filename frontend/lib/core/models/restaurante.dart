import 'usuario.dart';

class Restaurante {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final String? imagenUrl;

  /// Foto cuadrada de la lista (data URL o enlace).
  final String? imagenMiniatura;

  /// Foto rectangular 2:1 de la ficha (solo viene al abrir el restaurante).
  final String? imagenBanner;
  final double ratingPromedio;
  final Set<String> tiposCocina;
  /// Codigos de intolerancias para las que el local tiene opciones aptas.
  final Set<String> opcionesAptasPara;

  Restaurante({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.latitud,
    this.longitud,
    this.imagenUrl,
    this.imagenMiniatura,
    this.imagenBanner,
    required this.ratingPromedio,
    required this.tiposCocina,
    required this.opcionesAptasPara,
  });

  factory Restaurante.fromJson(Map<String, dynamic> json) {
    return Restaurante(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      direccion: json['direccion'],
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      imagenUrl: json['imagenUrl'],
      imagenMiniatura: json['imagenMiniatura'],
      imagenBanner: json['imagenBanner'],
      ratingPromedio: (json['ratingPromedio'] as num?)?.toDouble() ?? 0.0,
      tiposCocina: ((json['tiposCocina'] as List?) ?? []).map((e) => e.toString()).toSet(),
      opcionesAptasPara: codigosIntolerancias(json['opcionesAptasPara']),
    );
  }
}

class Comentario {
  final int id;
  final int restauranteId;
  final String usuarioNombre;
  final String texto;
  final DateTime fecha;

  Comentario({
    required this.id,
    required this.restauranteId,
    required this.usuarioNombre,
    required this.texto,
    required this.fecha,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) => Comentario(
        id: json['id'],
        restauranteId: json['restauranteId'],
        usuarioNombre: json['usuarioNombre'] ?? '',
        texto: json['texto'] ?? '',
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      );
}

class Evaluacion {
  final int id;
  final int restauranteId;
  final String usuarioNombre;
  final String? usuarioFoto;
  final int puntuacion;
  final String? comentario;
  final DateTime fecha;
  /// PENDIENTE, APROBADA o RECHAZADA.
  final String estado;
  final String? motivoRechazo;
  final String? restauranteNombre;

  Evaluacion({
    required this.id,
    required this.restauranteId,
    required this.usuarioNombre,
    this.usuarioFoto,
    required this.puntuacion,
    this.comentario,
    required this.fecha,
    this.estado = 'APROBADA',
    this.motivoRechazo,
    this.restauranteNombre,
  });

  bool get pendiente => estado == 'PENDIENTE';
  bool get rechazada => estado == 'RECHAZADA';

  factory Evaluacion.fromJson(Map<String, dynamic> json) => Evaluacion(
        id: json['id'],
        restauranteId: json['restauranteId'],
        usuarioNombre: json['usuarioNombre'] ?? '',
        usuarioFoto: json['usuarioFoto'],
        puntuacion: json['puntuacion'] ?? 0,
        comentario: json['comentario'],
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
        estado: json['estado'] ?? 'APROBADA',
        motivoRechazo: json['motivoRechazo'],
        restauranteNombre: json['restauranteNombre'],
      );
}

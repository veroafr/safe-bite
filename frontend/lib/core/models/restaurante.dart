import 'usuario.dart';

class Restaurante {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final String? imagenUrl;
  final double ratingPromedio;
  final Set<String> tiposCocina;
  final Set<TipoIntolerancia> opcionesAptasPara;

  Restaurante({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.latitud,
    this.longitud,
    this.imagenUrl,
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
      ratingPromedio: (json['ratingPromedio'] as num?)?.toDouble() ?? 0.0,
      tiposCocina: ((json['tiposCocina'] as List?) ?? []).map((e) => e.toString()).toSet(),
      opcionesAptasPara: ((json['opcionesAptasPara'] as List?) ?? [])
          .map((e) => tipoIntoleranciaDesde(e))
          .toSet(),
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
  final int puntuacion;
  final String? comentario;
  final DateTime fecha;

  Evaluacion({
    required this.id,
    required this.restauranteId,
    required this.usuarioNombre,
    required this.puntuacion,
    this.comentario,
    required this.fecha,
  });

  factory Evaluacion.fromJson(Map<String, dynamic> json) => Evaluacion(
        id: json['id'],
        restauranteId: json['restauranteId'],
        usuarioNombre: json['usuarioNombre'] ?? '',
        puntuacion: json['puntuacion'] ?? 0,
        comentario: json['comentario'],
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      );
}

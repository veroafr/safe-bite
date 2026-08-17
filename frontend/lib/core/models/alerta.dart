enum TipoAlerta { RESTAURANTE, PRODUCTO, COMENTARIO }

enum EstadoAlerta { PENDIENTE, ACEPTADA, DENEGADA }

TipoAlerta tipoAlertaDesde(String v) => TipoAlerta.values.firstWhere((e) => e.name == v);
EstadoAlerta estadoAlertaDesde(String v) => EstadoAlerta.values.firstWhere((e) => e.name == v);

class Alerta {
  final int id;
  final String? usuarioNombre;
  final TipoAlerta tipo;
  final int? restauranteId;
  final String? restauranteNombre;
  final int? productoId;
  final String? productoNombre;
  final String descripcion;
  final EstadoAlerta estado;
  final DateTime fecha;

  Alerta({
    required this.id,
    this.usuarioNombre,
    required this.tipo,
    this.restauranteId,
    this.restauranteNombre,
    this.productoId,
    this.productoNombre,
    required this.descripcion,
    required this.estado,
    required this.fecha,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        id: json['id'],
        usuarioNombre: json['usuarioNombre'],
        tipo: tipoAlertaDesde(json['tipo']),
        restauranteId: json['restauranteId'],
        restauranteNombre: json['restauranteNombre'],
        productoId: json['productoId'],
        productoNombre: json['productoNombre'],
        descripcion: json['descripcion'] ?? '',
        estado: estadoAlertaDesde(json['estado']),
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      );
}

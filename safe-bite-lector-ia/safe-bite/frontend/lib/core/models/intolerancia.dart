/// Intolerancia / alergeno del sistema. Ya no es un enum fijo: la lista
/// viene del backend (`/api/intolerancias`) y el administrador puede
/// agregar nuevas. En el resto de la app se manejan por su [codigo]
/// (ej: "TRIGO", "LECHE").
class Intolerancia {
  final int id;
  final String codigo;
  final String nombre;
  final String? nombreCientifico;
  final String? descripcion;
  final String? palabrasClave;
  final bool activa;
  final bool predefinida;
  final int orden;

  Intolerancia({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.nombreCientifico,
    this.descripcion,
    this.palabrasClave,
    this.activa = true,
    this.predefinida = false,
    this.orden = 0,
  });

  factory Intolerancia.fromJson(Map<String, dynamic> json) => Intolerancia(
        id: json['id'] ?? 0,
        codigo: json['codigo'] ?? '',
        nombre: json['nombre'] ?? '',
        nombreCientifico: json['nombreCientifico'],
        descripcion: json['descripcion'],
        palabrasClave: json['palabrasClave'],
        activa: json['activa'] ?? true,
        predefinida: json['predefinida'] ?? false,
        orden: json['orden'] ?? 0,
      );
}

/// Cache global de nombres (codigo -> nombre) para poder mostrar una
/// intolerancia desde cualquier widget sin pasar el provider. La completa
/// [IntoleranciasProvider] cada vez que carga la lista.
class IntoleranciaCatalogo {
  IntoleranciaCatalogo._();

  static final Map<String, String> _nombres = {};

  static void actualizar(Iterable<Intolerancia> lista) {
    for (final i in lista) {
      _nombres[i.codigo] = i.nombre;
    }
  }

  static String nombre(String codigo) => _nombres[codigo] ?? _legible(codigo);

  /// "CASTANA_CAJU" -> "Castana caju" (solo si todavia no cargo la lista).
  static String _legible(String codigo) {
    if (codigo.isEmpty) return codigo;
    final t = codigo.replaceAll('_', ' ').toLowerCase();
    return t[0].toUpperCase() + t.substring(1);
  }
}

/// Nombre para mostrar de un codigo de intolerancia.
String etiquetaIntolerancia(String codigo) => IntoleranciaCatalogo.nombre(codigo);

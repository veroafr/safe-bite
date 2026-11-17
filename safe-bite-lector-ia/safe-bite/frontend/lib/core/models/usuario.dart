export 'intolerancia.dart' show etiquetaIntolerancia, IntoleranciaCatalogo;

enum Rol { USUARIO, ADMINISTRADOR }

enum NivelAlerta { BAJO, MEDIO, ALTO }

Rol rolDesde(String? valor) =>
    Rol.values.firstWhere((e) => e.name == valor, orElse: () => Rol.USUARIO);

NivelAlerta nivelAlertaDesde(String? valor) => NivelAlerta.values
    .firstWhere((e) => e.name == valor, orElse: () => NivelAlerta.ALTO);

/// Convierte la lista JSON de codigos de intolerancias en un Set<String>.
Set<String> codigosIntolerancias(dynamic lista) =>
    ((lista as List?) ?? []).map((e) => e.toString()).toSet();

class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String? fotoPerfilUrl;
  final String? ciudad;
  final String? pais;
  final String idioma;
  final Rol rol;

  /// Codigos de intolerancias (ej: {"TRIGO", "LECHE"}).
  final Set<String> intolerancias;

  /// Opcion "Busco alimentarme mejor".
  final bool buscaAlimentacionSaludable;
  final NivelAlerta nivelAlerta;
  final Set<String> tiposCocinaPreferidos;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.fotoPerfilUrl,
    this.ciudad,
    this.pais,
    required this.idioma,
    required this.rol,
    required this.intolerancias,
    this.buscaAlimentacionSaludable = false,
    required this.nivelAlerta,
    required this.tiposCocinaPreferidos,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      fotoPerfilUrl: json['fotoPerfilUrl'],
      ciudad: json['ciudad'],
      pais: json['pais'],
      idioma: json['idioma'] ?? 'es',
      rol: rolDesde(json['rol']),
      intolerancias: codigosIntolerancias(json['intolerancias']),
      buscaAlimentacionSaludable: json['buscaAlimentacionSaludable'] ?? false,
      nivelAlerta: nivelAlertaDesde(json['nivelAlerta']),
      tiposCocinaPreferidos:
          ((json['tiposCocinaPreferidos'] as List?) ?? []).map((e) => e.toString()).toSet(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'fotoPerfilUrl': fotoPerfilUrl,
        'ciudad': ciudad,
        'pais': pais,
        'idioma': idioma,
        'rol': rol.name,
        'intolerancias': intolerancias.toList(),
        'buscaAlimentacionSaludable': buscaAlimentacionSaludable,
        'nivelAlerta': nivelAlerta.name,
        'tiposCocinaPreferidos': tiposCocinaPreferidos.toList(),
      };
}

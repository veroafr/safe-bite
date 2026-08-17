enum Rol { USUARIO, ADMINISTRADOR }

enum TipoIntolerancia { GLUTEN, LACTOSA, FRUTOS_SECOS, MARISCOS }

enum NivelAlerta { BAJO, MEDIO, ALTO }

Rol rolDesde(String? valor) =>
    Rol.values.firstWhere((e) => e.name == valor, orElse: () => Rol.USUARIO);

NivelAlerta nivelAlertaDesde(String? valor) => NivelAlerta.values
    .firstWhere((e) => e.name == valor, orElse: () => NivelAlerta.ALTO);

TipoIntolerancia tipoIntoleranciaDesde(String valor) =>
    TipoIntolerancia.values.firstWhere((e) => e.name == valor);

String etiquetaIntolerancia(TipoIntolerancia t) {
  switch (t) {
    case TipoIntolerancia.GLUTEN:
      return 'Gluten';
    case TipoIntolerancia.LACTOSA:
      return 'Lactosa';
    case TipoIntolerancia.FRUTOS_SECOS:
      return 'Frutos Secos';
    case TipoIntolerancia.MARISCOS:
      return 'Mariscos';
  }
}

class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String? fotoPerfilUrl;
  final String? ciudad;
  final String? pais;
  final String idioma;
  final Rol rol;
  final Set<TipoIntolerancia> intolerancias;
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
      intolerancias: ((json['intolerancias'] as List?) ?? [])
          .map((e) => tipoIntoleranciaDesde(e))
          .toSet(),
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
        'intolerancias': intolerancias.map((e) => e.name).toList(),
        'nivelAlerta': nivelAlerta.name,
        'tiposCocinaPreferidos': tiposCocinaPreferidos.toList(),
      };
}

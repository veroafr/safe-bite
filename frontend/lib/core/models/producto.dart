import 'usuario.dart';

class Producto {
  final int id;
  final String nombre;
  final String? marca;
  final String? codigoEan;
  final String? imagenUrl;
  final List<String> ingredientes;
  final Set<TipoIntolerancia> alergenos;
  final String origen;
  final bool verificado;
  final String? aportadoPorEmail;

  Producto({
    required this.id,
    required this.nombre,
    this.marca,
    this.codigoEan,
    this.imagenUrl,
    required this.ingredientes,
    required this.alergenos,
    this.origen = 'ADMIN',
    this.verificado = true,
    this.aportadoPorEmail,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        marca: json['marca'],
        codigoEan: json['codigoEan'],
        imagenUrl: json['imagenUrl'],
        ingredientes: ((json['ingredientes'] as List?) ?? []).map((e) => e.toString()).toList(),
        alergenos: ((json['alergenos'] as List?) ?? []).map((e) => tipoIntoleranciaDesde(e)).toSet(),
        origen: json['origen'] ?? 'ADMIN',
        verificado: json['verificado'] ?? true,
        aportadoPorEmail: json['aportadoPorEmail'],
      );
}

class ResultadoEscaneo {
  final Producto producto;
  final bool seguro;
  final bool datosSuficientes;
  final Set<TipoIntolerancia> alergenosEnConflicto;
  final String mensaje;

  ResultadoEscaneo({
    required this.producto,
    required this.seguro,
    required this.datosSuficientes,
    required this.alergenosEnConflicto,
    required this.mensaje,
  });

  factory ResultadoEscaneo.fromJson(Map<String, dynamic> json) => ResultadoEscaneo(
        producto: Producto.fromJson(json['producto']),
        seguro: json['seguro'] ?? false,
        datosSuficientes: json['datosSuficientes'] ?? true,
        alergenosEnConflicto: ((json['alergenosEnConflicto'] as List?) ?? [])
            .map((e) => tipoIntoleranciaDesde(e))
            .toSet(),
        mensaje: json['mensaje'] ?? '',
      );
}

class AnalisisIngredientes {
  final bool seguro;
  final Set<TipoIntolerancia> alergenosEncontrados;
  final String mensaje;
  final String textoAnalizado;

  AnalisisIngredientes({
    required this.seguro,
    required this.alergenosEncontrados,
    required this.mensaje,
    required this.textoAnalizado,
  });

  factory AnalisisIngredientes.fromJson(Map<String, dynamic> json) => AnalisisIngredientes(
        seguro: json['seguro'] ?? false,
        alergenosEncontrados: ((json['alergenosEncontrados'] as List?) ?? [])
            .map((e) => tipoIntoleranciaDesde(e))
            .toSet(),
        mensaje: json['mensaje'] ?? '',
        textoAnalizado: json['textoAnalizado'] ?? '',
      );
}

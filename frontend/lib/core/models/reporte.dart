class DatoReporte {
  final String etiqueta;
  final double valor;
  DatoReporte(this.etiqueta, this.valor);

  factory DatoReporte.fromJson(Map<String, dynamic> j) =>
      DatoReporte(j['etiqueta'] ?? '', (j['valor'] as num?)?.toDouble() ?? 0);
}

class SerieReporte {
  final String clave;
  final String titulo;
  final String? descripcion;
  /// "columnas" (evolución en el tiempo) o "barras" (categorías).
  final String tipo;
  final String unidad;
  final List<DatoReporte> datos;

  SerieReporte({
    required this.clave,
    required this.titulo,
    this.descripcion,
    required this.tipo,
    required this.unidad,
    required this.datos,
  });

  factory SerieReporte.fromJson(Map<String, dynamic> j) => SerieReporte(
        clave: j['clave'] ?? '',
        titulo: j['titulo'] ?? '',
        descripcion: j['descripcion'],
        tipo: j['tipo'] ?? 'barras',
        unidad: j['unidad'] ?? '',
        datos: ((j['datos'] as List?) ?? []).map((e) => DatoReporte.fromJson(e)).toList(),
      );
}

class Reporte {
  final int totalUsuarios;
  final int usuariosActivos;
  final int totalRestaurantes;
  final int totalRecetas;
  final int totalNoticias;
  final int totalProductos;
  final int totalResenas;
  final int alertasPendientes;
  final int alertasAceptadas;
  final int alertasDenegadas;
  final int productosPendientes;
  final int recetasPendientes;
  final int resenasPendientes;
  final int recuperacionesPendientes;
  final DateTime? generado;
  final List<SerieReporte> series;

  Reporte({
    required this.totalUsuarios,
    this.usuariosActivos = 0,
    required this.totalRestaurantes,
    required this.totalRecetas,
    required this.totalNoticias,
    required this.totalProductos,
    this.totalResenas = 0,
    required this.alertasPendientes,
    required this.alertasAceptadas,
    required this.alertasDenegadas,
    this.productosPendientes = 0,
    this.recetasPendientes = 0,
    this.resenasPendientes = 0,
    this.recuperacionesPendientes = 0,
    this.generado,
    this.series = const [],
  });

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
        totalUsuarios: json['totalUsuarios'] ?? 0,
        usuariosActivos: json['usuariosActivos'] ?? 0,
        totalRestaurantes: json['totalRestaurantes'] ?? 0,
        totalRecetas: json['totalRecetas'] ?? 0,
        totalNoticias: json['totalNoticias'] ?? 0,
        totalProductos: json['totalProductos'] ?? 0,
        totalResenas: json['totalResenas'] ?? 0,
        alertasPendientes: json['alertasPendientes'] ?? 0,
        alertasAceptadas: json['alertasAceptadas'] ?? 0,
        alertasDenegadas: json['alertasDenegadas'] ?? 0,
        productosPendientes: json['productosPendientes'] ?? 0,
        recetasPendientes: json['recetasPendientes'] ?? 0,
        resenasPendientes: json['resenasPendientes'] ?? 0,
        recuperacionesPendientes: json['recuperacionesPendientes'] ?? 0,
        generado: DateTime.tryParse(json['generado'] ?? ''),
        series: ((json['series'] as List?) ?? []).map((e) => SerieReporte.fromJson(e)).toList(),
      );
}

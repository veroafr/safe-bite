class Reporte {
  final int totalUsuarios;
  final int totalRestaurantes;
  final int totalRecetas;
  final int totalNoticias;
  final int totalProductos;
  final int alertasPendientes;
  final int alertasAceptadas;
  final int alertasDenegadas;

  Reporte({
    required this.totalUsuarios,
    required this.totalRestaurantes,
    required this.totalRecetas,
    required this.totalNoticias,
    required this.totalProductos,
    required this.alertasPendientes,
    required this.alertasAceptadas,
    required this.alertasDenegadas,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
        totalUsuarios: json['totalUsuarios'] ?? 0,
        totalRestaurantes: json['totalRestaurantes'] ?? 0,
        totalRecetas: json['totalRecetas'] ?? 0,
        totalNoticias: json['totalNoticias'] ?? 0,
        totalProductos: json['totalProductos'] ?? 0,
        alertasPendientes: json['alertasPendientes'] ?? 0,
        alertasAceptadas: json['alertasAceptadas'] ?? 0,
        alertasDenegadas: json['alertasDenegadas'] ?? 0,
      );
}

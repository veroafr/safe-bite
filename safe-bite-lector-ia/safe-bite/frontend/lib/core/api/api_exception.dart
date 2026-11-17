class ApiException implements Exception {
  final int statusCode;
  final String mensaje;

  ApiException(this.statusCode, this.mensaje);

  @override
  String toString() => mensaje;
}

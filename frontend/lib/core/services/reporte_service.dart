import '../api/api_client.dart';
import '../models/reporte.dart';

class ReporteService {
  final ApiClient _client;
  ReporteService(this._client);

  Future<Reporte> obtenerEstadisticas() async {
    final data = await _client.get('/admin/reportes/estadisticas');
    return Reporte.fromJson(data);
  }

  Future<List<int>> exportarPdf() => _client.getBytes('/admin/reportes/exportar-pdf');
}

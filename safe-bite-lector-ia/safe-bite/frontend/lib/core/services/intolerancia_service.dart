import '../api/api_client.dart';
import '../models/intolerancia.dart';

class IntoleranciaService {
  final ApiClient _client;
  IntoleranciaService(this._client);

  /// Intolerancias activas (publico: se usa tambien en el registro).
  Future<List<Intolerancia>> listarActivas() async {
    final data = await _client.get('/intolerancias', withAuth: false);
    return (data as List).map((e) => Intolerancia.fromJson(e)).toList();
  }

  // ---- Administracion ----

  Future<List<Intolerancia>> listarTodas() async {
    final data = await _client.get('/admin/intolerancias');
    return (data as List).map((e) => Intolerancia.fromJson(e)).toList();
  }

  Future<Intolerancia> crear(Map<String, dynamic> body) async {
    final data = await _client.post('/admin/intolerancias', body: body);
    return Intolerancia.fromJson(data);
  }

  Future<Intolerancia> editar(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/admin/intolerancias/$id', body: body);
    return Intolerancia.fromJson(data);
  }

  Future<Intolerancia> cambiarEstado(int id, bool activa) async {
    final data = await _client.patch('/admin/intolerancias/$id/estado', body: {'activa': activa});
    return Intolerancia.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/intolerancias/$id');
}

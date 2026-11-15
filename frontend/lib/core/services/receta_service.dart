import '../api/api_client.dart';
import '../models/receta.dart';

class RecetaService {
  final ApiClient _client;
  RecetaService(this._client);

  /// [intolerancias]: solo recetas libres de todas las indicadas.
  Future<List<Receta>> listar({bool? esTip, Set<String>? intolerancias, bool usarMisIntolerancias = false}) async {
    final data = await _client.get('/recetas', query: {
      'esTip': esTip,
      'intolerancias': intolerancias,
      'usarMisIntolerancias': usarMisIntolerancias,
    });
    return (data as List).map((e) => Receta.fromJson(e)).toList();
  }

  Future<Receta> obtener(int id) async {
    final data = await _client.get('/recetas/$id');
    return Receta.fromJson(data);
  }

  Future<Receta> crear(Map<String, dynamic> body) async {
    final data = await _client.post('/admin/recetas', body: body);
    return Receta.fromJson(data);
  }

  Future<Receta> editar(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/admin/recetas/$id', body: body);
    return Receta.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/recetas/$id');
}

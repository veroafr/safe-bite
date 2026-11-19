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

  /// Recetas de Spoonacular en vivo, filtradas por [intolerancias].
  Future<List<Receta>> externas({Set<String> intolerancias = const {}, String? consulta, int pagina = 0}) async {
    final data = await _client.get('/recetas/externas', query: {
      'intolerancias': intolerancias,
      'consulta': consulta,
      'pagina': pagina,
    });
    return (data as List).map((e) => Receta.fromJson(e)).toList();
  }

  Future<Receta> obtenerExterna(int externoId, Set<String> intolerancias) async {
    final data = await _client.get('/recetas/externas/$externoId', query: {'intolerancias': intolerancias});
    return Receta.fromJson(data);
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

  // ---- Recetas enviadas por usuarios ----

  /// Envía una receta propia: queda pendiente hasta que el admin la apruebe.
  Future<Receta> proponer(Map<String, dynamic> body) async {
    final data = await _client.post('/recetas/propuestas', body: body);
    return Receta.fromJson(data);
  }

  Future<Receta> editarPropuesta(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/recetas/propuestas/$id', body: body);
    return Receta.fromJson(data);
  }

  Future<List<Receta>> misPropuestas() async {
    final data = await _client.get('/recetas/mis-propuestas');
    return (data as List).map((e) => Receta.fromJson(e)).toList();
  }

  // ---- Moderación (admin) ----

  Future<List<Receta>> listarPorEstado(String estado) async {
    final data = await _client.get('/admin/recetas', query: {'estado': estado});
    return (data as List).map((e) => Receta.fromJson(e)).toList();
  }

  Future<Receta> moderar(int id, {required bool aprobar, String? motivo}) async {
    final data = await _client.put('/admin/recetas/$id/moderar', body: {'aprobar': aprobar, 'motivo': motivo});
    return Receta.fromJson(data);
  }

  // ---- Spoonacular (admin) ----

  Future<BusquedaExterna> buscarExternas({String? consulta, Set<String> intolerancias = const {}, int pagina = 0}) async {
    final data = await _client.get('/admin/recetas/spoonacular/buscar', query: {
      'consulta': consulta,
      'intolerancias': intolerancias,
      'pagina': pagina,
    });
    return BusquedaExterna.fromJson(data);
  }

  Future<Receta> vistaPreviaExterna(int externoId, Set<String> intolerancias) async {
    final data = await _client.get('/admin/recetas/spoonacular/$externoId', query: {'intolerancias': intolerancias});
    return Receta.fromJson(data);
  }

  Future<Receta> importarExterna(int externoId, {required String titulo, required Set<String> libreDe}) async {
    final data = await _client.post('/admin/recetas/spoonacular', body: {
      'externoId': externoId,
      'titulo': titulo,
      'libreDe': libreDe.toList(),
    });
    return Receta.fromJson(data);
  }
}

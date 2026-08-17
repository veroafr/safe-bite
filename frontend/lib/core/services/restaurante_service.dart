import '../api/api_client.dart';
import '../models/restaurante.dart';
import '../models/usuario.dart';

class RestauranteService {
  final ApiClient _client;
  RestauranteService(this._client);

  Future<List<Restaurante>> buscar({String? nombre, String? tipoCocina, TipoIntolerancia? intolerancia}) async {
    final data = await _client.get('/restaurantes', query: {
      'nombre': nombre,
      'tipoCocina': tipoCocina,
      'intolerancia': intolerancia?.name,
    });
    return (data as List).map((e) => Restaurante.fromJson(e)).toList();
  }

  Future<Restaurante> obtener(int id) async {
    final data = await _client.get('/restaurantes/$id');
    return Restaurante.fromJson(data);
  }

  Future<List<Comentario>> listarComentarios(int restauranteId) async {
    final data = await _client.get('/restaurantes/$restauranteId/comentarios');
    return (data as List).map((e) => Comentario.fromJson(e)).toList();
  }

  Future<Comentario> comentar(int restauranteId, String texto) async {
    final data = await _client.post('/restaurantes/$restauranteId/comentarios', body: {'texto': texto});
    return Comentario.fromJson(data);
  }

  Future<List<Evaluacion>> listarEvaluaciones(int restauranteId) async {
    final data = await _client.get('/restaurantes/$restauranteId/evaluaciones');
    return (data as List).map((e) => Evaluacion.fromJson(e)).toList();
  }

  Future<Evaluacion> evaluar(int restauranteId, int puntuacion, String? comentario) async {
    final data = await _client.post('/restaurantes/$restauranteId/evaluaciones',
        body: {'puntuacion': puntuacion, 'comentario': comentario});
    return Evaluacion.fromJson(data);
  }

  // ---- Administracion ----

  Future<Restaurante> crear(Map<String, dynamic> body) async {
    final data = await _client.post('/admin/restaurantes', body: body);
    return Restaurante.fromJson(data);
  }

  Future<Restaurante> editar(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/admin/restaurantes/$id', body: body);
    return Restaurante.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/restaurantes/$id');
}

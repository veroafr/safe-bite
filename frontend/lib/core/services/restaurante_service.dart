import '../api/api_client.dart';
import '../models/restaurante.dart';

class RestauranteService {
  final ApiClient _client;
  RestauranteService(this._client);

  /// [intolerancias]: el local tiene que tener opciones aptas para todas.
  Future<List<Restaurante>> buscar({String? nombre, String? tipoCocina, Set<String>? intolerancias}) async {
    final data = await _client.get('/restaurantes', query: {
      'nombre': nombre,
      'tipoCocina': tipoCocina,
      'intolerancias': intolerancias,
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

  /// Envía la reseña (estrellas + comentario). Queda pendiente hasta que el admin la apruebe.
  Future<Evaluacion> evaluar(int restauranteId, int puntuacion, String comentario) async {
    final data = await _client.post('/restaurantes/$restauranteId/evaluaciones',
        body: {'puntuacion': puntuacion, 'comentario': comentario});
    return Evaluacion.fromJson(data);
  }

  /// La reseña propia del usuario en ese restaurante (null si no tiene).
  Future<Evaluacion?> miEvaluacion(int restauranteId) async {
    final data = await _client.get('/restaurantes/$restauranteId/mi-evaluacion');
    if (data == null) return null;
    return Evaluacion.fromJson(data);
  }

  // ---- Moderación de reseñas (admin) ----

  Future<List<Evaluacion>> listarResenas({String estado = 'PENDIENTE'}) async {
    final data = await _client.get('/admin/restaurantes/resenas', query: {'estado': estado});
    return (data as List).map((e) => Evaluacion.fromJson(e)).toList();
  }

  Future<Evaluacion> moderarResena(int id, {required bool aprobar, String? motivo}) async {
    final data = await _client.put('/admin/restaurantes/resenas/$id/moderar',
        body: {'aprobar': aprobar, 'motivo': motivo});
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

import '../api/api_client.dart';
import '../models/noticia.dart';

class NoticiaService {
  final ApiClient _client;
  NoticiaService(this._client);

  /// [intolerancias]: noticias relacionadas con alguna de ellas.
  Future<List<Noticia>> listar({String? etiqueta, Set<String>? intolerancias}) async {
    final data = await _client.get('/noticias', query: {'etiqueta': etiqueta, 'intolerancias': intolerancias});
    return (data as List).map((e) => Noticia.fromJson(e)).toList();
  }

  Future<Noticia> obtener(int id) async {
    final data = await _client.get('/noticias/$id');
    return Noticia.fromJson(data);
  }

  Future<Noticia> crear(Map<String, dynamic> body) async {
    final data = await _client.post('/admin/noticias', body: body);
    return Noticia.fromJson(data);
  }

  Future<Noticia> editar(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/admin/noticias/$id', body: body);
    return Noticia.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/noticias/$id');
}

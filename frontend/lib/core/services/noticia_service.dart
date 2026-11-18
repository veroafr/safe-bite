import '../api/api_client.dart';
import '../models/noticia.dart';

class NoticiaService {
  final ApiClient _client;
  NoticiaService(this._client);

  /// [intolerancias]: noticias relacionadas con alguna de ellas.
  /// [pais]: UY o BR (las cargadas por el administrador se muestran siempre).
  Future<List<Noticia>> listar({String? etiqueta, Set<String>? intolerancias, String? pais}) async {
    final data = await _client.get('/noticias', query: {'etiqueta': etiqueta, 'intolerancias': intolerancias, 'pais': pais});
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

  /// Inicia en el servidor la importación de noticias de Uruguay y Brasil
  /// (RSS). Responde enseguida con un mensaje y el resultado de la anterior.
  Future<Map<String, dynamic>> importarRss() async {
    final data = await _client.post('/admin/noticias/importar-rss');
    return Map<String, dynamic>.from(data as Map);
  }
}

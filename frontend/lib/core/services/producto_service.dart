import '../api/api_client.dart';
import '../models/producto.dart';

class ProductoService {
  final ApiClient _client;
  ProductoService(this._client);

  Future<List<Producto>> buscarPorNombre(String nombre) async {
    final data = await _client.get('/productos/buscar', query: {'nombre': nombre});
    return (data as List).map((e) => Producto.fromJson(e)).toList();
  }

  Future<ResultadoEscaneo> escanearPorEan(String codigo) async {
    final data = await _client.get('/productos/ean/$codigo');
    return ResultadoEscaneo.fromJson(data);
  }

  Future<ResultadoEscaneo> escanearPorOcr(String textoDetectado) async {
    final data = await _client.post('/productos/ocr', body: {'textoDetectado': textoDetectado});
    return ResultadoEscaneo.fromJson(data);
  }

  Future<AnalisisIngredientes> analizarIngredientes(String textoDetectado) async {
    final data = await _client.post('/productos/analizar-ingredientes', body: {'textoDetectado': textoDetectado});
    return AnalisisIngredientes.fromJson(data);
  }

  /// Un usuario carga a mano un producto que no aparecio en el escaneo
  /// (ni en la base propia ni en Open Food Facts). Queda pendiente de
  /// revision por un admin.
  Future<Producto> aportar(Map<String, dynamic> body) async {
    final data = await _client.post('/productos/aportar', body: body);
    return Producto.fromJson(data);
  }

  // ---- Administracion ----

  Future<List<Producto>> listarTodos() async {
    final data = await _client.get('/admin/productos');
    return (data as List).map((e) => Producto.fromJson(e)).toList();
  }

  /// Productos aportados por usuarios, pendientes de revision.
  Future<List<Producto>> listarPendientes() async {
    final data = await _client.get('/admin/productos/pendientes');
    return (data as List).map((e) => Producto.fromJson(e)).toList();
  }

  Future<Producto> crear(Map<String, dynamic> body) async {
    final data = await _client.post('/admin/productos', body: body);
    return Producto.fromJson(data);
  }

  Future<Producto> editar(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/admin/productos/$id', body: body);
    return Producto.fromJson(data);
  }

  /// Aprobar un producto pendiente: lo edita marcando verificado=true,
  /// conservando el resto de sus datos actuales.
  Future<Producto> aprobar(Producto p) async {
    final data = await _client.put('/admin/productos/${p.id}', body: {
      'nombre': p.nombre,
      'marca': p.marca,
      'codigoEan': p.codigoEan,
      'imagenUrl': p.imagenUrl,
      'ingredientes': p.ingredientes,
      'alergenos': p.alergenos.map((a) => a.name).toList(),
      'verificado': true,
    });
    return Producto.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/productos/$id');
}

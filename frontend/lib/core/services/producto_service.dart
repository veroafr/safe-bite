import '../api/api_client.dart';
import '../models/producto.dart';
import '../models/usuario.dart';

/// Sugerencia de la IA de vision al leer las fotos del producto. El
/// formulario pre-completa estos valores, pero el usuario siempre puede
/// editarlos antes de enviar.
class AnalisisFotos {
  final String? nombreSugerido;
  final String? marcaSugerida;
  final String? categoriaSugerida;
  final List<String> ingredientes;
  final Set<TipoIntolerancia> alergenos;
  final bool pudoLeer;
  final String? observacion;

  AnalisisFotos({
    this.nombreSugerido,
    this.marcaSugerida,
    this.categoriaSugerida,
    required this.ingredientes,
    required this.alergenos,
    required this.pudoLeer,
    this.observacion,
  });

  factory AnalisisFotos.fromJson(Map<String, dynamic> json) => AnalisisFotos(
        nombreSugerido: json['nombreSugerido'],
        marcaSugerida: json['marcaSugerida'],
        categoriaSugerida: json['categoriaSugerida'],
        ingredientes: ((json['ingredientes'] as List?) ?? []).map((e) => e.toString()).toList(),
        alergenos: ((json['alergenos'] as List?) ?? []).map((e) => tipoIntoleranciaDesde(e)).toSet(),
        pudoLeer: json['pudoLeer'] ?? false,
        observacion: json['observacion'],
      );
}

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

  /// Completa los datos de un producto que ya existe pero llego con
  /// informacion insuficiente (tipicamente desde Open Food Facts).
  Future<Producto> completarDatos(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/productos/$id/completar', body: body);
    return Producto.fromJson(data);
  }

  /// Le pide a la IA que lea las fotos (frontal/composicion/nutricional)
  /// y sugiera nombre, marca, categoria, ingredientes y alergenos. Se usa
  /// desde el formulario de carga y desde "Escanear paquete".
  Future<AnalisisFotos> analizarFotos({
    String? fotoFrontalBase64,
    String? fotoComposicionBase64,
    String? fotoNutricionalBase64,
  }) async {
    final data = await _client.post('/productos/analizar-fotos', body: {
      'fotoFrontalBase64': fotoFrontalBase64,
      'fotoComposicionBase64': fotoComposicionBase64,
      'fotoNutricionalBase64': fotoNutricionalBase64,
    });
    return AnalisisFotos.fromJson(data);
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
      'fotoFrontalBase64': p.fotoFrontalBase64,
      'fotoComposicionBase64': p.fotoComposicionBase64,
      'fotoNutricionalBase64': p.fotoNutricionalBase64,
    });
    return Producto.fromJson(data);
  }

  /// Reemplaza o elimina UNA foto puntual (tipo: frontal/composicion/nutricional)
  /// sin tocar el resto de los datos del producto. base64 == null elimina.
  Future<Producto> actualizarFoto(int id, String tipo, String? base64) async {
    final data = await _client.put('/admin/productos/$id/foto', body: {
      'tipo': tipo,
      'base64': base64,
    });
    return Producto.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/productos/$id');
}

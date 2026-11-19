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
  final String? terminoBusquedaEs;
  final String? terminoBusquedaPt;
  final String? proveedor;
  final List<String> ingredientes;
  final Set<String> alergenos;
  final bool pudoLeer;
  final String? observacion;
  /// Código de barras que la IA leyó en la foto, si se veía.
  final String? codigoBarras;

  AnalisisFotos({
    this.nombreSugerido,
    this.marcaSugerida,
    this.categoriaSugerida,
    this.terminoBusquedaEs,
    this.terminoBusquedaPt,
    this.proveedor,
    required this.ingredientes,
    required this.alergenos,
    required this.pudoLeer,
    this.observacion,
    this.codigoBarras,
  });

  factory AnalisisFotos.fromJson(Map<String, dynamic> json) => AnalisisFotos(
        nombreSugerido: json['nombreSugerido'],
        marcaSugerida: json['marcaSugerida'],
        categoriaSugerida: json['categoriaSugerida'],
        terminoBusquedaEs: json['terminoBusquedaEs'],
        terminoBusquedaPt: json['terminoBusquedaPt'],
        proveedor: json['proveedor'],
        ingredientes: ((json['ingredientes'] as List?) ?? []).map((e) => e.toString()).toList(),
        alergenos: codigosIntolerancias(json['alergenos']),
        pudoLeer: json['pudoLeer'] ?? false,
        observacion: json['observacion'],
        codigoBarras: json['codigoBarras'],
      );
}

/// Una alternativa apta sugerida por la IA ("esto no, pero esto si").
class RecomendacionIa {
  final String nombre;
  final String? marca;
  final String? pais;
  final String? imagenUrl;
  final String origen; // SAFEBITE | OPEN_FOOD_FACTS
  final String? motivo;
  final bool verificarMarca;

  RecomendacionIa({
    required this.nombre,
    this.marca,
    this.pais,
    this.imagenUrl,
    required this.origen,
    this.motivo,
    this.verificarMarca = false,
  });

  factory RecomendacionIa.fromJson(Map<String, dynamic> json) => RecomendacionIa(
        nombre: json['nombre'] ?? '',
        marca: json['marca'],
        pais: json['pais'],
        imagenUrl: json['imagenUrl'],
        origen: json['origen'] ?? '',
        motivo: json['motivo'],
        verificarMarca: json['verificarMarca'] ?? false,
      );
}

class RecomendacionesIa {
  final String mensaje;
  final bool conIa;
  final String? advertencia;
  final List<RecomendacionIa> items;

  RecomendacionesIa({required this.mensaje, required this.conIa, this.advertencia, required this.items});

  factory RecomendacionesIa.fromJson(Map<String, dynamic> json) => RecomendacionesIa(
        mensaje: json['mensaje'] ?? '',
        conIa: json['conIa'] ?? false,
        advertencia: json['advertencia'],
        items: ((json['recomendaciones'] as List?) ?? [])
            .map((e) => RecomendacionIa.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ProductoService {
  final ApiClient _client;
  ProductoService(this._client);

  /// [excluirIntolerancias]: descarta los productos que contienen alguna.
  Future<List<Producto>> buscarPorNombre(String nombre, {Set<String>? excluirIntolerancias}) async {
    final data = await _client.get('/productos/buscar',
        query: {'nombre': nombre, 'excluirIntolerancias': excluirIntolerancias});
    return (data as List).map((e) => Producto.fromJson(e)).toList();
  }

  /// [intolerancias]: si se indica, el producto se evalua contra estas en
  /// lugar de las del perfil (filtro del escaner).
  Future<ResultadoEscaneo> escanearPorEan(String codigo, {Set<String>? intolerancias}) async {
    final data = await _client.get('/productos/ean/$codigo', query: {'intolerancias': intolerancias});
    return ResultadoEscaneo.fromJson(data);
  }

  Future<ResultadoEscaneo> escanearPorOcr(String textoDetectado, {Set<String>? intolerancias}) async {
    final data = await _client.post('/productos/ocr', body: {
      'textoDetectado': textoDetectado,
      if (intolerancias != null && intolerancias.isNotEmpty) 'intolerancias': intolerancias.toList(),
    });
    return ResultadoEscaneo.fromJson(data);
  }

  Future<AnalisisIngredientes> analizarIngredientes(String textoDetectado, {Set<String>? intolerancias}) async {
    final data = await _client.post('/productos/analizar-ingredientes', body: {
      'textoDetectado': textoDetectado,
      if (intolerancias != null && intolerancias.isNotEmpty) 'intolerancias': intolerancias.toList(),
    });
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

  /// Pide alternativas aptas para el usuario logueado a partir de un
  /// producto leido con "Escanear paquete" (base propia + Open Food Facts
  /// de Uruguay, Argentina y Brasil; la IA elige y explica).
  /// Foto de referencia (Open Food Facts) para un producto recomendado, o null.
  Future<String?> buscarImagen(String texto) async {
    final data = await _client.get('/productos/imagen', query: {'q': texto});
    final url = data is Map ? data['url'] : null;
    return url is String && url.isNotEmpty ? url : null;
  }

  Future<RecomendacionesIa> recomendar(AnalisisFotos a, {Set<String>? intolerancias}) async {
    final data = await _client.post('/productos/recomendar', body: {
      'nombre': a.nombreSugerido,
      'marca': a.marcaSugerida,
      'categoria': a.categoriaSugerida,
      'terminoBusquedaEs': a.terminoBusquedaEs,
      'terminoBusquedaPt': a.terminoBusquedaPt,
      'ingredientes': a.ingredientes,
      'alergenos': a.alergenos.toList(),
      if (intolerancias != null && intolerancias.isNotEmpty) 'intolerancias': intolerancias.toList(),
    });
    return RecomendacionesIa.fromJson(data);
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
      'categoria': p.categoria,
      'codigoEan': p.codigoEan,
      'imagenUrl': p.imagenUrl,
      'ingredientes': p.ingredientes,
      'alergenos': p.alergenos.toList(),
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

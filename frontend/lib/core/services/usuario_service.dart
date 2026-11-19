import '../api/api_client.dart';
import '../models/usuario.dart';

class UsuarioService {
  final ApiClient _client;
  UsuarioService(this._client);

  Future<Usuario> perfil() async {
    final data = await _client.get('/usuarios/me');
    return Usuario.fromJson(data);
  }

  Future<Usuario> actualizarPerfil(Map<String, dynamic> body) async {
    final data = await _client.put('/usuarios/me', body: body);
    return Usuario.fromJson(data);
  }

  Future<void> cambiarPassword(String actual, String nueva) => _client.put('/usuarios/me/password', body: {
        'passwordActual': actual,
        'passwordNueva': nueva,
      });

  Future<Usuario> actualizarPreferencias({
    Set<String>? intolerancias,
    bool? buscaAlimentacionSaludable,
    NivelAlerta? nivelAlerta,
    Set<String>? tiposCocinaPreferidos,
  }) async {
    final data = await _client.put('/usuarios/me/preferencias', body: {
      if (intolerancias != null) 'intolerancias': intolerancias.toList(),
      if (buscaAlimentacionSaludable != null) 'buscaAlimentacionSaludable': buscaAlimentacionSaludable,
      if (nivelAlerta != null) 'nivelAlerta': nivelAlerta.name,
      if (tiposCocinaPreferidos != null) 'tiposCocinaPreferidos': tiposCocinaPreferidos.toList(),
    });
    return Usuario.fromJson(data);
  }

  // ---- Administracion ----

  Future<List<Usuario>> listarTodos() async {
    final data = await _client.get('/admin/usuarios');
    return (data as List).map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Usuario> crearAdmin(Map<String, dynamic> body) async {
    final data = await _client.post('/admin/usuarios', body: body);
    return Usuario.fromJson(data);
  }

  Future<Usuario> editarAdmin(int id, Map<String, dynamic> body) async {
    final data = await _client.put('/admin/usuarios/$id', body: body);
    return Usuario.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/usuarios/$id');

  /// Asigna una contraseña; con [temporal] la persona debe cambiarla al entrar.
  Future<Usuario> asignarPassword(int id, String password, {bool temporal = true}) async {
    final data = await _client.put('/admin/usuarios/$id/password', body: {'password': password, 'temporal': temporal});
    return Usuario.fromJson(data);
  }

  // ---- Pedidos de recuperación de contraseña ----

  Future<List<SolicitudRecuperacion>> listarRecuperaciones({String estado = 'PENDIENTE'}) async {
    final data = await _client.get('/admin/recuperaciones', query: {'estado': estado});
    return (data as List).map((e) => SolicitudRecuperacion.fromJson(e)).toList();
  }

  Future<void> resolverRecuperacion(int id, String password, {String? nota}) =>
      _client.put('/admin/recuperaciones/$id/resolver', body: {'password': password, 'nota': nota});

  Future<void> descartarRecuperacion(int id, {String? nota}) =>
      _client.put('/admin/recuperaciones/$id/descartar', body: {'nota': nota});
}

class SolicitudRecuperacion {
  final int id;
  final String email;
  final String? telefono;
  final String? mensaje;
  final String estado;
  final DateTime? fecha;
  final DateTime? fechaResolucion;
  final String? nota;
  final bool cuentaEncontrada;
  final int? usuarioId;
  final String? usuarioNombre;
  final String? usuarioTelefono;
  final bool usuarioActivo;
  final String? resueltaPor;

  SolicitudRecuperacion.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        email = j['email'] ?? '',
        telefono = j['telefono'],
        mensaje = j['mensaje'],
        estado = j['estado'] ?? 'PENDIENTE',
        fecha = DateTime.tryParse(j['fecha'] ?? ''),
        fechaResolucion = DateTime.tryParse(j['fechaResolucion'] ?? ''),
        nota = j['nota'],
        cuentaEncontrada = j['cuentaEncontrada'] ?? false,
        usuarioId = j['usuarioId'],
        usuarioNombre = j['usuarioNombre'],
        usuarioTelefono = j['usuarioTelefono'],
        usuarioActivo = j['usuarioActivo'] ?? true,
        resueltaPor = j['resueltaPor'];

  bool get pendiente => estado == 'PENDIENTE';
}

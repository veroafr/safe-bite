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
    Set<TipoIntolerancia>? intolerancias,
    NivelAlerta? nivelAlerta,
    Set<String>? tiposCocinaPreferidos,
  }) async {
    final data = await _client.put('/usuarios/me/preferencias', body: {
      if (intolerancias != null) 'intolerancias': intolerancias.map((e) => e.name).toList(),
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
    final data = await _client.put('/admin/usuarios/', body: body);
    return Usuario.fromJson(data);
  }

  Future<void> eliminar(int id) => _client.delete('/admin/usuarios/');
}

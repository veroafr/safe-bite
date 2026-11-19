import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/usuario.dart';
import '../services/session_storage.dart';

enum EstadoAuth { cargando, autenticado, invitado }

class AuthProvider extends ChangeNotifier {
  final ApiClient _client;
  AuthProvider(this._client);

  EstadoAuth estado = EstadoAuth.cargando;
  Usuario? usuario;
  String? token;

  bool get esAdmin => usuario?.rol == Rol.ADMINISTRADOR;

  Future<void> cargarSesionGuardada() async {
    final t = await SessionStorage.getToken();
    final u = await SessionStorage.getUsuarioJson();
    if (t != null && u != null) {
      token = t;
      usuario = Usuario.fromJson(jsonDecode(u));
      estado = EstadoAuth.autenticado;
    } else {
      estado = EstadoAuth.invitado;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await _client.post('/auth/login',
        body: {'email': email, 'password': password}, withAuth: false);
    await _persistirSesion(data);
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    String? ciudad,
    String? pais,
    String idioma = 'es',
    Set<String> intolerancias = const {},
    bool buscaAlimentacionSaludable = false,
    String? fotoBase64,
  }) async {
    final data = await _client.post('/auth/registro', body: {
      if (fotoBase64 != null) 'fotoBase64': fotoBase64,
      'nombre': nombre,
      'email': email,
      'password': password,
      'ciudad': ciudad,
      'pais': pais,
      'idioma': idioma,
      'intolerancias': intolerancias.toList(),
      'buscaAlimentacionSaludable': buscaAlimentacionSaludable,
    }, withAuth: false);
    await _persistirSesion(data);
  }

  /// Pedido de "olvidé mi contraseña": llega al panel de administración.
  Future<void> recuperarPassword(String email, {String? telefono, String? mensaje}) async {
    await _client.post('/auth/recuperar-password',
        body: {
          'email': email,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
          if (mensaje != null && mensaje.isNotEmpty) 'mensaje': mensaje,
        },
        withAuth: false);
  }

  /// Cambia la contraseña temporal asignada por el administrador.
  Future<void> cambiarPasswordTemporal(String actual, String nueva) async {
    await _client.put('/usuarios/me/password', body: {'passwordActual': actual, 'passwordNueva': nueva});
    final data = await _client.get('/usuarios/me');
    await actualizarUsuario(Usuario.fromJson(data));
  }

  Future<void> _persistirSesion(dynamic data) async {
    token = data['token'];
    usuario = Usuario.fromJson(data['usuario']);
    await SessionStorage.guardarSesion(token!, jsonEncode(data['usuario']));
    estado = EstadoAuth.autenticado;
    notifyListeners();
  }

  Future<void> actualizarUsuario(Usuario nuevoUsuario) async {
    usuario = nuevoUsuario;
    if (token != null) {
      await SessionStorage.guardarSesion(token!, jsonEncode(nuevoUsuario.toJson()));
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await SessionStorage.cerrarSesion();
    token = null;
    usuario = null;
    estado = EstadoAuth.invitado;
    notifyListeners();
  }
}

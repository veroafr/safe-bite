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
  }) async {
    final data = await _client.post('/auth/registro', body: {
      'nombre': nombre,
      'email': email,
      'password': password,
      'ciudad': ciudad,
      'pais': pais,
      'idioma': idioma,
    }, withAuth: false);
    await _persistirSesion(data);
  }

  Future<void> recuperarPassword(String email) async {
    await _client.post('/auth/recuperar-password', body: {'email': email}, withAuth: false);
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

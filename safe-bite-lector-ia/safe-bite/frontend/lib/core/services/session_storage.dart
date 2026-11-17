import 'package:shared_preferences/shared_preferences.dart';

/// Persiste el token JWT y datos minimos de sesion entre reinicios de la app.
class SessionStorage {
  static const _keyToken = 'safebite_token';
  static const _keyUsuarioJson = 'safebite_usuario';

  static Future<void> guardarSesion(String token, String usuarioJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUsuarioJson, usuarioJson);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getUsuarioJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsuarioJson);
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsuarioJson);
  }
}

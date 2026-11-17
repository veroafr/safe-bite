/// Validaciones de formularios. Las expresiones son las mismas que usa el
/// backend (config/Validaciones.java), asi el mensaje aparece antes de enviar.
class Validadores {
  Validadores._();

  static final RegExp _email = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Ingresá tu email';
    if (!_email.hasMatch(t)) return 'Ingresá un email válido (ejemplo: nombre@dominio.com)';
    return null;
  }

  /// Reglas de contraseña segura. Devuelve la lista de lo que falta (vacia = OK).
  static List<String> faltantesPassword(String v) => [
        if (v.length < 6) 'al menos 6 caracteres',
        if (!RegExp(r'[A-Z]').hasMatch(v)) 'una mayúscula',
        if (!RegExp(r'\d').hasMatch(v)) 'un número',
        if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(v)) 'un carácter especial (ej: ! @ # \$ %)',
      ];

  static String? passwordSegura(String? v) {
    final faltan = faltantesPassword(v ?? '');
    if (faltan.isEmpty) return null;
    return 'La contraseña necesita ${faltan.join(', ')}';
  }

  static String? requerido(String? v, [String mensaje = 'Campo obligatorio']) =>
      (v == null || v.trim().isEmpty) ? mensaje : null;
}

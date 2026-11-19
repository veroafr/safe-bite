import '../../core/i18n/i18n.dart';
/// Validaciones de formularios. Las expresiones son las mismas que usa el
/// backend (config/Validaciones.java), asi el mensaje aparece antes de enviar.
class Validadores {
  Validadores._();

  static final RegExp _email = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$');

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return tr('Ingresá tu email');
    if (!_email.hasMatch(t)) return tr('Ingresá un email válido (ejemplo: nombre@dominio.com)');
    return null;
  }

  /// Reglas de contraseña segura. Devuelve la lista de lo que falta (vacia = OK).
  static List<String> faltantesPassword(String v) => [
        if (v.length < 6) tr('al menos 6 caracteres'),
        if (!RegExp(r'[A-Z]').hasMatch(v)) tr('una mayúscula'),
        if (!RegExp(r'\d').hasMatch(v)) tr('un número'),
        if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(v)) tr('un carácter especial (ej: ! @ # \$ %)'),
      ];

  static String? passwordSegura(String? v) {
    final faltan = faltantesPassword(v ?? '');
    if (faltan.isEmpty) return null;
    return tr('La contraseña necesita {0}', [faltan.join(', ')]);
  }

  static String? requerido(String? v, [String mensaje = 'Campo obligatorio']) =>
      (v == null || v.trim().isEmpty) ? tr(mensaje) : null;
}

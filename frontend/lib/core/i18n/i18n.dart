import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contenido.dart';
import 'pt.dart';

export 'contenido.dart' show TextoT, TraductorContenido, AmbitoTraduccion, TraduccionContexto;

/// Idioma de la app: 'es' (español) o 'pt' (portugués).
///
/// Los textos fijos de la interfaz se escriben en español dentro de tr('...')
/// y se buscan en el diccionario [textosPt]. El contenido que viene del
/// servidor (recetas, noticias, mensajes, etc.) lo traduce [TraductorContenido].
class Idioma extends ChangeNotifier {
  Idioma._();
  static final Idioma instancia = Idioma._();

  static const idiomas = {'es': 'Español', 'pt': 'Português'};
  static const _clave = 'safebite_idioma';

  String _codigo = 'es';
  String get codigo => _codigo;
  bool get esPortugues => _codigo == 'pt';
  Locale get locale => Locale(_codigo);

  /// Idioma guardado; si no hay, el del dispositivo (portugués si es pt).
  Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      if (guardado != null && idiomas.containsKey(guardado)) {
        _codigo = guardado;
      } else {
        final sistema = ui.PlatformDispatcher.instance.locale.languageCode;
        _codigo = sistema == 'pt' ? 'pt' : 'es';
      }
    } catch (_) {
      _codigo = 'es';
    }
    _indexar();
  }

  Future<void> cambiar(String codigo) async {
    if (!idiomas.containsKey(codigo) || codigo == _codigo) return;
    _codigo = codigo;
    _indexar();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, codigo);
    } catch (_) {}
    await TraductorContenido.instancia.cambiarIdioma(codigo);
    notifyListeners();
  }

  /// Textos que ya están en el idioma de la app (salidas del diccionario):
  /// el traductor de contenido no los vuelve a mandar a traducir.
  final Set<String> textosDeLaApp = {};

  void _indexar() {
    textosDeLaApp
      ..clear()
      ..addAll(esPortugues ? textosPt.values : textosPt.keys);
  }
}

/// Traduce un texto fijo de la interfaz. [es] es el texto en español, con
/// {0}, {1}... donde van los [args].
String tr(String es, [List<Object?> args = const []]) {
  final idioma = Idioma.instancia;
  var texto = es;
  if (idioma.esPortugues) {
    final pt = textosPt[es];
    if (pt != null) {
      texto = pt;
    } else {
      // No está en el diccionario (ej. un mensaje del servidor): se traduce
      // como contenido y, mientras tanto, se muestra el original.
      texto = TraductorContenido.instancia.traducirSinContexto(es);
    }
  }
  for (var i = 0; i < args.length; i++) {
    texto = texto.replaceAll('{$i}', '${args[i] ?? ''}');
  }
  return texto;
}

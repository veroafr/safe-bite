import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import 'i18n.dart';
import 'pt.dart';

/// Traduce el contenido que viene del servidor o de otras personas (recetas,
/// noticias, reseñas, mensajes de error...) al idioma de la app.
///
/// - Detecta si el texto ya está en el idioma elegido para no gastar en vano.
/// - Junta los pedidos en lotes y los manda al servidor (/traducciones), que
///   traduce con IA y guarda el resultado en la base.
/// - Guarda las traducciones en el dispositivo para que la próxima vez sean
///   instantáneas.
/// Mientras llega la traducción se muestra el texto original.
class TraductorContenido extends ChangeNotifier {
  TraductorContenido._();
  static final TraductorContenido instancia = TraductorContenido._();

  static const _clavePrefs = 'safebite_traducciones_';
  static const _maxGuardadas = 3000;

  ApiClient? _api;
  String _idioma = 'es';
  final Map<String, String> _cache = {};
  final Set<String> _pendientes = {};
  final Set<String> _enCurso = {};
  final Set<String> _fallidos = {};
  Timer? _lote;
  Timer? _guardar;

  Future<void> configurar(ApiClient api, String idioma) async {
    _api = api;
    await cambiarIdioma(idioma);
  }

  Future<void> cambiarIdioma(String idioma) async {
    _idioma = idioma;
    _cache.clear();
    _pendientes.clear();
    _fallidos.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('$_clavePrefs$idioma');
      if (json != null) {
        (jsonDecode(json) as Map<String, dynamic>).forEach((k, v) => _cache[k] = v.toString());
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Traducción para mostrar ahora (puede ser el original si todavía no llegó).
  /// Usar [TextoT] o context.tc(...) para que la pantalla se actualice sola.
  String traducirSinContexto(String texto) {
    if (_idioma == 'pt') {
      final fijo = textosPt[texto];
      if (fijo != null) return fijo;
    }
    if (!necesitaTraduccion(texto)) return texto;
    final hecho = _cache[texto];
    if (hecho != null) return hecho;
    _pedir(texto);
    return texto;
  }

  /// Traduce una lista y espera el resultado (para casos puntuales).
  Future<List<String>> traducirAhora(List<String> textos) async {
    final faltan = textos.where((t) => necesitaTraduccion(t) && !_cache.containsKey(t)).toSet().toList();
    if (faltan.isNotEmpty) await _enviar(faltan);
    return textos.map((t) => _cache[t] ?? t).toList();
  }

  bool necesitaTraduccion(String texto) {
    final t = texto.trim();
    if (t.length < 2 || !RegExp(r'[A-Za-zÀ-ÿ]{2}').hasMatch(t)) return false;
    if (_fallidos.contains(texto)) return false;
    if (Idioma.instancia.textosDeLaApp.contains(texto)) return false;
    if (RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(t)) return false; // email
    if (RegExp(r'^https?://').hasMatch(t)) return false;
    final idioma = detectarIdioma(t);
    if (idioma == _idioma) return false;
    // En español solo se traduce lo que claramente está en otro idioma.
    if (_idioma == 'es' && idioma == null) return false;
    return true;
  }

  void _pedir(String texto) {
    if (_enCurso.contains(texto) || _pendientes.contains(texto)) return;
    _pendientes.add(texto);
    _lote ??= Timer(const Duration(milliseconds: 120), () {
      _lote = null;
      final lote = _pendientes.toList();
      _pendientes.clear();
      for (var i = 0; i < lote.length; i += 40) {
        _enviar(lote.sublist(i, i + 40 > lote.length ? lote.length : i + 40));
      }
    });
  }

  Future<void> _enviar(List<String> textos) async {
    final api = _api;
    if (api == null || textos.isEmpty) return;
    _enCurso.addAll(textos);
    final idioma = _idioma;
    try {
      final data = await api.post('/traducciones', body: {'idioma': idioma, 'textos': textos});
      if (idioma != _idioma) return; // cambió el idioma mientras tanto
      final mapa = (data?['traducciones'] as Map?) ?? const {};
      var hubo = false;
      for (final t in textos) {
        final r = mapa[t];
        if (r is String && r.trim().isNotEmpty) {
          _cache[t] = r;
          hubo = true;
        } else {
          _fallidos.add(t);
        }
      }
      if (hubo) {
        notifyListeners();
        _programarGuardado();
      }
    } catch (_) {
      // Sin conexión o sin sesión: se reintenta la próxima vez que se muestre.
    } finally {
      _enCurso.removeAll(textos);
    }
  }

  void _programarGuardado() {
    _guardar?.cancel();
    _guardar = Timer(const Duration(seconds: 2), () async {
      try {
        var entradas = _cache.entries.toList();
        if (entradas.length > _maxGuardadas) entradas = entradas.sublist(entradas.length - _maxGuardadas);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_clavePrefs$_idioma', jsonEncode(Map.fromEntries(entradas)));
      } catch (_) {}
    });
  }
}

/// Detección simple de español / portugués por palabras y letras típicas.
/// Devuelve null si no se puede saber (textos muy cortos, nombres, inglés...).
String? detectarIdioma(String texto) {
  final t = ' ${texto.toLowerCase()} ';
  var pt = 0, es = 0;
  for (final m in ['ção', 'ções', 'ã', 'õ', 'ê', 'ô', 'lh', 'nh', ' não ', ' você', ' é ', ' em ', ' um ', ' uma ', ' do ', ' da ', ' dos ', ' das ', ' no ', ' na ', ' com ', ' para o', ' mais ', ' isso', ' sem ', 'ç']) {
    if (t.contains(m)) pt++;
  }
  for (final m in ['ñ', '¿', '¡', 'ción', ' el ', ' los ', ' las ', ' del ', ' y ', ' una ', ' con ', ' es ', ' sin ', ' está ', ' más ', ' para el', ' por ', ' que ', 'll']) {
    if (t.contains(m)) es++;
  }
  // " que " y " para " existen en los dos: sumaron a español, compensamos.
  if (t.contains(' que ') && pt > 0) es--;
  if (pt == 0 && es == 0) return null;
  if (pt == es) return null;
  return pt > es ? 'pt' : 'es';
}

/// Hace que los widgets que traducen contenido se reconstruyan cuando llegan traducciones.
class AmbitoTraduccion extends InheritedNotifier<TraductorContenido> {
  AmbitoTraduccion({super.key, required super.child}) : super(notifier: TraductorContenido.instancia);
}

extension TraduccionContexto on BuildContext {
  /// Contenido traducido al idioma de la app (se actualiza solo).
  String tc(String? texto) {
    if (texto == null) return '';
    dependOnInheritedWidgetOfExactType<AmbitoTraduccion>();
    return TraductorContenido.instancia.traducirSinContexto(texto);
  }
}

/// Como Text, pero traduce el contenido al idioma de la app.
class TextoT extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  const TextoT(this.data, {super.key, this.style, this.maxLines, this.overflow, this.textAlign, this.softWrap});

  @override
  Widget build(BuildContext context) => Text(
        context.tc(data),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        softWrap: softWrap,
      );
}

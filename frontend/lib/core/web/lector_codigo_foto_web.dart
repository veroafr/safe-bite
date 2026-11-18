import 'dart:js_interop';
import 'dart:typed_data';

@JS('safebiteLeerCodigoEnFoto')
external JSPromise<JSString?> _leerCodigoEnFoto(JSUint8Array bytes);

@JS('safebitePuedeFotografiarVideo')
external JSBoolean? _puedeFotografiarVideo();

@JS('safebiteTomarFotoDelVideo')
external JSPromise<JSUint8Array?> _tomarFotoDelVideo();

@JS('safebiteCamaraDisponible')
external JSBoolean? _camaraDisponible();

@JS('safebiteSacarFoto')
external JSPromise<JSUint8Array?> _sacarFoto(JSString titulo);

/// true si el navegador permite abrir la cámara propia de la app (web/camara-app.js).
bool camaraAppDisponible() {
  try {
    return _camaraDisponible()?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Abre la cámara propia de la app a pantalla completa y devuelve la foto
/// (JPEG) o null si el usuario canceló o no se pudo abrir.
Future<Uint8List?> sacarFotoConCamaraApp(String titulo) async {
  try {
    final foto = await _sacarFoto(titulo.toJS).toDart;
    return foto?.toDart;
  } catch (_) {
    return null;
  }
}

Future<String?> leerCodigoEnFoto(Uint8List bytes) async {
  try {
    final resultado = await _leerCodigoEnFoto(bytes.toJS).toDart;
    final texto = resultado?.toDart.trim();
    return (texto == null || texto.isEmpty) ? null : texto;
  } catch (_) {
    // El script no cargó o el navegador no permite leer la imagen.
    return null;
  }
}

/// true si la cámara del escáner está encendida y se le puede sacar una foto.
bool puedeTomarFotoDelVideo() {
  try {
    return _puedeFotografiarVideo()?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Saca una foto con la cámara del escáner (sin abrir la cámara del sistema).
Future<Uint8List?> tomarFotoDelVideo() async {
  try {
    final foto = await _tomarFotoDelVideo().toDart;
    return foto?.toDart;
  } catch (_) {
    return null;
  }
}

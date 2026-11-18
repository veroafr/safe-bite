import 'dart:js_interop';
import 'dart:typed_data';

@JS('safebiteLeerCodigoEnFoto')
external JSPromise<JSString?> _leerCodigoEnFoto(JSUint8Array bytes);

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

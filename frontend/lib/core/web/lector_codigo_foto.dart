/// Lee el código de barras en una foto. En la versión web usa
/// web/lector-foto.js (detector nativo del navegador o ZXing); en Android e
/// iOS devuelve null y se usa la IA como respaldo.
export 'lector_codigo_foto_stub.dart'
    if (dart.library.js_interop) 'lector_codigo_foto_web.dart';

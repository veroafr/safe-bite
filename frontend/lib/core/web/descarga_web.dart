import 'dart:convert';
import 'dart:js_interop';

@JS('safebiteDescargarArchivo')
external void _descargar(JSString base64, JSString nombre, JSString mime);

/// Devuelve null: el navegador muestra la descarga.
Future<String?> guardarArchivo(List<int> bytes, String nombre, String mime) async {
  _descargar(base64Encode(bytes).toJS, nombre.toJS, mime.toJS);
  return null;
}

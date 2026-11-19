import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../../core/i18n/i18n.dart';

/// Devuelve la ruta donde quedó guardado el archivo.
Future<String?> guardarArchivo(List<int> bytes, String nombre, String mime) async {
  Directory? dir;
  try {
    dir = await getDownloadsDirectory();
  } catch (_) {
    dir = null;
  }
  dir ??= await getApplicationDocumentsDirectory();
  final archivo = File('${dir.path}/${nombre}');
  await archivo.writeAsBytes(bytes);
  return archivo.path;
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'recortar_imagen.dart';

/// Elige una foto (cámara o galería) y la deja encuadrar en un círculo.
/// Devuelve la imagen recortada (PNG, 400 px) o null si se cancela.
Future<Uint8List?> elegirFotoDePerfil(BuildContext context) async {
  final bytes = await elegirFotoCamaraOGaleria(context, tituloCamara: 'Tu foto de perfil');
  if (bytes == null || !context.mounted) return null;
  return recortarImagen(context,
      bytes: Uint8List.fromList(bytes), proporcion: 1, anchoSalida: 400, titulo: 'Encuadrá tu foto');
}

/// Foto de perfil redonda con un botón de cámara para cambiarla.
class FotoPerfilEditable extends StatelessWidget {
  /// Foto recién elegida (tiene prioridad).
  final Uint8List? bytes;
  /// Foto actual (enlace o data URL).
  final String? fuente;
  final double tamano;
  final VoidCallback onCambiar;
  final VoidCallback? onQuitar;
  final bool cargando;

  const FotoPerfilEditable({
    super.key,
    this.bytes,
    this.fuente,
    this.tamano = 104,
    required this.onCambiar,
    this.onQuitar,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    final sinFoto = Container(
      color: AppColors.primarySoft,
      child: Icon(Icons.person, size: tamano * 0.5, color: AppColors.primary),
    );
    final tieneFoto = bytes != null || (fuente != null && fuente!.isNotEmpty);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(children: [
        GestureDetector(
          onTap: cargando ? null : onCambiar,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.lime),
            child: ClipOval(
              child: SizedBox(
                width: tamano,
                height: tamano,
                child: cargando
                    ? Container(color: AppColors.primarySoft, child: const Center(child: CircularProgressIndicator()))
                    : bytes != null
                        ? Image.memory(bytes!, fit: BoxFit.cover)
                        : ImagenFlexible(fuente: fuente, sinImagen: sinFoto),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: cargando ? null : onCambiar,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.photo_camera_outlined, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      if (tieneFoto && onQuitar != null)
        TextButton(onPressed: cargando ? null : onQuitar, child: const Text('Quitar foto'))
      else if (!tieneFoto)
        TextButton(onPressed: cargando ? null : onCambiar, child: const Text('Agregar foto (opcional)')),
    ]);
  }
}

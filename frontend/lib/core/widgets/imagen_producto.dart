import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import 'recortar_imagen.dart';

/// Miniatura de un producto recomendado. Si no trae foto, busca una imagen
/// de referencia en Open Food Facts con [busqueda] (ej: "Pan sin TACC Marca").
/// [ilustrativa]: la foto es genérica del tipo de alimento (sin marca), y así
/// se aclara al verla en grande. Al tocarla se ve en grande.
class ImagenProducto extends StatefulWidget {
  final String? url;
  final String? busqueda;
  final double lado;
  final IconData icono;
  final bool ilustrativa;

  const ImagenProducto(
      {super.key, this.url, this.busqueda, this.lado = 64, this.icono = Icons.fastfood_outlined, this.ilustrativa = false});

  @override
  State<ImagenProducto> createState() => _ImagenProductoState();
}

class _ImagenProductoState extends State<ImagenProducto> {
  /// Búsquedas ya hechas en esta sesión (texto → url o null).
  static final Map<String, Future<String?>> _cache = {};

  Future<String?>? _busqueda;

  @override
  void initState() {
    super.initState();
    final q = widget.busqueda?.trim();
    if ((widget.url == null || widget.url!.isEmpty) && q != null && q.isNotEmpty) {
      final servicio = context.read<ProductoService>();
      _busqueda = _cache.putIfAbsent(q.toLowerCase(), () => servicio.buscarImagen(q).catchError((_) => null));
    }
  }

  Widget _sinImagen() => Container(
        color: AppColors.primarySoft,
        child: Icon(widget.icono, color: AppColors.primary, size: widget.lado * 0.45),
      );

  void _ampliar(String url, bool referencia) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: InteractiveViewer(child: ImagenFlexible(fuente: url, fit: BoxFit.contain, sinImagen: _sinImagen())),
          ),
          if (referencia || widget.ilustrativa)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                  widget.ilustrativa
                      ? tr('Imagen ilustrativa del tipo de producto (Wikipedia)')
                      : tr('Imagen de referencia'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
        ]),
      ),
    );
  }

  Widget _foto(String url, bool referencia) => GestureDetector(
        onTap: () => _ampliar(url, referencia),
        child: Container(
          color: Colors.white,
          child: ImagenFlexible(fuente: url, fit: BoxFit.contain, sinImagen: _sinImagen()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget hijo;
    if (widget.url != null && widget.url!.isNotEmpty) {
      hijo = _foto(widget.url!, false);
    } else if (_busqueda != null) {
      hijo = FutureBuilder<String?>(
        future: _busqueda,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Container(
              color: AppColors.primarySoft,
              child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final url = snap.data;
          return url == null ? _sinImagen() : _foto(url, true);
        },
      );
    } else {
      hijo = _sinImagen();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: widget.lado, height: widget.lado, child: hijo),
    );
  }
}

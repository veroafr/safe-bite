import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;
  const ErrorView({super.key, required this.mensaje, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  const EmptyView({super.key, required this.mensaje, this.icono = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: AppColors.textSecondary, size: 42),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class SeccionTitulo extends StatelessWidget {
  final String texto;
  const SeccionTitulo(this.texto, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}

void mostrarError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString()), backgroundColor: AppColors.danger),
  );
}

void mostrarMensaje(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensaje), backgroundColor: AppColors.primary),
  );
}

class Chip1 extends StatelessWidget {
  final String texto;
  final Color color;
  const Chip1(this.texto, {super.key, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Le pregunta al usuario si quiere tomar una foto nueva con la cámara o
/// elegir una existente de la galería. Devuelve los bytes de la imagen ya
/// leídos (o null si canceló), listos para pasar a base64Encode().
Future<List<int>?> elegirFotoCamaraOGaleria(BuildContext context) async {
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Text('Elegir foto', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Tomar foto con la cámara'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (origen == null) return null;

  final picker = ImagePicker();
  final archivo = await picker.pickImage(source: origen, imageQuality: 70, maxWidth: 1400);
  if (archivo == null) return null;

  final bytes = await archivo.readAsBytes();
  return bytes;
}

/// Widget de selección de foto con miniatura, para usar en formularios.
/// Guarda internamente los bytes; expone el base64 vía [onCambio].
class SelectorFoto extends StatefulWidget {
  final String titulo;
  final String ayuda;
  final String? base64Inicial;
  final ValueChanged<String?> onCambio;

  const SelectorFoto({
    super.key,
    required this.titulo,
    required this.ayuda,
    required this.onCambio,
    this.base64Inicial,
  });

  @override
  State<SelectorFoto> createState() => _SelectorFotoState();
}

class _SelectorFotoState extends State<SelectorFoto> {
  List<int>? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.base64Inicial != null && widget.base64Inicial!.isNotEmpty) {
      try {
        _bytes = base64Decode(widget.base64Inicial!);
      } catch (_) {
        _bytes = null;
      }
    }
  }

  Future<void> _elegir() async {
    final bytes = await elegirFotoCamaraOGaleria(context);
    if (bytes == null) return;
    setState(() => _bytes = bytes);
    widget.onCambio(base64Encode(bytes));
  }

  void _quitar() {
    setState(() => _bytes = null);
    widget.onCambio(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _bytes == null
                ? Container(
                    width: 56,
                    height: 56,
                    color: AppColors.primary.withOpacity(0.08),
                    child: const Icon(Icons.image_outlined, color: AppColors.primary),
                  )
                : Image.memory(
                    Uint8List.fromList(_bytes!),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(widget.ayuda, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (_bytes != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
              onPressed: _quitar,
              tooltip: 'Quitar',
            ),
          TextButton.icon(
            onPressed: _elegir,
            icon: Icon(_bytes == null ? Icons.add_a_photo_outlined : Icons.refresh, size: 18),
            label: Text(_bytes == null ? 'Agregar' : 'Cambiar'),
          ),
        ],
      ),
    );
  }
}

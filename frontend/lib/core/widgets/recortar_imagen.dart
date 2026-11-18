import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_theme.dart';

/// Muestra una imagen que puede venir como data URL ("data:image/jpeg;base64,...")
/// o como enlace http(s). Si no hay imagen o falla, muestra [sinImagen].
class ImagenFlexible extends StatelessWidget {
  final String? fuente;
  final BoxFit fit;
  final Widget sinImagen;
  const ImagenFlexible({super.key, required this.fuente, this.fit = BoxFit.cover, required this.sinImagen});

  @override
  Widget build(BuildContext context) {
    final f = fuente;
    if (f == null || f.isEmpty) return sinImagen;
    if (f.startsWith('data:')) {
      final coma = f.indexOf(',');
      try {
        final bytes = base64Decode(f.substring(coma + 1));
        return Image.memory(bytes, fit: fit, gaplessPlayback: true, errorBuilder: (_, __, ___) => sinImagen);
      } catch (_) {
        return sinImagen;
      }
    }
    return Image.network(f, fit: fit, errorBuilder: (_, __, ___) => sinImagen);
  }
}

/// Abre una pantalla para encuadrar [bytes] en un marco de proporción
/// [proporcion] (ancho / alto): el usuario mueve y hace zoom con los dedos o
/// el mouse, y elige si la imagen llena el marco o se ve completa (útil para
/// logos). Devuelve la imagen recortada en PNG de [anchoSalida] píxeles de
/// ancho, o null si cancela.
Future<Uint8List?> recortarImagen(
  BuildContext context, {
  required Uint8List bytes,
  required double proporcion,
  required int anchoSalida,
  required String titulo,
}) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _RecortadorPantalla(
        bytes: bytes,
        proporcion: proporcion,
        anchoSalida: anchoSalida,
        titulo: titulo,
      ),
    ),
  );
}

class _RecortadorPantalla extends StatefulWidget {
  final Uint8List bytes;
  final double proporcion;
  final int anchoSalida;
  final String titulo;
  const _RecortadorPantalla({
    required this.bytes,
    required this.proporcion,
    required this.anchoSalida,
    required this.titulo,
  });

  @override
  State<_RecortadorPantalla> createState() => _RecortadorPantallaState();
}

class _RecortadorPantallaState extends State<_RecortadorPantalla> {
  final _marcoKey = GlobalKey();
  final _transformacion = TransformationController();
  bool _completa = false;
  bool _guardando = false;
  double _anchoMarco = 300;

  void _cambiarModo(bool completa) {
    setState(() {
      _completa = completa;
      _transformacion.value = Matrix4.identity();
    });
  }

  Future<void> _usar() async {
    setState(() => _guardando = true);
    try {
      final boundary = _marcoKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image imagen = await boundary.toImage(pixelRatio: widget.anchoSalida / _anchoMarco);
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      imagen.dispose();
      if (!mounted) return;
      Navigator.of(context).pop(datos?.buffer.asUint8List());
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo recortar la imagen: $e')));
      }
    }
  }

  @override
  void dispose() {
    _transformacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111A15),
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _usar,
            child: _guardando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Usar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              // El marco ocupa el ancho disponible sin pasarse del alto.
              var ancho = c.maxWidth - 32;
              var alto = ancho / widget.proporcion;
              if (alto > c.maxHeight - 32) {
                alto = c.maxHeight - 32;
                ancho = alto * widget.proporcion;
              }
              _anchoMarco = ancho;
              return Center(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                  child: RepaintBoundary(
                    key: _marcoKey,
                    child: ClipRect(
                      child: Container(
                        width: ancho,
                        height: alto,
                        color: Colors.white,
                        child: InteractiveViewer(
                          transformationController: _transformacion,
                          minScale: 0.3,
                          maxScale: 8,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          child: SizedBox(
                            width: ancho,
                            height: alto,
                            child: Image.memory(
                              widget.bytes,
                              fit: _completa ? BoxFit.contain : BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Container(
            color: Colors.black26,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const Text(
                    'Mové la imagen y hacé zoom (dos dedos o la rueda del mouse) para encuadrarla.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Llenar el marco'), icon: Icon(Icons.crop)),
                      ButtonSegment(value: true, label: Text('Imagen completa'), icon: Icon(Icons.fit_screen)),
                    ],
                    selected: {_completa},
                    onSelectionChanged: (s) => _cambiarModo(s.first),
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white,
                      selectedBackgroundColor: AppColors.lime,
                      selectedForegroundColor: AppColors.primaryDeeper,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

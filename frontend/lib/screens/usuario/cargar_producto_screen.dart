import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/usuario.dart';
import '../../core/services/producto_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

/// Pantalla para que el usuario cargue o complete un producto.
/// Dos modos:
/// - Nuevo (productoId == null): el codigo no aparecio en ningun lado.
/// - Completar (productoId != null): el producto existe (ej: vino de
///   Open Food Facts) pero le faltan ingredientes/alergenos/fotos.
class CargarProductoScreen extends StatefulWidget {
  final String codigoEan;
  final int? productoId;
  final String? nombreInicial;
  final String? marcaInicial;

  const CargarProductoScreen({
    super.key,
    required this.codigoEan,
    this.productoId,
    this.nombreInicial,
    this.marcaInicial,
  });

  @override
  State<CargarProductoScreen> createState() => _CargarProductoScreenState();
}

class _CargarProductoScreenState extends State<CargarProductoScreen> {
  late final _nombreCtrl = TextEditingController(text: widget.nombreInicial ?? '');
  late final _marcaCtrl = TextEditingController(text: widget.marcaInicial ?? '');
  final _ingredientesCtrl = TextEditingController();
  final Set<TipoIntolerancia> _alergenosSeleccionados = {};
  bool _enviando = false;

  String? _fotoFrontalBase64;
  String? _fotoComposicionBase64;
  String? _fotoNutricionalBase64;

  bool get _esCompletar => widget.productoId != null;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _marcaCtrl.dispose();
    _ingredientesCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_esCompletar && _nombreCtrl.text.trim().isEmpty) {
      mostrarMensaje(context, 'Ingresá al menos el nombre del producto');
      return;
    }

    setState(() => _enviando = true);
    try {
      final body = {
        'codigoEan': widget.codigoEan,
        'nombre': _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
        'marca': _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
        'ingredientes': _ingredientesCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'alergenos': _alergenosSeleccionados.map((a) => a.name).toList(),
        'fotoFrontalBase64': _fotoFrontalBase64,
        'fotoComposicionBase64': _fotoComposicionBase64,
        'fotoNutricionalBase64': _fotoNutricionalBase64,
      };

      final service = context.read<ProductoService>();
      if (_esCompletar) {
        await service.completarDatos(widget.productoId!, body);
      } else {
        await service.aportar(body);
      }

      if (mounted) {
        mostrarMensaje(context, 'Gracias, tu aporte quedó guardado. Un admin lo va a revisar antes de mostrarlo como verificado.');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esCompletar ? 'Completar producto' : 'Cargar producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.10),
                border: Border.all(color: AppColors.accent, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _esCompletar
                          ? 'Este producto existe pero le faltan datos de ingredientes o alérgenos. Completalo con lo que tengas — sacale foto a la etiqueta si podés, es lo más rápido.'
                          : 'No encontramos este código en nuestra base ni en Open Food Facts. Completá los datos que tengas — va a quedar visible para otros recién cuando un administrador lo revise.',
                      style: const TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Código escaneado: ${widget.codigoEan}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            const Text('Fotos del envase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Sacá cada foto por separado (con la cámara o desde tu galería), así queda más claro qué mirar en cada una.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SelectorFoto(
              titulo: '1. Frente del producto',
              ayuda: 'Que se vea el nombre y la marca',
              onCambio: (b64) => _fotoFrontalBase64 = b64,
            ),
            SelectorFoto(
              titulo: '2. Tabla de composición / ingredientes',
              ayuda: 'La lista de ingredientes del envase',
              onCambio: (b64) => _fotoComposicionBase64 = b64,
            ),
            SelectorFoto(
              titulo: '3. Tabla nutricional',
              ayuda: 'Los valores nutricionales por porción',
              onCambio: (b64) => _fotoNutricionalBase64 = b64,
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Datos del producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCtrl,
              decoration: InputDecoration(labelText: _esCompletar ? 'Nombre (opcional, ya lo tenemos)' : 'Nombre del producto *'),
            ),
            const SizedBox(height: 10),
            TextField(controller: _marcaCtrl, decoration: const InputDecoration(labelText: 'Marca')),
            const SizedBox(height: 10),
            TextField(
              controller: _ingredientesCtrl,
              decoration: const InputDecoration(
                labelText: 'Ingredientes',
                hintText: 'Separados por coma, ej: harina de trigo, sal, levadura',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('¿Contiene alguno de estos alérgenos?', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: TipoIntolerancia.values.map((t) {
                final seleccionado = _alergenosSeleccionados.contains(t);
                return FilterChip(
                  label: Text(etiquetaIntolerancia(t)),
                  selected: seleccionado,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _alergenosSeleccionados.add(t);
                    } else {
                      _alergenosSeleccionados.remove(t);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                child: _enviando
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

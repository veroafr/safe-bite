import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/usuario.dart';
import '../../core/services/producto_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

/// Pantalla para que el usuario cargue a mano un producto que escaneo y
/// no aparecio ni en la base propia ni en Open Food Facts. Queda pendiente
/// de revision por un admin (ver AdminProductosScreen).
class CargarProductoScreen extends StatefulWidget {
  final String codigoEan;
  const CargarProductoScreen({super.key, required this.codigoEan});

  @override
  State<CargarProductoScreen> createState() => _CargarProductoScreenState();
}

class _CargarProductoScreenState extends State<CargarProductoScreen> {
  final _nombreCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  final _ingredientesCtrl = TextEditingController();
  final Set<TipoIntolerancia> _alergenosSeleccionados = {};
  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _marcaCtrl.dispose();
    _imagenCtrl.dispose();
    _ingredientesCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      mostrarMensaje(context, 'Ingresá al menos el nombre del producto');
      return;
    }

    setState(() => _enviando = true);
    try {
      final body = {
        'codigoEan': widget.codigoEan,
        'nombre': _nombreCtrl.text.trim(),
        'marca': _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
        'imagenUrl': _imagenCtrl.text.trim().isEmpty ? null : _imagenCtrl.text.trim(),
        'ingredientes': _ingredientesCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'alergenos': _alergenosSeleccionados.map((a) => a.name).toList(),
      };
      await context.read<ProductoService>().aportar(body);
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
      appBar: AppBar(title: const Text('Cargar producto')),
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
                      'No encontramos este código en nuestra base ni en Open Food Facts. '
                      'Completá los datos que tengas a mano — va a quedar visible para otros usuarios '
                      'recién cuando un administrador lo revise.',
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
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del producto *')),
            const SizedBox(height: 10),
            TextField(controller: _marcaCtrl, decoration: const InputDecoration(labelText: 'Marca')),
            const SizedBox(height: 10),
            TextField(controller: _imagenCtrl, decoration: const InputDecoration(labelText: 'URL de imagen (opcional)')),
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

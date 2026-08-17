import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/models/producto.dart';
import '../../core/models/usuario.dart';
import '../../core/models/alerta.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/producto_service.dart';
import '../../core/services/alerta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class EscanerScreen extends StatelessWidget {
  const EscanerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Productos'),
      ),
      body: const _LectorEanTab(),
    );
  }
}

class _DesgloseIntolerancias extends StatelessWidget {
  final Set<TipoIntolerancia> alergenosProducto;
  const _DesgloseIntolerancias({required this.alergenosProducto});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final intolerancias = usuario?.intolerancias ?? <TipoIntolerancia>{};
    if (intolerancias.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('Tus intolerancias en este producto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        ...intolerancias.map((t) {
          final esSeguro = !alergenosProducto.contains(t);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  esSeguro ? Icons.check_circle : Icons.cancel,
                  color: esSeguro ? AppColors.primary : AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${etiquetaIntolerancia(t)}: ${esSeguro ? 'es seguro' : 'no es seguro'}',
                  style: TextStyle(
                    color: esSeguro ? AppColors.primary : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class ResultadoEscaneoCard extends StatelessWidget {
  final ResultadoEscaneo resultado;
  const ResultadoEscaneoCard({super.key, required this.resultado});

  Future<void> _reportarAlerta(BuildContext context) async {
    final descripcionCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar producto'),
        content: TextField(controller: descripcionCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Describí el problema')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (confirmado == true && descripcionCtrl.text.trim().isNotEmpty) {
      try {
        await context.read<AlertaService>().crear(
              tipo: TipoAlerta.PRODUCTO,
              productoId: resultado.producto.id,
              descripcion: descripcionCtrl.text.trim(),
            );
        if (context.mounted) mostrarMensaje(context, 'Alerta enviada');
      } catch (e) {
        if (context.mounted) mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = resultado.producto;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Chip1(
                  !resultado.datosSuficientes
                      ? 'Sin datos'
                      : (resultado.seguro ? 'Seguro' : 'Alerta'),
                  color: !resultado.datosSuficientes
                      ? AppColors.accent
                      : (resultado.seguro ? AppColors.primary : AppColors.danger),
                ),
              ],
            ),
            if (p.marca != null) Text(p.marca!, style: const TextStyle(color: AppColors.textSecondary)),
            if (p.codigoEan != null) Text('Código: ${p.codigoEan}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            if (!resultado.datosSuficientes)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.10),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.help_outline, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resultado.mensaje,
                        style: const TextStyle(
                          color: Color(0xFF8A5A00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (!resultado.seguro)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  border: Border.all(color: AppColors.danger, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resultado.mensaje,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.danger,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(resultado.mensaje),
            if (resultado.datosSuficientes) _DesgloseIntolerancias(alergenosProducto: p.alergenos),
            if (p.ingredientes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Ingredientes:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(p.ingredientes.join(', ')),
            ],
            if (p.alergenos.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: p.alergenos.map((a) => Chip1(etiquetaIntolerancia(a), color: AppColors.danger)).toList()),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _reportarAlerta(context),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Reportar producto'),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalisisIngredientesCard extends StatelessWidget {
  final AnalisisIngredientes analisis;
  const AnalisisIngredientesCard({super.key, required this.analisis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Análisis de ingredientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Chip1(
                analisis.seguro ? 'Seguro' : 'Alerta',
                color: analisis.seguro ? AppColors.primary : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!analisis.seguro)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                border: Border.all(color: AppColors.danger, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      analisis.mensaje,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.danger,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(analisis.mensaje),
          _DesgloseIntolerancias(alergenosProducto: analisis.alergenosEncontrados),
          if (analisis.alergenosEncontrados.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: analisis.alergenosEncontrados
                  .map((a) => Chip1(etiquetaIntolerancia(a), color: AppColors.danger))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          const Text('Texto detectado en la foto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(analisis.textoAnalizado, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LectorEanTab extends StatefulWidget {
  const _LectorEanTab();
  @override
  State<_LectorEanTab> createState() => _LectorEanTabState();
}

class _LectorEanTabState extends State<_LectorEanTab> {
  final MobileScannerController _controller = MobileScannerController();
  final _codigoManualCtrl = TextEditingController();
  ResultadoEscaneo? _resultado;
  String? _error;
  bool _procesando = false;
  String? _ultimoCodigoDetectado;
  int _deteccionesCrudas = 0;
  bool _analizandoIngredientes = false;

  Future<void> _escanearIngredientesPorFoto() async {
    setState(() => _analizandoIngredientes = true);
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (foto == null) return;

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final resultadoOcr = await recognizer.processImage(InputImage.fromFilePath(foto.path));
      await recognizer.close();

      final texto = resultadoOcr.text.trim();
      if (texto.isEmpty) {
        if (mounted) {
          mostrarError(context, 'No se pudo leer texto en la foto. Probá con mejor luz y más cerca de la etiqueta.');
        }
        return;
      }

      final analisis = await context.read<ProductoService>().analizarIngredientes(texto);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: AnalisisIngredientesCard(analisis: analisis),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _analizandoIngredientes = false);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (capture.barcodes.isNotEmpty) {
      setState(() {
        _deteccionesCrudas++;
        _ultimoCodigoDetectado = capture.barcodes.first.rawValue ?? '(codigo vacio/no legible)';
      });
    }

    if (_procesando) return;
    final codigo = capture.barcodes.firstOrNull?.rawValue;
    if (codigo == null || codigo.isEmpty) return;

    await _buscarProducto(codigo, detenerCamara: true);
  }

  Future<void> _buscarConCodigoManual() async {
    final codigo = _codigoManualCtrl.text.trim();
    if (codigo.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _buscarProducto(codigo, detenerCamara: false);
  }

  Future<void> _buscarProducto(String codigo, {required bool detenerCamara}) async {
    if (_procesando) return;
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final resultado = await context.read<ProductoService>().escanearPorEan(codigo);
      setState(() => _resultado = resultado);
      if (detenerCamara) await _controller.stop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _reiniciar() {
    setState(() {
      _resultado = null;
      _error = null;
    });
    _codigoManualCtrl.clear();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _codigoManualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                Center(
                  child: Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 3), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_procesando) const Center(child: CircularProgressIndicator(color: Colors.white)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            _ultimoCodigoDetectado != null
                ? 'Detecciones: $_deteccionesCrudas · Último: $_ultimoCodigoDetectado'
                : 'Todavía no se detectó ningún código con la cámara',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codigoManualCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'O ingresá el código manualmente...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _buscarConCodigoManual(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.primary),
                onPressed: _procesando ? null : _buscarConCodigoManual,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: OutlinedButton.icon(
            onPressed: _analizandoIngredientes ? null : _escanearIngredientesPorFoto,
            icon: _analizandoIngredientes
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_outlined),
            label: Text(_analizandoIngredientes ? 'Analizando...' : 'Escanear ingredientes por foto'),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _resultado != null
              ? SingleChildScrollView(child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: _reiniciar,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear otro producto'),
                    ),
                  ),
                  ResultadoEscaneoCard(resultado: _resultado!),
                ]))
              : _error != null
                  ? SingleChildScrollView(child: ErrorView(mensaje: _error!, onReintentar: _reiniciar))
                  : const SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Apuntá la cámara al código de barras del producto', textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
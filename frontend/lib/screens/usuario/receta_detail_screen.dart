import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/intolerancia.dart';
import '../../core/models/receta.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/receta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/receta_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import '../../core/i18n/i18n.dart';

class RecetaDetailScreen extends StatefulWidget {
  final int recetaId;
  /// Receta de Spoonacular traída en vivo (no publicada en SafeBite).
  final int? externoId;
  final Set<String> intolerancias;
  const RecetaDetailScreen({super.key, this.recetaId = 0, this.externoId, this.intolerancias = const {}});

  @override
  State<RecetaDetailScreen> createState() => _RecetaDetailScreenState();
}

class _RecetaDetailScreenState extends State<RecetaDetailScreen> {
  Receta? _receta;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _error = null;
      _receta = null;
    });
    try {
      final service = context.read<RecetaService>();
      final r = widget.externoId != null
          ? await service.obtenerExterna(widget.externoId!, widget.intolerancias)
          : await service.obtener(widget.recetaId);
      if (mounted) setState(() => _receta = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextoT(_receta?.titulo ?? tr('Receta'))),
      body: _error != null
          ? ErrorView(mensaje: _error!, onReintentar: _cargar)
          : _receta == null
              ? const LoadingView()
              : ContenidoReceta(receta: _receta!),
    );
  }
}

/// Cuerpo del detalle de una receta. Lo usa también el panel admin (vista previa).
class ContenidoReceta extends StatelessWidget {
  final Receta receta;
  final List<Widget> pie;
  const ContenidoReceta({super.key, required this.receta, this.pie = const []});

  @override
  Widget build(BuildContext context) {
    final r = receta;
    final misIntolerancias = context.watch<AuthProvider>().usuario?.intolerancias ?? <String>{};
    final peligrosas = r.detectados.intersection(misIntolerancias);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (r.imagenUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: ImagenFlexible(fuente: r.imagenUrl, sinImagen: Container(color: const Color(0xFFE0E0E0))),
            ),
          ),
        const SizedBox(height: 12),
        TextoT(r.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          EtiquetaOrigenReceta(receta: r),
          if (r.esDeUsuario && r.autorNombre != null)
            Text(tr('Compartida por {0}', [r.autorNombre]), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          if (r.tiempoPreparacionMinutos != null) _Dato(Icons.schedule, '${r.tiempoPreparacionMinutos} min'),
          if (r.porciones != null) _Dato(Icons.people_outline, tr('{0} porciones', [r.porciones])),
          if (r.dificultad != null) _Dato(Icons.signal_cellular_alt, context.tc(r.dificultad!)),
          ...r.etiquetas.map((e) => _Dato(Icons.label_outline, context.tc(e))),
        ]),

        // ---- Avisos de seguridad ----
        if (peligrosas.isNotEmpty)
          AvisoReceta(
            icono: Icons.warning_amber_rounded,
            titulo: tr('Atención: puede no ser apta para vos'),
            texto: tr('Los ingredientes mencionan: {0}. Revisalos antes de prepararla.', [peligrosas.map(etiquetaIntolerancia).join(', ')]),
            color: AppColors.danger,
          ),
        if (r.aviso != null)
          AvisoReceta(icono: Icons.info_outline, titulo: tr('Aviso'), texto: r.aviso, color: const Color(0xFFB26A00)),
        if (r.esSpoonacular)
          AvisoReceta(
            icono: Icons.translate_rounded,
            titulo: tr('Receta de una fuente externa'),
            texto: tr('{0}SafeBite filtró los ingredientes, pero siempre controlá las etiquetas de los productos que uses y el riesgo de contaminación cruzada.', [r.traducida ? tr('Traducida automáticamente del inglés. ') : '']),
            color: const Color(0xFF546E7A),
          ),

        if (r.libreDe.isNotEmpty) ...[
          SeccionTitulo(tr('Apta para quienes evitan')),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: r.libreDe.map((c) => Chip1(tr('Sin {0}', [etiquetaIntolerancia(c)]))).toList(),
          ),
        ],
        if (r.descripcion != null && r.descripcion!.isNotEmpty) ...[
          SeccionTitulo(tr('Descripción')),
          TextoT(r.descripcion!),
        ],
        if (r.ingredientes.isNotEmpty) ...[
          SeccionTitulo(tr('Ingredientes')),
          ...r.ingredientes.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: TextoT(i)),
                ]),
              )),
        ],
        if (r.pasos.isNotEmpty) ...[
          SeccionTitulo(tr('Preparación')),
          ...r.pasos.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 12, child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 10),
                    Expanded(child: TextoT(entry.value)),
                  ],
                ),
              )),
        ],

        // ---- Atribución de la fuente ----
        if (r.esSpoonacular) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.public_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: tr('Receta vía ')),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: InkWell(
                    onTap: () => abrirEnlace(context, 'https://spoonacular.com/food-api'),
                    child: const Text('spoonacular',
                        style: TextStyle(color: AppColors.primary, decoration: TextDecoration.underline)),
                  ),
                ),
                if (r.creditos != null) TextSpan(text: ' · ${r.creditos}'),
              ]), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
          ]),
          if (r.fuenteUrl != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => abrirEnlace(context, r.fuenteUrl!),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(tr('Ver la receta original')),
            ),
          ],
        ],
        ...pie,
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Dato(this.icono, this.texto);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(fontSize: 13)),
        ]),
      );
}

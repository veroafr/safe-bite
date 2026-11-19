import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/receta.dart';
import '../../core/services/receta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../../core/widgets/receta_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import 'receta_detail_screen.dart';

const dificultades = ['Fácil', 'Media', 'Difícil'];

/// Formulario para que una persona comparta su receta. Si [existente] viene,
/// se edita una receta propia (vuelve a revisión).
class EnviarRecetaScreen extends StatefulWidget {
  final Receta? existente;
  /// Administrador: se publica directamente (sin revisión) y puede marcar "Tip".
  final bool modoAdmin;
  const EnviarRecetaScreen({super.key, this.existente, this.modoAdmin = false});

  @override
  State<EnviarRecetaScreen> createState() => _EnviarRecetaScreenState();
}

class _EnviarRecetaScreenState extends State<EnviarRecetaScreen> {
  final _form = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.existente?.titulo ?? '');
  late final _descripcion = TextEditingController(text: widget.existente?.descripcion ?? '');
  late final _tiempo = TextEditingController(text: widget.existente?.tiempoPreparacionMinutos?.toString() ?? '');
  late final _ingredientes = TextEditingController(text: widget.existente?.ingredientes.join('\n') ?? '');
  late final _pasos = TextEditingController(text: widget.existente?.pasos.join('\n') ?? '');
  late String? _dificultad =
      dificultades.contains(widget.existente?.dificultad) ? widget.existente!.dificultad : null;
  late Set<String> _libreDe = {...?widget.existente?.libreDe};
  late bool _esTip = widget.existente?.esTip ?? false;
  late final _etiquetas = TextEditingController(text: widget.existente?.etiquetas.join(', ') ?? '');
  Uint8List? _foto;
  bool _quitarFoto = false;
  bool _enviando = false;

  @override
  void dispose() {
    for (final c in [_titulo, _descripcion, _tiempo, _ingredientes, _pasos, _etiquetas]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lineas(String t) =>
      t.split('\n').map((e) => e.replaceFirst(RegExp(r'^\s*(?:[-•*]|\d+[.)])\s*'), '').trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _elegirFoto() async {
    final bytes = await elegirFotoCamaraOGaleria(context, tituloCamara: 'Sacá una foto del plato');
    if (bytes == null || !mounted) return;
    setState(() {
      _foto = Uint8List.fromList(bytes);
      _quitarFoto = false;
    });
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final body = {
      'titulo': _titulo.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'tiempoPreparacionMinutos': int.tryParse(_tiempo.text.trim()),
      'dificultad': _dificultad,
      'libreDe': _libreDe.toList(),
      'ingredientes': _lineas(_ingredientes.text),
      'pasos': _lineas(_pasos.text),
      if (_foto != null) 'imagenBase64': base64Encode(_foto!),
      if (_quitarFoto) 'imagenBase64': '',
      if (_quitarFoto) 'imagenUrl': '',
      if (widget.modoAdmin) 'esTip': _esTip,
      if (widget.modoAdmin)
        'etiquetas': _etiquetas.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };
    try {
      final service = context.read<RecetaService>();
      if (widget.modoAdmin) {
        if (widget.existente == null) {
          await service.crear(body);
        } else {
          await service.editar(widget.existente!.id, body);
        }
      } else if (widget.existente == null) {
        await service.proponer(body);
      } else {
        await service.editarPropuesta(widget.existente!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoActual = _quitarFoto ? null : widget.existente?.imagenUrl;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.modoAdmin
              ? (widget.existente == null ? 'Nueva receta / tip' : 'Editar receta')
              : (widget.existente == null ? 'Compartir una receta' : 'Editar mi receta'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.modoAdmin)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Es un Tip de Salud (no receta)'),
                value: _esTip,
                onChanged: (v) => setState(() => _esTip = v),
              )
            else
            const AvisoReceta(
              icono: Icons.verified_user_outlined,
              titulo: 'Tu receta será revisada',
              texto: 'El equipo de SafeBite la revisa antes de publicarla, para que la información sea confiable '
                  'para personas con intolerancias.',
              color: AppColors.primary,
            ),
            if (widget.existente?.rechazada == true && widget.existente?.motivoRechazo != null)
              AvisoReceta(
                icono: Icons.info_outline,
                titulo: 'Motivo por el que no se aprobó',
                texto: widget.existente!.motivoRechazo,
                color: AppColors.danger,
              ),
            const SizedBox(height: 16),
            // Foto
            InkWell(
              onTap: _elegirFoto,
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _foto != null
                      ? Image.memory(_foto!, fit: BoxFit.cover)
                      : fotoActual != null
                          ? ImagenFlexible(fuente: fotoActual, sinImagen: _placeholderFoto())
                          : _placeholderFoto(),
                ),
              ),
            ),
            if (_foto != null || fotoActual != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _foto = null;
                    _quitarFoto = true;
                  }),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar foto'),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre de la receta *', hintText: 'Ej: Pan de mandioca sin gluten'),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Escribí un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcion,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descripción breve (opcional)'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _tiempo,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tiempo (min)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _dificultad,
                  decoration: const InputDecoration(labelText: 'Dificultad'),
                  items: dificultades.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _dificultad = v),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            const Text('¿Para quiénes es apta? (libre de...)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            const Text('Marcá solo lo que estés seguro/a de que la receta NO contiene.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            SelectorIntolerancias(
              seleccionadas: _libreDe,
              prefijo: 'Sin ',
              onChanged: (s) => setState(() => _libreDe = s),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _ingredientes,
              maxLines: 7,
              minLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ingredientes * (uno por línea)',
                hintText: '2 tazas de fécula de mandioca\n1 huevo\n100 g de queso rallado',
                alignLabelWithHint: true,
              ),
              validator: (v) => !_esTip && _lineas(v ?? '').isEmpty ? 'Agregá al menos un ingrediente' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pasos,
              maxLines: 8,
              minLines: 4,
              decoration: const InputDecoration(
                labelText: 'Pasos * (uno por línea)',
                hintText: 'Precalentar el horno a 180 °C\nMezclar los ingredientes secos\n...',
                alignLabelWithHint: true,
              ),
              validator: (v) => !_esTip && _lineas(v ?? '').isEmpty ? 'Agregá al menos un paso' : null,
            ),
            if (widget.modoAdmin) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _etiquetas,
                decoration: const InputDecoration(labelText: 'Otras etiquetas (ej: Vegano, Rápida)'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.send_rounded),
              label: Text(widget.modoAdmin
                  ? 'Guardar y publicar'
                  : (widget.existente == null ? 'Enviar para revisión' : 'Guardar y reenviar')),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _placeholderFoto() => Container(
        color: AppColors.primarySoft,
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_a_photo_outlined, size: 34, color: AppColors.primary),
          SizedBox(height: 6),
          Text('Agregar una foto (opcional)', style: TextStyle(color: AppColors.primary)),
        ]),
      );
}

/// Recetas que la persona envió, con su estado.
class MisRecetasScreen extends StatefulWidget {
  const MisRecetasScreen({super.key});
  @override
  State<MisRecetasScreen> createState() => _MisRecetasScreenState();
}

class _MisRecetasScreenState extends State<MisRecetasScreen> {
  late Future<List<Receta>> _future = context.read<RecetaService>().misPropuestas();

  void _recargar() => setState(() => _future = context.read<RecetaService>().misPropuestas());

  Future<void> _abrir(Receta r) async {
    if (r.estado == 'APROBADA') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecetaDetailScreen(recetaId: r.id)));
      return;
    }
    // Pendiente o rechazada: se puede corregir (hace falta el detalle completo).
    try {
      final completa = await context.read<RecetaService>().obtener(r.id);
      if (!mounted) return;
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => EnviarRecetaScreen(existente: completa)));
      if (ok == true && mounted) {
        mostrarMensaje(context, 'Receta reenviada para revisión');
        _recargar();
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _nueva() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const EnviarRecetaScreen()));
    if (ok == true && mounted) {
      mostrarMensaje(context, '¡Gracias! Tu receta se publicará cuando el equipo la apruebe.');
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis recetas enviadas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva receta'),
      ),
      body: FutureBuilder<List<Receta>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(mensaje: snap.error.toString(), onReintentar: _recargar);
          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return const EmptyView(
                mensaje: 'Todavía no enviaste recetas.\nCompartí las tuyas con la comunidad.', icono: Icons.menu_book_outlined);
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final r = lista[i];
                return Card(
                  child: ListTile(
                    onTap: () => _abrir(r),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: ImagenFlexible(
                          fuente: r.imagenUrl,
                          sinImagen: Container(color: AppColors.primarySoft, child: const Icon(Icons.restaurant_menu)),
                        ),
                      ),
                    ),
                    title: Text(r.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(children: [
                          EtiquetaEstadoReceta(receta: r),
                          if (r.fecha != null) ...[
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(r.fecha!), style: const TextStyle(fontSize: 12)),
                          ],
                        ]),
                        if (r.rechazada && r.motivoRechazo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Motivo: ${r.motivoRechazo}', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                          ),
                        if (!r.estado.contains('APROBADA'))
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text('Tocá para editarla', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

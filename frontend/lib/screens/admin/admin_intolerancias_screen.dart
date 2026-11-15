import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/intolerancia.dart';
import '../../core/providers/intolerancias_provider.dart';
import '../../core/services/intolerancia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

/// Gestion de las intolerancias / alergenos del sistema.
///
/// - Las de la lista oficial vienen precargadas (no se borran, se pueden desactivar).
/// - Las nuevas que agrega el admin aparecen al instante en el registro, el
///   perfil, los filtros de cada seccion y los formularios de locales,
///   noticias, recetas y productos.
/// - Las "palabras clave" sirven para que el escaner detecte la intolerancia
///   en las listas de ingredientes.
class AdminIntoleranciasScreen extends StatefulWidget {
  const AdminIntoleranciasScreen({super.key});

  @override
  State<AdminIntoleranciasScreen> createState() => _AdminIntoleranciasScreenState();
}

class _AdminIntoleranciasScreenState extends State<AdminIntoleranciasScreen> {
  late Future<List<Intolerancia>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<IntoleranciaService>().listarTodas();
  }

  /// Recarga esta lista y la lista global (registro, perfil, filtros...).
  Future<void> _recargar() async {
    setState(() {
      _future = context.read<IntoleranciaService>().listarTodas();
    });
    await context.read<IntoleranciasProvider>().recargar();
  }

  Future<void> _abrirFormulario({Intolerancia? existente}) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final cientificoCtrl = TextEditingController(text: existente?.nombreCientifico ?? '');
    final descripcionCtrl = TextEditingController(text: existente?.descripcion ?? '');
    final clavesCtrl = TextEditingController(
        text: (existente?.palabrasClave ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).join(', '));
    bool activa = existente?.activa ?? true;

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(existente == null ? 'Nueva intolerancia' : 'Editar intolerancia',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (existente != null)
                    Text('Código: ${existente.codigo}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nombreCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nombre (ej: Sésamo)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: cientificoCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre científico (opcional)', hintText: 'Ej: Sesamum indicum'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descripcionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: clavesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Palabras clave para detectarla en ingredientes',
                      hintText: 'Separadas por coma, en español y portugués. Ej: sesamo, gergelim, tahini',
                      helperText: 'Si lo dejás vacío se usa el nombre.',
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activa'),
                    subtitle: const Text('Si está inactiva no aparece en el registro, el perfil ni los filtros.'),
                    value: activa,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setModal(() => activa = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (guardar != true) return;
    final body = {
      'nombre': nombreCtrl.text.trim(),
      'nombreCientifico': cientificoCtrl.text.trim(),
      'descripcion': descripcionCtrl.text.trim(),
      'palabrasClave': clavesCtrl.text.trim(),
      'activa': activa,
    };
    try {
      final service = context.read<IntoleranciaService>();
      if (existente == null) {
        await service.crear(body);
      } else {
        await service.editar(existente.id, body);
      }
      if (!mounted) return;
      mostrarMensaje(context, existente == null ? 'Intolerancia agregada' : 'Intolerancia actualizada');
      await _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _cambiarEstado(Intolerancia i, bool activa) async {
    try {
      await context.read<IntoleranciaService>().cambiarEstado(i.id, activa);
      if (mounted) await _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _eliminar(Intolerancia i) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar intolerancia'),
        content: Text('¿Eliminar "${i.nombre}"? Si ya la usan usuarios o productos, conviene desactivarla en lugar de borrarla.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await context.read<IntoleranciaService>().eliminar(i.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Intolerancia eliminada');
      await _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intolerancias del sistema')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: FutureBuilder<List<Intolerancia>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final lista = snapshot.data ?? [];
          if (lista.isEmpty) return const EmptyView(mensaje: 'No hay intolerancias cargadas', icono: Icons.no_food_outlined);
          final activas = lista.where((i) => i.activa).length;
          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: lista.length + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '$activas activas de ${lista.length}. Las nuevas aparecen al instante en el registro, '
                      'el perfil, los filtros y los formularios de locales, noticias, recetas y productos.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  );
                }
                final i = lista[idx - 1];
                return Card(
                  child: ListTile(
                    title: Text(i.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: i.activa ? AppColors.textPrimary : AppColors.textSecondary,
                        )),
                    subtitle: Text(
                      [
                        if (i.nombreCientifico != null) i.nombreCientifico!,
                        i.predefinida ? 'Lista oficial' : 'Agregada por admin',
                        if (!i.activa) 'Inactiva',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => _abrirFormulario(existente: i),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: i.activa,
                          activeColor: AppColors.primary,
                          onChanged: (v) => _cambiarEstado(i, v),
                        ),
                        if (!i.predefinida)
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _eliminar(i),
                          ),
                      ],
                    ),
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

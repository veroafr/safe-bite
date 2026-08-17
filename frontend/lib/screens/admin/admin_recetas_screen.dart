import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/receta.dart';
import '../../core/services/receta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class AdminRecetasScreen extends StatefulWidget {
  const AdminRecetasScreen({super.key});
  @override
  State<AdminRecetasScreen> createState() => _AdminRecetasScreenState();
}

class _AdminRecetasScreenState extends State<AdminRecetasScreen> {
  late Future<List<Receta>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<RecetaService>().listar();
  }

  void _recargar() {
    setState(() {
      _future = context.read<RecetaService>().listar();
    });
  }

  Future<void> _abrirFormulario({Receta? existente}) async {
    final tituloCtrl = TextEditingController(text: existente?.titulo ?? '');
    final descripcionCtrl = TextEditingController(text: existente?.descripcion ?? '');
    final tiempoCtrl = TextEditingController(text: existente?.tiempoPreparacionMinutos?.toString() ?? '');
    final dificultadCtrl = TextEditingController(text: existente?.dificultad ?? '');
    final imagenCtrl = TextEditingController(text: existente?.imagenUrl ?? '');
    final etiquetasCtrl = TextEditingController(text: existente?.etiquetas.join(', ') ?? '');
    final ingredientesCtrl = TextEditingController(text: existente?.ingredientes.join('\n') ?? '');
    final pasosCtrl = TextEditingController(text: existente?.pasos.join('\n') ?? '');
    bool esTip = existente?.esTip ?? false;

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existente == null ? 'Publicar receta / tip' : 'Editar receta', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Es un Tip de Salud (no receta)'),
                  value: esTip,
                  onChanged: (v) => setModalState(() => esTip = v),
                ),
                TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título')),
                const SizedBox(height: 10),
                TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: tiempoCtrl, decoration: const InputDecoration(labelText: 'Tiempo (min)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: dificultadCtrl, decoration: const InputDecoration(labelText: 'Dificultad'))),
                ]),
                const SizedBox(height: 10),
                TextField(controller: imagenCtrl, decoration: const InputDecoration(labelText: 'URL de imagen')),
                const SizedBox(height: 10),
                TextField(controller: etiquetasCtrl, decoration: const InputDecoration(labelText: 'Etiquetas (ej: Sin Gluten, Vegano)')),
                const SizedBox(height: 10),
                TextField(controller: ingredientesCtrl, decoration: const InputDecoration(labelText: 'Ingredientes (uno por línea)'), maxLines: 4),
                const SizedBox(height: 10),
                TextField(controller: pasosCtrl, decoration: const InputDecoration(labelText: 'Pasos (uno por línea)'), maxLines: 4),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (tituloCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (guardar == true) {
      final body = {
        'titulo': tituloCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
        'tiempoPreparacionMinutos': int.tryParse(tiempoCtrl.text.trim()),
        'dificultad': dificultadCtrl.text.trim(),
        'imagenUrl': imagenCtrl.text.trim().isEmpty ? null : imagenCtrl.text.trim(),
        'esTip': esTip,
        'etiquetas': etiquetasCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'ingredientes': ingredientesCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'pasos': pasosCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      };
      try {
        final service = context.read<RecetaService>();
        if (existente == null) {
          await service.crear(body);
        } else {
          await service.editar(existente.id, body);
        }
        if (mounted) {
          mostrarMensaje(context, 'Receta guardada');
          _recargar();
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _eliminar(Receta r) async {
    try {
      await context.read<RecetaService>().eliminar(r.id);
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Recetas')),
      floatingActionButton: FloatingActionButton(onPressed: () => _abrirFormulario(), child: const Icon(Icons.add)),
      body: FutureBuilder<List<Receta>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final recetas = snapshot.data ?? [];
          if (recetas.isEmpty) return const EmptyView(mensaje: 'No hay recetas ni tips cargados');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recetas.length,
            itemBuilder: (context, i) {
              final r = recetas[i];
              return Card(
                child: ListTile(
                  title: Text(r.titulo),
                  subtitle: Text(r.esTip ? 'Tip de Salud' : 'Receta'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirFormulario(existente: r)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _eliminar(r)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
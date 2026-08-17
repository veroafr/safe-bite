import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurante.dart';
import '../../core/models/usuario.dart';
import '../../core/services/restaurante_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class AdminRestaurantesScreen extends StatefulWidget {
  const AdminRestaurantesScreen({super.key});
  @override
  State<AdminRestaurantesScreen> createState() => _AdminRestaurantesScreenState();
}

class _AdminRestaurantesScreenState extends State<AdminRestaurantesScreen> {
  late Future<List<Restaurante>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<RestauranteService>().buscar();
  }

  void _recargar() {
    setState(() {
      _future = context.read<RestauranteService>().buscar();
    });
  }

  Future<void> _abrirFormulario({Restaurante? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: existente?.descripcion ?? '');
    final direccionCtrl = TextEditingController(text: existente?.direccion ?? '');
    final latCtrl = TextEditingController(text: existente?.latitud?.toString() ?? '');
    final lngCtrl = TextEditingController(text: existente?.longitud?.toString() ?? '');
    final imagenCtrl = TextEditingController(text: existente?.imagenUrl ?? '');
    final tiposCocinaCtrl = TextEditingController(text: existente?.tiposCocina.join(', ') ?? '');
    Set<TipoIntolerancia> opciones = {...(existente?.opcionesAptasPara ?? {})};

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
                Text(existente == null ? 'Agregar restaurante' : 'Editar restaurante',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 10),
                TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                const SizedBox(height: 10),
                TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitud'), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitud'), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true))),
                ]),
                const SizedBox(height: 10),
                TextField(controller: imagenCtrl, decoration: const InputDecoration(labelText: 'URL de imagen')),
                const SizedBox(height: 10),
                TextField(controller: tiposCocinaCtrl, decoration: const InputDecoration(labelText: 'Tipos de cocina (separados por coma)')),
                const SizedBox(height: 10),
                const Text('Apto para intolerancias'),
                Wrap(
                  spacing: 8,
                  children: TipoIntolerancia.values
                      .map((t) => FilterChip(
                            label: Text(etiquetaIntolerancia(t)),
                            selected: opciones.contains(t),
                            onSelected: (v) => setModalState(() {
                              if (v) {
                                opciones.add(t);
                              } else {
                                opciones.remove(t);
                              }
                            }),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (nombreCtrl.text.trim().isEmpty) return;
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
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
        'direccion': direccionCtrl.text.trim(),
        'latitud': double.tryParse(latCtrl.text.trim()),
        'longitud': double.tryParse(lngCtrl.text.trim()),
        'imagenUrl': imagenCtrl.text.trim().isEmpty ? null : imagenCtrl.text.trim(),
        'tiposCocina': tiposCocinaCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'opcionesAptasPara': opciones.map((e) => e.name).toList(),
      };
      try {
        final service = context.read<RestauranteService>();
        if (existente == null) {
          await service.crear(body);
        } else {
          await service.editar(existente.id, body);
        }
        if (mounted) {
          mostrarMensaje(context, 'Restaurante guardado');
          _recargar();
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _eliminar(Restaurante r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar restaurante'),
        content: Text('¿Seguro que querés eliminar "${r.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await context.read<RestauranteService>().eliminar(r.id);
        _recargar();
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Restaurantes')),
      floatingActionButton: FloatingActionButton(onPressed: () => _abrirFormulario(), child: const Icon(Icons.add)),
      body: FutureBuilder<List<Restaurante>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final restaurantes = snapshot.data ?? [];
          if (restaurantes.isEmpty) return const EmptyView(mensaje: 'No hay restaurantes cargados');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurantes.length,
            itemBuilder: (context, i) {
              final r = restaurantes[i];
              return Card(
                child: ListTile(
                  title: Text(r.nombre),
                  subtitle: Text(r.direccion ?? ''),
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
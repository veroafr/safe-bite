import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/noticia.dart';
import '../../core/services/noticia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class AdminNoticiasScreen extends StatefulWidget {
  const AdminNoticiasScreen({super.key});
  @override
  State<AdminNoticiasScreen> createState() => _AdminNoticiasScreenState();
}

class _AdminNoticiasScreenState extends State<AdminNoticiasScreen> {
  late Future<List<Noticia>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<NoticiaService>().listar();
  }

  void _recargar() {
    setState(() {
      _future = context.read<NoticiaService>().listar();
    });
  }

  Future<void> _abrirFormulario({Noticia? existente}) async {
    final tituloCtrl = TextEditingController(text: existente?.titulo ?? '');
    final resumenCtrl = TextEditingController(text: existente?.resumen ?? '');
    final contenidoCtrl = TextEditingController(text: existente?.contenido ?? '');
    final imagenCtrl = TextEditingController(text: existente?.imagenUrl ?? '');
    final etiquetasCtrl = TextEditingController(text: existente?.etiquetas.join(', ') ?? '');

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existente == null ? 'Publicar noticia' : 'Editar noticia', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título')),
              const SizedBox(height: 10),
              TextField(controller: resumenCtrl, decoration: const InputDecoration(labelText: 'Resumen'), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: contenidoCtrl, decoration: const InputDecoration(labelText: 'Contenido'), maxLines: 5),
              const SizedBox(height: 10),
              TextField(controller: imagenCtrl, decoration: const InputDecoration(labelText: 'URL de imagen')),
              const SizedBox(height: 10),
              TextField(controller: etiquetasCtrl, decoration: const InputDecoration(labelText: 'Etiquetas (separadas por coma)')),
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
      ),
    );

    if (guardar == true) {
      final body = {
        'titulo': tituloCtrl.text.trim(),
        'resumen': resumenCtrl.text.trim(),
        'contenido': contenidoCtrl.text.trim(),
        'imagenUrl': imagenCtrl.text.trim().isEmpty ? null : imagenCtrl.text.trim(),
        'etiquetas': etiquetasCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      };
      try {
        final service = context.read<NoticiaService>();
        if (existente == null) {
          await service.crear(body);
        } else {
          await service.editar(existente.id, body);
        }
        if (mounted) {
          mostrarMensaje(context, 'Noticia guardada');
          _recargar();
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _eliminar(Noticia n) async {
    try {
      await context.read<NoticiaService>().eliminar(n.id);
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Noticias')),
      floatingActionButton: FloatingActionButton(onPressed: () => _abrirFormulario(), child: const Icon(Icons.add)),
      body: FutureBuilder<List<Noticia>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final noticias = snapshot.data ?? [];
          if (noticias.isEmpty) return const EmptyView(mensaje: 'No hay noticias publicadas');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: noticias.length,
            itemBuilder: (context, i) {
              final n = noticias[i];
              return Card(
                child: ListTile(
                  title: Text(n.titulo),
                  subtitle: Text(n.resumen ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirFormulario(existente: n)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _eliminar(n)),
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
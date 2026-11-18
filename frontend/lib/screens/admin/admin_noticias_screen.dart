import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/noticia.dart';
import '../../core/services/noticia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';

class AdminNoticiasScreen extends StatefulWidget {
  const AdminNoticiasScreen({super.key});
  @override
  State<AdminNoticiasScreen> createState() => _AdminNoticiasScreenState();
}

class _AdminNoticiasScreenState extends State<AdminNoticiasScreen> {
  late Future<List<Noticia>> _future;
  Set<String> _filtro = {};

  @override
  void initState() {
    super.initState();
    _future = context.read<NoticiaService>().listar();
  }

  void _recargar() {
    setState(() {
      _future = context.read<NoticiaService>().listar(intolerancias: _filtro);
    });
  }

  Future<void> _abrirFormulario({Noticia? existente}) async {
    final tituloCtrl = TextEditingController(text: existente?.titulo ?? '');
    final resumenCtrl = TextEditingController(text: existente?.resumen ?? '');
    final contenidoCtrl = TextEditingController(text: existente?.contenido ?? '');
    final imagenCtrl = TextEditingController(text: existente?.imagenUrl ?? '');
    final etiquetasCtrl = TextEditingController(text: existente?.etiquetas.join(', ') ?? '');
    Set<String> intolerancias = {...(existente?.intolerancias ?? <String>{})};

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
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
              const Text('Intolerancias relacionadas:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SelectorIntolerancias(
                seleccionadas: intolerancias,
                onChanged: (s) => setModalState(() => intolerancias = s),
              ),
              const SizedBox(height: 10),
              TextField(controller: etiquetasCtrl, decoration: const InputDecoration(labelText: 'Otras etiquetas (separadas por coma)')),
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
      )),
    );

    if (guardar == true) {
      final body = {
        'titulo': tituloCtrl.text.trim(),
        'resumen': resumenCtrl.text.trim(),
        'contenido': contenidoCtrl.text.trim(),
        'imagenUrl': imagenCtrl.text.trim().isEmpty ? null : imagenCtrl.text.trim(),
        'etiquetas': etiquetasCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'intolerancias': intolerancias.toList(),
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

  bool _importando = false;

  /// Trae ya las noticias de Uruguay y Brasil (sin esperar la importación
  /// automática, que corre cada 6 horas). El servidor revisa unos 50 canales
  /// (búsquedas generales y una por cada restricción) en segundo plano.
  Future<void> _importar() async {
    setState(() => _importando = true);
    try {
      final r = await context.read<NoticiaService>().importarRss();
      if (!mounted) return;
      _mostrarEstadoImportacion(r);
      // La importación sigue en el servidor: se recarga la lista en un rato.
      Future.delayed(const Duration(seconds: 90), () {
        if (mounted) _recargar();
      });
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  /// Muestra que la importación empezó y cómo salió la anterior, con sus
  /// errores, para saber si los canales RSS responden.
  void _mostrarEstadoImportacion(Map<String, dynamic> r) {
    final ultimo = r['ultimoResultado'] is Map ? Map<String, dynamic>.from(r['ultimoResultado']) : null;
    final errores = ((ultimo?['errores'] as List?) ?? const []).map((e) => e.toString()).toList();
    final fecha = r['ultimaImportacion']?.toString();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar noticias'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((r['mensaje'] ?? 'Importación iniciada').toString()),
              const SizedBox(height: 14),
              const Text('Importación anterior', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              if (ultimo == null)
                const Text('Todavía no hubo ninguna desde que arrancó el servidor.')
              else ...[
                if (fecha != null) Text('Fecha: ${fecha.replaceFirst('T', ' ').split('.').first}'),
                Text('Canales revisados: ${ultimo['canales']}'),
                Text('Noticias encontradas: ${ultimo['revisadas']}'),
                Text('Noticias nuevas: ${ultimo['nuevas']}'),
                if (errores.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Canales con error: ${errores.length}', style: const TextStyle(color: AppColors.danger)),
                  ...errores.take(5).map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
                ],
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _confirmarEliminar(Noticia n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(n.esImportada ? 'Ocultar noticia' : 'Eliminar noticia'),
        content: Text(n.esImportada
            ? 'La noticia deja de mostrarse y no se vuelve a importar.'
            : 'La noticia se elimina definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(n.esImportada ? 'Ocultar' : 'Eliminar')),
        ],
      ),
    );
    if (ok == true) await _eliminar(n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Noticias'),
        actions: [
          IconButton(
            tooltip: 'Importar noticias de Uruguay y Brasil',
            onPressed: _importando ? null : _importar,
            icon: _importando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rss_feed_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _abrirFormulario(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          const SizedBox(height: 8),
          BarraFiltroIntolerancias(
            seleccion: _filtro,
            prefijo: '',
            titulo: 'Noticias sobre...',
            ayuda: 'Muestra las noticias relacionadas con ALGUNA de las marcadas.',
            onChanged: (s) {
              _filtro = s;
              _recargar();
            },
          ),
          Expanded(
            child: FutureBuilder<List<Noticia>>(
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
                        subtitle: Text(
                          n.esImportada
                              ? 'Importada · ${n.nombrePais ?? ''} · ${n.fuente ?? ''}'
                              : (n.resumen ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirFormulario(existente: n)),
                            IconButton(
                              tooltip: n.esImportada ? 'Ocultar' : 'Eliminar',
                              icon: Icon(n.esImportada ? Icons.visibility_off_outlined : Icons.delete_outline, color: AppColors.danger),
                              onPressed: () => _confirmarEliminar(n),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
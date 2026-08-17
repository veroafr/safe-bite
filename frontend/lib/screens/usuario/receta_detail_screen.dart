import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/receta.dart';
import '../../core/services/receta_service.dart';
import '../../core/widgets/common_widgets.dart';

class RecetaDetailScreen extends StatefulWidget {
  final int recetaId;
  const RecetaDetailScreen({super.key, required this.recetaId});

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
    try {
      final r = await context.read<RecetaService>().obtener(widget.recetaId);
      setState(() => _receta = r);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_receta?.titulo ?? 'Receta')),
      body: _error != null
          ? ErrorView(mensaje: _error!, onReintentar: _cargar)
          : _receta == null
              ? const LoadingView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_receta!.imagenUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_receta!.imagenUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(height: 180, color: const Color(0xFFE0E0E0))),
                      ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, children: [
                      if (_receta!.tiempoPreparacionMinutos != null) Chip(label: Text('${_receta!.tiempoPreparacionMinutos} min')),
                      if (_receta!.dificultad != null) Chip(label: Text(_receta!.dificultad!)),
                      ..._receta!.etiquetas.map((e) => Chip(label: Text(e))),
                    ]),
                    if (_receta!.descripcion != null) ...[
                      const SeccionTitulo('Descripción'),
                      Text(_receta!.descripcion!),
                    ],
                    if (_receta!.ingredientes.isNotEmpty) ...[
                      const SeccionTitulo('Ingredientes'),
                      ..._receta!.ingredientes.map((i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(children: [const Icon(Icons.circle, size: 6), const SizedBox(width: 8), Expanded(child: Text(i))]),
                          )),
                    ],
                    if (_receta!.pasos.isNotEmpty) ...[
                      const SeccionTitulo('Preparación'),
                      ..._receta!.pasos.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 12, child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12))),
                                const SizedBox(width: 10),
                                Expanded(child: Text(entry.value)),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}

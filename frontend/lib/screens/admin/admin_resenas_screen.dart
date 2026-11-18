import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurante.dart';
import '../../core/services/restaurante_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../usuario/restaurante_detail_screen.dart' show EstrellasFijas;

/// Moderación de reseñas de restaurantes: nada se publica sin aprobación.
class AdminResenasScreen extends StatefulWidget {
  const AdminResenasScreen({super.key});
  @override
  State<AdminResenasScreen> createState() => _AdminResenasScreenState();
}

class _AdminResenasScreenState extends State<AdminResenasScreen> {
  String _estado = 'PENDIENTE';
  late Future<List<Evaluacion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Evaluacion>> _cargar() => context.read<RestauranteService>().listarResenas(estado: _estado);

  void _recargar() => setState(() => _future = _cargar());

  Future<void> _aprobar(Evaluacion e) async {
    try {
      await context.read<RestauranteService>().moderarResena(e.id, aprobar: true);
      if (mounted) mostrarMensaje(context, 'Reseña publicada');
      _recargar();
    } catch (err) {
      if (mounted) mostrarError(context, err);
    }
  }

  Future<void> _rechazar(Evaluacion e) async {
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar reseña'),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional, lo verá el autor)',
            hintText: 'Ej: contiene información no verificable u ofensiva',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<RestauranteService>().moderarResena(e.id, aprobar: false, motivo: motivoCtrl.text.trim());
      if (mounted) mostrarMensaje(context, 'Reseña rechazada');
      _recargar();
    } catch (err) {
      if (mounted) mostrarError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas de restaurantes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final (valor, texto) in const [
                  ('PENDIENTE', 'Pendientes'),
                  ('APROBADA', 'Aprobadas'),
                  ('RECHAZADA', 'Rechazadas'),
                ])
                  ChoiceChip(
                    label: Text(texto),
                    selected: _estado == valor,
                    onSelected: (_) {
                      _estado = valor;
                      _recargar();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Evaluacion>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
                if (snap.hasError) return ErrorView(mensaje: snap.error.toString(), onReintentar: _recargar);
                final lista = snap.data ?? [];
                if (lista.isEmpty) {
                  return EmptyView(
                      mensaje: _estado == 'PENDIENTE' ? 'No hay reseñas esperando aprobación' : 'No hay reseñas en este estado');
                }
                return RefreshIndicator(
                  onRefresh: () async => _recargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final e = lista[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(e.restauranteNombre ?? 'Restaurante #${e.restauranteId}',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              EstrellasFijas(valor: e.puntuacion),
                              const SizedBox(height: 6),
                              Text(e.comentario ?? ''),
                              const SizedBox(height: 6),
                              Text('Por ${e.usuarioNombre} · ${DateFormat('dd/MM/yyyy HH:mm').format(e.fecha)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              if (e.rechazada && e.motivoRechazo != null) ...[
                                const SizedBox(height: 4),
                                Text('Motivo: ${e.motivoRechazo}',
                                    style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                              ],
                              const SizedBox(height: 10),
                              Row(children: [
                                if (!e.rechazada)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _rechazar(e),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(color: AppColors.danger),
                                      ),
                                      child: Text(e.pendiente ? 'Rechazar' : 'Despublicar'),
                                    ),
                                  ),
                                if (!e.rechazada && e.pendiente) const SizedBox(width: 10),
                                if (e.pendiente || e.rechazada)
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _aprobar(e),
                                      child: const Text('Aprobar y publicar'),
                                    ),
                                  ),
                              ]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

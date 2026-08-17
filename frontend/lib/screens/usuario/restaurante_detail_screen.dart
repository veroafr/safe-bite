import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurante.dart';
import '../../core/models/usuario.dart';
import '../../core/models/alerta.dart';
import '../../core/services/restaurante_service.dart';
import '../../core/services/alerta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class RestauranteDetailScreen extends StatefulWidget {
  final int restauranteId;
  const RestauranteDetailScreen({super.key, required this.restauranteId});

  @override
  State<RestauranteDetailScreen> createState() => _RestauranteDetailScreenState();
}

class _RestauranteDetailScreenState extends State<RestauranteDetailScreen> {
  Restaurante? _restaurante;
  List<Comentario> _comentarios = [];
  List<Evaluacion> _evaluaciones = [];
  bool _cargando = true;
  String? _error;
  final _comentarioCtrl = TextEditingController();
  int _puntuacionSeleccionada = 5;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final service = context.read<RestauranteService>();
      final r = await service.obtener(widget.restauranteId);
      final c = await service.listarComentarios(widget.restauranteId);
      final e = await service.listarEvaluaciones(widget.restauranteId);
      setState(() {
        _restaurante = r;
        _comentarios = c;
        _evaluaciones = e;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _enviarComentario() async {
    if (_comentarioCtrl.text.trim().isEmpty) return;
    try {
      await context.read<RestauranteService>().comentar(widget.restauranteId, _comentarioCtrl.text.trim());
      _comentarioCtrl.clear();
      FocusScope.of(context).unfocus();
      await _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _evaluar() async {
    try {
      await context.read<RestauranteService>().evaluar(widget.restauranteId, _puntuacionSeleccionada, null);
      if (mounted) mostrarMensaje(context, 'Gracias por tu evaluación');
      await _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _reportarAlerta() async {
    final descripcionCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar alerta'),
        content: TextField(
          controller: descripcionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describí el problema (ej: no cumple con lo indicado)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );

    if (confirmado == true && descripcionCtrl.text.trim().isNotEmpty) {
      try {
        await context.read<AlertaService>().crear(
              tipo: TipoAlerta.RESTAURANTE,
              restauranteId: widget.restauranteId,
              descripcion: descripcionCtrl.text.trim(),
            );
        if (mounted) mostrarMensaje(context, 'Alerta enviada. El equipo la revisará pronto.');
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurante?.nombre ?? 'Restaurante'),
        actions: [
          IconButton(icon: const Icon(Icons.report_gmailerrorred_outlined), onPressed: _reportarAlerta, tooltip: 'Alertar'),
        ],
      ),
      body: _cargando
          ? const LoadingView()
          : _error != null
              ? ErrorView(mensaje: _error!, onReintentar: _cargar)
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_restaurante!.imagenUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(_restaurante!.imagenUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(height: 180, color: const Color(0xFFE0E0E0))),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.accent),
                          Text(' ${_restaurante!.ratingPromedio.toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 12),
                          if (_restaurante!.direccion != null)
                            Expanded(
                              child: Text(_restaurante!.direccion!,
                                  style: const TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                            ),
                        ],
                      ),
                      if (_restaurante!.descripcion != null) ...[
                        const SizedBox(height: 10),
                        Text(_restaurante!.descripcion!),
                      ],
                      if (_restaurante!.opcionesAptasPara.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: _restaurante!.opcionesAptasPara
                              .map((t) => Chip1('Sin ${etiquetaIntolerancia(t)}'))
                              .toList(),
                        ),
                      ],
                      if (_restaurante!.latitud != null && _restaurante!.longitud != null) ...[
                        const SeccionTitulo('Ubicación en el mapa'),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 180,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(_restaurante!.latitud!, _restaurante!.longitud!),
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.safebite.app',
                                ),
                                MarkerLayer(markers: [
                                  Marker(
                                    point: LatLng(_restaurante!.latitud!, _restaurante!.longitud!),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: AppColors.danger, size: 36),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SeccionTitulo('Tu evaluación'),
                      Row(
                        children: List.generate(5, (i) {
                          final valor = i + 1;
                          return IconButton(
                            icon: Icon(valor <= _puntuacionSeleccionada ? Icons.star : Icons.star_border, color: AppColors.accent),
                            onPressed: () => setState(() => _puntuacionSeleccionada = valor),
                          );
                        }),
                      ),
                      OutlinedButton(onPressed: _evaluar, child: const Text('Enviar evaluación')),
                      const SeccionTitulo('Comentarios'),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _comentarioCtrl,
                              decoration: const InputDecoration(hintText: 'Escribí un comentario...'),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.send, color: AppColors.primary), onPressed: _enviarComentario),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_comentarios.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Todavía no hay comentarios', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ..._comentarios.map((c) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(c.usuarioNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(c.texto),
                            ),
                          )),
                      const SeccionTitulo('Evaluaciones de otros usuarios'),
                      if (_evaluaciones.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Todavía no hay evaluaciones', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ..._evaluaciones.map((e) => Card(
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [const Icon(Icons.star, color: AppColors.accent, size: 18), Text('${e.puntuacion}')],
                              ),
                              title: Text(e.usuarioNombre),
                              subtitle: e.comentario != null ? Text(e.comentario!) : null,
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

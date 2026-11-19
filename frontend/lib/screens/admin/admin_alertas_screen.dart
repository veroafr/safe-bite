import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/alerta.dart';
import '../../core/services/alerta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import '../../core/i18n/i18n.dart';

class AdminAlertasScreen extends StatefulWidget {
  const AdminAlertasScreen({super.key});
  @override
  State<AdminAlertasScreen> createState() => _AdminAlertasScreenState();
}

class _AdminAlertasScreenState extends State<AdminAlertasScreen> {
  EstadoAlerta? _filtro = EstadoAlerta.PENDIENTE;
  late Future<List<Alerta>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Alerta>> _cargar() => context.read<AlertaService>().listarPorEstado(estado: _filtro);

  void _recargar() {
    setState(() {
      _future = _cargar();
    });
  }

  Future<void> _revisar(Alerta a, EstadoAlerta estado) async {
    try {
      await context.read<AlertaService>().revisar(a.id, estado);
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  void _verPrueba(String imagen) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          InteractiveViewer(
            maxScale: 5,
            child: ImagenFlexible(
              fuente: imagen,
              fit: BoxFit.contain,
              sinImagen: SizedBox(height: 200, child: Center(child: Text(tr('No se pudo mostrar')))),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: IconButton.filled(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Gestión de Alertas'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: Text(tr('Pendientes')), selected: _filtro == EstadoAlerta.PENDIENTE,
                    onSelected: (_) { setState(() => _filtro = EstadoAlerta.PENDIENTE); _recargar(); }),
                ChoiceChip(label: Text(tr('Aceptadas')), selected: _filtro == EstadoAlerta.ACEPTADA,
                    onSelected: (_) { setState(() => _filtro = EstadoAlerta.ACEPTADA); _recargar(); }),
                ChoiceChip(label: Text(tr('Denegadas')), selected: _filtro == EstadoAlerta.DENEGADA,
                    onSelected: (_) { setState(() => _filtro = EstadoAlerta.DENEGADA); _recargar(); }),
                ChoiceChip(label: Text(tr('Todas')), selected: _filtro == null,
                    onSelected: (_) { setState(() => _filtro = null); _recargar(); }),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Alerta>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
                final alertas = snapshot.data ?? [];
                if (alertas.isEmpty) return EmptyView(mensaje: tr('No hay alertas en este estado'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alertas.length,
                  itemBuilder: (context, i) {
                    final a = alertas[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(a.restauranteNombre ?? a.productoNombre ?? tr('Reporte'),
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Chip1(nombreTipoAlerta(a.tipo)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextoT(a.descripcion),
                            if (a.telefonoContacto != null) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => abrirEnlace(context, 'tel:${a.telefonoContacto!.replaceAll(RegExp(r'[^0-9+]'), '')}'),
                                child: Row(children: [
                                  const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(a.telefonoContacto!,
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ],
                            if (a.pruebas.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(tr('Pruebas ({0})', [a.pruebas.length]),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: a.pruebas
                                    .map((img) => InkWell(
                                          onTap: () => _verPrueba(img),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: ImagenFlexible(
                                                fuente: img,
                                                sinImagen: Container(color: const Color(0xFFE0E0E0)),
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(tr('Reportado por {0} el {1}', [a.usuarioNombre ?? '-', DateFormat('dd/MM/yyyy HH:mm').format(a.fecha)]),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            if (a.estado == EstadoAlerta.PENDIENTE) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _revisar(a, EstadoAlerta.DENEGADA),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                                      child: Text(tr('Denegar'), style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _revisar(a, EstadoAlerta.ACEPTADA),
                                      child: Text(tr('Aceptar')),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Chip1(nombreEstadoAlerta(a.estado), color: a.estado == EstadoAlerta.ACEPTADA ? AppColors.primary : AppColors.danger),
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
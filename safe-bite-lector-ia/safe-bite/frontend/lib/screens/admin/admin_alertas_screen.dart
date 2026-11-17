import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/alerta.dart';
import '../../core/services/alerta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Alertas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Pendientes'), selected: _filtro == EstadoAlerta.PENDIENTE,
                    onSelected: (_) { setState(() => _filtro = EstadoAlerta.PENDIENTE); _recargar(); }),
                ChoiceChip(label: const Text('Aceptadas'), selected: _filtro == EstadoAlerta.ACEPTADA,
                    onSelected: (_) { setState(() => _filtro = EstadoAlerta.ACEPTADA); _recargar(); }),
                ChoiceChip(label: const Text('Denegadas'), selected: _filtro == EstadoAlerta.DENEGADA,
                    onSelected: (_) { setState(() => _filtro = EstadoAlerta.DENEGADA); _recargar(); }),
                ChoiceChip(label: const Text('Todas'), selected: _filtro == null,
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
                if (alertas.isEmpty) return const EmptyView(mensaje: 'No hay alertas en este estado');
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
                                  child: Text(a.restauranteNombre ?? a.productoNombre ?? 'Reporte',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Chip1(a.tipo.name),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(a.descripcion),
                            const SizedBox(height: 6),
                            Text('Reportado por ${a.usuarioNombre ?? '-'} el ${DateFormat('dd/MM/yyyy HH:mm').format(a.fecha)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            if (a.estado == EstadoAlerta.PENDIENTE) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _revisar(a, EstadoAlerta.DENEGADA),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                                      child: const Text('Denegar', style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _revisar(a, EstadoAlerta.ACEPTADA),
                                      child: const Text('Aceptar'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Chip1(a.estado.name, color: a.estado == EstadoAlerta.ACEPTADA ? AppColors.primary : AppColors.danger),
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
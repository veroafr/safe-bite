import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/alerta.dart';
import '../../core/services/alerta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class MisAlertasScreen extends StatefulWidget {
  const MisAlertasScreen({super.key});
  @override
  State<MisAlertasScreen> createState() => _MisAlertasScreenState();
}

class _MisAlertasScreenState extends State<MisAlertasScreen> {
  late Future<List<Alerta>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AlertaService>().misAlertas();
  }

  void _recargar() {
    setState(() {
      _future = context.read<AlertaService>().misAlertas();
    });
  }

  Color _colorEstado(EstadoAlerta e) {
    switch (e) {
      case EstadoAlerta.PENDIENTE:
        return AppColors.accent;
      case EstadoAlerta.ACEPTADA:
        return AppColors.primary;
      case EstadoAlerta.DENEGADA:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Alertas Reportadas')),
      body: FutureBuilder<List<Alerta>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final alertas = snapshot.data ?? [];
          if (alertas.isEmpty) return const EmptyView(mensaje: 'No reportaste ninguna alerta todavía', icono: Icons.notifications_none);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alertas.length,
            itemBuilder: (context, i) {
              final a = alertas[i];
              return Card(
                child: ListTile(
                  title: Text(a.restauranteNombre ?? a.productoNombre ?? 'Reporte'),
                  subtitle: Text('${a.descripcion}\n${DateFormat('dd/MM/yyyy HH:mm').format(a.fecha)}'),
                  isThreeLine: true,
                  trailing: Chip1(a.estado.name, color: _colorEstado(a.estado)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
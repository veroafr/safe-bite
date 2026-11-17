import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/models/reporte.dart';
import '../../core/services/reporte_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});
  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  late Future<Reporte> _future;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<ReporteService>().obtenerEstadisticas();
  }

  void _recargar() {
    setState(() {
      _future = context.read<ReporteService>().obtenerEstadisticas();
    });
  }

  Future<void> _exportarPdf() async {
    setState(() => _exportando = true);
    try {
      final bytes = await context.read<ReporteService>().exportarPdf();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/reporte-safebite-${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) mostrarMensaje(context, 'PDF guardado en: ${file.path}');
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes y Estadísticas')),
      body: FutureBuilder<Reporte>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final r = snapshot.data!;
          final tarjetas = [
            _Estadistica('Usuarios', r.totalUsuarios, Icons.people, AppColors.primary),
            _Estadistica('Restaurantes', r.totalRestaurantes, Icons.restaurant, AppColors.primary),
            _Estadistica('Recetas', r.totalRecetas, Icons.menu_book, AppColors.primary),
            _Estadistica('Noticias', r.totalNoticias, Icons.newspaper, AppColors.primary),
            _Estadistica('Productos', r.totalProductos, Icons.inventory_2, AppColors.primary),
            _Estadistica('Alertas pendientes', r.alertasPendientes, Icons.report_gmailerrorred, AppColors.accent),
            _Estadistica('Alertas aceptadas', r.alertasAceptadas, Icons.check_circle_outline, AppColors.primary),
            _Estadistica('Alertas denegadas', r.alertasDenegadas, Icons.cancel_outlined, AppColors.danger),
          ];
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5),
                  itemCount: tarjetas.length,
                  itemBuilder: (context, i) {
                    final t = tarjetas[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t.icono, color: t.color),
                            const SizedBox(height: 8),
                            Text('${t.valor}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(t.titulo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _exportando ? null : _exportarPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_exportando ? 'Generando PDF...' : 'Exportar a PDF'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Estadistica {
  final String titulo;
  final int valor;
  final IconData icono;
  final Color color;
  _Estadistica(this.titulo, this.valor, this.icono, this.color);
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/reporte.dart';
import '../../core/services/reporte_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/web/descarga.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/i18n/i18n.dart';

/// Reportes y estadísticas: totales, gráficos de cada variable y exportación a PDF.
class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});
  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen> {
  late Future<Reporte> _future = context.read<ReporteService>().obtenerEstadisticas();
  bool _exportando = false;

  void _recargar() => setState(() => _future = context.read<ReporteService>().obtenerEstadisticas());

  Future<void> _exportarPdf() async {
    setState(() => _exportando = true);
    try {
      final bytes = await context.read<ReporteService>().exportarPdf();
      final nombre = 'reporte-safebite-${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.pdf';
      final ruta = await guardarArchivo(bytes, nombre, 'application/pdf');
      if (mounted) mostrarMensaje(context, ruta == null ? tr('PDF descargado: {0}', [nombre]) : tr('PDF guardado en: {0}', [ruta]));
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Reportes y estadísticas')),
        actions: [IconButton(tooltip: tr('Actualizar'), onPressed: _recargar, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportando ? null : _exportarPdf,
        icon: _exportando
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(_exportando ? tr('Generando...') : tr('Exportar PDF')),
      ),
      body: FutureBuilder<Reporte>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final r = snapshot.data!;
          final totales = [
            _Total(tr('Usuarios'), r.totalUsuarios, Icons.people_alt_rounded, const Color(0xFF1E88E5)),
            _Total(tr('Usuarios activos'), r.usuariosActivos, Icons.how_to_reg_rounded, AppColors.primary),
            _Total(tr('Restaurantes'), r.totalRestaurantes, Icons.storefront_rounded, const Color(0xFF00897B)),
            _Total(tr('Reseñas publicadas'), r.totalResenas, Icons.rate_review_rounded, const Color(0xFFFFB300)),
            _Total(tr('Recetas publicadas'), r.totalRecetas, Icons.menu_book_rounded, const Color(0xFF8E24AA)),
            _Total(tr('Productos'), r.totalProductos, Icons.inventory_2_rounded, const Color(0xFF7C4DFF)),
            _Total(tr('Noticias'), r.totalNoticias, Icons.newspaper_rounded, const Color(0xFFFF7043)),
            _Total(tr('Alertas pendientes'), r.alertasPendientes, Icons.warning_amber_rounded, AppColors.danger),
          ];
          final pendientes = [
            (tr('Productos por revisar'), r.productosPendientes),
            (tr('Recetas por aprobar'), r.recetasPendientes),
            (tr('Reseñas por aprobar'), r.resenasPendientes),
            (tr('Pedidos de contraseña'), r.recuperacionesPendientes),
          ];
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: LayoutBuilder(builder: (context, c) {
              final columnas = c.maxWidth > 900 ? 4 : (c.maxWidth > 560 ? 3 : 2);
              final anchoGrafico = c.maxWidth > 900 ? 2 : 1;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  if (r.generado != null)
                    Text(tr('Actualizado el {0}', [DateFormat('dd/MM/yyyy HH:mm').format(r.generado!)]),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: columnas,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.9,
                    children: totales.map((t) => _TarjetaTotal(total: t)).toList(),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          Text(tr('Pendientes de revisión:'), style: TextStyle(fontWeight: FontWeight.w600)),
                          for (final (titulo, valor) in pendientes)
                            Text('$titulo: $valor',
                                style: TextStyle(color: valor > 0 ? AppColors.danger : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 0,
                    children: r.series
                        .map((s) => SizedBox(
                              width: anchoGrafico == 2 ? (c.maxWidth - 32 - 12) / 2 : c.maxWidth - 32,
                              child: _TarjetaGrafico(serie: s),
                            ))
                        .toList(),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _Total {
  final String titulo;
  final int valor;
  final IconData icono;
  final Color color;
  _Total(this.titulo, this.valor, this.icono, this.color);
}

class _TarjetaTotal extends StatelessWidget {
  final _Total total;
  const _TarjetaTotal({required this.total});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: total.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(total.icono, color: total.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${total.valor}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(total.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ]),
        ),
      );
}

class _TarjetaGrafico extends StatelessWidget {
  final SerieReporte serie;
  const _TarjetaGrafico({required this.serie});

  @override
  Widget build(BuildContext context) {
    final vacia = serie.datos.isEmpty || serie.datos.every((d) => d.valor == 0);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextoT(serie.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (serie.descripcion != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: TextoT(serie.descripcion!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            const SizedBox(height: 14),
            if (vacia)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: Text(tr('Sin datos todavía'), style: TextStyle(color: AppColors.textSecondary))),
              )
            else if (serie.tipo == 'columnas')
              _GraficoColumnas(serie: serie)
            else
              _GraficoBarras(serie: serie),
          ],
        ),
      ),
    );
  }
}

String _numero(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Barras horizontales: comparación entre categorías.
class _GraficoBarras extends StatelessWidget {
  final SerieReporte serie;
  const _GraficoBarras({required this.serie});

  @override
  Widget build(BuildContext context) {
    final max = serie.datos.map((d) => d.valor).fold<double>(0, (a, b) => b > a ? b : a);
    return Column(
      children: serie.datos.map((d) {
        final proporcion = max <= 0 ? 0.0 : d.valor / max;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(
              width: 130,
              child: TextoT(d.etiqueta, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: '${context.tc(d.etiqueta)}: ${_numero(d.valor)} ${context.tc(serie.unidad)}',
                child: Stack(children: [
                  Container(
                    height: 18,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                  ),
                  FractionallySizedBox(
                    widthFactor: proporcion.clamp(0.02, 1.0),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.lime]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: Text(_numero(d.valor),
                  textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

/// Columnas verticales: evolución mes a mes.
class _GraficoColumnas extends StatelessWidget {
  final SerieReporte serie;
  const _GraficoColumnas({required this.serie});

  @override
  Widget build(BuildContext context) {
    const altoMax = 140.0;
    final max = serie.datos.map((d) => d.valor).fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      height: altoMax + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: serie.datos.map((d) {
          final alto = max <= 0 ? 0.0 : (d.valor / max) * altoMax;
          return Expanded(
            child: Tooltip(
              message: '${context.tc(d.etiqueta)}: ${_numero(d.valor)} ${context.tc(serie.unidad)}',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_numero(d.valor), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    height: alto < 3 ? 3 : alto,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.primaryDark, AppColors.lime],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextoT(d.etiqueta, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

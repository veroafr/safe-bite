import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/intolerancia.dart';
import '../../core/models/receta.dart';
import '../../core/services/receta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../../core/widgets/receta_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import 'enviar_receta_screen.dart';
import 'receta_detail_screen.dart';

class RecetasScreen extends StatefulWidget {
  const RecetasScreen({super.key});
  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  /// Intolerancias elegidas: solo recetas libres de todas ellas.
  Set<String> _filtro = {};
  late Future<List<Receta>> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _recargar();
    });
    _future = _cargar();
  }

  Future<List<Receta>> _cargar() {
    final service = context.read<RecetaService>();
    return service.listar(esTip: _tabController.index == 1, intolerancias: _filtro);
  }

  void _recargar() {
    setState(() {
      _future = _cargar();
    });
  }

  Future<void> _compartir() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const EnviarRecetaScreen()));
    if (ok == true && mounted) {
      mostrarMensaje(context, '¡Gracias! Tu receta se publicará cuando el equipo la apruebe.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _compartir,
              icon: const Icon(Icons.add),
              label: const Text('Compartir receta'),
            )
          : null,
      appBar: AppBar(
        title: const Text('Recetas y Tips'),
        actions: [
          IconButton(
            tooltip: 'Mis recetas enviadas',
            icon: const Icon(Icons.assignment_ind_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MisRecetasScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.lime,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Recetas'), Tab(text: 'Tips de Salud')],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          BarraFiltroIntolerancias(
            seleccion: _filtro,
            prefijo: 'Sin ',
            titulo: 'Recetas libres de...',
            ayuda: 'Se muestran las recetas aptas para TODAS las intolerancias que marques.',
            onChanged: (s) {
              _filtro = s;
              _recargar();
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FutureBuilder<List<Receta>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
                final recetas = snapshot.data ?? [];
                if (recetas.isEmpty) {
                  return EmptyView(
                      mensaje: _filtro.isEmpty ? 'No hay recetas disponibles' : 'No hay recetas libres de todo lo que elegiste',
                      icono: Icons.menu_book_outlined);
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.70),
                  itemCount: recetas.length,
                  itemBuilder: (context, i) => _TarjetaReceta(receta: recetas[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaReceta extends StatelessWidget {
  final Receta receta;
  const _TarjetaReceta({required this.receta});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecetaDetailScreen(recetaId: receta.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Stack(fit: StackFit.expand, children: [
                ImagenFlexible(
                  fuente: receta.imagenUrl,
                  sinImagen: Container(color: AppColors.primarySoft, child: const Icon(Icons.restaurant_menu)),
                ),
                if (!receta.esTip)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: EtiquetaOrigenReceta(receta: receta, compacta: true),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receta.titulo, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (receta.tiempoPreparacionMinutos != null) '${receta.tiempoPreparacionMinutos} min',
                      if (receta.dificultad != null) receta.dificultad!,
                    ].join(' • '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (receta.libreDe.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Chip1('Sin ${etiquetaIntolerancia(receta.libreDe.first)}'
                        '${receta.libreDe.length > 1 ? ' +${receta.libreDe.length - 1}' : ''}'),
                  ] else if (receta.etiquetas.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Chip1(receta.etiquetas.first),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
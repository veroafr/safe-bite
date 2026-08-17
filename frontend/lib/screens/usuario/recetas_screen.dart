import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/receta.dart';
import '../../core/services/receta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'receta_detail_screen.dart';

class RecetasScreen extends StatefulWidget {
  const RecetasScreen({super.key});
  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _soloAptasParaMi = false;
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
    return service.listar(esTip: _tabController.index == 1, usarMisIntolerancias: _soloAptasParaMi);
  }

  void _recargar() {
    setState(() {
      _future = _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas y Tips'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Recetas'), Tab(text: 'Tips de Salud')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilterChip(
              label: const Text('Solo aptas para mis intolerancias'),
              selected: _soloAptasParaMi,
              onSelected: (v) {
                setState(() => _soloAptasParaMi = v);
                _recargar();
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Receta>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
                final recetas = snapshot.data ?? [];
                if (recetas.isEmpty) return const EmptyView(mensaje: 'No hay recetas disponibles', icono: Icons.menu_book_outlined);
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
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
              child: receta.imagenUrl != null
                  ? Image.network(receta.imagenUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE0E0E0)))
                  : Container(color: const Color(0xFFE0E0E0), child: const Icon(Icons.restaurant_menu)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receta.titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (receta.tiempoPreparacionMinutos != null) '${receta.tiempoPreparacionMinutos} min',
                      if (receta.dificultad != null) receta.dificultad!,
                    ].join(' • '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (receta.etiquetas.isNotEmpty) ...[
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
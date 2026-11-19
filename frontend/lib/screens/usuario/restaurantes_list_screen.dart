import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurante.dart';
import '../../core/models/usuario.dart';
import '../../core/services/restaurante_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import 'restaurante_detail_screen.dart';

class RestaurantesListScreen extends StatefulWidget {
  const RestaurantesListScreen({super.key});
  @override
  State<RestaurantesListScreen> createState() => _RestaurantesListScreenState();
}

class _RestaurantesListScreenState extends State<RestaurantesListScreen> {
  final _buscadorCtrl = TextEditingController();
  /// Intolerancias elegidas: el local tiene que ser apto para todas.
  Set<String> _filtroIntolerancias = {};
  String? _filtroTipoCocina;

  late Future<List<Restaurante>> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<List<Restaurante>> _cargar() {
    final service = context.read<RestauranteService>();
    return service.buscar(
      nombre: _buscadorCtrl.text.trim().isEmpty ? null : _buscadorCtrl.text.trim(),
      tipoCocina: _filtroTipoCocina,
      intolerancias: _filtroIntolerancias,
    );
  }

  void _recargar() {
    setState(() {
      _future = _cargar();
    });
  }

  Future<void> _abrirFiltros() async {
    final resultado = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String? cocinaTemp = _filtroTipoCocina;
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Tipo de cocina'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: cocinaTemp == null,
                      onSelected: (_) => setModalState(() => cocinaTemp = null),
                    ),
                    for (final c in ['Vegana', 'Vegetariana', 'Casera', 'Saludable', 'Cafeteria'])
                      ChoiceChip(
                        label: Text(c),
                        selected: cocinaTemp == c,
                        onSelected: (_) => setModalState(() => cocinaTemp = c),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, {'cocina': cocinaTemp}),
                  child: const Text('Aplicar filtros'),
                ),
              ],
            ),
          );
        });
      },
    );

    if (resultado != null) {
      setState(() {
        _filtroTipoCocina = resultado['cocina'];
      });
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurantes')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buscadorCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Buscar restaurantes...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _recargar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      tooltip: 'Tipo de cocina',
                      onPressed: _abrirFiltros,
                    ),
                  ),
                ],
              ),
            ),
            BarraFiltroIntolerancias(
              seleccion: _filtroIntolerancias,
              titulo: 'Locales aptos para...',
              ayuda: 'Se muestran los locales con opciones aptas para TODAS las intolerancias que marques.',
              onChanged: (s) {
                _filtroIntolerancias = s;
                _recargar();
              },
            ),
            const SizedBox(height: 4),
            Expanded(
              child: FutureBuilder<List<Restaurante>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                  if (snapshot.hasError) {
                    return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
                  }
                  final restaurantes = snapshot.data ?? [];
                  if (restaurantes.isEmpty) {
                    return ListView(padding: const EdgeInsets.all(16), children: [
                      SizedBox(
                        height: 260,
                        child: EmptyView(
                            mensaje: _filtroIntolerancias.isEmpty
                                ? 'No se encontraron restaurantes'
                                : 'No hay locales aptos para todas las intolerancias elegidas',
                            icono: Icons.restaurant_outlined),
                      ),
                      const AvisoInformacionLocales(),
                    ]);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _recargar(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      // Al final de la lista, el aviso sobre el origen de la información.
                      itemCount: restaurantes.length + 1,
                      itemBuilder: (context, i) => i == restaurantes.length
                          ? const AvisoInformacionLocales()
                          : _TarjetaRestaurante(restaurante: restaurantes[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaRestaurante extends StatelessWidget {
  final Restaurante restaurante;
  const _TarjetaRestaurante({required this.restaurante});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RestauranteDetailScreen(restauranteId: restaurante.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: ImagenFlexible(
                    fuente: restaurante.imagenMiniatura ?? restaurante.imagenUrl,
                    sinImagen: _placeholder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurante.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.accent, size: 16),
                        Text(' ${restaurante.ratingPromedio.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (restaurante.descripcion != null) ...[
                      const SizedBox(height: 2),
                      Text(restaurante.descripcion!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                    if (restaurante.opcionesAptasPara.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: restaurante.opcionesAptasPara
                            .map((t) => Chip1('Sin ${etiquetaIntolerancia(t)}'))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.primarySoft,
        child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 30),
      );
}
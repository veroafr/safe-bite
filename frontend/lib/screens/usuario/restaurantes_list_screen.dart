import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurante.dart';
import '../../core/models/usuario.dart';
import '../../core/services/restaurante_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'restaurante_detail_screen.dart';

class RestaurantesListScreen extends StatefulWidget {
  const RestaurantesListScreen({super.key});
  @override
  State<RestaurantesListScreen> createState() => _RestaurantesListScreenState();
}

class _RestaurantesListScreenState extends State<RestaurantesListScreen> {
  final _buscadorCtrl = TextEditingController();
  TipoIntolerancia? _filtroIntolerancia;
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
      intolerancia: _filtroIntolerancia,
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
        TipoIntolerancia? intoleranciaTemp = _filtroIntolerancia;
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
                const Text('Apto para intolerancia'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: intoleranciaTemp == null,
                      onSelected: (_) => setModalState(() => intoleranciaTemp = null),
                    ),
                    ...TipoIntolerancia.values.map((t) => ChoiceChip(
                          label: Text(etiquetaIntolerancia(t)),
                          selected: intoleranciaTemp == t,
                          onSelected: (_) => setModalState(() => intoleranciaTemp = t),
                        )),
                  ],
                ),
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
                  onPressed: () => Navigator.pop(ctx, {'intolerancia': intoleranciaTemp, 'cocina': cocinaTemp}),
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
        _filtroIntolerancia = resultado['intolerancia'];
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
                      onPressed: _abrirFiltros,
                    ),
                  ),
                ],
              ),
            ),
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
                    return const EmptyView(mensaje: 'No se encontraron restaurantes', icono: Icons.restaurant_outlined);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _recargar(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: restaurantes.length,
                      itemBuilder: (context, i) => _TarjetaRestaurante(restaurante: restaurantes[i]),
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
                borderRadius: BorderRadius.circular(12),
                child: restaurante.imagenUrl != null
                    ? Image.network(restaurante.imagenUrl!, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
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
        width: 64,
        height: 64,
        color: const Color(0xFFE0E0E0),
        child: const Icon(Icons.restaurant, color: Colors.white),
      );
}
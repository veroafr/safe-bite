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
import '../../core/i18n/i18n.dart';

const _grilla = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.70);

/// Recetas: primero las de SafeBite (equipo y comunidad), después las que se
/// traen en vivo de Spoonacular con el mismo filtro de intolerancias.
class RecetasScreen extends StatefulWidget {
  const RecetasScreen({super.key});
  @override
  State<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends State<RecetasScreen> {
  /// Intolerancias elegidas: solo recetas libres de todas ellas.
  Set<String> _filtro = {};
  late Future<List<Receta>> _future;

  final List<Receta> _externas = [];
  int _paginaExternas = 0;
  bool _cargandoExternas = false;
  bool _hayMasExternas = true;
  String? _errorExternas;
  int _consulta = 0; // descarta respuestas viejas si el filtro cambió

  @override
  void initState() {
    super.initState();
    _future = _cargar();
    _cargarExternas(reiniciar: true);
  }

  Future<List<Receta>> _cargar() =>
      context.read<RecetaService>().listar(esTip: false, intolerancias: _filtro);

  Future<void> _cargarExternas({bool reiniciar = false}) async {
    final consulta = reiniciar ? ++_consulta : _consulta;
    setState(() {
      _cargandoExternas = true;
      _errorExternas = null;
      if (reiniciar) {
        _externas.clear();
        _paginaExternas = 0;
        _hayMasExternas = true;
      }
    });
    try {
      final lista = await context.read<RecetaService>().externas(intolerancias: _filtro, pagina: _paginaExternas);
      if (!mounted || consulta != _consulta) return;
      setState(() {
        _externas.addAll(lista);
        _paginaExternas++;
        _hayMasExternas = lista.isNotEmpty;
      });
    } catch (e) {
      if (mounted && consulta == _consulta) setState(() => _errorExternas = e.toString());
    } finally {
      if (mounted && consulta == _consulta) setState(() => _cargandoExternas = false);
    }
  }

  void _recargar() {
    setState(() => _future = _cargar());
    _cargarExternas(reiniciar: true);
  }

  Future<void> _compartir() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const EnviarRecetaScreen()));
    if (ok == true && mounted) {
      mostrarMensaje(context, tr('¡Gracias! Tu receta se publicará cuando el equipo la apruebe.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compartir,
        icon: const Icon(Icons.add),
        label: Text(tr('Compartir receta')),
      ),
      appBar: AppBar(
        title: Text(tr('Recetas')),
        actions: [
          IconButton(
            tooltip: tr('Mis recetas enviadas'),
            icon: const Icon(Icons.assignment_ind_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MisRecetasScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          BarraFiltroIntolerancias(
            seleccion: _filtro,
            prefijo: tr('Sin '),
            titulo: tr('Recetas libres de...'),
            ayuda: tr('Se muestran las recetas aptas para TODAS las intolerancias que marques.'),
            onChanged: (s) {
              _filtro = s;
              _recargar();
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: FutureBuilder<List<Receta>>(
                future: _future,
                builder: (context, snapshot) {
                  final cargandoPropias = snapshot.connectionState == ConnectionState.waiting;
                  final propias = snapshot.data ?? [];
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (cargandoPropias)
                        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: LoadingView()))
                      else if (snapshot.hasError)
                        SliverToBoxAdapter(
                            child: SizedBox(
                                height: 220, child: ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar)))
                      else if (propias.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          sliver: SliverGrid.builder(
                            gridDelegate: _grilla,
                            itemCount: propias.length,
                            itemBuilder: (context, i) => _TarjetaReceta(receta: propias[i]),
                          ),
                        ),
                      SliverToBoxAdapter(child: _tituloExternas()),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid.builder(
                          gridDelegate: _grilla,
                          itemCount: _externas.length,
                          itemBuilder: (context, i) => _TarjetaReceta(receta: _externas[i], filtro: _filtro),
                        ),
                      ),
                      SliverToBoxAdapter(child: _pieExternas(sinPropias: !cargandoPropias && propias.isEmpty)),
                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloExternas() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Row(children: [
          const Icon(Icons.public_rounded, size: 20, color: Color(0xFFE65100)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(tr('Más recetas de spoonacular'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (_filtro.isNotEmpty)
            Flexible(
              child: Text('sin ${_filtro.map(etiquetaIntolerancia).join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
        ]),
      );

  Widget _pieExternas({required bool sinPropias}) {
    if (_cargandoExternas) {
      return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    }
    if (_errorExternas != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(tr('No se pudieron traer recetas de Spoonacular: {0}', [context.tc(_errorExternas)]),
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: () => _cargarExternas(), child: Text(tr('Reintentar'))),
        ]),
      );
    }
    if (_externas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          sinPropias ? tr('No hay recetas libres de todo lo que elegiste.') : tr('No hay más recetas externas para este filtro.'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    if (!_hayMasExternas) return const SizedBox.shrink();
    return Center(
      child: TextButton.icon(
        onPressed: () => _cargarExternas(),
        icon: const Icon(Icons.expand_more),
        label: Text(tr('Cargar más recetas')),
      ),
    );
  }
}

class _TarjetaReceta extends StatelessWidget {
  final Receta receta;
  /// Para recetas de Spoonacular traídas en vivo: el filtro con que se buscaron.
  final Set<String> filtro;
  const _TarjetaReceta({required this.receta, this.filtro = const {}});

  @override
  Widget build(BuildContext context) {
    final enVivo = receta.esSpoonacular && receta.id == 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => enVivo
              ? RecetaDetailScreen(externoId: receta.externoId, intolerancias: filtro)
              : RecetaDetailScreen(recetaId: receta.id),
        )),
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
                  TextoT(receta.titulo,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (receta.tiempoPreparacionMinutos != null) '${receta.tiempoPreparacionMinutos} min',
                      if (receta.dificultad != null) context.tc(receta.dificultad!),
                    ].join(' • '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (receta.libreDe.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Chip1(tr('Sin {0}{1}', [etiquetaIntolerancia(receta.libreDe.first), receta.libreDe.length > 1 ? ' +${receta.libreDe.length - 1}' : ''])),
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

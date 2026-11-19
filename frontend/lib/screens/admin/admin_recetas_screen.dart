import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/intolerancia.dart';
import '../../core/models/receta.dart';
import '../../core/services/receta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../../core/widgets/receta_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import '../usuario/enviar_receta_screen.dart';
import '../usuario/receta_detail_screen.dart';
import '../../core/i18n/i18n.dart';

/// Gestión de recetas: aprobar las que envían los usuarios, administrar las
/// publicadas e importar recetas de Spoonacular.
class AdminRecetasScreen extends StatefulWidget {
  const AdminRecetasScreen({super.key});
  @override
  State<AdminRecetasScreen> createState() => _AdminRecetasScreenState();
}

class _AdminRecetasScreenState extends State<AdminRecetasScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)..addListener(() => setState(() {}));
  final _publicadasKey = GlobalKey<_PublicadasTabState>();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _nueva() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const EnviarRecetaScreen(modoAdmin: true)));
    if (ok == true && mounted) {
      mostrarMensaje(context, tr('Receta publicada'));
      _publicadasKey.currentState?.recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Gestión de Recetas')),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.lime,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: [Tab(text: tr('Por aprobar')), Tab(text: tr('Publicadas')), Tab(text: tr('Spoonacular'))],
        ),
      ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton.extended(onPressed: _nueva, icon: const Icon(Icons.add), label: Text(tr('Nueva')))
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [
          const _PorAprobarTab(),
          _PublicadasTab(key: _publicadasKey),
          const _SpoonacularTab(),
        ],
      ),
    );
  }
}

// =====================================================================
// Por aprobar (recetas enviadas por usuarios)
// =====================================================================

class _PorAprobarTab extends StatefulWidget {
  const _PorAprobarTab();
  @override
  State<_PorAprobarTab> createState() => _PorAprobarTabState();
}

class _PorAprobarTabState extends State<_PorAprobarTab> with AutomaticKeepAliveClientMixin {
  String _estado = 'PENDIENTE';
  late Future<List<Receta>> _future = _cargar();

  Future<List<Receta>> _cargar() => context.read<RecetaService>().listarPorEstado(_estado);
  void _recargar() => setState(() => _future = _cargar());

  @override
  bool get wantKeepAlive => true;

  Future<void> _revisar(Receta r) async {
    final cambio = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _RevisionRecetaScreen(receta: r)));
    if (cambio == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Wrap(spacing: 8, children: [
          for (final (valor, texto) in [('PENDIENTE', tr('Pendientes')), ('RECHAZADA', tr('Rechazadas'))])
            ChoiceChip(
              label: Text(texto),
              selected: _estado == valor,
              onSelected: (_) {
                _estado = valor;
                _recargar();
              },
            ),
        ]),
      ),
      Expanded(
        child: FutureBuilder<List<Receta>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snap.hasError) return ErrorView(mensaje: snap.error.toString(), onReintentar: _recargar);
            final lista = snap.data ?? [];
            if (lista.isEmpty) {
              return EmptyView(
                  mensaje: _estado == 'PENDIENTE' ? tr('No hay recetas esperando aprobación') : tr('No hay recetas rechazadas'));
            }
            return RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lista.length,
                itemBuilder: (context, i) {
                  final r = lista[i];
                  return Card(
                    child: InkWell(
                      onTap: () => _revisar(r),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: ImagenFlexible(
                                fuente: r.imagenUrl,
                                sinImagen: Container(color: AppColors.primarySoft, child: const Icon(Icons.restaurant_menu)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              TextoT(r.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                tr('Por {0}{1}', [r.autorNombre ?? '-', r.fecha != null ? ' · ${DateFormat('dd/MM/yyyy').format(r.fecha!)}' : '']),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              if (r.conflictos.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    tr('⚠ Dice "sin {0}" pero los ingredientes lo mencionan', [r.conflictos.map(etiquetaIntolerancia).join(', ')]),
                                    style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              if (r.rechazada && r.motivoRechazo != null)
                                Text(tr('Motivo: {0}', [context.tc(r.motivoRechazo)]), style: const TextStyle(fontSize: 12)),
                            ]),
                          ),
                          const Icon(Icons.chevron_right),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// Detalle completo de una receta enviada, con aprobar / rechazar / editar.
class _RevisionRecetaScreen extends StatefulWidget {
  final Receta receta;
  const _RevisionRecetaScreen({required this.receta});
  @override
  State<_RevisionRecetaScreen> createState() => _RevisionRecetaScreenState();
}

class _RevisionRecetaScreenState extends State<_RevisionRecetaScreen> {
  late Receta _receta = widget.receta;
  bool _trabajando = false;

  Future<void> _moderar(bool aprobar) async {
    String? motivo;
    if (!aprobar) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Rechazar receta')),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: tr('Motivo (lo verá quien la envió)'),
              hintText: tr('Ej: la harina que usa no está certificada sin gluten'),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar'))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Rechazar')),
            ),
          ],
        ),
      );
      if (ok != true) return;
      motivo = ctrl.text.trim();
    }
    setState(() => _trabajando = true);
    try {
      await context.read<RecetaService>().moderar(_receta.id, aprobar: aprobar, motivo: motivo);
      if (!mounted) return;
      mostrarMensaje(context, aprobar ? tr('Receta publicada') : tr('Receta rechazada'));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _trabajando = false);
        mostrarError(context, e);
      }
    }
  }

  Future<void> _editar() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => EnviarRecetaScreen(existente: _receta, modoAdmin: true)));
    if (ok == true && mounted) {
      final r = await context.read<RecetaService>().obtener(_receta.id);
      if (mounted) setState(() => _receta = r);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Revisar receta')),
        actions: [IconButton(tooltip: tr('Corregir antes de aprobar'), onPressed: _editar, icon: const Icon(Icons.edit_outlined))],
      ),
      body: ContenidoReceta(
        receta: _receta,
        pie: [
          if (_receta.conflictos.isNotEmpty)
            AvisoReceta(
              icono: Icons.report_problem_outlined,
              titulo: tr('Revisá lo declarado'),
              texto: tr('La receta dice ser libre de {0}, pero SafeBite lo encontró en los ingredientes. Corregila o rechazala.', [_receta.conflictos.map(etiquetaIntolerancia).join(', ')]),
              color: AppColors.danger,
            ),
          if (_receta.detectados.isNotEmpty)
            AvisoReceta(
              icono: Icons.search,
              titulo: tr('Detectado en los ingredientes'),
              texto: _receta.detectados.map(etiquetaIntolerancia).join(', '),
              color: const Color(0xFF546E7A),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _trabajando || _receta.rechazada ? null : () => _moderar(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(tr('Rechazar')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _trabajando ? null : () => _moderar(true),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(tr('Aprobar y publicar')),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// =====================================================================
// Publicadas
// =====================================================================

class _PublicadasTab extends StatefulWidget {
  const _PublicadasTab({super.key});
  @override
  State<_PublicadasTab> createState() => _PublicadasTabState();
}

class _PublicadasTabState extends State<_PublicadasTab> with AutomaticKeepAliveClientMixin {
  Set<String> _filtro = {};
  late Future<List<Receta>> _future = _cargar();

  Future<List<Receta>> _cargar() => context.read<RecetaService>().listar(intolerancias: _filtro);
  void recargar() => setState(() => _future = _cargar());

  @override
  bool get wantKeepAlive => true;

  Future<void> _editar(Receta r) async {
    if (r.esSpoonacular) {
      await _editarSpoonacular(r);
      return;
    }
    try {
      final completa = await context.read<RecetaService>().obtener(r.id);
      if (!mounted) return;
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => EnviarRecetaScreen(existente: completa, modoAdmin: true)));
      if (ok == true && mounted) {
        mostrarMensaje(context, tr('Receta guardada'));
        recargar();
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  /// De Spoonacular solo se editan el título en español y "libre de".
  Future<void> _editarSpoonacular(Receta r) async {
    final titulo = TextEditingController(text: r.titulo);
    var libreDe = {...r.libreDe};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(tr('Editar receta de Spoonacular'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: titulo, decoration: InputDecoration(labelText: tr('Título en español'))),
              const SizedBox(height: 12),
              Text(tr('Libre de:'), style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SelectorIntolerancias(seleccionadas: libreDe, prefijo: tr('Sin '), onChanged: (s) => setModal(() => libreDe = s)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Guardar'))),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await context.read<RecetaService>().editar(r.id, {'titulo': titulo.text.trim(), 'libreDe': libreDe.toList()});
      if (mounted) recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _eliminar(Receta r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Eliminar receta')),
        content: Text(tr('¿Eliminar "{0}"? No se puede deshacer.', [r.titulo])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Eliminar')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<RecetaService>().eliminar(r.id);
      recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      const SizedBox(height: 8),
      BarraFiltroIntolerancias(
        seleccion: _filtro,
        prefijo: tr('Sin '),
        titulo: tr('Recetas libres de...'),
        ayuda: tr('Muestra las recetas aptas para TODAS las marcadas.'),
        onChanged: (s) {
          _filtro = s;
          recargar();
        },
      ),
      Expanded(
        child: FutureBuilder<List<Receta>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: recargar);
            final recetas = snapshot.data ?? [];
            if (recetas.isEmpty) return EmptyView(mensaje: tr('No hay recetas ni tips publicados'));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: recetas.length,
              itemBuilder: (context, i) {
                final r = recetas[i];
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => RecetaDetailScreen(recetaId: r.id))),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: ImagenFlexible(
                          fuente: r.imagenUrl,
                          sinImagen: Container(color: AppColors.primarySoft, child: const Icon(Icons.restaurant_menu)),
                        ),
                      ),
                    ),
                    title: TextoT(r.titulo),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        if (r.esTip)
                          Text(tr('Tip de Salud'), style: TextStyle(fontSize: 12))
                        else
                          EtiquetaOrigenReceta(receta: r, compacta: true),
                      ]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editar(r)),
                        IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _eliminar(r)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

// =====================================================================
// Importar de Spoonacular
// =====================================================================

class _SpoonacularTab extends StatefulWidget {
  const _SpoonacularTab();
  @override
  State<_SpoonacularTab> createState() => _SpoonacularTabState();
}

class _SpoonacularTabState extends State<_SpoonacularTab> with AutomaticKeepAliveClientMixin {
  final _consulta = TextEditingController();
  Set<String> _intolerancias = {};
  final List<RecetaExterna> _resultados = [];
  BusquedaExterna? _ultima;
  int _pagina = 0;
  bool _buscando = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _consulta.dispose();
    super.dispose();
  }

  Future<void> _buscar({bool mas = false}) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _error = null;
      if (!mas) {
        _resultados.clear();
        _pagina = 0;
      }
    });
    try {
      final r = await context.read<RecetaService>().buscarExternas(
            consulta: _consulta.text.trim(),
            intolerancias: _intolerancias,
            pagina: mas ? _pagina + 1 : 0,
          );
      if (!mounted) return;
      setState(() {
        if (mas) _pagina++;
        _ultima = r;
        _resultados.addAll(r.resultados);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _abrir(RecetaExterna e) async {
    final publicada = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => _VistaPreviaExternaScreen(externa: e, intolerancias: _intolerancias),
    ));
    if (publicada == true && mounted) {
      setState(() {
        final i = _resultados.indexWhere((x) => x.externoId == e.externoId);
        if (i >= 0) {
          _resultados[i] = RecetaExterna(
              externoId: e.externoId, titulo: e.titulo, tituloOriginal: e.tituloOriginal, imagenUrl: e.imagenUrl, yaImportada: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ultima = _ultima;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          tr('Buscá recetas en Spoonacular filtradas por intolerancia. Revisá cada una y publicá solo las que estén bien. Ingredientes y pasos se cargan en vivo y se traducen al abrir la receta.'),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _consulta,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _buscar(),
          decoration: InputDecoration(
            labelText: tr('¿Qué receta buscás? (opcional)'),
            hintText: tr('Ej: pan, torta de chocolate, pollo'),
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Text(tr('Libres de:'), style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SelectorIntolerancias(
          seleccionadas: _intolerancias,
          prefijo: tr('Sin '),
          onChanged: (s) => setState(() => _intolerancias = s),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _buscando ? null : () => _buscar(),
          icon: const Icon(Icons.travel_explore),
          label: Text(tr('Buscar en Spoonacular')),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        if (ultima?.cuotaRestante != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(tr('Cuota diaria restante: {0} puntos', [ultima!.cuotaRestante!.toStringAsFixed(1)]),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        if (ultima != null && ultima.sinFiltroEnFuente.isNotEmpty)
          AvisoReceta(
            icono: Icons.info_outline,
            titulo: tr('Spoonacular no filtra: {0}', [ultima.sinFiltroEnFuente.map(context.tc).join(', ')]),
            texto: tr('Para esas, el único control es el analizador de SafeBite: revisá bien los ingredientes.'),
            color: const Color(0xFFB26A00),
          ),
        if (_error != null) AvisoReceta(icono: Icons.error_outline, titulo: tr('No se pudo buscar'), texto: _error, color: AppColors.danger),
        const SizedBox(height: 12),
        if (_buscando && _resultados.isEmpty) const Padding(padding: EdgeInsets.all(24), child: LoadingView()),
        if (!_buscando && ultima != null && _resultados.isEmpty)
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(tr('Sin resultados. Probá con otra búsqueda o menos filtros.'), textAlign: TextAlign.center),
          ),
        ..._resultados.map((e) => Card(
              child: ListTile(
                onTap: () => _abrir(e),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 48,
                    child: ImagenFlexible(fuente: e.imagenUrl, sinImagen: Container(color: AppColors.primarySoft)),
                  ),
                ),
                title: TextoT(e.titulo, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(e.tituloOriginal, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                trailing: e.yaImportada
                    ? Chip1(tr('Publicada'), color: AppColors.primary)
                    : const Icon(Icons.chevron_right),
              ),
            )),
        if (_resultados.isNotEmpty && (ultima?.resultados.length ?? 0) >= 10)
          TextButton.icon(
            onPressed: _buscando ? null : () => _buscar(mas: true),
            icon: _buscando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.expand_more),
            label: Text(tr('Cargar más')),
          ),
      ],
    );
  }
}

class _VistaPreviaExternaScreen extends StatefulWidget {
  final RecetaExterna externa;
  final Set<String> intolerancias;
  const _VistaPreviaExternaScreen({required this.externa, required this.intolerancias});
  @override
  State<_VistaPreviaExternaScreen> createState() => _VistaPreviaExternaScreenState();
}

class _VistaPreviaExternaScreenState extends State<_VistaPreviaExternaScreen> {
  Receta? _receta;
  String? _error;
  late final _titulo = TextEditingController(text: widget.externa.titulo);
  Set<String> _libreDe = {};
  bool _publicando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final r = await context.read<RecetaService>().vistaPreviaExterna(widget.externa.externoId, widget.intolerancias);
      if (!mounted) return;
      setState(() {
        _receta = r;
        _libreDe = {...r.libreDe};
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _publicar() async {
    if (_titulo.text.trim().isEmpty) {
      mostrarMensaje(context, tr('Escribí el título en español'));
      return;
    }
    setState(() => _publicando = true);
    try {
      await context
          .read<RecetaService>()
          .importarExterna(widget.externa.externoId, titulo: _titulo.text.trim(), libreDe: _libreDe);
      if (!mounted) return;
      mostrarMensaje(context, tr('Receta publicada en SafeBite'));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _publicando = false);
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _receta;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Vista previa'))),
      body: _error != null
          ? ErrorView(mensaje: _error!, onReintentar: _cargar)
          : r == null
              ? const LoadingView()
              : ContenidoReceta(
                  receta: r,
                  pie: [
                    const SizedBox(height: 16),
                    const Divider(),
                    SeccionTitulo(tr('Publicar en SafeBite')),
                    if (r.detectados.isNotEmpty)
                      AvisoReceta(
                        icono: Icons.search,
                        titulo: tr('SafeBite detectó en los ingredientes'),
                        texto: tr('{0}. No se marcan como "libre de".', [r.detectados.map(etiquetaIntolerancia).join(', ')]),
                        color: AppColors.danger,
                      ),
                    const SizedBox(height: 10),
                    TextField(controller: _titulo, decoration: InputDecoration(labelText: tr('Título en español *'))),
                    const SizedBox(height: 12),
                    Text(tr('Libre de (revisá y ajustá):'), style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    SelectorIntolerancias(
                      seleccionadas: _libreDe,
                      prefijo: tr('Sin '),
                      onChanged: (s) => setState(() => _libreDe = s),
                    ),
                    if (_libreDe.intersection(r.detectados).isNotEmpty)
                      AvisoReceta(
                        icono: Icons.warning_amber_rounded,
                        titulo: tr('Contradicción'),
                        texto: tr('Marcaste "sin {0}" pero aparece en los ingredientes.', [_libreDe.intersection(r.detectados).map(etiquetaIntolerancia).join(', ')]),
                        color: AppColors.danger,
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _publicando || widget.externa.yaImportada ? null : _publicar,
                      icon: const Icon(Icons.publish_rounded),
                      label: Text(widget.externa.yaImportada ? tr('Ya está publicada') : tr('Aprobar y publicar')),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                  ],
                ),
    );
  }
}

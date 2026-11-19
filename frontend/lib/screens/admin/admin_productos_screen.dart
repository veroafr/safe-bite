import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/producto.dart';
import '../../core/models/usuario.dart';
import '../../core/services/producto_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../../core/i18n/i18n.dart';

class AdminProductosScreen extends StatefulWidget {
  const AdminProductosScreen({super.key});
  @override
  State<AdminProductosScreen> createState() => _AdminProductosScreenState();
}

class _AdminProductosScreenState extends State<AdminProductosScreen> {
  late Future<List<Producto>> _futurePendientes;
  late Future<List<Producto>> _futureTodos;

  /// Filtro del catalogo: oculta los productos que contienen alguna de estas.
  Set<String> _filtroSin = {};

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _futurePendientes = context.read<ProductoService>().listarPendientes();
      _futureTodos = context.read<ProductoService>().listarTodos();
    });
  }

  Future<void> _aprobar(Producto p) async {
    try {
      await context.read<ProductoService>().aprobar(p);
      if (mounted) {
        mostrarMensaje(context, tr('Producto aprobado y visible para todos'));
        _recargar();
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _descartar(Producto p) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Descartar producto')),
        content: Text(tr('¿Eliminar "{0}"? Esta acción no se puede deshacer.', [p.nombre])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Eliminar'))),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      await context.read<ProductoService>().eliminar(p.id);
      if (mounted) {
        mostrarMensaje(context, tr('Producto descartado'));
        _recargar();
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _abrirFormulario({Producto? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final marcaCtrl = TextEditingController(text: existente?.marca ?? '');
    final categoriaCtrl = TextEditingController(text: existente?.categoria ?? '');
    final codigoCtrl = TextEditingController(text: existente?.codigoEan ?? '');
    final ingredientesCtrl = TextEditingController(text: existente?.ingredientes.join(', ') ?? '');
    var alergenosSeleccionados = <String>{...?existente?.alergenos};

    String? fotoFrontal = existente?.fotoFrontalBase64;
    String? fotoComposicion = existente?.fotoComposicionBase64;
    String? fotoNutricional = existente?.fotoNutricionalBase64;

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existente == null ? tr('Cargar producto') : tr('Editar producto'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: tr('Nombre'))),
                const SizedBox(height: 10),
                TextField(controller: marcaCtrl, decoration: InputDecoration(labelText: tr('Marca'))),
                const SizedBox(height: 10),
                TextField(controller: codigoCtrl, decoration: InputDecoration(labelText: tr('Código de barras (EAN)'))),
                const SizedBox(height: 16),
                Text(tr('Fotos del envase'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(tr('Con la cámara o desde la galería, no hace falta buscar una URL.'),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                SelectorFoto(
                  titulo: tr('1. Frente del producto'),
                  ayuda: tr('Que se vea el nombre y la marca'),
                  base64Inicial: fotoFrontal,
                  onCambio: (b64) => fotoFrontal = b64,
                ),
                SelectorFoto(
                  titulo: tr('2. Tabla de composición / ingredientes'),
                  ayuda: tr('La lista de ingredientes del envase'),
                  base64Inicial: fotoComposicion,
                  onCambio: (b64) => fotoComposicion = b64,
                ),
                SelectorFoto(
                  titulo: tr('3. Tabla nutricional'),
                  ayuda: tr('Los valores nutricionales por porción'),
                  base64Inicial: fotoNutricional,
                  onCambio: (b64) => fotoNutricional = b64,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (fotoFrontal == null && fotoComposicion == null && fotoNutricional == null) {
                        mostrarMensaje(context, tr('Agregá al menos una foto para poder analizarla'));
                        return;
                      }
                      try {
                        final analisis = await context.read<ProductoService>().analizarFotos(
                              fotoFrontalBase64: fotoFrontal,
                              fotoComposicionBase64: fotoComposicion,
                              fotoNutricionalBase64: fotoNutricional,
                            );
                        if (!analisis.pudoLeer) {
                          if (ctx.mounted) mostrarMensaje(ctx, analisis.observacion ?? tr('No se pudo leer la foto'));
                          return;
                        }
                        setModalState(() {
                          if (analisis.nombreSugerido != null && nombreCtrl.text.trim().isEmpty) {
                            nombreCtrl.text = analisis.nombreSugerido!;
                          }
                          if (analisis.marcaSugerida != null && marcaCtrl.text.trim().isEmpty) {
                            marcaCtrl.text = analisis.marcaSugerida!;
                          }
                          if (analisis.categoriaSugerida != null && categoriaCtrl.text.trim().isEmpty) {
                            categoriaCtrl.text = analisis.categoriaSugerida!;
                          }
                          if (analisis.ingredientes.isNotEmpty && ingredientesCtrl.text.trim().isEmpty) {
                            ingredientesCtrl.text = analisis.ingredientes.join(', ');
                          }
                          alergenosSeleccionados.addAll(analisis.alergenos);
                        });
                      } catch (e) {
                        if (ctx.mounted) mostrarError(ctx, e);
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(tr('Analizar con IA y completar automáticamente')),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoriaCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Categoría'),
                    hintText: tr('Ej: Panificados, Lácteos, Snacks, Bebidas'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ingredientesCtrl,
                  decoration: InputDecoration(labelText: tr('Ingredientes (separados por coma)')),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Text(tr('Alérgenos que contiene'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SelectorIntolerancias(
                  seleccionadas: alergenosSeleccionados,
                  color: AppColors.danger,
                  onChanged: (s) => setModalState(() => alergenosSeleccionados = s),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: Text(tr('Guardar')),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (guardar == true) {
      final body = {
        'nombre': nombreCtrl.text.trim(),
        'marca': marcaCtrl.text.trim().isEmpty ? null : marcaCtrl.text.trim(),
        'categoria': categoriaCtrl.text.trim().isEmpty ? null : categoriaCtrl.text.trim(),
        'codigoEan': codigoCtrl.text.trim().isEmpty ? null : codigoCtrl.text.trim(),
        'ingredientes': ingredientesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'alergenos': alergenosSeleccionados.toList(),
        'verificado': true,
        'fotoFrontalBase64': fotoFrontal,
        'fotoComposicionBase64': fotoComposicion,
        'fotoNutricionalBase64': fotoNutricional,
      };
      try {
        final service = context.read<ProductoService>();
        if (existente == null) {
          await service.crear(body);
        } else {
          await service.editar(existente.id, body);
        }
        if (mounted) {
          mostrarMensaje(context, tr('Producto guardado'));
          _recargar();
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Widget _miniatura(Producto p) {
    if (p.fotoFrontalBase64 != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            Uint8List.fromList(base64Decode(p.fotoFrontalBase64!)),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        // sigue al placeholder
      }
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('Gestión de Productos')),
          bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: AppColors.lime,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              tabs: [
            Tab(text: tr('Pendientes de revisión')),
            Tab(text: tr('Catálogo completo')),
          ]),
        ),
        floatingActionButton: FloatingActionButton(onPressed: () => _abrirFormulario(), child: const Icon(Icons.add)),
        body: TabBarView(
          children: [
            FutureBuilder<List<Producto>>(
              future: _futurePendientes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
                final pendientes = snapshot.data ?? [];
                if (pendientes.isEmpty) {
                  return EmptyView(mensaje: tr('No hay productos pendientes de revisión'), icono: Icons.check_circle_outline);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendientes.length,
                  itemBuilder: (context, i) {
                    final p = pendientes[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _miniatura(p),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextoT(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (p.marca != null) Text(p.marca!, style: const TextStyle(color: AppColors.textSecondary)),
                                      if (p.codigoEan != null)
                                        Text(tr('Código: {0}', [p.codigoEan]), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      if (p.aportadoPorEmail != null)
                                        Text(tr('Aportado por: {0}', [p.aportadoPorEmail]), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (p.ingredientes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(tr('Ingredientes: {0}', [context.tc(p.ingredientes.join(', '))]), style: const TextStyle(fontSize: 12)),
                            ],
                            if (p.alergenos.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: p.alergenos.map((a) => Chip1(etiquetaIntolerancia(a), color: AppColors.danger)).toList(),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _RevisionFotos(producto: p, onCambio: _recargar),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _abrirFormulario(existente: p),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: Text(tr('Editar datos')),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _descartar(p),
                                    icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                                    label: Text(tr('Descartar'), style: TextStyle(color: AppColors.danger)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _aprobar(p),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: Text(tr('Aprobar')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Column(
              children: [
                const SizedBox(height: 8),
                BarraFiltroIntolerancias(
                  seleccion: _filtroSin,
                  prefijo: tr('Sin '),
                  titulo: tr('Productos sin...'),
                  ayuda: tr('Oculta los productos que contienen ALGUNA de las marcadas.'),
                  onChanged: (s) => setState(() => _filtroSin = s),
                ),
                Expanded(
                  child: FutureBuilder<List<Producto>>(
              future: _futureTodos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
                final productos = (snapshot.data ?? [])
                    .where((p) => _filtroSin.isEmpty || p.alergenos.intersection(_filtroSin).isEmpty)
                    .toList();
                if (productos.isEmpty) {
                  return EmptyView(
                      mensaje: _filtroSin.isEmpty ? tr('No hay productos cargados') : tr('Ningún producto cumple el filtro'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productos.length,
                  itemBuilder: (context, i) {
                    final p = productos[i];
                    return Card(
                      child: ListTile(
                        leading: _miniatura(p),
                        title: TextoT(p.nombre),
                        subtitle: Text([
                          if (p.marca != null) p.marca!,
                          if (p.codigoEan != null) tr('Código: {0}', [p.codigoEan]),
                          p.verificado ? tr('Verificado') : tr('Sin verificar'),
                          if (p.alergenos.isNotEmpty) tr('Contiene: {0}', [p.alergenos.map(etiquetaIntolerancia).join(', ')]),
                        ].join(' · ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirFormulario(existente: p)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _descartar(p)),
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
          ],
        ),
      ),
    );
  }
}

/// Sección de revisión de fotos dentro de la tarjeta de un producto
/// pendiente: muestra cada una de las 3 fotos en tamaño grande (o un
/// placeholder si falta) y deja que el admin, foto por foto, la
/// **elimine** (si está fea/mal sacada) o la **reemplace** por una propia,
/// sin tener que abrir el formulario completo ni tocar el resto de los
/// datos del producto.
class _RevisionFotos extends StatefulWidget {
  final Producto producto;
  final VoidCallback onCambio;
  const _RevisionFotos({required this.producto, required this.onCambio});

  @override
  State<_RevisionFotos> createState() => _RevisionFotosState();
}

class _RevisionFotosState extends State<_RevisionFotos> {
  bool _procesando = false;

  Future<void> _reemplazar(String tipo) async {
    final bytes = await elegirFotoCamaraOGaleria(context);
    if (bytes == null) return;
    await _guardar(tipo, base64Encode(bytes));
  }

  Future<void> _eliminar(String tipo) async {
    await _guardar(tipo, null);
  }

  Future<void> _guardar(String tipo, String? base64) async {
    setState(() => _procesando = true);
    try {
      await context.read<ProductoService>().actualizarFoto(widget.producto.id, tipo, base64);
      if (mounted) {
        mostrarMensaje(context, base64 == null ? tr('Foto eliminada') : tr('Foto actualizada'));
        widget.onCambio();
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Widget _slot(String titulo, String tipo, String? base64) {
    Widget imagen;
    if (base64 != null) {
      try {
        imagen = Image.memory(Uint8List.fromList(base64Decode(base64)), height: 90, width: double.infinity, fit: BoxFit.cover);
      } catch (_) {
        imagen = Container(
          height: 90,
          color: AppColors.danger.withOpacity(0.08),
          child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.danger)),
        );
      }
    } else {
      imagen = Container(
        height: 90,
        color: AppColors.textSecondary.withOpacity(0.08),
        child: Center(child: Text(tr('Sin foto'), style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: imagen),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 18,
                tooltip: tr('Reemplazar'),
                onPressed: _procesando ? null : () => _reemplazar(tipo),
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              ),
              if (base64 != null)
                IconButton(
                  iconSize: 18,
                  tooltip: tr('Eliminar'),
                  onPressed: _procesando ? null : () => _eliminar(tipo),
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Fotos enviadas — aceptalas, reemplazalas o eliminalas'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _slot(tr('Frente'), 'frontal', p.fotoFrontalBase64),
            const SizedBox(width: 8),
            _slot(tr('Composición'), 'composicion', p.fotoComposicionBase64),
            const SizedBox(width: 8),
            _slot(tr('Nutricional'), 'nutricional', p.fotoNutricionalBase64),
          ],
        ),
      ],
    );
  }
}

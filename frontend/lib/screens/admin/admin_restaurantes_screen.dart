import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurante.dart';
import '../../core/models/usuario.dart';
import '../../core/services/restaurante_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import '../../core/i18n/i18n.dart';

class AdminRestaurantesScreen extends StatefulWidget {
  const AdminRestaurantesScreen({super.key});
  @override
  State<AdminRestaurantesScreen> createState() => _AdminRestaurantesScreenState();
}

class _AdminRestaurantesScreenState extends State<AdminRestaurantesScreen> {
  late Future<List<Restaurante>> _future;
  Set<String> _filtro = {};

  @override
  void initState() {
    super.initState();
    _future = context.read<RestauranteService>().buscar();
  }

  void _recargar() {
    setState(() {
      _future = context.read<RestauranteService>().buscar(intolerancias: _filtro);
    });
  }

  Future<void> _abrirFormulario({Restaurante? existente}) async {
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: existente?.descripcion ?? '');
    final direccionCtrl = TextEditingController(text: existente?.direccion ?? '');
    final latCtrl = TextEditingController(text: existente?.latitud?.toString() ?? '');
    final lngCtrl = TextEditingController(text: existente?.longitud?.toString() ?? '');
    // Fotos: la miniatura cuadrada (lista) y el banner 2:1 (ficha).
    // El banner no viene en la lista: se pide la ficha completa para mostrarlo.
    String? miniaturaActual = existente?.imagenMiniatura ?? existente?.imagenUrl;
    String? bannerActual;
    if (existente != null) {
      try {
        bannerActual = (await context.read<RestauranteService>().obtener(existente.id)).imagenBanner;
      } catch (_) {}
      if (!mounted) return;
    }
    Uint8List? miniaturaNueva;
    Uint8List? bannerNueva;
    bool quitarMiniatura = false;
    bool quitarBanner = false;
    final tiposCocinaCtrl = TextEditingController(text: existente?.tiposCocina.join(', ') ?? '');
    Set<String> opciones = {...(existente?.opcionesAptasPara ?? <String>{})};

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
                Text(existente == null ? tr('Agregar restaurante') : tr('Editar restaurante'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: tr('Nombre'))),
                const SizedBox(height: 10),
                TextField(controller: descripcionCtrl, decoration: InputDecoration(labelText: tr('Descripción')), maxLines: 2),
                const SizedBox(height: 10),
                TextField(controller: direccionCtrl, decoration: InputDecoration(labelText: tr('Dirección'))),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: tr('Latitud')), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: lngCtrl, decoration: InputDecoration(labelText: tr('Longitud')), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true))),
                ]),
                const SizedBox(height: 10),
                Text(tr('Fotos'), style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SelectorFotoRestaurante(
                      titulo: tr('Miniatura'),
                      ayuda: tr('Cuadrada, para la lista'),
                      proporcion: 1,
                      anchoVista: 104,
                      anchoSalida: 600,
                      nueva: miniaturaNueva,
                      actual: quitarMiniatura ? null : miniaturaActual,
                      onElegida: (b) => setModalState(() {
                        miniaturaNueva = b;
                        quitarMiniatura = false;
                      }),
                      onQuitar: () => setModalState(() {
                        miniaturaNueva = null;
                        quitarMiniatura = true;
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SelectorFotoRestaurante(
                        titulo: tr('Banner'),
                        ayuda: tr('Rectangular (2:1), para la ficha'),
                        proporcion: 2,
                        anchoVista: null,
                        anchoSalida: 1200,
                        nueva: bannerNueva,
                        actual: quitarBanner ? null : bannerActual,
                        onElegida: (b) => setModalState(() {
                          bannerNueva = b;
                          quitarBanner = false;
                        }),
                        onQuitar: () => setModalState(() {
                          bannerNueva = null;
                          quitarBanner = true;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: tiposCocinaCtrl, decoration: InputDecoration(labelText: tr('Tipos de cocina (separados por coma)'))),
                const SizedBox(height: 10),
                Text(tr('Tiene opciones aptas para quienes evitan:'), style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SelectorIntolerancias(
                  seleccionadas: opciones,
                  prefijo: tr('Sin '),
                  onChanged: (s) => setModalState(() => opciones = s),
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
        'descripcion': descripcionCtrl.text.trim(),
        'direccion': direccionCtrl.text.trim(),
        'latitud': double.tryParse(latCtrl.text.trim()),
        'longitud': double.tryParse(lngCtrl.text.trim()),
        // null = no cambia; '' = se quita; base64 = foto nueva (el servidor la ajusta).
        if (miniaturaNueva != null) 'imagenMiniatura': base64Encode(miniaturaNueva!)
        else if (quitarMiniatura) 'imagenMiniatura': '',
        if (bannerNueva != null) 'imagenBanner': base64Encode(bannerNueva!)
        else if (quitarBanner) 'imagenBanner': '',
        if (quitarMiniatura) 'imagenUrl': null else 'imagenUrl': existente?.imagenUrl,
        'tiposCocina': tiposCocinaCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'opcionesAptasPara': opciones.toList(),
      };
      try {
        final service = context.read<RestauranteService>();
        if (existente == null) {
          await service.crear(body);
        } else {
          await service.editar(existente.id, body);
        }
        if (mounted) {
          mostrarMensaje(context, tr('Restaurante guardado'));
          _recargar();
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _eliminar(Restaurante r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Eliminar restaurante')),
        content: Text(tr('¿Seguro que querés eliminar "{0}"?', [r.nombre])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar'))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Eliminar'))),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await context.read<RestauranteService>().eliminar(r.id);
        _recargar();
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Gestión de Restaurantes'))),
      floatingActionButton: FloatingActionButton(onPressed: () => _abrirFormulario(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          const SizedBox(height: 8),
          BarraFiltroIntolerancias(
            seleccion: _filtro,
            prefijo: tr('Sin '),
            titulo: tr('Locales aptos para...'),
            ayuda: tr('Muestra los locales con opciones aptas para TODAS las marcadas.'),
            onChanged: (s) {
              _filtro = s;
              _recargar();
            },
          ),
          Expanded(
            child: FutureBuilder<List<Restaurante>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
                final restaurantes = snapshot.data ?? [];
                if (restaurantes.isEmpty) return EmptyView(mensaje: tr('No hay restaurantes cargados'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: restaurantes.length,
                  itemBuilder: (context, i) {
                    final r = restaurantes[i];
                    return Card(
                      child: ListTile(
                        title: Text(r.nombre),
                        subtitle: Text(r.direccion ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirFormulario(existente: r)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _eliminar(r)),
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
    );
  }
}

/// Elige una foto (cámara o galería), la encuadra en la proporción pedida y
/// muestra la vista previa con ese mismo encuadre.
class _SelectorFotoRestaurante extends StatelessWidget {
  final String titulo;
  final String ayuda;
  final double proporcion;
  /// Ancho fijo de la vista previa (null = todo el ancho disponible).
  final double? anchoVista;
  final int anchoSalida;
  final Uint8List? nueva;
  final String? actual;
  final ValueChanged<Uint8List> onElegida;
  final VoidCallback onQuitar;

  const _SelectorFotoRestaurante({
    required this.titulo,
    required this.ayuda,
    required this.proporcion,
    required this.anchoVista,
    required this.anchoSalida,
    required this.nueva,
    required this.actual,
    required this.onElegida,
    required this.onQuitar,
  });

  Future<void> _elegir(BuildContext context) async {
    final bytes = await elegirFotoCamaraOGaleria(context);
    if (bytes == null || !context.mounted) return;
    final recortada = await recortarImagen(
      context,
      bytes: Uint8List.fromList(bytes),
      proporcion: proporcion,
      anchoSalida: anchoSalida,
      titulo: tr('Encuadrar {0}', [titulo.toLowerCase()]),
    );
    if (recortada != null) onElegida(recortada);
  }

  @override
  Widget build(BuildContext context) {
    final hayFoto = nueva != null || (actual != null && actual!.isNotEmpty);
    final vacio = Container(
      color: AppColors.primarySoft,
      child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
    );
    final vista = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: proporcion,
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => _elegir(context),
            child: nueva != null
                ? Image.memory(nueva!, fit: BoxFit.cover)
                : ImagenFlexible(fuente: actual, sinImagen: vacio),
          ),
        ),
      ),
    );
    return SizedBox(
      width: anchoVista,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vista,
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(ayuda, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                onPressed: () => _elegir(context),
                child: Text(hayFoto ? tr('Cambiar') : tr('Elegir')),
              ),
              if (hayFoto)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 8),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: onQuitar,
                  child: Text(tr('Quitar')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

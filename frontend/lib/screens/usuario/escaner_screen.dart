import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/models/producto.dart';
import '../../core/models/usuario.dart';
import '../../core/models/alerta.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/filtro_escaner_provider.dart';
import '../../core/services/producto_service.dart';
import '../../core/services/alerta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/marca_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import 'cargar_producto_screen.dart';
import '../../core/web/lector_codigo_foto.dart';
import '../../core/i18n/i18n.dart';
import '../../core/widgets/imagen_producto.dart';

class EscanerScreen extends StatelessWidget {
  const EscanerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _LectorEanTab(),
    );
  }
}

class _DesgloseIntolerancias extends StatelessWidget {
  final Set<String> alergenosProducto;
  const _DesgloseIntolerancias({required this.alergenosProducto});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final filtro = context.watch<FiltroEscanerProvider>();
    final intolerancias = filtro.efectivas(usuario);
    if (intolerancias.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(filtro.personalizado ? tr('Intolerancias elegidas en el filtro:') : tr('Tus intolerancias en este producto:'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        ...intolerancias.map((t) {
          final esSeguro = !alergenosProducto.contains(t);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  esSeguro ? Icons.check_circle : Icons.cancel,
                  color: esSeguro ? AppColors.primary : AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${etiquetaIntolerancia(t)}: ${esSeguro ? tr('es seguro') : tr('no es seguro')}',
                  style: TextStyle(
                    color: esSeguro ? AppColors.primary : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Muestra la foto principal del producto, con reglas distintas segun el
/// origen del dato:
/// - Open Food Facts: solo se muestra si el producto tiene datos completos
///   (ingredientes/alergenos cargados) - evita mostrar fotos de fichas
///   incompletas o mal cargadas de OFF.
/// - Cargada por un usuario: solo se muestra una vez que un admin aprobo
///   el producto (verificado = true) - el admin decide si esa foto se usa.
/// - Cargada por un admin: siempre se muestra, ya la curó directamente.
class _FotoProducto extends StatelessWidget {
  final Producto producto;
  final bool datosSuficientes;
  const _FotoProducto({required this.producto, required this.datosSuficientes});

  bool get _debeMostrarse {
    switch (producto.origen) {
      case 'OPEN_FOOD_FACTS':
        return datosSuficientes && producto.imagenUrl != null;
      case 'USUARIO':
        return producto.verificado && producto.fotoFrontalBase64 != null;
      default: // ADMIN
        return producto.fotoFrontalBase64 != null || producto.imagenUrl != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_debeMostrarse) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: producto.fotoFrontalBase64 != null
              ? Image.memory(
                  Uint8List.fromList(base64Decode(producto.fotoFrontalBase64!)),
                  height: 160,
                  fit: BoxFit.contain,
                )
              : Image.network(
                  producto.imagenUrl!,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 80,
                    child: Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary)),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Miniaturas de las fotos de composicion/tabla nutricional. Estas dos
/// solo existen si alguien las subio a mano (Open Food Facts no las
/// provee), asi que se rigen por el mismo criterio que la foto de un
/// usuario: solo se muestran una vez verificadas por un admin.
class _FotosSecundarias extends StatelessWidget {
  final Producto producto;
  const _FotosSecundarias({required this.producto});

  @override
  Widget build(BuildContext context) {
    if (!producto.verificado) return const SizedBox.shrink();

    final tieneComposicion = producto.fotoComposicionBase64 != null;
    final tieneNutricional = producto.fotoNutricionalBase64 != null;
    if (!tieneComposicion && !tieneNutricional) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            if (tieneComposicion)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    Uint8List.fromList(base64Decode(producto.fotoComposicionBase64!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (tieneComposicion && tieneNutricional) const SizedBox(width: 6),
            if (tieneNutricional)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    Uint8List.fromList(base64Decode(producto.fotoNutricionalBase64!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ResultadoEscaneoCard extends StatelessWidget {
  final ResultadoEscaneo resultado;
  const ResultadoEscaneoCard({super.key, required this.resultado});

  Future<void> _reportarAlerta(BuildContext context) async {
    final descripcionCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Reportar producto')),
        content: TextField(controller: descripcionCtrl, maxLines: 3, decoration: InputDecoration(hintText: tr('Describí el problema'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancelar'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Enviar'))),
        ],
      ),
    );
    if (confirmado == true && descripcionCtrl.text.trim().isNotEmpty) {
      try {
        await context.read<AlertaService>().crear(
              tipo: TipoAlerta.PRODUCTO,
              productoId: resultado.producto.id,
              descripcion: descripcionCtrl.text.trim(),
            );
        if (context.mounted) mostrarMensaje(context, tr('Alerta enviada'));
      } catch (e) {
        if (context.mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _completarDatos(BuildContext context) async {
    final p = resultado.producto;
    final completado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CargarProductoScreen(
          codigoEan: p.codigoEan ?? '',
          productoId: p.id,
          nombreInicial: p.nombre,
          marcaInicial: p.marca,
        ),
      ),
    );
    if (completado == true && context.mounted) {
      mostrarMensaje(context, tr('Escaneá de nuevo el producto para ver los datos actualizados'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = resultado.producto;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FotoProducto(producto: p, datosSuficientes: resultado.datosSuficientes),
            _FotosSecundarias(producto: p),
            Row(
              children: [
                Expanded(
                  child: TextoT(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Chip1(
                  !resultado.datosSuficientes
                      ? tr('Sin datos')
                      : (resultado.seguro ? tr('Seguro') : tr('Alerta')),
                  color: !resultado.datosSuficientes
                      ? AppColors.accent
                      : (resultado.seguro ? AppColors.primary : AppColors.danger),
                ),
              ],
            ),
            if (p.marca != null) Text(p.marca!, style: const TextStyle(color: AppColors.textSecondary)),
            if (p.codigoEan != null) Text(tr('Código: {0}', [p.codigoEan]), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
            if (!p.verificado)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.10),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, color: AppColors.accent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('Cargado por otro usuario, pendiente de revisión por un admin.'),
                        style: TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (!resultado.datosSuficientes) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.10),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.help_outline, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resultado.mensaje,
                        style: const TextStyle(
                          color: Color(0xFF8A5A00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completarDatos(context),
                  icon: const Icon(Icons.edit_note),
                  label: Text(tr('Completar datos de este producto')),
                ),
              ),
            ] else if (!resultado.seguro)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  border: Border.all(color: AppColors.danger, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resultado.mensaje,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.danger,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              TextoT(resultado.mensaje),
            if (resultado.datosSuficientes) _DesgloseIntolerancias(alergenosProducto: p.alergenos),
            if (p.ingredientes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('Ingredientes:'), style: TextStyle(fontWeight: FontWeight.bold)),
              TextoT(p.ingredientes.join(', ')),
            ],
            if (p.alergenos.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: p.alergenos.map((a) => Chip1(etiquetaIntolerancia(a), color: AppColors.danger)).toList()),
            ],
            if (resultado.alternativas.isNotEmpty) _AlternativasSeguras(alternativas: resultado.alternativas),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _reportarAlerta(context),
              icon: const Icon(Icons.flag_outlined),
              label: Text(tr('Reportar producto')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resultado de "Escanear paquete": una sola foto del envase, leída por IA,
/// con el veredicto ya cruzado contra las intolerancias del usuario. Es un
/// chequeo rápido — no requiere código de barras ni que el producto ya
/// esté cargado en la base.
class _AnalisisPaqueteCard extends StatelessWidget {
  final AnalisisFotos analisis;
  final String fotoBase64;
  const _AnalisisPaqueteCard({required this.analisis, required this.fotoBase64});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final intolerancias = context.watch<FiltroEscanerProvider>().efectivas(usuario);
    final enConflicto = analisis.alergenos.intersection(intolerancias);
    final hayDatos = analisis.ingredientes.isNotEmpty || analisis.alergenos.isNotEmpty;
    final seguro = hayDatos && enConflicto.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(Uint8List.fromList(base64Decode(fotoBase64)), height: 140, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  analisis.nombreSugerido ?? tr('Producto sin identificar'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Chip1(
                !hayDatos ? tr('Sin datos') : (seguro ? tr('Seguro') : tr('Alerta')),
                color: !hayDatos ? AppColors.accent : (seguro ? AppColors.primary : AppColors.danger),
              ),
            ],
          ),
          if (analisis.marcaSugerida != null) Text(analisis.marcaSugerida!, style: const TextStyle(color: AppColors.textSecondary)),
          if (analisis.categoriaSugerida != null)
            TextoT(analisis.categoriaSugerida!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          if (!hayDatos)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.10),
                border: Border.all(color: AppColors.accent, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr('No se pudieron identificar ingredientes en esta foto. Probá sacarle una foto más de cerca a la tabla de ingredientes.'),
                style: TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.bold),
              ),
            )
          else if (!seguro)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                border: Border.all(color: AppColors.danger, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr('Atención: este producto contiene alérgenos que coinciden con tus intolerancias.'),
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(tr('No detectamos alérgenos que coincidan con tus intolerancias en esta foto.')),
          _DesgloseIntolerancias(alergenosProducto: analisis.alergenos),
          if (hayDatos && !seguro) _RecomendacionesIa(analisis: analisis),
          if (analisis.ingredientes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(tr('Ingredientes detectados:'), style: TextStyle(fontWeight: FontWeight.bold)),
            TextoT(analisis.ingredientes.join(', ')),
          ],
          if (analisis.observacion != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: TextoT(analisis.observacion!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
          if (analisis.proveedor != null) ...[
            const SizedBox(height: 6),
            Text(tr('Leído con IA ({0})', [analisis.proveedor]), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Text(
              tr('Este chequeo es rápido y no queda guardado en la base. Si querés que otros usuarios también lo vean, escaneá su código de barras y cargalo desde ahí.'),
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Esto no, pero esto sí": cuando el paquete escaneado no es apto, pide al
/// backend alternativas (base propia + Open Food Facts de Uruguay, Argentina
/// y Brasil) y la IA elige y explica las mejores.
class _RecomendacionesIa extends StatefulWidget {
  final AnalisisFotos analisis;
  const _RecomendacionesIa({required this.analisis});

  @override
  State<_RecomendacionesIa> createState() => _RecomendacionesIaState();
}

class _RecomendacionesIaState extends State<_RecomendacionesIa> {
  late Future<RecomendacionesIa> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _pedir();
  }

  Future<RecomendacionesIa> _pedir() => context
      .read<ProductoService>()
      .recomendar(widget.analisis, intolerancias: context.read<FiltroEscanerProvider>().filtro);

  void _reintentar() {
    setState(() {
      _futuro = _pedir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: FutureBuilder<RecomendacionesIa>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Row(
              children: [
                SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Expanded(child: Text(tr('Buscando alternativas para vos...'), style: TextStyle(fontSize: 13))),
              ],
            );
          }
          if (snap.hasError || snap.data == null) {
            return Row(
              children: [
                Expanded(
                  child: Text(tr('No pudimos buscar alternativas ahora.'), style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
                TextButton(onPressed: _reintentar, child: Text(tr('Reintentar'))),
              ],
            );
          }
          final r = snap.data!;
          if (r.items.isEmpty) {
            return TextoT(r.mensaje, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(tr('Esto sí podrías consumir'), style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  if (r.conIa) const Icon(Icons.smart_toy_outlined, size: 14, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 4),
              TextoT(r.mensaje, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...r.items.map(_itemTile),
              if (r.advertencia != null && r.advertencia!.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 2, bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.10),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.fact_check_outlined, size: 18, color: Color(0xFF8A5A00)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.advertencia!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A5A00), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                tr('Datos de la comunidad SafeBite, de Open Food Facts y sugerencias de la IA.'),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _itemTile(RecomendacionIa it) {
    final detalle = it.origen == 'GENERICA'
        ? tr('Sugerencia general')
        : it.origen == 'MARCA_IA'
            ? [if (it.marca != null && it.marca!.isNotEmpty) it.marca!, tr('Sugerencia de la IA')].join(' · ')
            : [
            if (it.marca != null && it.marca!.isNotEmpty) it.marca!,
            if (it.pais != null) it.pais!,
          ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto del producto; si no tiene, se busca una imagen de referencia.
          ImagenProducto(
            url: it.imagenUrl,
            busqueda: [it.nombre, if (it.marca != null && it.marca!.isNotEmpty) it.marca!].join(' '),
            lado: 64,
            icono: it.origen == 'GENERICA'
                ? Icons.lightbulb_outline
                : (it.origen == 'MARCA_IA' ? Icons.storefront_outlined : Icons.fastfood_outlined),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: TextoT(it.nombre, style: const TextStyle(fontWeight: FontWeight.w600))),
                    if (it.origen == 'SAFEBITE')
                      const Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
                  ],
                ),
                if (detalle.isNotEmpty)
                  TextoT(detalle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (it.motivo != null && it.motivo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: TextoT(it.motivo!, style: const TextStyle(fontSize: 12)),
                  ),
                if (it.verificarMarca)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFF8A5A00)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tr('Depende de la marca o del lote: revisá el envase'),
                            style: TextStyle(fontSize: 11, color: Color(0xFF8A5A00), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Esto no lo podes comer, pero esto si": lista de productos similares
/// (misma categoria) que son aptos segun las intolerancias del usuario,
/// mostrada cuando el producto escaneado no es seguro.
class _AlternativasSeguras extends StatelessWidget {
  final List<Producto> alternativas;
  const _AlternativasSeguras({required this.alternativas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text(tr('Estas opciones sí podés comer'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ...alternativas.map((a) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ImagenProducto(
                      url: a.imagenUrl ??
                          (a.fotoFrontalBase64 == null
                              ? null
                              : a.fotoFrontalBase64!.startsWith('data:')
                                  ? a.fotoFrontalBase64
                                  : 'data:image/jpeg;base64,${a.fotoFrontalBase64}'),
                      busqueda: [a.nombre, if (a.marca != null) a.marca!].join(' '),
                      lado: 52,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextoT(a.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (a.marca != null) Text(a.marca!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class AnalisisIngredientesCard extends StatelessWidget {
  final AnalisisIngredientes analisis;
  const AnalisisIngredientesCard({super.key, required this.analisis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr('Análisis de ingredientes'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Chip1(
                analisis.seguro ? tr('Seguro') : tr('Alerta'),
                color: analisis.seguro ? AppColors.primary : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!analisis.seguro)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                border: Border.all(color: AppColors.danger, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      analisis.mensaje,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.danger,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            TextoT(analisis.mensaje),
          _DesgloseIntolerancias(alergenosProducto: analisis.alergenosEncontrados),
          if (analisis.alergenosEncontrados.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: analisis.alergenosEncontrados
                  .map((a) => Chip1(etiquetaIntolerancia(a), color: AppColors.danger))
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(tr('Texto detectado en la foto:'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(analisis.textoAnalizado, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LectorEanTab extends StatefulWidget {
  const _LectorEanTab();
  @override
  State<_LectorEanTab> createState() => _LectorEanTabState();
}

class _LectorEanTabState extends State<_LectorEanTab> {
  final _codigoManualCtrl = TextEditingController();
  ResultadoEscaneo? _resultado;
  String? _error;
  bool _procesando = false;
  String? _ultimoCodigoBuscado;
  bool _escaneandoPaquete = false;
  bool _leyendoFotoCodigo = false;

  bool get _ocupado => _procesando || _escaneandoPaquete || _leyendoFotoCodigo;

  /// Botón "Escanear código de barras": abre la cámara, se saca una foto del
  /// código y se busca el producto (base propia o Open Food Facts).
  /// El código se lee primero en el propio teléfono (instantáneo y gratis);
  /// si no se puede, la IA lee los números de la foto.
  Future<void> _escanearCodigoDeBarras() async {
    // La cámara se abre directamente, en el mismo toque (el navegador solo la
    // abre así). Resolución alta para que las barras se vean nítidas.
    // En la web se usa la cámara propia de la app (web/camara-app.js); en el
    // teléfono, la cámara del sistema.
    final Future<Uint8List?> pedido = camaraAppDisponible()
        ? sacarFotoConCamaraApp(tr('Sacá una foto del código de barras'))
        : ImagePicker()
            .pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 90)
            .then((f) async => f == null ? null : await f.readAsBytes());
    setState(() => _leyendoFotoCodigo = true);
    try {
      final datos = await pedido;
      if (datos == null || !mounted) return;

      String? codigo = await leerCodigoEnFoto(datos);
      if (codigo == null && mounted) {
        final analisis = await context.read<ProductoService>().analizarFotos(fotoFrontalBase64: base64Encode(datos));
        codigo = analisis.codigoBarras;
      }
      if (!mounted) return;
      if (codigo == null || codigo.isEmpty) {
        mostrarError(context,
            tr('No se pudo leer el código en la foto. Sacala de frente, a unos 15 cm y con buena luz, o ingresá el número a mano.'));
        return;
      }
      _codigoManualCtrl.text = codigo;
      await _buscarProducto(codigo);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _leyendoFotoCodigo = false);
    }
  }

  /// Botón "Escanear ingredientes del paquete": se saca una foto de la
  /// etiqueta y la IA (Claude, con Gemini de respaldo) lee ingredientes y
  /// alérgenos.
  Future<void> _escanearIngredientes() async {
    setState(() => _escaneandoPaquete = true);
    try {
      final bytes = await elegirFotoCamaraOGaleria(context, tituloCamara: tr('Sacá una foto de la lista de ingredientes'));
      if (bytes == null || !mounted) return;

      final foto64 = base64Encode(bytes);
      final analisis = await context.read<ProductoService>().analizarFotos(fotoFrontalBase64: foto64);
      if (!mounted) return;

      if (!analisis.pudoLeer) {
        // No se pudieron leer los ingredientes, pero si la IA vio el código de
        // barras, se busca el producto por código.
        final codigo = analisis.codigoBarras;
        if (codigo != null && codigo.isNotEmpty) {
          final encontrado = await _buscarProducto(codigo, silencioso: true);
          if (encontrado) return;
        }
        if (mounted) {
          mostrarError(context, analisis.observacion ?? tr('No se pudo leer el envase. Probá con mejor luz y más cerca.'));
        }
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: _AnalisisPaqueteCard(analisis: analisis, fotoBase64: foto64),
          ),
        ),
      );
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _escaneandoPaquete = false);
    }
  }

  Future<void> _buscarConCodigoManual() async {
    final codigo = _codigoManualCtrl.text.trim();
    if (codigo.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _buscarProducto(codigo);
  }

  /// Busca el producto por código. Devuelve true si lo encontró.
  /// Con [silencioso] no muestra el error en pantalla.
  Future<bool> _buscarProducto(String codigo, {bool silencioso = false}) async {
    if (_procesando) return false;
    setState(() {
      _procesando = true;
      _error = null;
      _ultimoCodigoBuscado = codigo;
    });
    try {
      final resultado = await context
          .read<ProductoService>()
          .escanearPorEan(codigo, intolerancias: context.read<FiltroEscanerProvider>().filtro);
      if (!mounted) return true;
      setState(() => _resultado = resultado);
      return true;
    } catch (e) {
      if (mounted && !silencioso) setState(() => _error = tr('Código: {0}\n{1}', [codigo, e]));
      return false;
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _reiniciar() {
    setState(() {
      _resultado = null;
      _error = null;
      _ultimoCodigoBuscado = null;
    });
    _codigoManualCtrl.clear();
  }

  Future<void> _irACargarProducto() async {
    final codigo = _ultimoCodigoBuscado;
    if (codigo == null) return;
    final cargado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CargarProductoScreen(codigoEan: codigo)),
    );
    if (cargado == true) _reiniciar();
  }

  @override
  void dispose() {
    _codigoManualCtrl.dispose();
    super.dispose();
  }

  /// Tarjeta de acción del diseño "Fresco": ícono en un recuadro de color,
  /// título y una línea de ayuda.
  Widget _tarjetaAccion({
    required IconData icono,
    required Color colorIcono,
    required Color fondoIcono,
    required String texto,
    required String ayuda,
    required String textoCargando,
    required bool cargando,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _ocupado ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.sombraSuave,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: fondoIcono, borderRadius: BorderRadius.circular(16)),
                  child: cargando
                      ? Padding(
                          padding: const EdgeInsets.all(13),
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: colorIcono),
                        )
                      : Icon(icono, color: colorIcono, size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  cargando ? textoCargando : texto,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(ayuda, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenidoResultado() {
    if (_procesando) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_resultado != null) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: _reiniciar,
            icon: const Icon(Icons.barcode_reader),
            label: Text(tr('Escanear otro producto')),
          ),
        ),
        ResultadoEscaneoCard(resultado: _resultado!),
      ]);
    }
    if (_error != null) {
      return Column(
        children: [
          ErrorView(mensaje: _error!, onReintentar: _reiniciar),
          if (_ultimoCodigoBuscado != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _irACargarProducto,
                icon: const Icon(Icons.add_box_outlined),
                label: Text(tr('Cargar este producto')),
              ),
            ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            tr('Sacá una foto del código de barras para ver el producto, o de la lista de ingredientes para que la IA la analice.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EncabezadoSafeBite(
              titulo: tr('¿Qué vas a comer hoy?'),
              subtitulo: tr('Revisamos cada producto contra tus restricciones.'),
              espacioInferior: 64,
            ),
            // Las dos tarjetas se superponen al encabezado.
            Transform.translate(
              offset: const Offset(0, -44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tarjetaAccion(
                        icono: Icons.barcode_reader,
                        colorIcono: AppColors.primary,
                        fondoIcono: AppColors.primarySoft,
                        texto: tr('Escanear código de barras'),
                        ayuda: tr('Foto del código'),
                        textoCargando: tr('Leyendo el código...'),
                        cargando: _leyendoFotoCodigo,
                        onPressed: _escanearCodigoDeBarras,
                      ),
                      const SizedBox(width: 12),
                      _tarjetaAccion(
                        icono: Icons.auto_awesome,
                        colorIcono: const Color(0xFFB26A00),
                        fondoIcono: AppColors.accentSoft,
                        texto: tr('Escanear ingredientes del paquete'),
                        ayuda: tr('La IA lee la etiqueta'),
                        textoCargando: tr('Analizando con IA...'),
                        cargando: _escaneandoPaquete,
                        onPressed: _escanearIngredientes,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _codigoManualCtrl,
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _buscarConCodigoManual(),
                      decoration: InputDecoration(
                        hintText: tr('Ingresá el código a mano'),
                        prefixIcon: const Icon(Icons.dialpad_rounded, color: AppColors.textSecondary),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(6),
                          child: IconButton.filled(
                            tooltip: tr('Buscar'),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.search_rounded),
                            onPressed: _ocupado ? null : _buscarConCodigoManual,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FiltroEscanerBarra(onCambio: () {
                    // Si ya hay un producto en pantalla, se vuelve a evaluar con el filtro nuevo.
                    final codigo = _ultimoCodigoBuscado;
                    if (_resultado != null && codigo != null) _buscarProducto(codigo);
                  }),
                  _contenidoResultado(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Revisar contra": por defecto las intolerancias del perfil; se pueden
/// elegir otras para evaluar los productos escaneados.
class _FiltroEscanerBarra extends StatelessWidget {
  final VoidCallback onCambio;
  const _FiltroEscanerBarra({required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final filtro = context.watch<FiltroEscanerProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  filtro.personalizado ? tr('Revisando contra el filtro elegido:') : tr('Revisando contra tus intolerancias:'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              if (filtro.personalizado)
                TextButton(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    filtro.restablecer();
                    onCambio();
                  },
                  child: Text(tr('Usar las mías'), style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        BarraFiltroIntolerancias(
          seleccion: filtro.efectivas(usuario),
          titulo: tr('Revisar productos contra...'),
          ayuda: tr('El escáner te avisa si el producto contiene alguna de las intolerancias marcadas. Por defecto se usan las de tu perfil.'),
          onChanged: (s) {
            filtro.cambiar(s, usuario);
            onCambio();
          },
        ),
      ],
    );
  }
}


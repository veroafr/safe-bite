import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/models/restaurante.dart';
import '../../core/models/usuario.dart';
import '../../core/models/alerta.dart';
import '../../core/services/restaurante_service.dart';
import '../../core/services/alerta_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';
import '../../core/i18n/i18n.dart';

/// Qué significa cada cantidad de estrellas. Se muestra solo al dejar una reseña.
const List<(String, String)> significadoEstrellas = [
  ('Muy mala', 'No respetaron mi restricción alimentaria, me sentí mal o hubo riesgo de contaminación.'),
  ('Mala', 'Pocas opciones aptas o información confusa; no me dio confianza.'),
  ('Regular', 'Pude comer, pero con dudas: faltó información o cuidado en la preparación.'),
  ('Buena', 'Me sentí seguro/a y bien atendido/a; solo detalles a mejorar.'),
  ('Excelente', 'Total confianza: personal informado, preparación separada y buenas opciones. ¡Lo recomiendo!'),
];

const _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class RestauranteDetailScreen extends StatefulWidget {
  final int restauranteId;
  const RestauranteDetailScreen({super.key, required this.restauranteId});

  @override
  State<RestauranteDetailScreen> createState() => _RestauranteDetailScreenState();
}

class _RestauranteDetailScreenState extends State<RestauranteDetailScreen> {
  Restaurante? _restaurante;
  List<Evaluacion> _resenas = [];
  Evaluacion? _miResena;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final service = context.read<RestauranteService>();
      final r = await service.obtener(widget.restauranteId);
      final e = await service.listarEvaluaciones(widget.restauranteId);
      Evaluacion? mia;
      try {
        mia = await service.miEvaluacion(widget.restauranteId);
      } catch (_) {
        mia = null; // sin sesión o backend anterior
      }
      setState(() {
        _restaurante = r;
        _resenas = e;
        _miResena = mia;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _dejarResena() async {
    final enviada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _HojaResena(
        restauranteId: widget.restauranteId,
        restauranteNombre: _restaurante?.nombre ?? '',
        anterior: _miResena,
      ),
    );
    if (enviada == true) {
      if (mounted) {
        mostrarMensaje(context, tr('¡Gracias! Tu reseña será publicada cuando el equipo la apruebe.'));
      }
      await _cargar();
    }
  }

  Future<void> _reportarProblema() async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FormularioReporte(
          restauranteId: widget.restauranteId,
          restauranteNombre: _restaurante?.nombre ?? '',
        ),
      ),
    );
    if (enviado == true && mounted) {
      mostrarMensaje(context, tr('Reporte enviado. El equipo lo revisará y podrá contactarte.'));
    }
  }

  void _abrirMapaCompleto() {
    final r = _restaurante!;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MapaCompletoScreen(
        nombre: r.nombre,
        direccion: r.direccion,
        punto: LatLng(r.latitud!, r.longitud!),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_restaurante?.nombre ?? tr('Restaurante'))),
      body: _cargando
          ? const LoadingView()
          : _error != null
              ? ErrorView(mensaje: _error!, onReintentar: _cargar)
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._cabecera(),
                      if (_restaurante!.latitud != null && _restaurante!.longitud != null) ..._mapa(),
                      ..._seccionResenas(),
                      const SizedBox(height: 20),
                      const AvisoInformacionLocales(),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(tr('¿Algo no está bien en este local?'),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _reportarProblema,
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(tr('Reportar un problema con este local')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _cabecera() {
    final r = _restaurante!;
    return [
      if (r.imagenBanner != null || r.imagenMiniatura != null || r.imagenUrl != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 2,
            child: r.imagenBanner != null
                ? ImagenFlexible(fuente: r.imagenBanner, sinImagen: Container(color: const Color(0xFFE0E0E0)))
                // Sin banner: se muestra la otra foto completa sobre fondo blanco.
                : Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: ImagenFlexible(
                      fuente: r.imagenMiniatura ?? r.imagenUrl,
                      fit: BoxFit.contain,
                      sinImagen: Container(color: const Color(0xFFE0E0E0)),
                    ),
                  ),
          ),
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accent),
          Text(' ${r.ratingPromedio.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('  (${_resenas.length} ${_resenas.length == 1 ? tr('reseña') : tr('reseñas')})',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
      if (r.direccion != null) ...[
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(child: Text(r.direccion!, style: const TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      ],
      if (r.descripcion != null) ...[
        const SizedBox(height: 10),
        TextoT(r.descripcion!),
      ],
      if (r.opcionesAptasPara.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: r.opcionesAptasPara.map((t) => Chip1(tr('Sin {0}', [etiquetaIntolerancia(t)]))).toList(),
        ),
      ],
    ];
  }

  List<Widget> _mapa() {
    final r = _restaurante!;
    final punto = LatLng(r.latitud!, r.longitud!);
    return [
      SeccionTitulo(tr('Ubicación en el mapa')),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 230,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: punto,
                  initialZoom: 15,
                  minZoom: 3,
                  maxZoom: 19,
                  // Se puede mover y acercar con los dedos; la rueda del mouse
                  // queda para desplazar la página.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.flingAnimation,
                  ),
                ),
                children: [
                  TileLayer(urlTemplate: _tiles, userAgentPackageName: 'com.safebite.app'),
                  MarkerLayer(markers: [_marcador(punto)]),
                ],
              ),
              Positioned(
                right: 8,
                top: 8,
                child: _BotonMapa(icono: Icons.open_in_full_rounded, texto: tr('Ampliar'), onTap: _abrirMapaCompleto),
              ),
              const Positioned(left: 6, bottom: 4, child: _CreditoOsm()),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(tr('Arrastrá o pellizcá el mapa para ver las calles cercanas.'),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ];
  }

  List<Widget> _seccionResenas() {
    final mia = _miResena;
    return [
      SeccionTitulo(tr('Reseñas')),
      if (mia != null && (mia.pendiente || mia.rechazada))
        Card(
          color: mia.pendiente ? AppColors.accentSoft : const Color(0xFFFDECEC),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(mia.pendiente ? Icons.hourglass_top_rounded : Icons.block_rounded,
                    color: mia.pendiente ? AppColors.primaryDark : AppColors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mia.pendiente ? tr('Tu reseña está en revisión') : tr('Tu reseña no fue aprobada'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        mia.pendiente
                            ? tr('La publicaremos cuando el equipo la apruebe.')
                            : (mia.motivoRechazo != null
                                ? tr('Motivo: {0}. Podés editarla y enviarla de nuevo.', [context.tc(mia.motivoRechazo)])
                                : tr('Podés editarla y enviarla de nuevo.')),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 4),
      FilledButton.icon(
        onPressed: _dejarResena,
        icon: const Icon(Icons.rate_review_outlined),
        label: Text(mia == null ? tr('Dejar un comentario') : tr('Editar mi comentario')),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      const SizedBox(height: 12),
      if (_resenas.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(tr('Todavía no hay reseñas publicadas. ¡Sé el primero en contar tu experiencia!'),
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ..._resenas.map((e) => _TarjetaResena(resena: e)),
    ];
  }
}

Marker _marcador(LatLng punto) => Marker(
      point: punto,
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: const Icon(Icons.location_on, color: AppColors.danger, size: 42),
    );

class _CreditoOsm extends StatelessWidget {
  const _CreditoOsm();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        color: Colors.white70,
        child: Text(tr('© OpenStreetMap'), style: TextStyle(fontSize: 10, color: Colors.black87)),
      );
}

class _BotonMapa extends StatelessWidget {
  final IconData icono;
  final String? texto;
  final VoidCallback onTap;
  const _BotonMapa({required this.icono, this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: texto == null ? 10 : 12, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icono, size: 20, color: AppColors.primaryDark),
              if (texto != null) ...[
                const SizedBox(width: 6),
                Text(texto!, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
              ],
            ]),
          ),
        ),
      );
}

class _TarjetaResena extends StatelessWidget {
  final Evaluacion resena;
  const _TarjetaResena({required this.resena});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(resena.usuarioNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(DateFormat('dd/MM/yyyy').format(resena.fecha),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              EstrellasFijas(valor: resena.puntuacion),
              if (resena.comentario != null && resena.comentario!.isNotEmpty) ...[
                const SizedBox(height: 6),
                TextoT(resena.comentario!),
              ],
            ],
          ),
        ),
      );
}

class EstrellasFijas extends StatelessWidget {
  final int valor;
  final double tamano;
  const EstrellasFijas({super.key, required this.valor, this.tamano = 18});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            5,
            (i) => Icon(i < valor ? Icons.star_rounded : Icons.star_outline_rounded,
                size: tamano, color: AppColors.accent),
          ),
          if (valor >= 1 && valor <= 5) ...[
            const SizedBox(width: 6),
            Text(tr(significadoEstrellas[valor - 1].$1),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      );
}

// ======================================================================
// Hoja para dejar la reseña: estrellas + comentario juntos.
// ======================================================================

class _HojaResena extends StatefulWidget {
  final int restauranteId;
  final String restauranteNombre;
  final Evaluacion? anterior;
  const _HojaResena({required this.restauranteId, required this.restauranteNombre, this.anterior});

  @override
  State<_HojaResena> createState() => _HojaResenaState();
}

class _HojaResenaState extends State<_HojaResena> {
  late int _estrellas = widget.anterior?.puntuacion ?? 0;
  late final _texto = TextEditingController(text: widget.anterior?.comentario ?? '');
  bool _enviando = false;
  String? _aviso;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (_estrellas == 0) {
      setState(() => _aviso = tr('Elegí cuántas estrellas le das.'));
      return;
    }
    if (texto.length < 10) {
      setState(() => _aviso = tr('Contanos un poco más (mínimo 10 caracteres).'));
      return;
    }
    setState(() {
      _enviando = true;
      _aviso = null;
    });
    try {
      await context.read<RestauranteService>().evaluar(widget.restauranteId, _estrellas, texto);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(tr('Tu experiencia en {0}', [widget.restauranteNombre]),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(tr('Elegí las estrellas y contá cómo te fue.'),
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final valor = i + 1;
                  return IconButton(
                    iconSize: 40,
                    tooltip: valor == 1 ? tr('1 estrella') : tr('{0} estrellas', [valor]),
                    icon: Icon(valor <= _estrellas ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.accent),
                    onPressed: () => setState(() {
                      _estrellas = valor;
                      _aviso = null;
                    }),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Text(tr('¿Qué significa cada puntuación?'), style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...List.generate(5, (i) {
              final valor = i + 1;
              final elegido = valor == _estrellas;
              final (titulo, detalle) = significadoEstrellas[i];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _estrellas = valor;
                  _aviso = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: elegido ? AppColors.primarySoft : Colors.transparent,
                    border: Border.all(color: elegido ? AppColors.primary : AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('$valor', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                        ]),
                      ),
                      Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: '${tr(titulo)}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: tr(detalle)),
                        ]), style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: _texto,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: tr('Tu comentario'),
                hintText: tr('Ej: Tienen carta sin gluten y me explicaron cómo preparan los platos.'),
                alignLabelWithHint: true,
              ),
            ),
            if (_aviso != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_aviso!, style: const TextStyle(color: AppColors.danger)),
              ),
            Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(tr('Para evitar reseñas falsas, el equipo de SafeBite revisa cada comentario antes de publicarlo.'),
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _enviando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(tr('Enviar reseña')),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Formulario de reporte: teléfono, descripción y pruebas opcionales.
// ======================================================================

class _FormularioReporte extends StatefulWidget {
  final int restauranteId;
  final String restauranteNombre;
  const _FormularioReporte({required this.restauranteId, required this.restauranteNombre});

  @override
  State<_FormularioReporte> createState() => _FormularioReporteState();
}

class _FormularioReporteState extends State<_FormularioReporte> {
  static const _maxPruebas = 3;
  final _form = GlobalKey<FormState>();
  final _telefono = TextEditingController();
  final _descripcion = TextEditingController();
  final List<List<int>> _pruebas = [];
  bool _enviando = false;

  @override
  void dispose() {
    _telefono.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _agregarPrueba() async {
    final bytes = await elegirFotoCamaraOGaleria(context, tituloCamara: tr('Sacá una foto de la prueba'));
    if (bytes == null || !mounted) return;
    setState(() => _pruebas.add(bytes));
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await context.read<AlertaService>().crear(
            tipo: TipoAlerta.RESTAURANTE,
            restauranteId: widget.restauranteId,
            descripcion: _descripcion.text.trim(),
            telefonoContacto: _telefono.text.trim(),
            pruebas: _pruebas.map(base64Encode).toList(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Reportar un problema'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(tr('Local: {0}', [widget.restauranteNombre]), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              tr('Contanos qué pasó. El equipo de SafeBite revisa cada reporte y puede contactarte para pedir más detalles.'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\s.-]'))],
              decoration: InputDecoration(
                labelText: tr('Teléfono de contacto *'),
                hintText: tr('Ej: 099 123 456'),
                prefixIcon: Icon(Icons.phone_outlined),
                helperText: tr('Solo lo ve el equipo de SafeBite.'),
              ),
              validator: (v) {
                final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '').length;
                if (digitos == 0) return tr('Indicá un teléfono para poder contactarte');
                if (digitos < 8 || digitos > 15) return tr('Revisá el número (8 a 15 dígitos)');
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcion,
              maxLines: 6,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: tr('Describí el problema *'),
                hintText: tr('Ej: Pedí un plato sin gluten y me lo sirvieron con pan rallado. Fue el 12/11 al mediodía.'),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return tr('Describí el problema');
                if (t.length < 15) return tr('Agregá un poco más de detalle (mínimo 15 caracteres)');
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(tr('Pruebas (opcional)'), style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(tr('Fotos del plato, del menú, del ticket o de lo que respalde tu reporte. Hasta 3.'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _pruebas.length; i++)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(Uint8List.fromList(_pruebas[i]), width: 92, height: 92, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: IconButton.filled(
                          iconSize: 16,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(backgroundColor: AppColors.danger),
                          tooltip: tr('Quitar'),
                          onPressed: () => setState(() => _pruebas.removeAt(i)),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                if (_pruebas.length < _maxPruebas)
                  InkWell(
                    onTap: _agregarPrueba,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primarySoft,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                          SizedBox(height: 4),
                          Text(tr('Agregar'), style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.send_rounded),
              label: Text(tr('Enviar reporte')),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Mapa a pantalla completa, navegable.
// ======================================================================

class _MapaCompletoScreen extends StatefulWidget {
  final String nombre;
  final String? direccion;
  final LatLng punto;
  const _MapaCompletoScreen({required this.nombre, this.direccion, required this.punto});

  @override
  State<_MapaCompletoScreen> createState() => _MapaCompletoScreenState();
}

class _MapaCompletoScreenState extends State<_MapaCompletoScreen> {
  final _mapa = MapController();

  void _zoom(double delta) {
    final camara = _mapa.camera;
    _mapa.move(camara.center, (camara.zoom + delta).clamp(3, 19).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.punto;
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: p,
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(urlTemplate: _tiles, userAgentPackageName: 'com.safebite.app'),
              MarkerLayer(markers: [_marcador(p)]),
            ],
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Column(children: [
              _BotonMapa(icono: Icons.add, onTap: () => _zoom(1)),
              const SizedBox(height: 8),
              _BotonMapa(icono: Icons.remove, onTap: () => _zoom(-1)),
              const SizedBox(height: 8),
              _BotonMapa(icono: Icons.my_location_rounded, onTap: () => _mapa.move(p, 16)),
            ]),
          ),
          const Positioned(left: 8, bottom: 96, child: _CreditoOsm()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: SafeArea(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (widget.direccion != null)
                              Text(widget.direccion!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => abrirEnlace(context,
                            'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}'),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: Text(tr('Cómo llegar')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

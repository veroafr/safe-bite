import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/intolerancia.dart';
import '../providers/auth_provider.dart';
import '../providers/intolerancias_provider.dart';
import '../theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

/// Chips para marcar / desmarcar intolerancias. Muestra TODAS las
/// intolerancias activas del sistema (las predefinidas y las que agrega el
/// admin). Si alguna seleccionada ya no esta activa, igual aparece para
/// poder quitarla.
class SelectorIntolerancias extends StatefulWidget {
  final Set<String> seleccionadas;
  final ValueChanged<Set<String>> onChanged;

  /// Texto opcional delante de cada nombre (ej: "Sin " -> "Sin Trigo").
  final String prefijo;
  final Color color;
  final bool habilitado;

  const SelectorIntolerancias({
    super.key,
    required this.seleccionadas,
    required this.onChanged,
    this.prefijo = '',
    this.color = AppColors.primary,
    this.habilitado = true,
  });

  @override
  State<SelectorIntolerancias> createState() => _SelectorIntoleranciasState();
}

class _SelectorIntoleranciasState extends State<SelectorIntolerancias> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<IntoleranciasProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IntoleranciasProvider>();

    if (provider.cargando && provider.activas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (provider.activas.isEmpty && provider.error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(tr('No se pudo cargar la lista de intolerancias.'),
                style: TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
          TextButton(onPressed: provider.recargar, child: Text(tr('Reintentar'))),
        ],
      );
    }

    final activos = provider.activas.map((i) => i.codigo).toSet();
    final extras = widget.seleccionadas.where((c) => !activos.contains(c)).toList();

    Widget chip(String codigo, String nombre, {String? tooltip}) {
      final sel = widget.seleccionadas.contains(codigo);
      final c = FilterChip(
        label: Text('${widget.prefijo}${context.tc(nombre)}'),
        selected: sel,
        showCheckmark: true,
        selectedColor: widget.color.withOpacity(0.18),
        checkmarkColor: widget.color,
        labelStyle: TextStyle(
          fontSize: 13,
          color: sel ? widget.color : AppColors.textPrimary,
          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
        ),
        onSelected: !widget.habilitado
            ? null
            : (v) {
                final nuevo = {...widget.seleccionadas};
                v ? nuevo.add(codigo) : nuevo.remove(codigo);
                widget.onChanged(nuevo);
              },
      );
      return tooltip == null ? c : Tooltip(message: tooltip, child: c);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        for (final i in provider.activas) chip(i.codigo, i.nombre, tooltip: i.nombreCientifico),
        for (final c in extras) chip(c, tr('{0} (inactiva)', [etiquetaIntolerancia(c)])),
      ],
    );
  }
}

/// Abre una hoja inferior para elegir intolerancias como filtro. Devuelve el
/// conjunto elegido (vacio = sin filtro) o null si se cancela.
Future<Set<String>?> abrirFiltroIntolerancias(
  BuildContext context, {
  required Set<String> actuales,
  String titulo = 'Filtrar por intolerancias',
  String? ayuda,
  String prefijoChips = '',
}) {
  Set<String> temp = {...actuales};
  final misIntolerancias = context.read<AuthProvider>().usuario?.intolerancias ?? <String>{};

  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr(titulo), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (ayuda != null) ...[
                  const SizedBox(height: 4),
                  Text(ayuda, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (misIntolerancias.isNotEmpty)
                      ActionChip(
                        avatar: const Icon(Icons.person_outline, size: 18),
                        label: Text(tr('Mis intolerancias')),
                        onPressed: () => setModal(() => temp = {...misIntolerancias}),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.clear_all, size: 18),
                      label: Text(tr('Limpiar')),
                      onPressed: () => setModal(() => temp = {}),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectorIntolerancias(
                  seleccionadas: temp,
                  prefijo: prefijoChips,
                  onChanged: (s) => setModal(() => temp = s),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, temp),
                  child: Text(temp.isEmpty ? tr('Ver todo') : tr('Aplicar ({0})', [temp.length])),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Fila de filtro para las pantallas de listado: boton que abre el
/// selector + chips con lo que esta filtrado (se pueden quitar de a uno).
class BarraFiltroIntolerancias extends StatelessWidget {
  final Set<String> seleccion;
  final ValueChanged<Set<String>> onChanged;
  final String titulo;
  final String? ayuda;

  /// Prefijo para los chips de la barra (ej: "Sin ").
  final String prefijo;

  const BarraFiltroIntolerancias({
    super.key,
    required this.seleccion,
    required this.onChanged,
    this.titulo = 'Filtrar por intolerancias',
    this.ayuda,
    this.prefijo = '',
  });

  Future<void> _abrir(BuildContext context) async {
    final r = await abrirFiltroIntolerancias(context,
        actuales: seleccion, titulo: titulo, ayuda: ayuda, prefijoChips: prefijo);
    if (r != null) onChanged(r);
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el provider para refrescar nombres cuando termina de cargar.
    context.watch<IntoleranciasProvider>();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              avatar: Icon(Icons.tune, size: 18, color: seleccion.isEmpty ? AppColors.textSecondary : AppColors.primary),
              label: Text(seleccion.isEmpty ? tr('Intolerancias') : tr('Intolerancias ({0})', [seleccion.length])),
              onPressed: () => _abrir(context),
            ),
          ),
          for (final c in seleccion)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputChip(
                label: Text('${prefijo}${etiquetaIntolerancia(c)}'),
                selected: true,
                showCheckmark: false,
                selectedColor: AppColors.primary.withOpacity(0.15),
                onDeleted: () => onChanged({...seleccion}..remove(c)),
              ),
            ),
          if (seleccion.isNotEmpty)
            TextButton(onPressed: () => onChanged({}), child: Text(tr('Quitar filtros'))),
        ],
      ),
    );
  }
}

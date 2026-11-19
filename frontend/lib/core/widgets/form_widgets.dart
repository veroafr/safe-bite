import 'package:flutter/material.dart';

import '../data/ubicaciones.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import '../../core/i18n/i18n.dart';

/// Campo de contraseña con "ojito" para mostrar / ocultar el texto.
class CampoPassword extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

  /// Muestra debajo la lista de requisitos (mayuscula, numero, especial) con tildes.
  final bool mostrarRequisitos;

  const CampoPassword({
    super.key,
    required this.controller,
    this.label = 'Contraseña',
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.mostrarRequisitos = false,
  });

  @override
  State<CampoPassword> createState() => _CampoPasswordState();
}

class _CampoPasswordState extends State<CampoPassword> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _oculta,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            labelText: tr(widget.label),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _oculta ? tr('Mostrar contraseña') : tr('Ocultar contraseña'),
              icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _oculta = !_oculta),
            ),
            errorMaxLines: 3,
          ),
          validator: widget.validator,
          onChanged: (v) {
            if (widget.mostrarRequisitos) setState(() {});
            widget.onChanged?.call(v);
          },
        ),
        if (widget.mostrarRequisitos) ...[
          const SizedBox(height: 6),
          _RequisitosPassword(valor: widget.controller.text),
        ],
      ],
    );
  }
}

class _RequisitosPassword extends StatelessWidget {
  final String valor;
  const _RequisitosPassword({required this.valor});

  @override
  Widget build(BuildContext context) {
    Widget item(bool ok, String texto) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16, color: ok ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(texto, style: TextStyle(fontSize: 12, color: ok ? AppColors.primary : AppColors.textSecondary)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(valor.length >= 6, tr('Mínimo 6 caracteres')),
        item(RegExp(r'[A-Z]').hasMatch(valor), tr('Al menos 1 mayúscula')),
        item(RegExp(r'\d').hasMatch(valor), tr('Al menos 1 número')),
        item(RegExp(r'[^A-Za-z0-9\s]').hasMatch(valor), tr('Al menos 1 carácter especial (! @ # \$ % ...)')),
      ],
    );
  }
}

/// País (desplegable) y ciudad (campo con búsqueda): Uruguay y Brasil tienen
/// todas sus localidades, así que la ciudad se busca escribiendo. Si la
/// ciudad no aparece, se puede escribir igual.
class SelectorUbicacion extends StatelessWidget {
  final String? pais;
  final String? ciudad;
  final void Function(String? pais, String? ciudad) onChanged;
  final bool obligatorio;

  const SelectorUbicacion({
    super.key,
    required this.pais,
    required this.ciudad,
    required this.onChanged,
    this.obligatorio = true,
  });

  @override
  Widget build(BuildContext context) {
    final paises = ciudadesPorPais.keys.toList();
    if (pais != null && pais!.isNotEmpty && !paises.contains(pais)) paises.add(pais!);

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: (pais == null || pais!.isEmpty) ? null : pais,
          isExpanded: true,
          decoration: InputDecoration(labelText: tr('País'), prefixIcon: Icon(Icons.public)),
          items: paises.map((p) => DropdownMenuItem(value: p, child: Text(tr(p)))).toList(),
          onChanged: (p) => onChanged(p, null),
          validator: obligatorio ? (v) => Validadores.requerido(v, tr('Elegí tu país')) : null,
        ),
        const SizedBox(height: 14),
        _CampoCiudad(
          // La key cambia con el país para que el campo se reinicie.
          key: ValueKey('ciudad-$pais'),
          pais: pais,
          ciudad: ciudad,
          obligatorio: obligatorio,
          onChanged: (c) => onChanged(pais, c),
        ),
      ],
    );
  }
}

String _sinAcentos(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const a = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? a[i] : ch);
  }
  return b.toString().toLowerCase();
}

class _CampoCiudad extends StatelessWidget {
  final String? pais;
  final String? ciudad;
  final bool obligatorio;
  final ValueChanged<String?> onChanged;

  const _CampoCiudad({super.key, required this.pais, required this.ciudad, required this.obligatorio, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ciudades = ciudadesPorPais[pais] ?? const <String>[];
    // Índice sin acentos para buscar rápido entre miles de ciudades.
    final indice = [for (final c in ciudades) (c, _sinAcentos(c))];

    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<String>(
        initialValue: TextEditingValue(text: ciudad ?? ''),
        optionsBuilder: (valor) {
          final q = _sinAcentos(valor.text.trim());
          if (q.isEmpty) return ciudades.length <= 60 ? ciudades : const <String>[];
          final empiezan = <String>[];
          final contienen = <String>[];
          for (final (original, normal) in indice) {
            if (normal.startsWith(q)) {
              empiezan.add(original);
            } else if (normal.contains(q)) {
              contienen.add(original);
            }
            if (empiezan.length >= 40) break;
          }
          return [...empiezan, ...contienen].take(40);
        },
        onSelected: onChanged,
        optionsViewBuilder: (context, onSelected, opciones) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260, maxWidth: constraints.maxWidth),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opciones.length,
                itemBuilder: (context, i) {
                  final o = opciones.elementAt(i);
                  return ListTile(dense: true, title: Text(o), onTap: () => onSelected(o));
                },
              ),
            ),
          ),
        ),
        fieldViewBuilder: (context, controller, focus, onSubmit) => TextFormField(
          controller: controller,
          focusNode: focus,
          enabled: pais != null && pais!.isNotEmpty,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: tr('Ciudad'),
            prefixIcon: const Icon(Icons.location_city_outlined),
            suffixIcon: const Icon(Icons.search),
            hintText: pais == null ? tr('Primero elegí el país') : tr('Escribí para buscar'),
            helperText: pais != null && ciudades.length > 60 ? tr('Si tu localidad no aparece, escribila igual') : null,
          ),
          // Se acepta lo que escriba (por si su localidad no está en la lista).
          onChanged: (v) => onChanged(v.trim().isEmpty ? null : v.trim()),
          validator: obligatorio ? (v) => Validadores.requerido(v, tr('Elegí tu ciudad')) : null,
        ),
      ),
    );
  }
}

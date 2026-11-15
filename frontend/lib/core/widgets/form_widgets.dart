import 'package:flutter/material.dart';

import '../data/ubicaciones.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

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
            labelText: widget.label,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
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
        item(valor.length >= 6, 'Mínimo 6 caracteres'),
        item(RegExp(r'[A-Z]').hasMatch(valor), 'Al menos 1 mayúscula'),
        item(RegExp(r'\d').hasMatch(valor), 'Al menos 1 número'),
        item(RegExp(r'[^A-Za-z0-9\s]').hasMatch(valor), 'Al menos 1 carácter especial (! @ # \$ % ...)'),
      ],
    );
  }
}

/// Dos menus desplegables encadenados: primero el pais y despues la
/// ciudad de ese pais. Si el usuario ya tenia guardado un valor que no
/// esta en la lista (cuentas viejas), se muestra igual para no perderlo.
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

    final ciudades = <String>[...(ciudadesPorPais[pais] ?? const <String>[])];
    if (pais != null) {
      if (ciudad != null && ciudad!.isNotEmpty && !ciudades.contains(ciudad)) ciudades.add(ciudad!);
      if (!ciudades.contains(otraCiudad)) ciudades.add(otraCiudad);
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: (pais == null || pais!.isEmpty) ? null : pais,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'País', prefixIcon: Icon(Icons.public)),
          items: paises.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (p) => onChanged(p, null),
          validator: obligatorio ? (v) => Validadores.requerido(v, 'Elegí tu país') : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          // La key cambia con el pais para que el desplegable se reinicie.
          key: ValueKey('ciudad-$pais'),
          value: (ciudad == null || ciudad!.isEmpty) ? null : ciudad,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Ciudad',
            prefixIcon: const Icon(Icons.location_city_outlined),
            hintText: pais == null ? 'Primero elegí el país' : null,
          ),
          items: ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: pais == null ? null : (c) => onChanged(pais, c),
          validator: obligatorio ? (v) => Validadores.requerido(v, 'Elegí tu ciudad') : null,
        ),
      ],
    );
  }
}

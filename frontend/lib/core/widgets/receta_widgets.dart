import 'package:flutter/material.dart';
import '../models/receta.dart';
import '../theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

/// Indica de dónde viene la receta: del equipo de SafeBite, de la comunidad
/// (enviada por una persona y aprobada) o de Spoonacular.
class EtiquetaOrigenReceta extends StatelessWidget {
  final Receta receta;
  final bool compacta;
  const EtiquetaOrigenReceta({super.key, required this.receta, this.compacta = false});

  @override
  Widget build(BuildContext context) {
    final (IconData icono, String texto, Color color) = switch (receta.origen) {
      'USUARIO' => (Icons.people_alt_rounded, tr('Comunidad'), const Color(0xFF7C4DFF)),
      'SPOONACULAR' => (Icons.public_rounded, 'spoonacular', const Color(0xFFE65100)),
      _ => (Icons.verified_rounded, compacta ? tr('SafeBite') : tr('Verificada por SafeBite'), AppColors.primary),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compacta ? 6 : 8, vertical: compacta ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: compacta ? 12 : 14, color: color),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: compacta ? 10 : 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Estado de una receta enviada por el usuario.
class EtiquetaEstadoReceta extends StatelessWidget {
  final Receta receta;
  const EtiquetaEstadoReceta({super.key, required this.receta});

  @override
  Widget build(BuildContext context) {
    final (String texto, Color color) = switch (receta.estado) {
      'PENDIENTE' => (tr('En revisión'), const Color(0xFFB26A00)),
      'RECHAZADA' => (tr('No aprobada'), AppColors.danger),
      _ => (tr('Publicada'), AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// Recuadro de aviso (rojo = peligro, ámbar = atención, gris = información).
class AvisoReceta extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? texto;
  final Color color;
  const AvisoReceta({super.key, required this.icono, required this.titulo, this.texto, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextoT(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              if (texto != null) ...[
                const SizedBox(height: 2),
                TextoT(texto!, style: const TextStyle(fontSize: 13)),
              ],
            ]),
          ),
        ]),
      );
}

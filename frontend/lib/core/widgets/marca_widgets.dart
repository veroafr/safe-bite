import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rutas de las imágenes de la marca (carpeta assets/images).
class MarcaAssets {
  /// Logo completo, para fondos claros.
  static const String logo = 'assets/images/logo_safebite.png';

  /// Logo con "Safe" en blanco, para fondos verdes oscuros.
  static const String logoClaro = 'assets/images/logo_safebite_claro.png';

  /// Solo el escudo.
  static const String escudo = 'assets/images/escudo.png';
}

/// Logo de SafeBite. Con [claro] usa la versión para fondos oscuros.
class LogoSafeBite extends StatelessWidget {
  final double alto;
  final bool claro;
  const LogoSafeBite({super.key, this.alto = 36, this.claro = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      claro ? MarcaAssets.logoClaro : MarcaAssets.logo,
      height: alto,
      fit: BoxFit.contain,
      semanticLabel: 'SafeBite',
    );
  }
}

/// AppBar con el logo de SafeBite en lugar del título.
class AppBarSafeBite extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;
  const AppBarSafeBite({super.key, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: kToolbarHeight + 4,
      leading: leading,
      title: const LogoSafeBite(alto: 34, claro: true),
      actions: actions,
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.headerGradient)),
    );
  }
}

/// Encabezado verde con el logo, un título y un texto, con bordes inferiores
/// redondeados (diseño "Fresco"). [abajo] deja espacio para que contenido
/// posterior se superponga al encabezado.
class EncabezadoSafeBite extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;
  final double espacioInferior;
  const EncabezadoSafeBite({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones = const [],
    this.espacioInferior = 24,
  });

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, arriba + 14, 12, espacioInferior),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LogoSafeBite(alto: 32, claro: true),
              const Spacer(),
              ...acciones,
            ],
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 6),
            Text(subtitulo!, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

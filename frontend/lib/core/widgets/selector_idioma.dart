import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../providers/auth_provider.dart';
import '../services/usuario_service.dart';

/// Banderas para elegir el idioma: Uruguay = Español, Brasil = Português.
/// Se dibujan (no son emojis) para que se vean igual en todos los dispositivos.
class SelectorIdioma extends StatelessWidget {
  final bool claro;
  const SelectorIdioma({super.key, this.claro = false});

  @override
  Widget build(BuildContext context) {
    final actual = Idioma.instancia.codigo;
    return Tooltip(
      message: tr('Idioma de la app'),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: claro ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final codigo in Idioma.idiomas.keys)
            _BotonBandera(
              codigo: codigo,
              elegido: codigo == actual,
              onTap: () => cambiarIdiomaApp(context, codigo),
            ),
        ]),
      ),
    );
  }
}

class _BotonBandera extends StatelessWidget {
  final String codigo;
  final bool elegido;
  final VoidCallback onTap;
  const _BotonBandera({required this.codigo, required this.elegido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: Idioma.idiomas[codigo],
      child: InkWell(
        onTap: elegido ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: elegido ? const Color(0xFF6CC51D) : Colors.transparent, width: 2.5),
          ),
          child: Opacity(
            opacity: elegido ? 1 : 0.55,
            child: Bandera(codigo: codigo, ancho: 30),
          ),
        ),
      ),
    );
  }
}

/// Bandera dibujada: 'es' → Uruguay, 'pt' → Brasil.
class Bandera extends StatelessWidget {
  final String codigo;
  final double ancho;
  const Bandera({super.key, required this.codigo, this.ancho = 28});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black12, width: 0.5)),
        child: CustomPaint(
          size: Size(ancho, ancho * 2 / 3),
          painter: codigo == 'pt' ? _BanderaBrasil() : _BanderaUruguay(),
        ),
      ),
    );
  }
}

class _BanderaUruguay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final azul = Paint()..color = const Color(0xFF0038A8);
    canvas.drawRect(Offset.zero & s, Paint()..color = Colors.white);
    final franja = s.height / 9;
    for (var i = 1; i < 9; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, franja * i, s.width, franja), azul);
    }
    // Cantón blanco con el Sol de Mayo
    final canton = Rect.fromLTWH(0, 0, s.height * 5 / 9, s.height * 5 / 9);
    canvas.drawRect(canton, Paint()..color = Colors.white);
    final centro = canton.center;
    final sol = Paint()..color = const Color(0xFFFCD116);
    final r = canton.width * 0.22;
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final p = Path()
        ..moveTo(centro.dx + math.cos(a - 0.18) * r, centro.dy + math.sin(a - 0.18) * r)
        ..lineTo(centro.dx + math.cos(a) * r * 1.9, centro.dy + math.sin(a) * r * 1.9)
        ..lineTo(centro.dx + math.cos(a + 0.18) * r, centro.dy + math.sin(a + 0.18) * r)
        ..close();
      canvas.drawPath(p, sol);
    }
    canvas.drawCircle(centro, r, sol);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BanderaBrasil extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF009C3B));
    final mx = s.width * 0.085, my = s.height * 0.12;
    final rombo = Path()
      ..moveTo(s.width / 2, my)
      ..lineTo(s.width - mx, s.height / 2)
      ..lineTo(s.width / 2, s.height - my)
      ..lineTo(mx, s.height / 2)
      ..close();
    canvas.drawPath(rombo, Paint()..color = const Color(0xFFFFDF00));
    final centro = Offset(s.width / 2, s.height / 2);
    final r = s.height * 0.25;
    canvas.drawCircle(centro, r, Paint()..color = const Color(0xFF002776));
    // Franja blanca curva
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: centro, radius: r)));
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centro.dx - r * 0.4, centro.dy + r * 1.6), radius: r * 2),
      -math.pi * 0.62,
      math.pi * 0.5,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.28,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cambia el idioma y, si hay sesión, lo guarda en el perfil (sin esperar).
Future<void> cambiarIdiomaApp(BuildContext context, String codigo) async {
  final auth = context.read<AuthProvider>();
  final usuarios = context.read<UsuarioService>();
  if (auth.usuario != null) {
    usuarios.actualizarPerfil({'idioma': codigo}).then(auth.actualizarUsuario).catchError((_) {});
  }
  await Idioma.instancia.cambiar(codigo);
}

/// Fila para el perfil: "Idioma · Español" con las banderas.
class FilaIdioma extends StatelessWidget {
  const FilaIdioma({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.language),
        title: Text(tr('Idioma')),
        subtitle: Text(Idioma.idiomas[Idioma.instancia.codigo] ?? ''),
        trailing: const SelectorIdioma(),
      );
}

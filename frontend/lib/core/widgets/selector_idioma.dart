import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../providers/auth_provider.dart';
import '../services/usuario_service.dart';

/// Botón para elegir el idioma de la app (Español / Português).
/// Si hay sesión iniciada, también se guarda en el perfil de la persona.
class SelectorIdioma extends StatelessWidget {
  final bool claro;
  const SelectorIdioma({super.key, this.claro = false});

  @override
  Widget build(BuildContext context) {
    final color = claro ? Colors.white : Theme.of(context).colorScheme.primary;
    return PopupMenuButton<String>(
      tooltip: tr('Idioma de la app'),
      initialValue: Idioma.instancia.codigo,
      onSelected: (c) => cambiarIdiomaApp(context, c),
      itemBuilder: (_) => [
        for (final e in Idioma.idiomas.entries)
          PopupMenuItem(value: e.key, child: Text('${e.key == 'es' ? '🇺🇾' : '🇧🇷'}  ${e.value}')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.language, color: color, size: 20),
          const SizedBox(width: 4),
          Text(Idioma.instancia.codigo.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
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

/// Fila para el perfil: "Idioma · Español".
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

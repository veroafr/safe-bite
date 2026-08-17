import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/usuario.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/usuario_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/welcome_screen.dart';
import 'mis_alertas_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Set<TipoIntolerancia> _intolerancias;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().usuario!;
    _intolerancias = {...u.intolerancias};
  }

  Future<void> _guardarPreferencias() async {
    setState(() => _guardando = true);
    try {
      final nuevo = await context.read<UsuarioService>().actualizarPreferencias(
            intolerancias: _intolerancias,
          );
      if (mounted) {
        await context.read<AuthProvider>().actualizarUsuario(nuevo);
        mostrarMensaje(context, 'Preferencias actualizadas');
      }
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _editarDatos() async {
    final u = context.read<AuthProvider>().usuario!;
    final nombreCtrl = TextEditingController(text: u.nombre);
    final emailCtrl = TextEditingController(text: u.email);
    final ciudadCtrl = TextEditingController(text: u.ciudad ?? '');
    final paisCtrl = TextEditingController(text: u.pais ?? '');

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(controller: ciudadCtrl, decoration: const InputDecoration(labelText: 'Ciudad')),
            const SizedBox(height: 10),
            TextField(controller: paisCtrl, decoration: const InputDecoration(labelText: 'País')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (guardar == true) {
      try {
        final nuevo = await context.read<UsuarioService>().actualizarPerfil({
          'nombre': nombreCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'ciudad': ciudadCtrl.text.trim(),
          'pais': paisCtrl.text.trim(),
        });
        if (mounted) {
          await context.read<AuthProvider>().actualizarUsuario(nuevo);
          mostrarMensaje(context, 'Datos actualizados');
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _cambiarContrasena() async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: actualCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: nuevaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await context.read<UsuarioService>().cambiarPassword(actualCtrl.text, nuevaCtrl.text);
        if (mounted) mostrarMensaje(context, 'Contraseña actualizada');
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthProvider>().usuario!;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de Usuario')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: u.fotoPerfilUrl != null ? NetworkImage(u.fotoPerfilUrl!) : null,
                  child: u.fotoPerfilUrl == null ? const Icon(Icons.person, size: 42, color: AppColors.primary) : null,
                ),
                const SizedBox(height: 10),
                Text(u.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(u.email, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Datos Personales'), trailing: const Icon(Icons.chevron_right), onTap: _editarDatos),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Cambiar contraseña'), trailing: const Icon(Icons.chevron_right), onTap: _cambiarContrasena),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Mis alertas reportadas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MisAlertasScreen())),
                ),
              ],
            ),
          ),
          const SeccionTitulo('Intolerancias y Restricciones'),
          Card(
            child: Column(
              children: TipoIntolerancia.values
                  .map((t) => SwitchListTile(
                        title: Text(etiquetaIntolerancia(t)),
                        value: _intolerancias.contains(t),
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() {
                          if (v) {
                            _intolerancias.add(t);
                          } else {
                            _intolerancias.remove(t);
                          }
                        }),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _guardando ? null : _guardarPreferencias,
            child: _guardando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Actualizar Preferencias'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Cerrar sesión', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
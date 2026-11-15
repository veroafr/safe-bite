import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/usuario.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/usuario_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validadores.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../auth/welcome_screen.dart';
import 'mis_alertas_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Set<String> _intolerancias;
  late bool _comerMejor;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().usuario!;
    _intolerancias = {...u.intolerancias};
    _comerMejor = u.buscaAlimentacionSaludable;
  }

  bool _hayCambios(Usuario u) =>
      _comerMejor != u.buscaAlimentacionSaludable ||
      _intolerancias.length != u.intolerancias.length ||
      !_intolerancias.containsAll(u.intolerancias);

  Future<void> _guardarPreferencias() async {
    setState(() => _guardando = true);
    try {
      final nuevo = await context.read<UsuarioService>().actualizarPreferencias(
            intolerancias: _intolerancias,
            buscaAlimentacionSaludable: _comerMejor,
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
    String? pais = (u.pais?.isEmpty ?? true) ? null : u.pais;
    String? ciudad = (u.ciudad?.isEmpty ?? true) ? null : u.ciudad;
    final formKey = GlobalKey<FormState>();

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Editar datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => Validadores.requerido(v, 'Ingresá tu nombre'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: Validadores.email,
                  ),
                  const SizedBox(height: 10),
                  SelectorUbicacion(
                    pais: pais,
                    ciudad: ciudad,
                    obligatorio: false,
                    onChanged: (p, c) => setModal(() {
                      pais = p;
                      ciudad = c;
                    }),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (guardar == true) {
      try {
        final nuevo = await context.read<UsuarioService>().actualizarPerfil({
          'nombre': nombreCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'ciudad': ciudad ?? '',
          'pais': pais ?? '',
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CampoPassword(
                  controller: actualCtrl,
                  label: 'Contraseña actual',
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                CampoPassword(
                  controller: nuevaCtrl,
                  label: 'Nueva contraseña',
                  mostrarRequisitos: true,
                  validator: Validadores.passwordSegura,
                ),
              ],
            ),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _intolerancias.isEmpty
                        ? 'Tocá un alimento para marcarlo (o desmarcarlo).'
                        : 'Marcadas: ${_intolerancias.length}. Tocá para marcar o desmarcar.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  SelectorIntolerancias(
                    seleccionadas: _intolerancias,
                    color: AppColors.danger,
                    onChanged: (s) => setState(() => _intolerancias = s),
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Busco alimentarme mejor'),
                    subtitle: const Text('Quiero comer más sano'),
                    value: _comerMejor,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _comerMejor = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_guardando || !_hayCambios(u)) ? null : _guardarPreferencias,
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/usuario.dart';
import '../../core/services/usuario_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});
  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  late Future<List<Usuario>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<UsuarioService>().listarTodos();
  }

  void _recargar() {
    setState(() {
      _future = context.read<UsuarioService>().listarTodos();
    });
  }

  Future<void> _agregarUsuario() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    Rol rol = Rol.USUARIO;

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 10),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Contraseña inicial'), obscureText: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<Rol>(
                value: rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: Rol.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                onChanged: (v) => setModalState(() => rol = v ?? Rol.USUARIO),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nombreCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Crear'),
              ),
            ],
          ),
        );
      }),
    );

    if (guardar == true) {
      try {
        await context.read<UsuarioService>().crearAdmin({
          'nombre': nombreCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text.isEmpty ? 'safebite123' : passwordCtrl.text,
          'rol': rol.name,
        });
        if (mounted) {
          mostrarMensaje(context, 'Usuario creado');
          _recargar();
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  Future<void> _eliminar(Usuario u) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que querés eliminar a ${u.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await context.read<UsuarioService>().eliminar(u.id);
        _recargar();
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      floatingActionButton: FloatingActionButton(onPressed: _agregarUsuario, child: const Icon(Icons.add)),
      body: FutureBuilder<List<Usuario>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final usuarios = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (context, i) {
              final u = usuarios[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u.rol == Rol.ADMINISTRADOR ? AppColors.accent : AppColors.primary,
                    child: Icon(u.rol == Rol.ADMINISTRADOR ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
                  ),
                  title: Text(u.nombre),
                  subtitle: Text(u.email),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _eliminar(u)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
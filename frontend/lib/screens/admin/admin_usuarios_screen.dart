import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/usuario.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/usuario_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validadores.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../../core/widgets/recortar_imagen.dart';

/// Usuarios: buscar y editar perfiles, y atender los pedidos de "olvidé mi contraseña".
class AdminUsuariosScreen extends StatefulWidget {
  /// 0 = usuarios, 1 = pedidos de contraseña.
  final int pestanaInicial;
  const AdminUsuariosScreen({super.key, this.pestanaInicial = 0});
  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this, initialIndex: widget.pestanaInicial)..addListener(() => setState(() {}));
  final _listaKey = GlobalKey<_ListaUsuariosState>();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.lime,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Usuarios'), Tab(text: 'Pedidos de contraseña')],
        ),
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton(
              tooltip: 'Agregar usuario',
              onPressed: () => _listaKey.currentState?.agregarUsuario(),
              child: const Icon(Icons.person_add_alt_1),
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [
          _ListaUsuarios(key: _listaKey),
          const _PedidosRecuperacion(),
        ],
      ),
    );
  }
}

// =====================================================================
// Lista de usuarios
// =====================================================================

class _ListaUsuarios extends StatefulWidget {
  const _ListaUsuarios({super.key});
  @override
  State<_ListaUsuarios> createState() => _ListaUsuariosState();
}

class _ListaUsuariosState extends State<_ListaUsuarios> with AutomaticKeepAliveClientMixin {
  late Future<List<Usuario>> _future = context.read<UsuarioService>().listarTodos();
  String _busqueda = '';

  @override
  bool get wantKeepAlive => true;

  void recargar() => setState(() => _future = context.read<UsuarioService>().listarTodos());

  Future<void> _editar(Usuario u) async {
    final cambio = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => AdminEditarUsuarioScreen(usuario: u)));
    if (cambio == true) recargar();
  }

  Future<void> agregarUsuario() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: generarPassword());
    final form = GlobalKey<FormState>();
    Rol rol = Rol.USUARIO;

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Agregar usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => Validadores.requerido(v),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: Validadores.email,
                  ),
                  const SizedBox(height: 10),
                  CampoPassword(
                    controller: passwordCtrl,
                    label: 'Contraseña inicial',
                    validator: Validadores.passwordSegura,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Rol>(
                    value: rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: Rol.values.map((r) => DropdownMenuItem(value: r, child: Text(_nombreRol(r)))).toList(),
                    onChanged: (v) => setModalState(() => rol = v ?? Rol.USUARIO),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) Navigator.pop(ctx, true);
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Crear'),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );

    if (guardar == true) {
      try {
        await context.read<UsuarioService>().crearAdmin({
          'nombre': nombreCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text,
          'rol': rol.name,
        });
        if (mounted) {
          mostrarMensaje(context, 'Usuario creado');
          recargar();
        }
      } catch (e) {
        if (mounted) mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre, email o teléfono',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Usuario>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: recargar);
            final usuarios = (snapshot.data ?? [])
                .where((u) =>
                    _busqueda.isEmpty ||
                    u.nombre.toLowerCase().contains(_busqueda) ||
                    u.email.toLowerCase().contains(_busqueda) ||
                    (u.telefono ?? '').contains(_busqueda))
                .toList();
            if (usuarios.isEmpty) return const EmptyView(mensaje: 'No se encontraron usuarios');
            return RefreshIndicator(
              onRefresh: () async => recargar(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: usuarios.length,
                itemBuilder: (context, i) {
                  final u = usuarios[i];
                  return Card(
                    child: ListTile(
                      onTap: () => _editar(u),
                      leading: AvatarUsuario(usuario: u),
                      title: Row(children: [
                        Flexible(child: Text(u.nombre, overflow: TextOverflow.ellipsis)),
                        if (u.rol == Rol.ADMINISTRADOR) ...[
                          const SizedBox(width: 6),
                          Chip1('Admin', color: AppColors.accent),
                        ],
                        if (!u.activo) ...[
                          const SizedBox(width: 6),
                          Chip1('Desactivado', color: AppColors.danger),
                        ],
                      ]),
                      subtitle: Text(u.email),
                      trailing: const Icon(Icons.edit_outlined),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ]);
  }
}

String _nombreRol(Rol r) => r == Rol.ADMINISTRADOR ? 'Administrador' : 'Usuario';

class AvatarUsuario extends StatelessWidget {
  final Usuario usuario;
  final double radio;
  const AvatarUsuario({super.key, required this.usuario, this.radio = 22});

  @override
  Widget build(BuildContext context) {
    final esAdmin = usuario.rol == Rol.ADMINISTRADOR;
    final sinFoto = CircleAvatar(
      radius: radio,
      backgroundColor: esAdmin ? AppColors.accent : AppColors.primary,
      child: Icon(esAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white, size: radio),
    );
    if (usuario.fotoPerfilUrl == null) return sinFoto;
    return ClipOval(
      child: SizedBox(
        width: radio * 2,
        height: radio * 2,
        child: ImagenFlexible(fuente: usuario.fotoPerfilUrl, sinImagen: sinFoto),
      ),
    );
  }
}

// =====================================================================
// Editar usuario
// =====================================================================

class AdminEditarUsuarioScreen extends StatefulWidget {
  final Usuario usuario;
  const AdminEditarUsuarioScreen({super.key, required this.usuario});
  @override
  State<AdminEditarUsuarioScreen> createState() => _AdminEditarUsuarioScreenState();
}

class _AdminEditarUsuarioScreenState extends State<AdminEditarUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  late final Usuario u = widget.usuario;
  late final _nombre = TextEditingController(text: u.nombre);
  late final _email = TextEditingController(text: u.email);
  late final _telefono = TextEditingController(text: u.telefono ?? '');
  late String? _pais = u.pais;
  late String? _ciudad = u.ciudad;
  late Rol _rol = u.rol;
  late bool _activo = u.activo;
  late Set<String> _intolerancias = {...u.intolerancias};
  late bool _saludable = u.buscaAlimentacionSaludable;
  late NivelAlerta _nivel = u.nivelAlerta;
  Uint8List? _fotoNueva;
  bool _quitarFoto = false;
  bool _guardando = false;
  bool _huboCambios = false;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final bytes = await elegirFotoCamaraOGaleria(context, tituloCamara: 'Foto de perfil');
    if (bytes == null || !mounted) return;
    final recortada = await recortarImagen(context,
        bytes: Uint8List.fromList(bytes), proporcion: 1, anchoSalida: 400, titulo: 'Encuadrá la foto de perfil');
    if (recortada == null || !mounted) return;
    setState(() {
      _fotoNueva = recortada;
      _quitarFoto = false;
    });
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<UsuarioService>().editarAdmin(u.id, {
        'nombre': _nombre.text.trim(),
        'email': _email.text.trim(),
        'telefono': _telefono.text.trim(),
        'pais': _pais ?? '',
        'ciudad': _ciudad ?? '',
        'rol': _rol.name,
        'activo': _activo,
        'intolerancias': _intolerancias.toList(),
        'buscaAlimentacionSaludable': _saludable,
        'nivelAlerta': _nivel.name,
        if (_fotoNueva != null) 'fotoBase64': base64Encode(_fotoNueva!),
        if (_quitarFoto) 'fotoBase64': '',
      });
      if (!mounted) return;
      mostrarMensaje(context, 'Perfil actualizado');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarError(context, e);
      }
    }
  }

  Future<void> _asignarPassword() async {
    final resultado = await pedirPasswordNueva(context, nombre: u.nombre);
    if (resultado == null || !mounted) return;
    try {
      await context.read<UsuarioService>().asignarPassword(u.id, resultado.password, temporal: resultado.temporal);
      _huboCambios = true;
      if (!mounted) return;
      await mostrarPasswordAsignada(context,
          password: resultado.password, nombre: u.nombre, email: _email.text.trim(), telefono: _telefono.text.trim());
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final yo = context.watch<AuthProvider>().usuario;
    final esUnoMismo = yo?.id == u.id;
    final fotoActual = _quitarFoto ? null : u.fotoPerfilUrl;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _huboCambios);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar usuario')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(children: [
                  GestureDetector(
                    onTap: _elegirFoto,
                    child: ClipOval(
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: _fotoNueva != null
                            ? Image.memory(_fotoNueva!, fit: BoxFit.cover)
                            : ImagenFlexible(
                                fuente: fotoActual,
                                sinImagen: Container(
                                  color: AppColors.primarySoft,
                                  child: const Icon(Icons.person, size: 56, color: AppColors.primary),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      tooltip: 'Cambiar foto',
                      onPressed: _elegirFoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    ),
                  ),
                ]),
              ),
              if (_fotoNueva != null || fotoActual != null)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _fotoNueva = null;
                      _quitarFoto = true;
                    }),
                    child: const Text('Quitar foto'),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'ID ${u.id}'
                '${u.fechaRegistro != null ? ' · registrado el ${DateFormat('dd/MM/yyyy').format(u.fechaRegistro!)}' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SeccionTitulo('Datos personales'),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => Validadores.requerido(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
                validator: Validadores.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\s.-]'))],
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),
              SelectorUbicacion(
                pais: _pais,
                ciudad: _ciudad,
                obligatorio: false,
                onChanged: (p, c) => setState(() {
                  _pais = p;
                  _ciudad = c;
                }),
              ),
              const SeccionTitulo('Cuenta'),
              DropdownButtonFormField<Rol>(
                value: _rol,
                decoration: const InputDecoration(labelText: 'Rol', prefixIcon: Icon(Icons.badge_outlined)),
                items: Rol.values.map((r) => DropdownMenuItem(value: r, child: Text(_nombreRol(r)))).toList(),
                onChanged: esUnoMismo ? null : (v) => setState(() => _rol = v ?? _rol),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cuenta activa'),
                subtitle: const Text('Si la desactivás, la persona no puede iniciar sesión'),
                value: _activo,
                onChanged: esUnoMismo ? null : (v) => setState(() => _activo = v),
              ),
              OutlinedButton.icon(
                onPressed: _asignarPassword,
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Asignar contraseña nueva'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              ),
              const SeccionTitulo('Restricciones alimentarias'),
              SelectorIntolerancias(
                seleccionadas: _intolerancias,
                onChanged: (s) => setState(() => _intolerancias = s),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Busca alimentarse mejor'),
                value: _saludable,
                onChanged: (v) => setState(() => _saludable = v),
              ),
              DropdownButtonFormField<NivelAlerta>(
                value: _nivel,
                decoration: const InputDecoration(labelText: 'Nivel de alerta'),
                items: const [
                  DropdownMenuItem(value: NivelAlerta.BAJO, child: Text('Bajo')),
                  DropdownMenuItem(value: NivelAlerta.MEDIO, child: Text('Medio')),
                  DropdownMenuItem(value: NivelAlerta.ALTO, child: Text('Alto')),
                ],
                onChanged: (v) => setState(() => _nivel = v ?? _nivel),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 12),
              if (!esUnoMismo)
                TextButton.icon(
                  onPressed: _eliminar,
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  label: const Text('Eliminar usuario', style: TextStyle(color: AppColors.danger)),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que querés eliminar a ${u.nombre}? No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await context.read<UsuarioService>().eliminar(u.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }
}

// =====================================================================
// Contraseñas: generar, pedir y mostrar
// =====================================================================

/// Contraseña que cumple las reglas de la app (mayúscula, número y carácter especial).
String generarPassword() {
  final r = Random.secure();
  const mayus = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const minus = 'abcdefghijkmnpqrstuvwxyz';
  final letras = List.generate(2, (_) => minus[r.nextInt(minus.length)]).join();
  final numeros = List.generate(4, (_) => r.nextInt(10)).join();
  return 'Sb${mayus[r.nextInt(mayus.length)]}$letras#$numeros';
}

class PasswordNueva {
  final String password;
  final bool temporal;
  final String? nota;
  PasswordNueva(this.password, this.temporal, this.nota);
}

Future<PasswordNueva?> pedirPasswordNueva(BuildContext context, {required String nombre, bool conNota = false}) {
  final ctrl = TextEditingController(text: generarPassword());
  final nota = TextEditingController();
  final form = GlobalKey<FormState>();
  var temporal = true;
  return showDialog<PasswordNueva>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text('Nueva contraseña para $nombre'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CampoPassword(controller: ctrl, label: 'Contraseña', validator: Validadores.passwordSegura),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setD(() => ctrl.text = generarPassword()),
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: const Text('Generar otra'),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: temporal,
                onChanged: (v) => setD(() => temporal = v ?? true),
                title: const Text('Pedir que la cambie al entrar'),
                subtitle: const Text('Recomendado'),
              ),
              if (conNota)
                TextField(
                  controller: nota,
                  decoration: const InputDecoration(labelText: 'Nota interna (opcional)', hintText: 'Ej: verificado por teléfono'),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, PasswordNueva(ctrl.text, temporal, nota.text.trim().isEmpty ? null : nota.text.trim()));
              }
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    ),
  );
}

/// Muestra la contraseña asignada para copiarla y avisarle a la persona.
Future<void> mostrarPasswordAsignada(BuildContext context,
    {required String password, required String nombre, required String email, String? telefono}) {
  final texto = 'Hola $nombre, te escribimos de SafeBite. Tu contraseña temporal es: $password\n'
      'Entrá a la app con tu email ($email) y elegí una contraseña nueva.';
  final digitos = (telefono ?? '').replaceAll(RegExp(r'\D'), '');
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Contraseña asignada'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Comunicásela a la persona por un medio seguro:'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
          child: SelectableText(password,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: password));
            mostrarMensaje(ctx, 'Contraseña copiada');
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copiar contraseña'),
        ),
        if (digitos.length >= 8)
          TextButton.icon(
            onPressed: () => abrirEnlace(ctx, 'https://wa.me/$digitos?text=${Uri.encodeComponent(texto)}'),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Avisar por WhatsApp'),
          ),
        TextButton.icon(
          onPressed: () => abrirEnlace(ctx,
              'mailto:$email?subject=${Uri.encodeComponent('SafeBite: tu contraseña temporal')}&body=${Uri.encodeComponent(texto)}'),
          icon: const Icon(Icons.email_outlined, size: 18),
          label: const Text('Avisar por email'),
        ),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Listo'))],
    ),
  );
}

// =====================================================================
// Pedidos de recuperación de contraseña
// =====================================================================

class _PedidosRecuperacion extends StatefulWidget {
  const _PedidosRecuperacion();
  @override
  State<_PedidosRecuperacion> createState() => _PedidosRecuperacionState();
}

class _PedidosRecuperacionState extends State<_PedidosRecuperacion> with AutomaticKeepAliveClientMixin {
  String _estado = 'PENDIENTE';
  late Future<List<SolicitudRecuperacion>> _future = _cargar();

  Future<List<SolicitudRecuperacion>> _cargar() =>
      context.read<UsuarioService>().listarRecuperaciones(estado: _estado);
  void _recargar() => setState(() => _future = _cargar());

  @override
  bool get wantKeepAlive => true;

  Future<void> _resolver(SolicitudRecuperacion s) async {
    final r = await pedirPasswordNueva(context, nombre: s.usuarioNombre ?? s.email, conNota: true);
    if (r == null || !mounted) return;
    try {
      await context.read<UsuarioService>().resolverRecuperacion(s.id, r.password, nota: r.nota);
      if (!mounted) return;
      await mostrarPasswordAsignada(context,
          password: r.password,
          nombre: s.usuarioNombre ?? '',
          email: s.email,
          telefono: s.telefono ?? s.usuarioTelefono);
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _descartar(SolicitudRecuperacion s) async {
    final nota = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar pedido'),
        content: TextField(
          controller: nota,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)', hintText: 'Ej: no se pudo verificar la identidad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Descartar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<UsuarioService>().descartarRecuperacion(s.id, nota: nota.text.trim());
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _verPerfil(SolicitudRecuperacion s) async {
    try {
      final todos = await context.read<UsuarioService>().listarTodos();
      final u = todos.where((x) => x.id == s.usuarioId).firstOrNull;
      if (u == null || !mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminEditarUsuarioScreen(usuario: u)));
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Wrap(spacing: 8, children: [
          for (final (valor, texto) in const [
            ('PENDIENTE', 'Pendientes'),
            ('RESUELTA', 'Resueltos'),
            ('DESCARTADA', 'Descartados'),
          ])
            ChoiceChip(
              label: Text(texto),
              selected: _estado == valor,
              onSelected: (_) {
                _estado = valor;
                _recargar();
              },
            ),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          'Antes de asignar una contraseña, confirmá que quien pide es la dueña de la cuenta '
          '(por ejemplo, llamando al teléfono que dejó o preguntando datos de su perfil).',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<SolicitudRecuperacion>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snap.hasError) return ErrorView(mensaje: snap.error.toString(), onReintentar: _recargar);
            final lista = snap.data ?? [];
            if (lista.isEmpty) {
              return EmptyView(
                  mensaje: _estado == 'PENDIENTE' ? 'No hay pedidos de contraseña pendientes' : 'No hay pedidos en este estado',
                  icono: Icons.lock_open_rounded);
            }
            return RefreshIndicator(
              onRefresh: () async => _recargar(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lista.length,
                itemBuilder: (context, i) {
                  final s = lista[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.email, style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (s.fecha != null)
                            Text(DateFormat('dd/MM HH:mm').format(s.fecha!),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                        const SizedBox(height: 6),
                        if (s.cuentaEncontrada)
                          Text('Cuenta: ${s.usuarioNombre}${s.usuarioActivo ? '' : ' (desactivada)'}')
                        else
                          const Text('⚠ No hay ninguna cuenta con ese email',
                              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                        if ((s.telefono ?? s.usuarioTelefono) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Teléfono: ${s.telefono ?? s.usuarioTelefono}'),
                          ),
                        if (s.mensaje != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('"${s.mensaje}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ),
                        if (!s.pendiente)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${s.estado == 'RESUELTA' ? 'Resuelto' : 'Descartado'}'
                              '${s.resueltaPor != null ? ' por ${s.resueltaPor}' : ''}'
                              '${s.fechaResolucion != null ? ' el ${DateFormat('dd/MM/yyyy').format(s.fechaResolucion!)}' : ''}'
                              '${s.nota != null ? ' · ${s.nota}' : ''}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        if (s.pendiente) ...[
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            if (s.cuentaEncontrada)
                              FilledButton.icon(
                                onPressed: () => _resolver(s),
                                icon: const Icon(Icons.key_rounded, size: 18),
                                label: const Text('Asignar contraseña'),
                              ),
                            if (s.cuentaEncontrada)
                              OutlinedButton(onPressed: () => _verPerfil(s), child: const Text('Ver perfil')),
                            TextButton(onPressed: () => _descartar(s), child: const Text('Descartar')),
                          ]),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ]);
  }
}

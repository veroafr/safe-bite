import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/usuario.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/marca_widgets.dart';
import '../../core/utils/validadores.dart';
import '../../core/widgets/form_widgets.dart';
import '../usuario/usuario_home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'register_screen.dart';
import 'recuperar_password_screen.dart';
import '../../core/i18n/i18n.dart';

class LoginScreen extends StatefulWidget {
  final String idiomaInicial;
  const LoginScreen({super.key, this.idiomaInicial = 'es'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      final esAdmin = auth.usuario?.rol == Rol.ADMINISTRADOR;
      final Widget destino = esAdmin ? const AdminHomeScreen() : const UsuarioHomeScreen();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          // Contraseña temporal asignada por el admin: primero tiene que elegir una nueva.
          builder: (_) => auth.usuario?.debeCambiarPassword == true
              ? CambiarPasswordTemporalScreen(passwordActual: _passwordCtrl.text, destino: destino)
              : destino,
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Iniciar Sesión'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: LogoSafeBite(alto: 64)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: tr('Email'), prefixIcon: Icon(Icons.email_outlined)),
                  textInputAction: TextInputAction.next,
                  validator: Validadores.email,
                ),
                const SizedBox(height: 14),
                CampoPassword(
                  controller: _passwordCtrl,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _cargando ? null : _iniciarSesion(),
                  validator: (v) => (v == null || v.isEmpty) ? tr('Ingresá tu contraseña') : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => RecuperarPasswordScreen(emailInicial: _emailCtrl.text.trim()))),
                    child: Text(tr('¿Olvidaste tu contraseña?')),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  TextoT(_error!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _cargando ? null : _iniciarSesion,
                  child: _cargando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(tr('Iniciar Sesión')),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr('¿No tenés cuenta?')),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => RegisterScreen(idiomaInicial: widget.idiomaInicial))),
                      child: Text(tr('Crear Usuario')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
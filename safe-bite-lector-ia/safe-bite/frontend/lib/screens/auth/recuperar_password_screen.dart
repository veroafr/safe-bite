import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validadores.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/form_widgets.dart';

/// "¿Olvidaste tu contraseña?" en dos pasos:
/// 1) el usuario ingresa su email y el backend le envia un codigo de 6 digitos;
/// 2) ingresa el codigo y la contraseña nueva (con las mismas reglas del registro).
class RecuperarPasswordScreen extends StatefulWidget {
  final String emailInicial;
  const RecuperarPasswordScreen({super.key, this.emailInicial = ''});
  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

enum _Paso { email, codigo, listo }

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formEmail = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _codigoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _cargando = false;
  _Paso _paso = _Paso.email;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codigoCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_formEmail.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().recuperarPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _paso = _Paso.codigo);
      mostrarMensaje(context, 'Si el email está registrado, te enviamos un código.');
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _restablecer() async {
    if (!_formCodigo.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().restablecerPassword(
            email: _emailCtrl.text.trim(),
            codigo: _codigoCtrl.text.trim(),
            passwordNueva: _passCtrl.text,
          );
      if (mounted) setState(() => _paso = _Paso.listo);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _boton(String texto, VoidCallback onPressed) => ElevatedButton(
        onPressed: _cargando ? null : onPressed,
        child: _cargando
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(texto),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: switch (_paso) {
            _Paso.email => _pasoEmail(),
            _Paso.codigo => _pasoCodigo(),
            _Paso.listo => _pasoListo(),
          },
        ),
      ),
    );
  }

  Widget _pasoEmail() => Form(
        key: _formEmail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text('Ingresá el email de tu cuenta y te enviaremos un código de 6 dígitos para crear una contraseña nueva.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: Validadores.email,
              onFieldSubmitted: (_) => _enviarCodigo(),
            ),
            const SizedBox(height: 20),
            _boton('Enviar código', _enviarCodigo),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (_formEmail.currentState!.validate()) setState(() => _paso = _Paso.codigo);
              },
              child: const Text('Ya tengo un código'),
            ),
          ],
        ),
      );

  Widget _pasoCodigo() => Form(
        key: _formCodigo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Revisá tu correo (${_emailCtrl.text.trim()}). El código vence en 15 minutos.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextFormField(
              controller: _codigoCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Código de 6 dígitos', prefixIcon: Icon(Icons.pin_outlined)),
              validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : 'El código tiene 6 dígitos',
            ),
            const SizedBox(height: 8),
            CampoPassword(
              controller: _passCtrl,
              label: 'Nueva contraseña',
              mostrarRequisitos: true,
              validator: Validadores.passwordSegura,
            ),
            const SizedBox(height: 14),
            CampoPassword(
              controller: _pass2Ctrl,
              label: 'Repetí la nueva contraseña',
              validator: (v) => v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 20),
            _boton('Cambiar contraseña', _restablecer),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _cargando ? null : () => setState(() => _paso = _Paso.email),
              child: const Text('No me llegó: reenviar código'),
            ),
          ],
        ),
      );

  Widget _pasoListo() => Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text('¡Listo! Tu contraseña fue actualizada.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      );
}

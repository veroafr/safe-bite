import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validadores.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/form_widgets.dart';

/// "¿Olvidaste tu contraseña?": la persona deja su email (y si quiere un
/// teléfono) y el pedido llega al panel de administración. El equipo le
/// asigna una contraseña temporal y se la comunica; al entrar, la app le
/// pide que elija una nueva.
class RecuperarPasswordScreen extends StatefulWidget {
  final String emailInicial;
  const RecuperarPasswordScreen({super.key, this.emailInicial = ''});
  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.emailInicial);
  final _telefono = TextEditingController();
  final _mensaje = TextEditingController();
  bool _cargando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _email.dispose();
    _telefono.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().recuperarPassword(
            _email.text.trim(),
            telefono: _telefono.text.trim(),
            mensaje: _mensaje.text.trim(),
          );
      if (mounted) setState(() => _enviado = true);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _enviado ? _listo() : _formulario(),
        ),
      ),
    );
  }

  Widget _formulario() => Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Escribí el email de tu cuenta. Tu pedido le llega al equipo de SafeBite, que te va a asignar '
              'una contraseña temporal y se va a comunicar con vos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email de tu cuenta *', prefixIcon: Icon(Icons.email_outlined)),
              validator: Validadores.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\s.-]'))],
              decoration: const InputDecoration(
                labelText: 'Teléfono o WhatsApp (opcional)',
                helperText: 'Para avisarte más rápido',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '').length;
                return d == 0 || (d >= 8 && d <= 15) ? null : 'Revisá el número';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _mensaje,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Ej: cambié de celular y no recuerdo la contraseña',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargando ? null : _enviar,
              child: _cargando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar pedido'),
            ),
          ],
        ),
      );

  Widget _listo() => Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text('¡Pedido enviado!',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'El equipo de SafeBite va a revisar tu pedido y te va a enviar una contraseña temporal. '
            'Cuando entres con ella, la app te va a pedir que elijas una nueva.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      );
}

/// Pantalla obligatoria cuando el administrador asignó una contraseña temporal.
class CambiarPasswordTemporalScreen extends StatefulWidget {
  final String passwordActual;
  final Widget destino;
  const CambiarPasswordTemporalScreen({super.key, required this.passwordActual, required this.destino});
  @override
  State<CambiarPasswordTemporalScreen> createState() => _CambiarPasswordTemporalScreenState();
}

class _CambiarPasswordTemporalScreenState extends State<CambiarPasswordTemporalScreen> {
  final _form = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await context.read<AuthProvider>().cambiarPasswordTemporal(widget.passwordActual, _pass.text);
      if (!mounted) return;
      mostrarMensaje(context, 'Contraseña actualizada');
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => widget.destino), (_) => false);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elegí una contraseña nueva'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.key_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                'Entraste con una contraseña temporal que te dio el equipo de SafeBite. '
                'Por seguridad, elegí una contraseña nueva que solo vos conozcas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CampoPassword(
                controller: _pass,
                label: 'Nueva contraseña',
                mostrarRequisitos: true,
                validator: (v) => v == widget.passwordActual
                    ? 'Tiene que ser distinta a la temporal'
                    : Validadores.passwordSegura(v),
              ),
              const SizedBox(height: 14),
              CampoPassword(
                controller: _pass2,
                label: 'Repetí la nueva contraseña',
                validator: (v) => v != _pass.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar contraseña'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

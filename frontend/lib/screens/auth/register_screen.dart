import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/widgets/foto_perfil_widget.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validadores.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../usuario/usuario_home_screen.dart';
import '../../core/i18n/i18n.dart';

class RegisterScreen extends StatefulWidget {
  final String idiomaInicial;
  const RegisterScreen({super.key, this.idiomaInicial = 'es'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();
  String? _pais;
  String? _ciudad;
  Set<String> _intolerancias = {};
  bool _comerMejor = false;
  Uint8List? _foto;
  bool _cargando = false;
  bool _intentoEnviar = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  bool get _restriccionValida => _intolerancias.isNotEmpty || _comerMejor;

  Future<void> _registrarse() async {
    setState(() => _intentoEnviar = true);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || !_restriccionValida) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.registrar(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        ciudad: _ciudad,
        pais: _pais,
        idioma: Idioma.instancia.codigo,
        intolerancias: _intolerancias,
        buscaAlimentacionSaludable: _comerMejor,
        fotoBase64: _foto != null ? base64Encode(_foto!) : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UsuarioHomeScreen()),
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
      appBar: AppBar(title: Text(tr('Crear Usuario'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: FotoPerfilEditable(
                    bytes: _foto,
                    onCambiar: () async {
                      final f = await elegirFotoDePerfil(context);
                      if (f != null && mounted) setState(() => _foto = f);
                    },
                    onQuitar: () => setState(() => _foto = null),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: tr('Nombre completo'), prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => Validadores.requerido(v, tr('Ingresá tu nombre')),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: tr('Email'),
                    hintText: 'nombre@dominio.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validadores.email,
                ),
                const SizedBox(height: 14),
                CampoPassword(
                  controller: _passwordCtrl,
                  mostrarRequisitos: true,
                  validator: Validadores.passwordSegura,
                ),
                const SizedBox(height: 14),
                CampoPassword(
                  controller: _password2Ctrl,
                  label: tr('Repetir la contraseña'),
                  validator: (v) => v != _passwordCtrl.text ? tr('Las contraseñas no coinciden') : null,
                ),
                const SizedBox(height: 14),
                SelectorUbicacion(
                  pais: _pais,
                  ciudad: _ciudad,
                  onChanged: (p, c) => setState(() {
                    _pais = p;
                    _ciudad = c;
                  }),
                ),
                const SizedBox(height: 24),
                Text(tr('Restricción alimentaria'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  tr('Marcá los alimentos a los que tenés alergia o intolerancia. Podés cambiarlos después desde tu perfil.'),
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                SelectorIntolerancias(
                  seleccionadas: _intolerancias,
                  color: AppColors.danger,
                  onChanged: (s) => setState(() => _intolerancias = s),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(_comerMejor ? 0.12 : 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    value: _comerMejor,
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(tr('Busco alimentarme mejor'), style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(tr('No tengo (solo) una restricción: quiero comer más sano.')),
                    onChanged: (v) => setState(() => _comerMejor = v ?? false),
                  ),
                ),
                if (_intentoEnviar && !_restriccionValida)
                  Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(tr('Elegí al menos una restricción o "Busco alimentarme mejor"'),
                        style: TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  TextoT(_error!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _cargando ? null : _registrarse,
                  child: _cargando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(tr('Crear cuenta')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

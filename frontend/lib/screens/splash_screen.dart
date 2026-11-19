import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/intolerancias_provider.dart';
import '../core/models/usuario.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/marca_widgets.dart';
import 'auth/welcome_screen.dart';
import 'usuario/usuario_home_screen.dart';
import 'admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  Future<void> _iniciar() async {
    final auth = context.read<AuthProvider>();
    // Se precarga la lista de intolerancias (nombres para chips y filtros).
    context.read<IntoleranciasProvider>().cargar();
    await auth.cargarSesionGuardada();
    if (!mounted) return;
    // Quedó pendiente cambiar una contraseña temporal: se vuelve a pedir el login.
    if (auth.usuario?.debeCambiarPassword == true) await auth.logout();
    if (!mounted) return;

    if (auth.estado == EstadoAuth.autenticado) {
      final esAdmin = auth.usuario?.rol == Rol.ADMINISTRADOR;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => esAdmin ? const AdminHomeScreen() : const UsuarioHomeScreen(),
      ));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LogoSafeBite(alto: 80, claro: true),
              const SizedBox(height: 12),
              Text('Elegí mejor qué comer, a tu medida',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 28),
              const CircularProgressIndicator(color: AppColors.lime),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/models/usuario.dart';
import '../core/theme/app_theme.dart';
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
    await auth.cargarSesionGuardada();
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
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, color: AppColors.primary, size: 72),
            SizedBox(height: 12),
            Text('Safe-Bite',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
            SizedBox(height: 4),
            Text('Tu compañero alimentario seguro', style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

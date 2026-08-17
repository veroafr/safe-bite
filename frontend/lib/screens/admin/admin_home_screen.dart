import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/welcome_screen.dart';
import 'admin_restaurantes_screen.dart';
import 'admin_alertas_screen.dart';
import 'admin_noticias_screen.dart';
import 'admin_usuarios_screen.dart';
import 'admin_recetas_screen.dart';
import 'admin_reportes_screen.dart';
import 'admin_productos_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    final modulos = [
      _ModuloAdmin('Gestión de Productos', Icons.qr_code_2, const AdminProductosScreen()),
      _ModuloAdmin('Gestión de Restaurantes', Icons.restaurant, const AdminRestaurantesScreen()),
      _ModuloAdmin('Gestión de Alertas', Icons.report_gmailerrorred, const AdminAlertasScreen()),
      _ModuloAdmin('Gestión de Noticias', Icons.newspaper, const AdminNoticiasScreen()),
      _ModuloAdmin('Gestión de Recetas', Icons.menu_book, const AdminRecetasScreen()),
      _ModuloAdmin('Gestión de Usuarios', Icons.people, const AdminUsuariosScreen()),
      _ModuloAdmin('Reportes y Estadísticas', Icons.bar_chart, const AdminReportesScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: AppColors.primary.withOpacity(0.08),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.admin_panel_settings, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario?.nombre ?? 'Administrador', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(usuario?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.1),
              itemCount: modulos.length,
              itemBuilder: (context, i) {
                final m = modulos[i];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => m.pantalla)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(m.icono, size: 34, color: AppColors.primary),
                          const SizedBox(height: 10),
                          Text(m.titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuloAdmin {
  final String titulo;
  final IconData icono;
  final Widget pantalla;
  _ModuloAdmin(this.titulo, this.icono, this.pantalla);
}

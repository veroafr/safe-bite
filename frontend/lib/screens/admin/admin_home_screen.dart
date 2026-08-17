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

    // Luego estos números pueden venir del backend.
    const int totalProductos = 126;
    const int totalUsuarios = 84;
    const int totalRestaurantes = 18;
    const int totalAlertas = 7;

    final modulos = [
      _ModuloAdmin(
        titulo: 'Productos',
        subtitulo: 'Administrar catálogo',
        icono: Icons.inventory_2_rounded,
        pantalla: const AdminProductosScreen(),
        notificaciones: 5,
      ),
      _ModuloAdmin(
        titulo: 'Restaurantes',
        subtitulo: 'Locales registrados',
        icono: Icons.storefront_rounded,
        pantalla: const AdminRestaurantesScreen(),
        notificaciones: 2,
      ),
      _ModuloAdmin(
        titulo: 'Alertas',
        subtitulo: 'Revisar incidencias',
        icono: Icons.warning_amber_rounded,
        pantalla: const AdminAlertasScreen(),
        notificaciones: 7,
      ),
      _ModuloAdmin(
        titulo: 'Noticias',
        subtitulo: 'Publicaciones',
        icono: Icons.newspaper_rounded,
        pantalla: const AdminNoticiasScreen(),
        notificaciones: 1,
      ),
      _ModuloAdmin(
        titulo: 'Recetas',
        subtitulo: 'Contenido gastronómico',
        icono: Icons.menu_book_rounded,
        pantalla: const AdminRecetasScreen(),
        notificaciones: 0,
      ),
      _ModuloAdmin(
        titulo: 'Usuarios',
        subtitulo: 'Gestionar cuentas',
        icono: Icons.groups_rounded,
        pantalla: const AdminUsuariosScreen(),
        notificaciones: 3,
      ),
      _ModuloAdmin(
        titulo: 'Reportes',
        subtitulo: 'Estadísticas del sistema',
        icono: Icons.analytics_rounded,
        pantalla: const AdminReportesScreen(),
        notificaciones: 2,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'SafeBite Admin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF212121),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF616161),
            ),
            onPressed: () async {
              await context.read<AuthProvider>().logout();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // CABECERA
            // =========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${usuario?.nombre ?? 'Administrador'} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          usuario?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.82),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Resumen general',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            // =========================
            // TARJETAS KPI
            // =========================

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.45,
              children: const [
                _StatCard(
                  titulo: 'Productos',
                  valor: '$totalProductos',
                  icono: Icons.inventory_2_rounded,
                  color: Color(0xFF7C4DFF),
                ),
                _StatCard(
                  titulo: 'Usuarios',
                  valor: '$totalUsuarios',
                  icono: Icons.people_alt_rounded,
                  color: Color(0xFF00B8D4),
                ),
                _StatCard(
                  titulo: 'Restaurantes',
                  valor: '$totalRestaurantes',
                  icono: Icons.storefront_rounded,
                  color: Color(0xFF00C853),
                ),
                _StatCard(
                  titulo: 'Alertas',
                  valor: '$totalAlertas',
                  icono: Icons.warning_amber_rounded,
                  color: Color(0xFFFF5252),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // =========================
            // GRÁFICO
            // =========================

            const _ActividadCard(),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Administración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${modulos.length} módulos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // =========================
            // MÓDULOS
            // =========================

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modulos.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: .95,
              ),
              itemBuilder: (context, index) {
                final modulo = modulos[index];

                return _ModuloCard(
                  modulo: modulo,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => modulo.pantalla,
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CARD ESTADÍSTICA
// ======================================================

class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icono,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// GRÁFICO SIMPLE
// ======================================================

class _ActividadCard extends StatelessWidget {
  const _ActividadCard();

  @override
  Widget build(BuildContext context) {
    final valores = [
      0.35,
      0.58,
      0.42,
      0.72,
      0.55,
      0.83,
      0.67,
    ];

    final dias = [
      'L',
      'M',
      'M',
      'J',
      'V',
      'S',
      'D',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividad semanal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Registros realizados en SafeBite',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                valores.length,
                (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment:
                                  Alignment.bottomCenter,
                              child:
                                  FractionallySizedBox(
                                heightFactor:
                                    valores[index],
                                child: Container(
                                  decoration:
                                      BoxDecoration(
                                    gradient:
                                        LinearGradient(
                                      begin:
                                          Alignment.topCenter,
                                      end: Alignment
                                          .bottomCenter,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary
                                            .withOpacity(.45),
                                      ],
                                    ),
                                    borderRadius:
                                        const BorderRadius
                                            .vertical(
                                      top:
                                          Radius.circular(
                                              8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dias[index],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// CARD MÓDULO
// ======================================================

class _ModuloCard extends StatelessWidget {
  final _ModuloAdmin modulo;
  final VoidCallback onTap;

  const _ModuloCard({
    required this.modulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(.1),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Icon(
                      modulo.icono,
                      color: AppColors.primary,
                      size: 27,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    modulo.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    modulo.subtitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Row(
                    children: [
                      Text(
                        'Abrir',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),

              // BADGE DE NOTIFICACIONES
              if (modulo.notificaciones > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 25,
                      minHeight: 25,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4F),
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      modulo.notificaciones > 99
                          ? '99+'
                          : modulo.notificaciones
                              .toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// MODELO
// ======================================================

class _ModuloAdmin {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget pantalla;
  final int notificaciones;

  const _ModuloAdmin({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.pantalla,
    this.notificaciones = 0,
  });
}

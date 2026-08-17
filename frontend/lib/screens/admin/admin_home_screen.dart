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

    // =====================================================
    // DATOS TEMPORALES
    // Estos números representan PENDIENTES / NUEVOS.
    // Después deben venir desde tu backend.
    // =====================================================

    const int productosNuevos = 3;
    const int restaurantesPendientes = 2;
    const int alertasPendientes = 5;
    const int usuariosPendientes = 1;

    const int noticiasPendientes = 1;
    const int recetasPendientes = 0;
    const int reportesPendientes = 2;

    final modulos = [
      _ModuloAdmin(
        titulo: 'Productos',
        subtitulo: 'Gestionar productos',
        icono: Icons.inventory_2_rounded,
        pantalla: const AdminProductosScreen(),
        notificaciones: productosNuevos,
        color: const Color(0xFF7C4DFF),
      ),
      _ModuloAdmin(
        titulo: 'Restaurantes',
        subtitulo: 'Gestionar locales',
        icono: Icons.storefront_rounded,
        pantalla: const AdminRestaurantesScreen(),
        notificaciones: restaurantesPendientes,
        color: const Color(0xFF00C853),
      ),
      _ModuloAdmin(
        titulo: 'Alertas',
        subtitulo: 'Revisar incidencias',
        icono: Icons.warning_amber_rounded,
        pantalla: const AdminAlertasScreen(),
        notificaciones: alertasPendientes,
        color: const Color(0xFFFF5252),
      ),
      _ModuloAdmin(
        titulo: 'Noticias',
        subtitulo: 'Gestionar noticias',
        icono: Icons.newspaper_rounded,
        pantalla: const AdminNoticiasScreen(),
        notificaciones: noticiasPendientes,
        color: const Color(0xFFFF9800),
      ),
      _ModuloAdmin(
        titulo: 'Recetas',
        subtitulo: 'Gestionar recetas',
        icono: Icons.menu_book_rounded,
        pantalla: const AdminRecetasScreen(),
        notificaciones: recetasPendientes,
        color: const Color(0xFF009688),
      ),
      _ModuloAdmin(
        titulo: 'Usuarios',
        subtitulo: 'Gestionar usuarios',
        icono: Icons.groups_rounded,
        pantalla: const AdminUsuariosScreen(),
        notificaciones: usuariosPendientes,
        color: const Color(0xFF00B8D4),
      ),
      _ModuloAdmin(
        titulo: 'Reportes',
        subtitulo: 'Ver estadísticas',
        icono: Icons.analytics_rounded,
        pantalla: const AdminReportesScreen(),
        notificaciones: reportesPendientes,
        color: const Color(0xFF3F51B5),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
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
              color: Color(0xFF555555),
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
          const SizedBox(width: 4),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth =
              constraints.maxWidth > 900 ? 900 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: maxWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================================
                    // CABECERA
                    // =====================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(.76),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(.16),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${usuario?.nombre ?? 'Administrador'} 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  usuario?.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =====================================================
                    // PENDIENTES
                    // =====================================================

                    const Text(
                      'Pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Elementos que necesitan revisión o aprobación.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),

                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount:
                          constraints.maxWidth < 360 ? 1 : 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,

                      // Cards mucho más bajas que antes
                      childAspectRatio:
                          constraints.maxWidth < 360 ? 4.2 : 2.7,

                      children: [
                        _PendingCard(
                          titulo: 'Productos nuevos',
                          valor: productosNuevos,
                          icono: Icons.inventory_2_rounded,
                          color: const Color(0xFF7C4DFF),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminProductosScreen(),
                              ),
                            );
                          },
                        ),

                        _PendingCard(
                          titulo: 'Restaurantes',
                          valor: restaurantesPendientes,
                          icono: Icons.storefront_rounded,
                          color: const Color(0xFF00C853),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminRestaurantesScreen(),
                              ),
                            );
                          },
                        ),

                        _PendingCard(
                          titulo: 'Alertas',
                          valor: alertasPendientes,
                          icono: Icons.warning_amber_rounded,
                          color: const Color(0xFFFF5252),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminAlertasScreen(),
                              ),
                            );
                          },
                        ),

                        _PendingCard(
                          titulo: 'Usuarios',
                          valor: usuariosPendientes,
                          icono: Icons.person_search_rounded,
                          color: const Color(0xFF00B8D4),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminUsuariosScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // =====================================================
                    // ACTIVIDAD
                    // =====================================================

                    const _ActividadCard(),

                    const SizedBox(height: 24),

                    // =====================================================
                    // ADMINISTRACIÓN
                    // =====================================================

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Administración',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${modulos.length} módulos',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modulos.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            constraints.maxWidth < 360 ? 1 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio:
                            constraints.maxWidth < 360 ? 3.4 : 1.75,
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// TARJETA DE PENDIENTES
// =====================================================

class _PendingCard extends StatelessWidget {
  final String titulo;
  final int valor;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _PendingCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool tienePendientes = valor > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tienePendientes
                  ? color.withOpacity(.15)
                  : const Color(0xFFEEEEEE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.025),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          valor.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: tienePendientes
                                ? const Color(0xFF222222)
                                : Colors.grey,
                          ),
                        ),

                        if (tienePendientes) ...[
                          const SizedBox(width: 5),

                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 1),

                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ACTIVIDAD DEL SISTEMA
// =====================================================

class _ActividadCard extends StatelessWidget {
  const _ActividadCard();

  @override
  Widget build(BuildContext context) {
    // Ejemplo temporal.
    // Después estos valores pueden venir del backend.
    final valores = <double>[
      .32,
      .55,
      .41,
      .68,
      .51,
      .82,
      .64,
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
      padding: const EdgeInsets.fromLTRB(
        16,
        15,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividad semanal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Movimientos recientes en SafeBite',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 105,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                valores.length,
                (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: valores[index],
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(.42),
                                      ],
                                    ),
                                    borderRadius:
                                        const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            dias[index],
                            style: const TextStyle(
                              fontSize: 9.5,
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

// =====================================================
// TARJETA DE MÓDULO
// =====================================================

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
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.025),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: modulo.color.withOpacity(.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      modulo.icono,
                      color: modulo.color,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modulo.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          modulo.subtitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 5),

                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFBDBDBD),
                  ),
                ],
              ),

              // =================================================
              // BADGE
              // Solo aparece cuando hay pendientes.
              // =================================================
              if (modulo.notificaciones > 0)
                Positioned(
                  top: 0,
                  right: 1,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4545),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      modulo.notificaciones > 99
                          ? '99+'
                          : modulo.notificaciones.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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

// =====================================================
// MODELO DE MÓDULO
// =====================================================

class _ModuloAdmin {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget pantalla;
  final int notificaciones;
  final Color color;

  const _ModuloAdmin({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.pantalla,
    required this.color,
    this.notificaciones = 0,
  });
}

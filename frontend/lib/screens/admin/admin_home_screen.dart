import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/alerta.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/alerta_service.dart';
import '../../core/services/producto_service.dart';
import '../../core/theme/app_theme.dart';

import '../auth/welcome_screen.dart';
import 'admin_restaurantes_screen.dart';
import 'admin_alertas_screen.dart';
import 'admin_noticias_screen.dart';
import 'admin_usuarios_screen.dart';
import 'admin_recetas_screen.dart';
import 'admin_reportes_screen.dart';
import 'admin_productos_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _productosPendientes = 0;
  int _alertasPendientes = 0;

  bool _cargando = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPendientes();
    });
  }

  // =========================================================
  // CARGA LOS PENDIENTES REALES DEL BACKEND
  // =========================================================

  Future<void> _cargarPendientes() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _error = false;
    });

    try {
      final productoService = context.read<ProductoService>();
      final alertaService = context.read<AlertaService>();

      final resultados = await Future.wait([
        productoService.listarPendientes(),
        alertaService.listarPorEstado(
          estado: EstadoAlerta.PENDIENTE,
        ),
      ]);

      final productos = resultados[0] as List;
      final alertas = resultados[1] as List;

      if (!mounted) return;

      setState(() {
        _productosPendientes = productos.length;
        _alertasPendientes = alertas.length;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _productosPendientes = 0;
        _alertasPendientes = 0;
        _cargando = false;
        _error = true;
      });
    }
  }

  int get _totalPendientes =>
      _productosPendientes + _alertasPendientes;

  // =========================================================
  // ABRIR PANTALLA Y ACTUALIZAR AL VOLVER
  // =========================================================

  Future<void> _abrirPantalla(Widget pantalla) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => pantalla,
      ),
    );

    // Cuando el administrador vuelve de revisar algo,
    // volvemos a consultar el backend.
    if (mounted) {
      await _cargarPendientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    final modulos = [
      _ModuloAdmin(
        titulo: 'Productos',
        subtitulo: 'Gestionar catálogo',
        icono: Icons.inventory_2_rounded,
        pantalla: const AdminProductosScreen(),
        notificaciones: _productosPendientes,
        color: const Color(0xFF7C4DFF),
      ),
      _ModuloAdmin(
        titulo: 'Restaurantes',
        subtitulo: 'Gestionar locales',
        icono: Icons.storefront_rounded,
        pantalla: const AdminRestaurantesScreen(),
        notificaciones: 0,
        color: const Color(0xFF00C853),
      ),
      _ModuloAdmin(
        titulo: 'Alertas',
        subtitulo: 'Revisar incidencias',
        icono: Icons.warning_amber_rounded,
        pantalla: const AdminAlertasScreen(),
        notificaciones: _alertasPendientes,
        color: const Color(0xFFFF5252),
      ),
      _ModuloAdmin(
        titulo: 'Noticias',
        subtitulo: 'Gestionar noticias',
        icono: Icons.newspaper_rounded,
        pantalla: const AdminNoticiasScreen(),
        notificaciones: 0,
        color: const Color(0xFFFF9800),
      ),
      _ModuloAdmin(
        titulo: 'Recetas',
        subtitulo: 'Gestionar recetas',
        icono: Icons.menu_book_rounded,
        pantalla: const AdminRecetasScreen(),
        notificaciones: 0,
        color: const Color(0xFF009688),
      ),
      _ModuloAdmin(
        titulo: 'Usuarios',
        subtitulo: 'Gestionar usuarios',
        icono: Icons.groups_rounded,
        pantalla: const AdminUsuariosScreen(),
        notificaciones: 0,
        color: const Color(0xFF00B8D4),
      ),
      _ModuloAdmin(
        titulo: 'Reportes',
        subtitulo: 'Ver estadísticas',
        icono: Icons.analytics_rounded,
        pantalla: const AdminReportesScreen(),
        notificaciones: 0,
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
          // Actualizar manualmente
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF555555),
            ),
            onPressed: _cargando ? null : _cargarPendientes,
          ),

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

      body: RefreshIndicator(
        onRefresh: _cargarPendientes,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double contentWidth =
                constraints.maxWidth > 900
                    ? 900
                    : constraints.maxWidth;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      14,
                      14,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // =============================================
                        // CABECERA
                        // =============================================

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
                                color:
                                    AppColors.primary.withOpacity(.16),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(.18),
                                  borderRadius:
                                      BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons
                                      .admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hola, ${usuario?.nombre ?? 'Administrador'} 👋',
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      usuario?.email ?? '',
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(.85),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // =============================================
                        // PENDIENTES
                        // =============================================

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Pendientes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            if (!_cargando &&
                                _totalPendientes > 0)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_totalPendientes pendientes',
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Elementos que necesitan tu revisión.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (_cargando)

                          // =========================================
                          // CARGANDO
                          // =========================================

                          const _CargandoPendientes()

                        else if (_error)

                          // =========================================
                          // ERROR
                          // =========================================

                          _ErrorPendientes(
                            onReintentar: _cargarPendientes,
                          )

                        else if (_totalPendientes == 0)

                          // =========================================
                          // TODO AL DÍA
                          // =========================================

                          const _TodoAlDiaCard()

                        else

                          // =========================================
                          // PENDIENTES REALES
                          // =========================================

                          _buildPendientesGrid(
                            constraints,
                          ),

                        const SizedBox(height: 24),

                        // =============================================
                        // ADMINISTRACIÓN
                        // =============================================

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
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: modulos.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                constraints.maxWidth < 360
                                    ? 1
                                    : 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio:
                                constraints.maxWidth < 360
                                    ? 3.5
                                    : 2.15,
                          ),
                          itemBuilder: (context, index) {
                            final modulo = modulos[index];

                            return _ModuloCard(
                              modulo: modulo,
                              onTap: () {
                                _abrirPantalla(
                                  modulo.pantalla,
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // =============================================
                        // ACTIVIDAD
                        // =============================================

                        const _ActividadCard(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =============================================================
  // GRID DE PENDIENTES
  // Solo aparecen tarjetas que realmente tienen elementos.
  // =============================================================

  Widget _buildPendientesGrid(
    BoxConstraints constraints,
  ) {
    final tarjetas = <Widget>[];

    if (_productosPendientes > 0) {
      tarjetas.add(
        _PendingCard(
          titulo: 'Productos por revisar',
          valor: _productosPendientes,
          icono: Icons.inventory_2_rounded,
          color: const Color(0xFF7C4DFF),
          onTap: () {
            _abrirPantalla(
              const AdminProductosScreen(),
            );
          },
        ),
      );
    }

    if (_alertasPendientes > 0) {
      tarjetas.add(
        _PendingCard(
          titulo: 'Alertas por revisar',
          valor: _alertasPendientes,
          icono: Icons.warning_amber_rounded,
          color: const Color(0xFFFF5252),
          onTap: () {
            _abrirPantalla(
              const AdminAlertasScreen(),
            );
          },
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount:
          constraints.maxWidth < 360 ? 1 : 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio:
          constraints.maxWidth < 360 ? 4.5 : 3.0,
      children: tarjetas,
    );
  }
}

// =============================================================
// TODO AL DÍA
// =============================================================

class _TodoAlDiaCard extends StatelessWidget {
  const _TodoAlDiaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50)
              .withOpacity(.15),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D32),
            size: 28,
          ),

          SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo al día',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No hay elementos pendientes de revisión.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF558B2F),
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

// =============================================================
// CARGANDO
// =============================================================

class _CargandoPendientes extends StatelessWidget {
  const _CargandoPendientes();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

// =============================================================
// ERROR DE CARGA
// =============================================================

class _ErrorPendientes extends StatelessWidget {
  final VoidCallback onReintentar;

  const _ErrorPendientes({
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFF57C00),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'No se pudieron consultar los pendientes.',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),

          TextButton(
            onPressed: onReintentar,
            child: const Text(
              'Reintentar',
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TARJETA DE PENDIENTE
// =============================================================

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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      valor.toString(),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// TARJETA DEL MÓDULO
// =============================================================

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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.02),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration: BoxDecoration(
                      color:
                          modulo.color.withOpacity(.10),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      modulo.icono,
                      color: modulo.color,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          modulo.titulo,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          modulo.subtitulo,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 7),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFBDBDBD),
                    size: 19,
                  ),
                ],
              ),

              // Badge SOLO si realmente hay pendientes
              if (modulo.notificaciones > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFF4545),
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
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w800,
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

// =============================================================
// ACTIVIDAD
// =============================================================

class _ActividadCard extends StatelessWidget {
  const _ActividadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Reportes y estadísticas',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Consulta la información general de SafeBite.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
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

// =============================================================
// MODELO
// =============================================================

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

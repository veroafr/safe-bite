import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/restaurante_service.dart';
import 'core/services/receta_service.dart';
import 'core/services/noticia_service.dart';
import 'core/services/producto_service.dart';
import 'core/services/alerta_service.dart';
import 'core/services/usuario_service.dart';
import 'core/services/reporte_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<RestauranteService>(create: (_) => RestauranteService(apiClient)),
        Provider<RecetaService>(create: (_) => RecetaService(apiClient)),
        Provider<NoticiaService>(create: (_) => NoticiaService(apiClient)),
        Provider<ProductoService>(create: (_) => ProductoService(apiClient)),
        Provider<AlertaService>(create: (_) => AlertaService(apiClient)),
        Provider<UsuarioService>(create: (_) => UsuarioService(apiClient)),
        Provider<ReporteService>(create: (_) => ReporteService(apiClient)),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(apiClient)),
      ],
      child: const SafeBiteApp(),
    ),
  );
}

class SafeBiteApp extends StatelessWidget {
  const SafeBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe-Bite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}

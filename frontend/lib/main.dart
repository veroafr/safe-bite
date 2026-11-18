import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/intolerancias_provider.dart';
import 'core/providers/filtro_escaner_provider.dart';
import 'core/services/restaurante_service.dart';
import 'core/services/receta_service.dart';
import 'core/services/noticia_service.dart';
import 'core/services/producto_service.dart';
import 'core/services/alerta_service.dart';
import 'core/services/usuario_service.dart';
import 'core/services/reporte_service.dart';
import 'core/services/intolerancia_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  // En la versión web el lector de códigos usa la librería ZXing. Se sirve
  // desde la propia app (web/zxing) en lugar de descargarla de unpkg.com en
  // cada uso: si ese sitio falla o cambia, el lector deja de reconocer códigos.
  if (kIsWeb) {
    MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl('zxing/index.min.js');
  }

  final apiClient = ApiClient();
  final intoleranciaService = IntoleranciaService(apiClient);

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
        Provider<IntoleranciaService>.value(value: intoleranciaService),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(apiClient)),
        // Lista de intolerancias del sistema (dinamica: el admin puede agregar nuevas)
        // (la primera carga la dispara SplashScreen)
        ChangeNotifierProvider<IntoleranciasProvider>(create: (_) => IntoleranciasProvider(intoleranciaService)),
        ChangeNotifierProvider<FiltroEscanerProvider>(create: (_) => FiltroEscanerProvider()),
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
      title: 'SafeBite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}

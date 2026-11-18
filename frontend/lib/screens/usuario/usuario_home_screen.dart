import 'package:flutter/material.dart';
import 'restaurantes_list_screen.dart';
import 'recetas_screen.dart';
import 'escaner_screen.dart';
import 'noticias_screen.dart';
import 'perfil_screen.dart';

/// Dashboard del Usuario con navegacion inferior a los 5 modulos
/// principales del wireframe: Restaurantes, Recetas, Escaner, Noticias, Perfil.
class UsuarioHomeScreen extends StatefulWidget {
  const UsuarioHomeScreen({super.key});
  @override
  State<UsuarioHomeScreen> createState() => _UsuarioHomeScreenState();
}

class _UsuarioHomeScreenState extends State<UsuarioHomeScreen> {
  int _index = 0;

  final _screens = const [
    RestaurantesListScreen(),
    RecetasScreen(),
    EscanerScreen(),
    NoticiasScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Restaurantes'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Recetas'),
          NavigationDestination(icon: Icon(Icons.barcode_reader), selectedIcon: Icon(Icons.barcode_reader), label: 'Escáner'),
          NavigationDestination(icon: Icon(Icons.newspaper_outlined), selectedIcon: Icon(Icons.newspaper), label: 'Noticias'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

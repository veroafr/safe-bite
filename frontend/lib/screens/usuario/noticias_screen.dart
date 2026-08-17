import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/noticia.dart';
import '../../core/services/noticia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});
  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  late Future<List<Noticia>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<NoticiaService>().listar();
  }

  void _recargar() {
    setState(() {
      _future = context.read<NoticiaService>().listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noticias')),
      body: FutureBuilder<List<Noticia>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
          final noticias = snapshot.data ?? [];
          if (noticias.isEmpty) return const EmptyView(mensaje: 'No hay noticias por el momento', icono: Icons.newspaper_outlined);
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: noticias.length,
              itemBuilder: (context, i) {
                final n = noticias[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoticiaDetailScreen(noticia: n))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.imagenUrl != null)
                          Image.network(n.imagenUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(height: 140, color: const Color(0xFFE0E0E0))),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              if (n.resumen != null) Text(n.resumen!, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text(DateFormat('dd/MM/yyyy').format(n.fechaPublicacion),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NoticiaDetailScreen extends StatelessWidget {
  final Noticia noticia;
  const NoticiaDetailScreen({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noticia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (noticia.imagenUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(noticia.imagenUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 180, color: const Color(0xFFE0E0E0))),
            ),
          const SizedBox(height: 12),
          Text(noticia.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(DateFormat('dd/MM/yyyy').format(noticia.fechaPublicacion),
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Text(noticia.contenido ?? '', style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
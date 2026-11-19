import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/intolerancia.dart';
import '../../core/models/noticia.dart';
import '../../core/services/noticia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/intolerancias_widgets.dart';
import '../../core/i18n/i18n.dart';

/// Noticias: las que publica el administrador y las que se importan
/// automáticamente de medios de Uruguay y Brasil (RSS).
class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});
  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  late Future<List<Noticia>> _future;

  /// Intolerancias elegidas: noticias relacionadas con alguna de ellas.
  Set<String> _filtro = {};

  /// null = todos los países; UY o BR.
  String? _pais;

  @override
  void initState() {
    super.initState();
    _future = context.read<NoticiaService>().listar();
  }

  void _recargar() {
    setState(() {
      _future = context.read<NoticiaService>().listar(intolerancias: _filtro, pais: _pais);
    });
  }

  Widget _chipPais(String? codigo, String texto) {
    final elegido = _pais == codigo;
    return ChoiceChip(
      label: Text(texto),
      selected: elegido,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: elegido ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        _pais = codigo;
        _recargar();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Noticias'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _chipPais(null, tr('Todas')),
                const SizedBox(width: 8),
                _chipPais('UY', tr('Uruguay')),
                const SizedBox(width: 8),
                _chipPais('BR', tr('Brasil')),
              ],
            ),
          ),
          BarraFiltroIntolerancias(
            seleccion: _filtro,
            titulo: tr('Noticias sobre...'),
            ayuda: tr('Se muestran las noticias relacionadas con ALGUNA de las intolerancias que marques.'),
            onChanged: (s) {
              _filtro = s;
              _recargar();
            },
          ),
          const SizedBox(height: 4),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    return FutureBuilder<List<Noticia>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snapshot.hasError) return ErrorView(mensaje: snapshot.error.toString(), onReintentar: _recargar);
        final noticias = snapshot.data ?? [];
        if (noticias.isEmpty) {
          return EmptyView(
              mensaje: _filtro.isEmpty && _pais == null
                  ? tr('No hay noticias por el momento')
                  : tr('No hay noticias con ese filtro'),
              icono: Icons.newspaper_outlined);
        }
        return RefreshIndicator(
          onRefresh: () async => _recargar(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
            itemCount: noticias.length,
            itemBuilder: (context, i) => TarjetaNoticia(noticia: noticias[i]),
          ),
        );
      },
    );
  }
}

/// Línea con el país, el medio y la fecha de una noticia.
class _MetaNoticia extends StatelessWidget {
  final Noticia noticia;
  const _MetaNoticia({required this.noticia});

  @override
  Widget build(BuildContext context) {
    final n = noticia;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (n.nombrePais != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: n.pais == 'UY' ? const Color(0xFFE3EEFB) : const Color(0xFFFFF4CC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              n.nombrePais!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: n.pais == 'UY' ? const Color(0xFF1D4E89) : const Color(0xFF7A5A00),
              ),
            ),
          ),
        Text(
          [
            if (n.fuente != null) n.fuente!,
            if (!n.esImportada) tr('SafeBite'),
            DateFormat('dd/MM/yyyy').format(n.fechaPublicacion),
          ].join(' · '),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class TarjetaNoticia extends StatelessWidget {
  final Noticia noticia;
  const TarjetaNoticia({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    final n = noticia;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoticiaDetailScreen(noticia: n))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.imagenUrl != null)
              Image.network(n.imagenUrl!, height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaNoticia(noticia: n),
                  const SizedBox(height: 8),
                  TextoT(n.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.3)),
                  if (n.resumen != null && n.resumen!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    TextoT(n.resumen!, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                  ],
                  if (n.intolerancias.isNotEmpty || n.etiquetas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...n.etiquetas
                            .where((e) => e != 'Uruguay' && e != 'Brasil')
                            .take(3)
                            .map((e) => Chip1(e, color: AppColors.textSecondary)),
                        ...n.intolerancias.take(3).map((c) => Chip1(etiquetaIntolerancia(c))),
                        if (n.intolerancias.length > 3) Chip1('+${n.intolerancias.length - 3}'),
                      ],
                    ),
                  ],
                  if (n.esImportada && n.urlOriginal != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => abrirEnlace(context, n.urlOriginal!),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(tr('Leer en {0}', [n.fuente ?? tr('la fuente')])),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoticiaDetailScreen extends StatelessWidget {
  final Noticia noticia;
  const NoticiaDetailScreen({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    final n = noticia;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Noticia'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (n.imagenUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(n.imagenUrl!, height: 190, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
          _MetaNoticia(noticia: n),
          const SizedBox(height: 10),
          TextoT(n.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
          if (n.intolerancias.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: n.intolerancias.map((c) => Chip1(etiquetaIntolerancia(c))).toList(),
            ),
          ],
          const SizedBox(height: 16),
          if (n.resumen != null && n.resumen!.isNotEmpty && (n.contenido == null || n.contenido!.isEmpty))
            TextoT(n.resumen!, style: const TextStyle(height: 1.5, fontSize: 15)),
          if (n.contenido != null && n.contenido!.isNotEmpty)
            TextoT(n.contenido!, style: const TextStyle(height: 1.5, fontSize: 15)),
          if (n.esImportada && n.urlOriginal != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tr('Esta noticia fue publicada por {0}. SafeBite la encontró automáticamente; el contenido completo está en el sitio original.', [n.fuente ?? tr('un medio externo')]),
                style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => abrirEnlace(context, n.urlOriginal!),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(tr('Leer la noticia completa')),
            ),
          ],
        ],
      ),
    );
  }
}

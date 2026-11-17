import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

/// Estado de la inteligencia artificial: gasto estimado de Claude, último
/// error de cada proveedor y una prueba de conexión que explica qué falla
/// (clave faltante o inválida, modelo inexistente, sin saldo o sin cuota).
class AdminIaScreen extends StatefulWidget {
  const AdminIaScreen({super.key});

  @override
  State<AdminIaScreen> createState() => _AdminIaScreenState();
}

class _AdminIaScreenState extends State<AdminIaScreen> {
  Map<String, dynamic>? _uso;
  Map<String, dynamic>? _diagnostico;
  bool _cargando = true;
  bool _probando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUso();
  }

  Future<void> _cargarUso() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await context.read<ApiClient>().get('/admin/ia/uso');
      if (mounted) setState(() => _uso = Map<String, dynamic>.from(data as Map));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _probar() async {
    setState(() => _probando = true);
    try {
      final data = await context.read<ApiClient>().get('/admin/ia/diagnostico');
      if (mounted) setState(() => _diagnostico = Map<String, dynamic>.from(data as Map));
      await _cargarUso();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo hacer la prueba: $e')));
      }
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inteligencia artificial'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargando ? null : _cargarUso),
        ],
      ),
      body: _cargando && _uso == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ),
                if (_uso != null) _TarjetaGasto(uso: _uso!),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _probando ? null : _probar,
                    icon: _probando
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.network_check),
                    label: Text(_probando ? 'Probando...' : 'Probar conexión con Claude y Gemini'),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hace una consulta mínima a cada proveedor (cuesta una fracción de centavo) y explica qué falla.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _TarjetaProveedor(
                  titulo: 'Claude (principal)',
                  estado: _mapa(_uso?['claude']),
                  prueba: _mapa(_diagnostico?['claude']),
                ),
                const SizedBox(height: 12),
                _TarjetaProveedor(
                  titulo: 'Gemini (respaldo)',
                  estado: _mapa(_uso?['gemini']),
                  prueba: _mapa(_diagnostico?['gemini']),
                ),
              ],
            ),
    );
  }

  Map<String, dynamic>? _mapa(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;
}

class _TarjetaGasto extends StatelessWidget {
  final Map<String, dynamic> uso;
  const _TarjetaGasto({required this.uso});

  @override
  Widget build(BuildContext context) {
    String usd(dynamic v) => v == null ? '-' : 'USD ${(v as num).toStringAsFixed(4)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gasto estimado de Claude', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Gastado: ${usd(uso['gastoEstimadoClaudeUsd'])} de ${usd(uso['presupuestoUsd'])}'),
            Text('Restante: ${usd(uso['restanteEstimadoUsd'])}'),
            Text('Consultas: Claude ${uso['llamadasClaude'] ?? 0} · Gemini ${uso['llamadasGemini'] ?? 0}'),
            if (uso['nota'] != null) ...[
              const SizedBox(height: 6),
              Text(uso['nota'].toString(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaProveedor extends StatelessWidget {
  final String titulo;
  final Map<String, dynamic>? estado;
  final Map<String, dynamic>? prueba;
  const _TarjetaProveedor({required this.titulo, this.estado, this.prueba});

  @override
  Widget build(BuildContext context) {
    final ok = prueba?['ok'] == true;
    final pruebasModelos = (prueba?['pruebas'] as List?) ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold))),
                if (prueba != null)
                  Icon(ok ? Icons.check_circle : Icons.error, color: ok ? AppColors.primary : AppColors.danger),
              ],
            ),
            if (prueba != null) ...[
              const SizedBox(height: 8),
              Text(prueba!['mensaje']?.toString() ?? ''),
              const SizedBox(height: 4),
              Text(
                'Clave: ${prueba!['claveConfigurada'] == true ? 'cargada (${prueba!['finClave']})' : 'no configurada'} · Modelo: ${prueba!['modelo'] ?? '-'}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              for (final p in pruebasModelos)
                if (p is Map)
                  Text('• ${p['modelo']}: ${p['detalle']}', style: const TextStyle(fontSize: 11)),
              if (prueba!['respuestaApi'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Respuesta de la API: ${prueba!['respuestaApi']}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
            ],
            const SizedBox(height: 8),
            Text('Último uso correcto: ${estado?['ultimoExito'] ?? 'ninguno desde que arrancó el servidor'}',
                style: const TextStyle(fontSize: 11)),
            if (estado?['ultimoError'] != null)
              Text('Último error: ${estado!['ultimoError']}',
                  style: const TextStyle(fontSize: 11, color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}

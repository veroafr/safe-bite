import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/i18n.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('No se pudo hacer la prueba: {0}', [e]))));
      }
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Inteligencia artificial')),
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
                    child: TextoT(_error!, style: const TextStyle(color: AppColors.danger)),
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
                    label: Text(_probando ? tr('Probando...') : tr('Probar conexión con Claude y Gemini')),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Hace una consulta mínima a cada proveedor (cuesta una fracción de centavo) y explica qué falla.'),
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _TarjetaProveedor(
                  titulo: tr('Claude (principal)'),
                  estado: _mapa(_uso?['claude']),
                  prueba: _mapa(_diagnostico?['claude']),
                ),
                const SizedBox(height: 12),
                _TarjetaProveedor(
                  titulo: tr('Gemini (respaldo)'),
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
            Text(tr('Gasto estimado de Claude'), style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tr('Gastado: {0} de {1}', [usd(uso['gastoEstimadoClaudeUsd']), usd(uso['presupuestoUsd'])])),
            Text(tr('Restante: {0}', [usd(uso['restanteEstimadoUsd'])])),
            Text(tr('Consultas: Claude {0} · Gemini {1}', [uso['llamadasClaude'] ?? 0, uso['llamadasGemini'] ?? 0])),
            if (uso['nota'] != null) ...[
              const SizedBox(height: 6),
              TextoT(uso['nota'].toString(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
              TextoT(prueba!['mensaje']?.toString() ?? ''),
              const SizedBox(height: 4),
              Text(
                tr('Clave: {0} · Modelo: {1}', [prueba!['claveConfigurada'] == true ? tr('cargada ({0})', [prueba!['finClave']]) : tr('no configurada'), prueba!['modelo'] ?? '-']),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              for (final p in pruebasModelos)
                if (p is Map)
                  Text('• ${p['modelo']}: ${p['detalle']}', style: const TextStyle(fontSize: 11)),
              if (prueba!['respuestaApi'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(tr('Respuesta de la API: {0}', [prueba!['respuestaApi']]),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
            ],
            const SizedBox(height: 8),
            Text(tr('Último uso correcto: {0}', [context.tc(estado?['ultimoExito']?.toString() ?? tr('ninguno desde que arrancó el servidor'))]),
                style: const TextStyle(fontSize: 11)),
            if (estado?['ultimoError'] != null)
              Text(tr('Último error: {0}', [context.tc(estado!['ultimoError']?.toString())]),
                  style: const TextStyle(fontSize: 11, color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}

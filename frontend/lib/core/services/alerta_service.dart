import '../api/api_client.dart';
import '../models/alerta.dart';

class AlertaService {
  final ApiClient _client;
  AlertaService(this._client);

  Future<Alerta> crear({required TipoAlerta tipo, int? restauranteId, int? productoId, required String descripcion}) async {
    final data = await _client.post('/alertas', body: {
      'tipo': tipo.name,
      'restauranteId': restauranteId,
      'productoId': productoId,
      'descripcion': descripcion,
    });
    return Alerta.fromJson(data);
  }

  Future<List<Alerta>> misAlertas() async {
    final data = await _client.get('/alertas/me');
    return (data as List).map((e) => Alerta.fromJson(e)).toList();
  }

  // ---- Administracion ----

  Future<List<Alerta>> listarPorEstado({EstadoAlerta? estado}) async {
    final data = await _client.get('/admin/alertas', query: {'estado': estado?.name});
    return (data as List).map((e) => Alerta.fromJson(e)).toList();
  }

  Future<Alerta> revisar(int id, EstadoAlerta estado) async {
    final data = await _client.put('/admin/alertas/$id/revisar', body: {'estado': estado.name});
    return Alerta.fromJson(data);
  }
}

import 'package:flutter/foundation.dart';
import '../models/intolerancia.dart';
import '../services/intolerancia_service.dart';

/// Lista de intolerancias activas compartida por toda la app (registro,
/// perfil, filtros y formularios del admin). Cuando el admin agrega o
/// edita una, llama a [recargar] y todas las pantallas se actualizan.
class IntoleranciasProvider extends ChangeNotifier {
  final IntoleranciaService _service;
  IntoleranciasProvider(this._service);

  List<Intolerancia> _activas = [];
  bool _cargando = false;
  bool _cargadoAlgunaVez = false;
  DateTime? _ultimaCarga;
  String? error;

  /// Pasado este tiempo, la lista se vuelve a pedir al abrir una pantalla
  /// que la usa (asi se ven las intolerancias que el admin agrego despues).
  static const _vigencia = Duration(minutes: 2);

  List<Intolerancia> get activas => List.unmodifiable(_activas);
  bool get cargando => _cargando;
  bool get cargado => _cargadoAlgunaVez;

  /// Carga la lista si todavia no se cargo o si quedo vieja (o siempre, con [forzar]).
  Future<void> cargar({bool forzar = false}) async {
    if (_cargando) return;
    final vigente = _ultimaCarga != null && DateTime.now().difference(_ultimaCarga!) < _vigencia;
    if (_cargadoAlgunaVez && vigente && !forzar) return;
    _cargando = true;
    error = null;
    notifyListeners();
    try {
      _activas = await _service.listarActivas();
      IntoleranciaCatalogo.actualizar(_activas);
      _cargadoAlgunaVez = true;
      _ultimaCarga = DateTime.now();
    } catch (e) {
      error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> recargar() => cargar(forzar: true);

  String nombre(String codigo) => IntoleranciaCatalogo.nombre(codigo);
}

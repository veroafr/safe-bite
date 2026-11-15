import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

/// Intolerancias contra las que el escaner evalua los productos.
/// Por defecto (null) se usan las del perfil del usuario; el filtro permite
/// revisar contra otras (por ejemplo, si compra para otra persona).
class FiltroEscanerProvider extends ChangeNotifier {
  Set<String>? _filtro;

  /// null = usar las intolerancias del perfil.
  Set<String>? get filtro => _filtro;
  bool get personalizado => _filtro != null;

  Set<String> efectivas(Usuario? usuario) => _filtro ?? (usuario?.intolerancias ?? <String>{});

  void cambiar(Set<String> nuevo, Usuario? usuario) {
    final mias = usuario?.intolerancias ?? <String>{};
    final igualAMias = nuevo.length == mias.length && nuevo.containsAll(mias);
    _filtro = (nuevo.isEmpty || igualAMias) ? null : {...nuevo};
    notifyListeners();
  }

  void restablecer() {
    _filtro = null;
    notifyListeners();
  }
}

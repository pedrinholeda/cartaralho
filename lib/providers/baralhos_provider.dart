import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/baralho.dart';

/// Todos os pacotes de [pacotes], lidos dos assets uma vez só, na ordem do
/// catálogo.
final baralhosProvider = FutureProvider<List<Baralho>>((ref) async {
  return Future.wait([
    for (final id in pacotes)
      rootBundle
          .loadString(arquivoDoPacote(id))
          .then((conteudo) => Baralho.fromJsonString(conteudo, id: id)),
  ]);
});

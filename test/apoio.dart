import 'dart:io';

import 'package:cartaralho/game/baralho.dart';

/// Um pacote de cartas de verdade, lido do disco (nos testes não há
/// rootBundle). `flutter test` roda na raiz do projeto.
Baralho pacoteDoArquivo(String id) => Baralho.fromJsonString(
      File(arquivoDoPacote(id)).readAsStringSync(),
      id: id,
    );

/// O pacote básico, o baralho dos testes de regra.
Baralho baralhoDoArquivo() => pacoteDoArquivo('basico');

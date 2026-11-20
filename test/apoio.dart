import 'dart:io';

import 'package:cartaralho/game/baralho.dart';

/// O baralho do arquivo de verdade, lido do disco (nos testes não há
/// rootBundle). `flutter test` roda na raiz do projeto.
Baralho baralhoDoArquivo() =>
    Baralho.fromJsonString(File(arquivoDoBaralho).readAsStringSync());

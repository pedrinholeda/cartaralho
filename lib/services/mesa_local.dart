import 'dart:async';
import 'dart:math';

import '../game/bots.dart';
import '../models/game_room.dart';

/// As partidas do modo solo: vivem só neste aparelho, sem Firestore. As
/// jogadas passam pelas mesmas regras de `lib/game/regras.dart`, e os bots
/// jogam um de cada vez, com uma pausa, para dar tempo de ver.
abstract final class MesaLocal {
  static const prefixo = 'SOLO-';
  static final _mesas = <String, _Mesa>{};

  /// Se o código é de uma partida solo (e não de uma sala do Firestore).
  static bool eh(String roomId) => roomId.startsWith(prefixo);

  /// Abre a mesa com a [sala] e põe os bots para jogar.
  static void abrir(GameRoom sala, {Random? random}) {
    fechar(sala.roomId);
    _mesas[sala.roomId] = _Mesa(sala, random ?? Random())..agendar();
  }

  /// A sala agora e a cada mudança.
  static Stream<GameRoom?> observar(String roomId) {
    final mesa = _mesas[roomId];
    if (mesa == null) return Stream.value(null);
    return Stream.multi((ouvinte) {
      ouvinte.add(mesa.sala);
      final mudancas =
          mesa.mudancas.stream.listen(ouvinte.add, onDone: ouvinte.close);
      ouvinte.onCancel = mudancas.cancel;
    });
  }

  /// A jogada de quem está no aparelho: roda a [regra] na hora (ela lança
  /// `JogadaInvalida` se não vale) e acorda os bots.
  static void alterar(String roomId, GameRoom Function(GameRoom) regra) {
    final mesa = _mesas[roomId];
    if (mesa == null) throw StateError('Partida solo não encontrada');
    mesa.publicar(regra(mesa.sala));
  }

  static void fechar(String roomId) => _mesas.remove(roomId)?.fechar();
}

class _Mesa {
  GameRoom sala;
  final Random rng;
  final mudancas = StreamController<GameRoom?>.broadcast();
  Timer? _proxima;

  _Mesa(this.sala, this.rng);

  void publicar(GameRoom nova) {
    sala = nova;
    mudancas.add(nova);
    agendar();
  }

  /// Se for a vez de algum bot, ele joga depois de uma pausa
  /// ([pausaDosBots]).
  void agendar() {
    _proxima?.cancel();
    if (passoDosBots(sala, Random(0)) == null) return;
    _proxima = Timer(pausaDosBots(sala.phase, rng), () {
      final nova = passoDosBots(sala, rng);
      if (nova != null) publicar(nova);
    });
  }

  void fechar() {
    _proxima?.cancel();
    mudancas.close();
  }
}

import 'dart:async';
import 'dart:math';

import 'package:cartaralho/game/bots.dart';
import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:cartaralho/services/mesa_local.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio.dart';

GameRoom _sala() => salaSolo(
      roomId: 'SOLO-T1',
      voce: Player(id: 'eu', name: 'Você'),
      baralho: pacoteDoArquivo('basico'),
      random: Random(1),
    );

void main() {
  tearDown(() => MesaLocal.fechar('SOLO-T1'));

  test('reconhece o código de uma partida solo', () {
    expect(MesaLocal.eh('SOLO-AB12'), isTrue);
    expect(MesaLocal.eh('K7PX2M'), isFalse);
  });

  testWidgets('os bots jogam sozinhos, com pausa entre um e outro',
      (tester) async {
    MesaLocal.abrir(_sala(), random: Random(2));
    final vistas = <GameRoom?>[];
    final assinatura = MesaLocal.observar('SOLO-T1').listen(vistas.add);
    await tester.pump();
    expect(vistas.single!.submittedCards, isEmpty);

    // Antes de 0,9 s ninguém jogou.
    await tester.pump(const Duration(milliseconds: 800));
    expect(vistas, hasLength(1));

    // Em alguns segundos os três bots enviaram e a vez é do juiz (você).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(vistas.last!.phase, GamePhase.judgeChoosing);
    expect(vistas.last!.submittedCards, hasLength(3));
    unawaited(assinatura.cancel());
  });

  testWidgets('a jogada da pessoa passa pela regra', (tester) async {
    MesaLocal.abrir(_sala(), random: Random(2));
    // Ainda ninguém enviou: escolher vencedor agora não vale.
    expect(
      () => MesaLocal.alterar(
          'SOLO-T1', (s) => escolherVencedor(s, 'eu', s.players[1].id)),
      throwsA(isA<JogadaInvalida>()),
    );
    MesaLocal.fechar('SOLO-T1');
  });

  testWidgets('depois de fechada, a partida some', (tester) async {
    MesaLocal.abrir(_sala());
    MesaLocal.fechar('SOLO-T1');
    final primeira = await MesaLocal.observar('SOLO-T1').first;
    expect(primeira, isNull);
  });

  test('todos os adversários são bots de verdade', () {
    expect(
        _sala().players.skip(1).every((p) => botPorId(p.id) != null), isTrue);
  });
}

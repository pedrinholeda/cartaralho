import 'dart:math';

import 'package:cartaralho/game/baralho.dart';
import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio.dart';

/// Configuração da sala, troca de mão e jogar de novo.

final baralho = baralhoDoArquivo();

GameRoom salaCom(
  int jogadores, {
  int maxPoints = 5,
  int handSize = 5,
  Baralho? deck,
}) {
  var sala = novaSala(
    roomId: 'ABC234',
    anfitriao: Player(id: 'p0', name: 'Ana'),
    baralho: deck ?? baralho,
    maxPoints: maxPoints,
    handSize: handSize,
  );
  for (var i = 1; i < jogadores; i++) {
    sala = entrarNaSala(sala, Player(id: 'p$i', name: 'Jogador $i'));
  }
  return sala;
}

int totalDeBrancas(GameRoom s) =>
    s.whiteCards.length +
    s.hands.values.fold<int>(0, (n, m) => n + m.length) +
    s.submittedCards.values.fold<int>(0, (n, cs) => n + cs.length);

void main() {
  group('novaSala', () {
    test('guarda a configuração e começa com o baralho inteiro', () {
      final sala = salaCom(1, maxPoints: 7, handSize: 7);

      expect(sala.maxPoints, 7);
      expect(sala.handSize, 7);
      expect(sala.players.single.isHost, isTrue);
      expect(sala.whiteCards, hasLength(baralho.brancas.length));
      expect(sala.blackCards, hasLength(baralho.pretas.length));
    });

    test('recusa valores fora das opções', () {
      expect(() => salaCom(1, maxPoints: 2), throwsA(isA<JogadaInvalida>()));
      expect(() => salaCom(1, handSize: 20), throwsA(isA<JogadaInvalida>()));
    });

    test('a configuração sobrevive à ida e volta pelo Firestore', () {
      final lida = GameRoom.fromJson(salaCom(1, handSize: 7).toJson());
      expect(lida.handSize, 7);
    });
  });

  group('mão de 7 cartas', () {
    test('cada jogador recebe 7 e a mão é completada até 7', () {
      var s = iniciarJogo(salaCom(3, handSize: 7), 'p0', random: Random(1));
      for (final p in s.players) {
        expect(s.hands[p.id], hasLength(7));
      }
      for (final p in s.players.where((p) => p.id != s.currentJudgeId)) {
        s = enviarCarta(s, p.id, [
          for (final c in s.hands[p.id]!.take(s.currentBlackCard!.pick)) c.id,
        ]);
      }
      final juiz = s.currentJudgeId!;
      s = proximaRodada(
          escolherVencedor(s, juiz, s.submittedCards.keys.first), juiz);
      for (final p in s.players) {
        expect(s.hands[p.id], hasLength(7));
      }
    });

    test('com gente demais para o baralho, explica o que fazer', () {
      // Um baralho de 50 brancas não dá 7 cartas para 8 jogadores.
      final pequeno = Baralho(
        id: 'pequeno',
        nome: 'pequeno',
        pretas: baralho.pretas,
        brancas: baralho.brancas.take(50).toList(),
      );
      expect(
        () => iniciarJogo(salaCom(8, handSize: 7, deck: pequeno), 'p0'),
        throwsA(isA<JogadaInvalida>()
            .having((e) => e.mensagem, 'mensagem', contains('Diminua a mão'))),
      );
    });
  });

  group('trocarMao', () {
    late GameRoom sala;
    setUp(() => sala = iniciarJogo(salaCom(3), 'p0', random: Random(1)));

    test('troca a mão inteira por cartas do monte e devolve as antigas', () {
      final antiga = sala.hands['p1']!.map((c) => c.id).toSet();
      final depois = trocarMao(sala, 'p1');
      final nova = depois.hands['p1']!.map((c) => c.id).toSet();

      expect(nova, hasLength(5));
      expect(nova.intersection(antiga), isEmpty);
      expect(
          depois.whiteCards.reversed.take(5).map((c) => c.id).toSet(), antiga,
          reason: 'as cartas devolvidas vão para o fim do monte');
      expect(totalDeBrancas(depois), totalDeBrancas(sala));
    });

    test('só uma vez por partida', () {
      final depois = trocarMao(sala, 'p1');
      expect(() => trocarMao(depois, 'p1'), throwsA(isA<JogadaInvalida>()));
      expect(trocarMao(depois, 'p2').handSwapsUsed, ['p1', 'p2']);
    });

    test('não troca depois de enviar a carta da rodada', () {
      final enviou = enviarCarta(sala, 'p1', [
        for (final c in sala.hands['p1']!.take(sala.currentBlackCard!.pick))
          c.id,
      ]);
      expect(() => trocarMao(enviou, 'p1'), throwsA(isA<JogadaInvalida>()));
    });

    test('não troca sem cartas suficientes no monte', () {
      final semMonte = sala.copyWith(whiteCards: const []);
      expect(() => trocarMao(semMonte, 'p1'), throwsA(isA<JogadaInvalida>()));
    });
  });

  group('jogarDeNovo', () {
    late GameRoom fim;
    setUp(() {
      var s = iniciarJogo(salaCom(3, maxPoints: 3), 'p0', random: Random(4));
      while (s.phase != GamePhase.gameComplete) {
        for (final p in s.players.where((p) => p.id != s.currentJudgeId)) {
          s = enviarCarta(s, p.id, [
            for (final c in s.hands[p.id]!.take(s.currentBlackCard!.pick)) c.id,
          ]);
        }
        final juiz = s.currentJudgeId!;
        s = escolherVencedor(s, juiz, s.submittedCards.keys.first);
        if (s.phase == GamePhase.roundResult) s = proximaRodada(s, juiz);
      }
      fim = s;
    });

    test('zera o placar e volta para a sala de espera', () {
      final denovo = jogarDeNovo(fim, 'p0');

      expect(denovo.phase, GamePhase.waitingForPlayers);
      expect(denovo.players.every((p) => p.points == 0), isTrue);
      expect(denovo.winnerId, isNull);
      expect(denovo.hands, isEmpty);
      expect(denovo.submittedCards, isEmpty);
      expect(denovo.handSwapsUsed, isEmpty);
      expect(denovo.maxPoints, 3);
    });

    test('todas as cartas voltam ao baralho', () {
      final denovo = jogarDeNovo(fim, 'p0');
      expect(denovo.whiteCards.map((c) => c.id).toSet(),
          baralho.brancas.map((c) => c.id).toSet());
      expect(denovo.blackCards.map((c) => c.id).toSet(),
          baralho.pretas.map((c) => c.id).toSet());
    });

    test('dá para iniciar de novo em seguida', () {
      final denovo = iniciarJogo(jogarDeNovo(fim, 'p0'), 'p0');
      expect(denovo.phase, GamePhase.playersSubmitting);
    });

    test('só o anfitrião, e só com o jogo terminado', () {
      expect(() => jogarDeNovo(fim, 'p1'), throwsA(isA<JogadaInvalida>()));
      final emJogo = iniciarJogo(salaCom(3), 'p0');
      expect(() => jogarDeNovo(emJogo, 'p0'), throwsA(isA<JogadaInvalida>()));
    });
  });
}

import 'dart:math';

import 'package:cartaralho/game/baralho.dart';
import 'package:cartaralho/game/bots.dart';
import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/models/card.dart';
import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio.dart';

final _todos = Baralho.juntar([for (final id in pacotes) pacoteDoArquivo(id)]);
final _voce = Player(id: 'eu', name: 'Você');

GameRoom _solo({int adversarios = 3, int seed = 1, int maxPoints = 5}) =>
    salaSolo(
      roomId: 'SOLO-AB12',
      voce: _voce,
      baralho: _todos,
      adversarios: adversarios,
      maxPoints: maxPoints,
      random: Random(seed),
    );

/// A jogada da pessoa, quando é a vez dela: a primeira carta, o primeiro que
/// enviou, a próxima rodada.
GameRoom? _jogadaDaPessoa(GameRoom s) {
  switch (s.phase) {
    case GamePhase.playersSubmitting:
      if (s.currentJudgeId == 'eu' || s.submittedCards.containsKey('eu')) {
        return null;
      }
      final pede = s.currentBlackCard!.pick;
      return enviarCarta(
          s, 'eu', [for (final c in s.hands['eu']!.take(pede)) c.id]);
    case GamePhase.judgeChoosing:
      if (s.currentJudgeId != 'eu') return null;
      return escolherVencedor(s, 'eu', s.submittedCards.keys.first);
    case GamePhase.roundResult:
      if (s.currentJudgeId != 'eu') return null;
      return proximaRodada(s, 'eu');
    default:
      return null;
  }
}

void main() {
  group('salaSolo', () {
    test('começa já em jogo, com você de anfitrião e juiz', () {
      final s = _solo();
      expect(s.players, hasLength(4));
      expect(s.players.first.id, 'eu');
      expect(s.players.first.isHost, isTrue);
      expect(s.players.skip(1).every((p) => ehBot(p.id)), isTrue);
      expect(s.players.map((p) => p.id).toSet(), hasLength(4));
      expect(s.phase, GamePhase.playersSubmitting);
      expect(s.currentJudgeId, 'eu');
    });

    test('aceita 2, 3 ou 4 bots, e recusa o resto', () {
      for (final n in opcoesDeAdversarios) {
        expect(_solo(adversarios: n).players, hasLength(n + 1));
      }
      expect(() => _solo(adversarios: 1), throwsA(isA<JogadaInvalida>()));
      expect(() => _solo(adversarios: 8), throwsA(isA<JogadaInvalida>()));
    });

    test('todo bot tem um pacote que existe', () {
      for (final b in bots) {
        expect(pacotes, contains(b.pacote), reason: b.nome);
        expect(ehBot(b.id), isTrue);
      }
    });
  });

  group('gosto dos bots', () {
    GameCard carta(String id) =>
        GameCard(id: id, text: id, type: CardType.white);

    // A Tia do Zap com uma carta da família e quatro de outros pacotes.
    GameRoom salaDaTia() => GameRoom(
          roomId: 'SOLO-T',
          blackCards: const [],
          whiteCards: const [],
          players: [_voce, Player(id: 'bot-tia', name: 'Tia do Zap')],
          currentBlackCard: GameCard(
              id: 'basico-b1', text: 'Frase ____.', type: CardType.black),
          hands: {
            'bot-tia': [
              carta('firma-w1'),
              carta('role-w2'),
              carta('familia-w3'),
              carta('amor-w4'),
              carta('internet-w5'),
            ],
          },
          phase: GamePhase.playersSubmitting,
          currentJudgeId: 'eu',
        );

    test('o bot envia quantas cartas a preta pede, da própria mão', () {
      final s = salaDaTia();
      final ids = jogadaDoBot(s, 'bot-tia', Random(3));
      expect(ids, hasLength(1));
      expect(s.hands['bot-tia']!.map((c) => c.id), contains(ids.single));
    });

    test('na maioria das vezes, joga a carta do pacote preferido', () {
      final s = salaDaTia();
      var familia = 0;
      for (var i = 0; i < 300; i++) {
        if (jogadaDoBot(s, 'bot-tia', Random(i)).single == 'familia-w3') {
          familia++;
        }
      }
      expect(familia, greaterThan(220));
      expect(familia, lessThan(300), reason: 'às vezes a sorte fala mais alto');
    });

    test('como juiz, prefere quem jogou carta do pacote dele', () {
      final s = salaDaTia().copyWith(
        phase: GamePhase.judgeChoosing,
        currentJudgeId: 'bot-tia',
        submittedCards: {
          'a': [carta('firma-w9')],
          'b': [carta('familia-w8')],
          'c': [carta('role-w7')],
        },
      );
      var b = 0;
      for (var i = 0; i < 300; i++) {
        final voto = votoDoBot(s, 'bot-tia', Random(i));
        expect(['a', 'b', 'c'], contains(voto));
        if (voto == 'b') b++;
      }
      expect(b, greaterThan(200));
    });
  });

  group('passoDosBots', () {
    test('os bots enviam um de cada vez e esperam a pessoa', () {
      // Você é o juiz da primeira rodada: os três bots enviam.
      var s = _solo();
      for (var i = 0; i < 3; i++) {
        s = passoDosBots(s, Random(i))!;
      }
      expect(s.phase, GamePhase.judgeChoosing);
      // Agora o juiz é você: nenhum bot joga.
      expect(passoDosBots(s, Random(9)), isNull);
    });

    test('quando você joga, os bots esperam a sua carta', () {
      var s = _solo();
      s = proximaRodada(
          escolherVencedor(
              [for (var i = 0; i < 3; i++) i]
                  .fold(s, (sala, i) => passoDosBots(sala, Random(i))!),
              'eu',
              s.players[1].id),
          'eu');
      // Rodada 2: um bot é juiz; os outros dois enviam, e falta você.
      expect(s.currentJudgeId, isNot('eu'));
      s = passoDosBots(s, Random(1))!;
      s = passoDosBots(s, Random(2))!;
      expect(s.phase, GamePhase.playersSubmitting);
      expect(passoDosBots(s, Random(3)), isNull);
    });

    test('uma partida inteira contra os bots chega ao fim', () {
      for (final seed in [1, 2, 3]) {
        var s = _solo(seed: seed, adversarios: 4, maxPoints: 3);
        final rng = Random(seed);
        var passos = 0;
        while (s.phase != GamePhase.gameComplete) {
          s = passoDosBots(s, rng) ?? _jogadaDaPessoa(s)!;
          expect(++passos, lessThan(1000), reason: 'a partida travou');
        }
        expect(s.players.any((p) => p.points == 3), isTrue);
      }
    });
  });
}

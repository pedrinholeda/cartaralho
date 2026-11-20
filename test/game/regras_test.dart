import 'dart:math';

import 'package:cartaralho/game/baralho.dart';
import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/models/card.dart';
import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

GameRoom salaDeEspera({int jogadores = 3, int brancas = 30, int pretas = 5}) {
  return GameRoom(
    roomId: 'ABC234',
    players: [
      for (var i = 0; i < jogadores; i++)
        Player(id: 'p$i', name: 'Jogador $i', isHost: i == 0),
    ],
    whiteCards: [
      for (var i = 0; i < brancas; i++)
        GameCard(id: 'w$i', text: 'Branca $i', type: CardType.white),
    ],
    blackCards: [
      for (var i = 0; i < pretas; i++)
        GameCard(id: 'b$i', text: 'Preta $i ____', type: CardType.black),
    ],
  );
}

/// Todos menos o juiz enviam a primeira carta da mão.
GameRoom todosEnviam(GameRoom sala) {
  var s = sala;
  for (final p in sala.players.where((p) => p.id != sala.currentJudgeId)) {
    s = enviarCarta(s, p.id, s.hands[p.id]!.first.id);
  }
  return s;
}

/// Juiz escolhe o primeiro que enviou e começa a próxima rodada.
GameRoom fecharRodada(GameRoom sala) {
  final juiz = sala.currentJudgeId!;
  final alguem = sala.submittedCards.keys.first;
  return proximaRodada(escolherVencedor(sala, juiz, alguem), juiz);
}

void main() {
  group('iniciarJogo', () {
    test('dá uma mão a cada jogador e abre o envio de cartas', () {
      final sala = iniciarJogo(salaDeEspera(), 'p0', random: Random(1));

      expect(sala.phase, GamePhase.playersSubmitting);
      expect(sala.currentJudgeId, 'p0');
      expect(sala.currentBlackCard, isNotNull);
      for (final p in sala.players) {
        expect(sala.hands[p.id], hasLength(tamanhoDaMao));
      }
      final distribuidas = sala.hands.values.expand((m) => m).map((c) => c.id);
      expect(distribuidas.toSet(), hasLength(3 * tamanhoDaMao),
          reason: 'nenhuma carta pode estar em duas mãos');
      expect(sala.whiteCards, hasLength(30 - 3 * tamanhoDaMao));
    });

    test('a carta preta virada sai do baralho', () {
      final sala = iniciarJogo(salaDeEspera(), 'p0', random: Random(1));
      expect(sala.blackCards.map((c) => c.id),
          isNot(contains(sala.currentBlackCard!.id)));
    });

    test('só o anfitrião inicia', () {
      expect(() => iniciarJogo(salaDeEspera(), 'p1'),
          throwsA(isA<JogadaInvalida>()));
    });

    test('exige o mínimo de jogadores', () {
      expect(() => iniciarJogo(salaDeEspera(jogadores: 2), 'p0'),
          throwsA(isA<JogadaInvalida>()));
    });

    test('recusa quando não há cartas brancas para todos', () {
      expect(() => iniciarJogo(salaDeEspera(brancas: 10), 'p0'),
          throwsA(isA<JogadaInvalida>()));
    });
  });

  group('enviarCarta', () {
    late GameRoom sala;
    setUp(() => sala = iniciarJogo(salaDeEspera(), 'p0', random: Random(1)));

    test('a fase só muda quando todos menos o juiz enviaram', () {
      final umaEnviada = enviarCarta(sala, 'p1', sala.hands['p1']!.first.id);
      expect(umaEnviada.phase, GamePhase.playersSubmitting);

      final todas =
          enviarCarta(umaEnviada, 'p2', umaEnviada.hands['p2']!.first.id);
      expect(todas.phase, GamePhase.judgeChoosing);
      expect(todas.submittedCards.keys, unorderedEquals(['p1', 'p2']));
    });

    test('quando todos enviam, sorteia a ordem das cartas na mesa', () {
      final ordens = <String>{};
      for (var semente = 0; semente < 20; semente++) {
        var s =
            iniciarJogo(salaDeEspera(jogadores: 5), 'p0', random: Random(1));
        for (final p in s.players.where((p) => p.id != 'p0')) {
          s = enviarCarta(s, p.id, s.hands[p.id]!.first.id,
              random: Random(semente));
        }
        expect(s.revealOrder, unorderedEquals(['p1', 'p2', 'p3', 'p4']));
        ordens.add(s.revealOrder.join());
      }
      expect(ordens.length, greaterThan(1),
          reason: 'a ordem não pode ser sempre a mesma');
    });

    test('a carta enviada sai da mão', () {
      final carta = sala.hands['p1']!.first;
      final depois = enviarCarta(sala, 'p1', carta.id);
      expect(depois.hands['p1']!.map((c) => c.id), isNot(contains(carta.id)));
      expect(depois.hands['p1'], hasLength(tamanhoDaMao - 1));
    });

    test('o juiz não envia', () {
      expect(() => enviarCarta(sala, 'p0', sala.hands['p0']!.first.id),
          throwsA(isA<JogadaInvalida>()));
    });

    test('não envia carta que não está na mão', () {
      expect(() => enviarCarta(sala, 'p1', sala.hands['p2']!.first.id),
          throwsA(isA<JogadaInvalida>()));
    });

    test('não envia duas vezes na mesma rodada', () {
      final depois = enviarCarta(sala, 'p1', sala.hands['p1']![0].id);
      expect(() => enviarCarta(depois, 'p1', depois.hands['p1']![0].id),
          throwsA(isA<JogadaInvalida>()));
    });
  });

  group('escolherVencedor', () {
    late GameRoom sala;
    setUp(() {
      sala = todosEnviam(iniciarJogo(salaDeEspera(), 'p0', random: Random(1)));
    });

    test('dá o ponto e mostra o resultado da rodada', () {
      final depois = escolherVencedor(sala, 'p0', 'p2');

      expect(depois.players.firstWhere((p) => p.id == 'p2').points, 1);
      expect(depois.phase, GamePhase.roundResult);
      expect(depois.lastRoundWinnerId, 'p2');
    });

    test('no resultado a mesa continua com as cartas e o juiz não muda', () {
      final depois = escolherVencedor(sala, 'p0', 'p2');

      expect(depois.submittedCards.keys, unorderedEquals(['p1', 'p2']));
      expect(depois.cardsOnTable, hasLength(2));
      expect(depois.currentJudgeId, 'p0');
      expect(depois.currentBlackCard!.id, sala.currentBlackCard!.id);
    });

    test('termina o jogo quando alguém chega ao máximo de pontos', () {
      final quaseLa = sala.copyWith(players: [
        for (final p in sala.players)
          p.id == 'p1' ? p.copyWith(points: sala.maxPoints - 1) : p,
      ]);
      final fim = escolherVencedor(quaseLa, 'p0', 'p1');

      expect(fim.phase, GamePhase.gameComplete);
      expect(fim.winnerId, 'p1');
    });

    test('só o juiz escolhe', () {
      expect(() => escolherVencedor(sala, 'p1', 'p2'),
          throwsA(isA<JogadaInvalida>()));
    });

    test('não escolhe quem não enviou carta', () {
      expect(() => escolherVencedor(sala, 'p0', 'p0'),
          throwsA(isA<JogadaInvalida>()));
    });
  });

  group('proximaRodada', () {
    late GameRoom resultado;
    setUp(() {
      final sala =
          todosEnviam(iniciarJogo(salaDeEspera(), 'p0', random: Random(1)));
      resultado = escolherVencedor(sala, 'p0', 'p2');
    });

    test('passa o juiz para o próximo jogador e limpa a mesa', () {
      final depois = proximaRodada(resultado, 'p0');

      expect(depois.currentJudgeId, 'p1');
      expect(depois.phase, GamePhase.playersSubmitting);
      expect(depois.submittedCards, isEmpty);
      expect(depois.revealOrder, isEmpty);
    });

    test('completa as mãos e vira uma carta preta nova', () {
      final depois = proximaRodada(resultado, 'p0');

      for (final p in depois.players) {
        expect(depois.hands[p.id], hasLength(tamanhoDaMao));
      }
      expect(
          depois.currentBlackCard!.id, isNot(resultado.currentBlackCard!.id));
    });

    test('o juiz roda por todos e volta ao primeiro', () {
      var s = iniciarJogo(salaDeEspera(), 'p0', random: Random(1));
      final juizes = <String>[s.currentJudgeId!];
      for (var rodada = 0; rodada < 3; rodada++) {
        s = fecharRodada(todosEnviam(s));
        juizes.add(s.currentJudgeId!);
      }
      expect(juizes, ['p0', 'p1', 'p2', 'p0']);
    });

    test('o baralho não acaba: as cartas jogadas voltam para o fim', () {
      // 3 jogadores x 5 cartas = 15: o baralho começa vazio depois de dar as mãos.
      var s = iniciarJogo(salaDeEspera(brancas: 15), 'p0', random: Random(2));
      expect(s.whiteCards, isEmpty);
      for (var rodada = 0; rodada < 4; rodada++) {
        s = fecharRodada(todosEnviam(s));
        for (final p in s.players) {
          expect(s.hands[p.id], hasLength(tamanhoDaMao));
        }
      }
    });

    test('só o juiz da rodada que acabou começa a próxima', () {
      expect(
          () => proximaRodada(resultado, 'p1'), throwsA(isA<JogadaInvalida>()));
    });

    test('não pula a escolha do juiz', () {
      final semResultado =
          todosEnviam(iniciarJogo(salaDeEspera(), 'p0', random: Random(1)));
      expect(() => proximaRodada(semResultado, 'p0'),
          throwsA(isA<JogadaInvalida>()));
    });
  });

  group('fraseCompleta', () {
    GameCard preta(String t) =>
        GameCard(id: 'b', text: t, type: CardType.black);
    GameCard branca(String t) => GameCard(id: t, text: t, type: CardType.white);

    test('põe a branca no lugar da lacuna', () {
      expect(fraseCompleta(preta('Não vivo sem ____.'), [branca('café')]),
          'Não vivo sem café.');
    });

    test('várias lacunas são preenchidas na ordem', () {
      expect(
        fraseCompleta(preta('____ e ____ são iguais.'),
            [branca('Pão'), branca('pastel')]),
        'Pão e pastel são iguais.',
      );
    });

    test('pergunta sem lacuna recebe a resposta no fim', () {
      expect(fraseCompleta(preta('O que estraga a festa?'), [branca('O tio')]),
          'O que estraga a festa? O tio');
    });
  });

  group('entrarNaSala', () {
    test('adiciona o jogador novo', () {
      final sala =
          entrarNaSala(salaDeEspera(), Player(id: 'novo', name: 'Novo'));
      expect(sala.players.map((p) => p.id), contains('novo'));
    });

    test('quem já está na sala não entra de novo', () {
      final sala = entrarNaSala(salaDeEspera(), Player(id: 'p1', name: 'X'));
      expect(sala.players, hasLength(3));
    });

    test('recusa quando a sala está cheia', () {
      final cheia = salaDeEspera(jogadores: maximoDeJogadores);
      expect(() => entrarNaSala(cheia, Player(id: 'novo', name: 'Novo')),
          throwsA(isA<JogadaInvalida>()));
    });

    test('recusa depois que o jogo começou', () {
      final emJogo = iniciarJogo(salaDeEspera(), 'p0');
      expect(() => entrarNaSala(emJogo, Player(id: 'novo', name: 'Novo')),
          throwsA(isA<JogadaInvalida>()));
    });
  });

  group('gerarCodigoSala', () {
    test('tem 6 caracteres do alfabeto sem ambíguos', () {
      final rng = Random(3);
      for (var i = 0; i < 200; i++) {
        final codigo = gerarCodigoSala(random: rng);
        expect(codigo, matches(RegExp(r'^[A-HJKMNP-Z2-9]{6}$')));
      }
    });

    test('códigos gerados em sequência não se repetem nem andam juntos', () {
      // O gerador antigo usava o relógio e produzia letras consecutivas
      // ("ABCDEF", "BCDEFG"...), então duas salas criadas no mesmo
      // milissegundo tinham o mesmo código.
      final codigos = {for (var i = 0; i < 1000; i++) gerarCodigoSala()};
      expect(codigos.length, greaterThan(995));
    });
  });
}

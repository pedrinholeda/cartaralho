import 'dart:math';

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
    final pede = s.currentBlackCard!.pick;
    s = enviarCarta(s, p.id, [for (final c in s.hands[p.id]!.take(pede)) c.id]);
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
      final umaEnviada = enviarCarta(sala, 'p1', [sala.hands['p1']!.first.id]);
      expect(umaEnviada.phase, GamePhase.playersSubmitting);

      final todas =
          enviarCarta(umaEnviada, 'p2', [umaEnviada.hands['p2']!.first.id]);
      expect(todas.phase, GamePhase.judgeChoosing);
      expect(todas.submittedCards.keys, unorderedEquals(['p1', 'p2']));
    });

    test('quando todos enviam, sorteia a ordem das cartas na mesa', () {
      final ordens = <String>{};
      for (var semente = 0; semente < 20; semente++) {
        var s =
            iniciarJogo(salaDeEspera(jogadores: 5), 'p0', random: Random(1));
        for (final p in s.players.where((p) => p.id != 'p0')) {
          s = enviarCarta(s, p.id, [s.hands[p.id]!.first.id],
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
      final depois = enviarCarta(sala, 'p1', [carta.id]);
      expect(depois.hands['p1']!.map((c) => c.id), isNot(contains(carta.id)));
      expect(depois.hands['p1'], hasLength(tamanhoDaMao - 1));
    });

    test('o juiz não envia', () {
      expect(() => enviarCarta(sala, 'p0', [sala.hands['p0']!.first.id]),
          throwsA(isA<JogadaInvalida>()));
    });

    test('não envia carta que não está na mão', () {
      expect(() => enviarCarta(sala, 'p1', [sala.hands['p2']!.first.id]),
          throwsA(isA<JogadaInvalida>()));
    });

    test('não envia duas vezes na mesma rodada', () {
      final depois = enviarCarta(sala, 'p1', [sala.hands['p1']![0].id]);
      expect(() => enviarCarta(depois, 'p1', [depois.hands['p1']![0].id]),
          throwsA(isA<JogadaInvalida>()));
    });
  });

  group('cartas "Escolha 2"', () {
    late GameRoom sala;
    setUp(() {
      sala = iniciarJogo(salaDeEspera(), 'p0', random: Random(1)).copyWith(
        currentBlackCard: GameCard(
            id: 'bx', text: '____ combina com ____.', type: CardType.black),
      );
    });

    test('a carta preta pede uma branca por lacuna', () {
      expect(sala.currentBlackCard!.pick, 2);
      expect(
          GameCard(id: 'q', text: 'O que é isso?', type: CardType.black).pick,
          1);
    });

    test('o jogador envia duas cartas, na ordem escolhida', () {
      final mao = sala.hands['p1']!;
      final depois = enviarCarta(sala, 'p1', [mao[3].id, mao[1].id]);

      expect(depois.submittedCards['p1']!.map((c) => c.id),
          [mao[3].id, mao[1].id]);
      expect(depois.hands['p1'], hasLength(tamanhoDaMao - 2));
      expect(
          fraseCompleta(depois.currentBlackCard!, depois.submittedCards['p1']!),
          '${mao[3].text} combina com ${mao[1].text}.');
    });

    test('recusa uma carta só quando a preta pede duas', () {
      expect(() => enviarCarta(sala, 'p1', [sala.hands['p1']!.first.id]),
          throwsA(isA<JogadaInvalida>()));
    });

    test('recusa a mesma carta duas vezes', () {
      final id = sala.hands['p1']!.first.id;
      expect(() => enviarCarta(sala, 'p1', [id, id]),
          throwsA(isA<JogadaInvalida>()));
    });

    test('as duas cartas voltam ao baralho e a mão é completada', () {
      final fim = fecharRodada(todosEnviam(sala));
      for (final p in fim.players) {
        expect(fim.hands[p.id], hasLength(tamanhoDaMao));
      }
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

    test('a branca ganha maiúscula quando a lacuna abre a frase', () {
      expect(fraseCompleta(preta('____ é tudo.'), [branca('pizza fria')]),
          'Pizza fria é tudo.');
      expect(fraseCompleta(preta('Quem chegou? ____.'), [branca('o tio')]),
          'Quem chegou? O tio.');
      expect(fraseCompleta(preta('Ele gritou: "____!"'), [branca('socorro')]),
          'Ele gritou: "Socorro!"');
    });

    test('no meio da frase a branca fica como foi escrita', () {
      expect(
          fraseCompleta(
              preta('Vi ____ e ____.'), [branca('o tio'), branca('TikTok')]),
          'Vi o tio e TikTok.');
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

  group('carta em branco', () {
    // Sala em que a mão do p1 tem uma carta em branco.
    GameRoom comBranca() {
      final s = iniciarJogo(salaDeEspera(), 'p0', random: Random(1));
      final livre = GameCard(id: 'livre-1', text: '', type: CardType.white);
      return s.copyWith(hands: {
        ...s.hands,
        'p1': [livre, ...s.hands['p1']!.skip(1)],
      });
    }

    test('vai para a mesa com o texto escrito', () {
      final s = enviarCarta(comBranca(), 'p1', ['livre-1'],
          textos: {'livre-1': '  o boleto do meu ex.  '});
      expect(s.submittedCards['p1']!.single.text, 'o boleto do meu ex');
      expect(s.submittedCards['p1']!.single.emBranco, isTrue);
    });

    test('sem texto, ou com texto demais, é recusada', () {
      expect(() => enviarCarta(comBranca(), 'p1', ['livre-1']),
          throwsA(isA<JogadaInvalida>()));
      expect(
          () => enviarCarta(comBranca(), 'p1', ['livre-1'],
              textos: {'livre-1': 'a' * (maximoDoTextoLivre + 1)}),
          throwsA(isA<JogadaInvalida>()));
    });

    test('volta vazia para o monte depois da rodada', () {
      var s = enviarCarta(comBranca(), 'p1', ['livre-1'],
          textos: {'livre-1': 'qualquer coisa'});
      s = enviarCarta(s, 'p2', [s.hands['p2']!.first.id]);
      s = proximaRodada(escolherVencedor(s, 'p0', 'p1'), 'p0');
      final todas = [...s.whiteCards, ...s.hands.values.expand((m) => m)];
      final livre = todas.singleWhere((c) => c.id == 'livre-1');
      expect(livre.text, isEmpty);
    });

    test('toda sala nova ganha cartas em branco no monte', () {
      expect(cartasEmBranco(30), hasLength(4));
      expect(cartasEmBranco(454), hasLength(37));
      expect(cartasEmBranco(454).every((c) => c.emBranco && c.text.isEmpty),
          isTrue);
    });
  });

  group('sairDaSala', () {
    int brancas(GameRoom s) =>
        s.whiteCards.length +
        s.hands.values.fold<int>(0, (n, m) => n + m.length) +
        s.submittedCards.values.fold<int>(0, (n, cs) => n + cs.length);

    test('na espera: sai da lista, e o anfitrião passa para o próximo', () {
      // Numa sala de verdade o anfitrião começa como juiz (novaSala).
      final s = sairDaSala(
          salaDeEspera(jogadores: 4).copyWith(currentJudgeId: 'p0'), 'p0');
      expect(s.players.map((p) => p.id), ['p1', 'p2', 'p3']);
      expect(s.players.first.isHost, isTrue);
      expect(s.currentJudgeId, 'p1');
    });

    test('quem não está na sala não sai', () {
      expect(() => sairDaSala(salaDeEspera(), 'intruso'),
          throwsA(isA<JogadaInvalida>()));
    });

    test('no meio da partida, as cartas de quem sai voltam ao monte', () {
      final antes =
          iniciarJogo(salaDeEspera(jogadores: 4), 'p0', random: Random(1));
      final total = brancas(antes);
      final depois = sairDaSala(antes, 'p2');
      expect(depois.players, hasLength(3));
      expect(depois.hands.containsKey('p2'), isFalse);
      expect(brancas(depois), total);
      expect(depois.phase, GamePhase.playersSubmitting);
    });

    test('se era o último que faltava enviar, a mesa vai para o juiz', () {
      var s = iniciarJogo(salaDeEspera(jogadores: 4), 'p0', random: Random(1));
      s = enviarCarta(s, 'p1', [s.hands['p1']!.first.id]);
      s = enviarCarta(s, 'p2', [s.hands['p2']!.first.id]);
      s = sairDaSala(s, 'p3', random: Random(2));
      expect(s.phase, GamePhase.judgeChoosing);
      expect(s.revealOrder.toSet(), {'p1', 'p2'});
    });

    test('o juiz saiu: o juiz passa adiante e as cartas voltam às mãos', () {
      var s = iniciarJogo(salaDeEspera(jogadores: 4), 'p0', random: Random(1));
      final total = brancas(s);
      s = enviarCarta(s, 'p1', [s.hands['p1']!.first.id]);
      s = sairDaSala(s, 'p0');
      expect(s.currentJudgeId, 'p1');
      expect(s.phase, GamePhase.playersSubmitting);
      expect(s.submittedCards, isEmpty);
      expect(s.hands['p1'], hasLength(tamanhoDaMao));
      expect(brancas(s), total);
    });

    test('com menos de três, todos voltam para a espera, zerados', () {
      var s = iniciarJogo(salaDeEspera(), 'p0', random: Random(1));
      final total = brancas(s);
      s = sairDaSala(s, 'p2');
      expect(s.phase, GamePhase.waitingForPlayers);
      expect(s.players.map((p) => p.id), ['p0', 'p1']);
      expect(s.hands, isEmpty);
      expect(s.whiteCards, hasLength(total));
      expect(s.players.every((p) => p.points == 0), isTrue);
    });

    test('sobrou só bot: a sala fica sem gente (e o serviço a apaga)', () {
      final s = sairDaSala(
        GameRoom(
          roomId: 'X',
          players: [
            Player(id: 'p0', name: 'Ana', isHost: true),
            Player(id: 'bot-ze-aleatorio', name: 'Zé'),
          ],
          blackCards: const [],
          whiteCards: const [],
        ),
        'p0',
      );
      expect(temGenteNaSala(s), isFalse);
      expect(temGenteNaSala(salaDeEspera()), isTrue);
    });
  });

  group('reagir', () {
    test('qualquer um manda, em qualquer fase, e a conta sobe', () {
      var s = reagir(salaDeEspera(), 'p1', 'risada');
      expect(s.players[1].reacao, 'risada');
      expect(s.players[1].reacaoVez, 1);
      s = reagir(iniciarJogo(s, 'p0', random: Random(1)), 'p1', 'choro');
      expect(s.players[1].reacao, 'choro');
      expect(s.players[1].reacaoVez, 2);
      expect(s.players[0].reacaoVez, 0);
    });

    test('reação desconhecida ou de fora da sala é recusada', () {
      expect(() => reagir(salaDeEspera(), 'p1', 'tapa'),
          throwsA(isA<JogadaInvalida>()));
      expect(() => reagir(salaDeEspera(), 'intruso', 'risada'),
          throwsA(isA<JogadaInvalida>()));
    });
  });

  group('sortearOutraCarinha', () {
    test('passa para a próxima carinha só de quem pediu', () {
      final s = sortearOutraCarinha(salaDeEspera(), 'p1');
      expect([for (final p in s.players) p.avatar], [0, 1, 0]);
      expect(sortearOutraCarinha(s, 'p1').players[1].avatar, 2);
    });

    test('depois que o jogo começou, recusa', () {
      final s = iniciarJogo(salaDeEspera(), 'p0', random: Random(1));
      expect(
          () => sortearOutraCarinha(s, 'p1'), throwsA(isA<JogadaInvalida>()));
    });

    test('quem não está na sala não troca nada', () {
      expect(() => sortearOutraCarinha(salaDeEspera(), 'intruso'),
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

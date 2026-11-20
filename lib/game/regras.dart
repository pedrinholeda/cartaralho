import 'dart:math';

import 'baralho.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';

/// Regras do jogo como funções puras: recebem a sala e devolvem a sala nova.
///
/// O FirebaseService lê o documento, chama uma destas funções e grava o
/// resultado numa transação. Assim a regra é testável sem Firestore.

/// Quantas cartas brancas cada jogador tem na mão.
const tamanhoDaMao = 5;

/// Mínimo de jogadores para começar: um juiz e ao menos dois que jogam cartas.
const minimoDeJogadores = 3;

/// Erro de regra: a jogada não vale no estado atual da sala.
class JogadaInvalida implements Exception {
  JogadaInvalida(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Começa a partida: embaralha os baralhos, dá [tamanhoDaMao] cartas a cada
/// jogador, vira a primeira carta preta e abre a fase de envio.
GameRoom iniciarJogo(GameRoom sala, String quemPediu, {Random? random}) {
  final rng = random ?? Random();
  if (sala.phase != GamePhase.waitingForPlayers) {
    throw JogadaInvalida('O jogo já começou');
  }
  if (!sala.players.any((p) => p.id == quemPediu && p.isHost)) {
    throw JogadaInvalida('Só o anfitrião pode iniciar o jogo');
  }
  if (sala.players.length < minimoDeJogadores) {
    throw JogadaInvalida(
      'São precisos ao menos $minimoDeJogadores jogadores para começar',
    );
  }

  final brancas = List<GameCard>.from(sala.whiteCards)..shuffle(rng);
  final pretas = List<GameCard>.from(sala.blackCards)..shuffle(rng);
  if (brancas.length < sala.players.length * tamanhoDaMao) {
    throw JogadaInvalida('Não há cartas brancas para todos os jogadores');
  }

  final maos = <String, List<GameCard>>{};
  for (final jogador in sala.players) {
    maos[jogador.id] = [
      for (var i = 0; i < tamanhoDaMao; i++) brancas.removeAt(0),
    ];
  }

  return sala.copyWith(
    whiteCards: brancas,
    blackCards: pretas.sublist(1),
    currentBlackCard: pretas.first,
    currentJudgeId: sala.players.first.id,
    hands: maos,
    submittedCards: const {},
    phase: GamePhase.playersSubmitting,
  );
}

/// Um jogador envia da própria mão as cartas que a carta preta pede, na ordem
/// das lacunas (uma só na carta comum). Quando todos menos o juiz
/// enviaram, a sala passa para a escolha do juiz, com as cartas numa ordem
/// sorteada ([GameRoom.revealOrder]) para ninguém saber quem enviou qual.
GameRoom enviarCarta(
  GameRoom sala,
  String jogadorId,
  List<String> cartaIds, {
  Random? random,
}) {
  if (sala.phase != GamePhase.playersSubmitting) {
    throw JogadaInvalida('Não é hora de enviar cartas');
  }
  if (jogadorId == sala.currentJudgeId) {
    throw JogadaInvalida('O juiz não envia carta');
  }
  if (sala.submittedCards.containsKey(jogadorId)) {
    throw JogadaInvalida('Você já enviou sua carta nesta rodada');
  }
  final pede = sala.currentBlackCard?.pick ?? 1;
  if (cartaIds.length != pede) {
    throw JogadaInvalida(
      pede == 1
          ? 'Escolha uma carta'
          : 'Escolha $pede cartas para esta carta preta',
    );
  }
  if (cartaIds.toSet().length != cartaIds.length) {
    throw JogadaInvalida('A mesma carta não pode ir duas vezes');
  }
  final mao = sala.hands[jogadorId] ?? const <GameCard>[];
  final cartas = [
    for (final id in cartaIds)
      mao.where((c) => c.id == id).firstOrNull ??
          (throw JogadaInvalida('Essa carta não está na sua mão')),
  ];

  final enviadas = {...sala.submittedCards, jogadorId: cartas};
  final maos = {
    ...sala.hands,
    jogadorId: [
      for (final c in mao)
        if (!cartaIds.contains(c.id)) c
    ],
  };
  final faltam = sala.players
      .where((p) => p.id != sala.currentJudgeId)
      .any((p) => !enviadas.containsKey(p.id));

  if (faltam) {
    return sala.copyWith(submittedCards: enviadas, hands: maos);
  }
  return sala.copyWith(
    submittedCards: enviadas,
    hands: maos,
    revealOrder: enviadas.keys.toList()..shuffle(random ?? Random()),
    phase: GamePhase.judgeChoosing,
  );
}

/// O juiz escolhe a carta vencedora e o dono ganha um ponto. Se chegou a
/// [GameRoom.maxPoints] o jogo acaba; senão a sala mostra o resultado da
/// rodada até o juiz chamar [proximaRodada].
GameRoom escolherVencedor(GameRoom sala, String juizId, String vencedorId) {
  if (sala.phase != GamePhase.judgeChoosing) {
    throw JogadaInvalida('Não é hora de escolher o vencedor');
  }
  if (juizId != sala.currentJudgeId) {
    throw JogadaInvalida('Só o juiz escolhe o vencedor');
  }
  if (!sala.submittedCards.containsKey(vencedorId)) {
    throw JogadaInvalida('Esse jogador não enviou carta');
  }

  final jogadores = [
    for (final p in sala.players)
      p.id == vencedorId ? p.copyWith(points: p.points + 1) : p,
  ];
  final campeao =
      jogadores.where((p) => p.points >= sala.maxPoints).firstOrNull;
  if (campeao != null) {
    return sala.copyWith(
      players: jogadores,
      phase: GamePhase.gameComplete,
      winnerId: campeao.id,
      lastRoundWinnerId: vencedorId,
    );
  }

  return sala.copyWith(
    players: jogadores,
    lastRoundWinnerId: vencedorId,
    phase: GamePhase.roundResult,
  );
}

/// Fecha o resultado da rodada: o juiz passa para o próximo jogador, as mãos
/// são completadas e uma nova carta preta é virada. Quem chama é o juiz da
/// rodada que acabou, quando o grupo terminou de ler.
GameRoom proximaRodada(GameRoom sala, String quemPediu) {
  if (sala.phase != GamePhase.roundResult) {
    throw JogadaInvalida('A rodada ainda não terminou');
  }
  if (quemPediu != sala.currentJudgeId) {
    throw JogadaInvalida('Só o juiz começa a próxima rodada');
  }

  // As cartas usadas voltam para o fim do baralho, para ele nunca acabar.
  final brancas = [
    ...sala.whiteCards,
    ...sala.submittedCards.values.expand((cs) => cs),
  ];
  final maos = <String, List<GameCard>>{};
  for (final p in sala.players) {
    final mao = [...?sala.hands[p.id]];
    while (mao.length < tamanhoDaMao && brancas.isNotEmpty) {
      mao.add(brancas.removeAt(0));
    }
    maos[p.id] = mao;
  }
  final pretas = [
    ...sala.blackCards,
    if (sala.currentBlackCard != null) sala.currentBlackCard!,
  ];

  return sala.copyWith(
    whiteCards: brancas,
    blackCards: pretas.sublist(1),
    currentBlackCard: pretas.first,
    currentJudgeId: proximoJuiz(sala.players, sala.currentJudgeId),
    hands: maos,
    submittedCards: const {},
    revealOrder: const [],
    phase: GamePhase.playersSubmitting,
  );
}

/// A carta preta com as brancas no lugar de cada `____`, na ordem. Se a preta
/// não tem lacuna (uma pergunta), as brancas vêm depois do texto.
String fraseCompleta(GameCard preta, List<GameCard> brancas) {
  var i = 0;
  final frase = preta.text.replaceAllMapped(RegExp('_{2,}'), (m) {
    return i < brancas.length ? brancas[i++].text : m[0]!;
  });
  if (i < brancas.length) {
    return '$frase ${brancas.skip(i).map((c) => c.text).join(' / ')}';
  }
  return frase;
}

/// O jogador seguinte ao juiz atual, voltando ao primeiro depois do último.
String proximoJuiz(List<Player> jogadores, String? juizAtual) {
  final i = jogadores.indexWhere((p) => p.id == juizAtual);
  return jogadores[(i + 1) % jogadores.length].id;
}

/// Adiciona um jogador à sala, se ela ainda está esperando e ele não está nela.
GameRoom entrarNaSala(GameRoom sala, Player jogador) {
  if (sala.players.any((p) => p.id == jogador.id)) return sala;
  if (sala.phase != GamePhase.waitingForPlayers) {
    throw JogadaInvalida('O jogo dessa sala já começou');
  }
  if (sala.players.length >= maximoDeJogadores) {
    throw JogadaInvalida('A sala está cheia');
  }
  return sala.copyWith(players: [...sala.players, jogador]);
}

/// Letras e números sem os que se confundem ao ditar ou ler (0/O, 1/I/L).
const _alfabetoDoCodigo = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Código de sala com [tamanho] caracteres sorteados de [_alfabetoDoCodigo].
String gerarCodigoSala({Random? random, int tamanho = 6}) {
  final rng = random ?? Random.secure();
  return String.fromCharCodes([
    for (var i = 0; i < tamanho; i++)
      _alfabetoDoCodigo.codeUnitAt(rng.nextInt(_alfabetoDoCodigo.length)),
  ]);
}

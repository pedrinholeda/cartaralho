import 'dart:math';

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

/// Um jogador envia uma carta da própria mão. Quando todos menos o juiz
/// enviaram, a sala passa para a escolha do juiz.
GameRoom enviarCarta(GameRoom sala, String jogadorId, String cartaId) {
  if (sala.phase != GamePhase.playersSubmitting) {
    throw JogadaInvalida('Não é hora de enviar cartas');
  }
  if (jogadorId == sala.currentJudgeId) {
    throw JogadaInvalida('O juiz não envia carta');
  }
  if (sala.submittedCards.containsKey(jogadorId)) {
    throw JogadaInvalida('Você já enviou sua carta nesta rodada');
  }
  final mao = sala.hands[jogadorId] ?? const <GameCard>[];
  final carta = mao.where((c) => c.id == cartaId).firstOrNull;
  if (carta == null) {
    throw JogadaInvalida('Essa carta não está na sua mão');
  }

  final enviadas = {...sala.submittedCards, jogadorId: carta};
  final maos = {
    ...sala.hands,
    jogadorId: [
      for (final c in mao)
        if (c.id != cartaId) c
    ],
  };
  final faltam = sala.players
      .where((p) => p.id != sala.currentJudgeId)
      .any((p) => !enviadas.containsKey(p.id));

  return sala.copyWith(
    submittedCards: enviadas,
    hands: maos,
    phase: faltam ? GamePhase.playersSubmitting : GamePhase.judgeChoosing,
  );
}

/// O juiz escolhe a carta vencedora. O dono ganha um ponto; se chegou a
/// [GameRoom.maxPoints] o jogo acaba, senão o juiz passa para o próximo
/// jogador, as mãos são completadas e uma nova carta preta é virada.
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

  // As cartas usadas voltam para o fim do baralho, para ele nunca acabar.
  final brancas = [...sala.whiteCards, ...sala.submittedCards.values];
  final maos = <String, List<GameCard>>{};
  for (final p in jogadores) {
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
    players: jogadores,
    whiteCards: brancas,
    blackCards: pretas.sublist(1),
    currentBlackCard: pretas.first,
    currentJudgeId: proximoJuiz(jogadores, sala.currentJudgeId),
    hands: maos,
    submittedCards: const {},
    lastRoundWinnerId: vencedorId,
    phase: GamePhase.playersSubmitting,
  );
}

/// O jogador seguinte ao juiz atual, voltando ao primeiro depois do último.
String proximoJuiz(List<Player> jogadores, String? juizAtual) {
  final i = jogadores.indexWhere((p) => p.id == juizAtual);
  return jogadores[(i + 1) % jogadores.length].id;
}

import 'dart:math';

import 'baralho.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';

/// Regras do jogo como funções puras: recebem a sala e devolvem a sala nova.
///
/// O FirebaseService lê o documento, chama uma destas funções e grava o
/// resultado numa transação. Assim a regra é testável sem Firestore.

/// Quantas cartas brancas cada jogador tem na mão, se a sala não disser outra coisa.
const tamanhoDaMao = 5;

/// Quantos caracteres cabem numa carta em branco.
const maximoDoTextoLivre = 60;

/// As cartas em branco que entram no monte: uma para cada 12 brancas, e ao
/// menos 4, para aparecerem de vez em quando em qualquer baralho.
List<GameCard> cartasEmBranco(int brancas) => [
      for (var i = 1; i <= max(4, brancas ~/ 12); i++)
        GameCard(id: 'livre-$i', text: '', type: CardType.white),
    ];

/// Uma carta usada voltando ao monte: a em branco volta vazia.
GameCard _devolvida(GameCard c) => c.emBranco ? c.comTexto('') : c;

/// O texto escrito numa carta em branco, conferido: sem espaço nas pontas,
/// sem ponto final, não vazio e dentro do limite.
String textoLivre(String? escrito) {
  var t = (escrito ?? '').trim();
  while (t.endsWith('.')) {
    t = t.substring(0, t.length - 1).trimRight();
  }
  if (t.isEmpty) throw JogadaInvalida('Escreva algo na carta em branco');
  if (t.length > maximoDoTextoLivre) {
    throw JogadaInvalida(
        'A carta em branco cabe até $maximoDoTextoLivre caracteres');
  }
  return t;
}

/// Opções oferecidas ao criar a sala.
const opcoesDePontos = [3, 5, 7, 10];
const opcoesDeMao = [5, 7];

/// Máximo de jogadores numa sala.
const maximoDeJogadores = 8;

/// Mínimo de jogadores para começar: um juiz e ao menos dois que jogam cartas.
const minimoDeJogadores = 3;

/// Erro de regra: a jogada não vale no estado atual da sala.
class JogadaInvalida implements Exception {
  JogadaInvalida(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Começa a partida: embaralha os baralhos, dá [GameRoom.handSize] cartas a cada
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
  if (brancas.length < sala.players.length * sala.handSize) {
    throw JogadaInvalida(
      'Não há cartas brancas para ${sala.players.length} jogadores com '
      '${sala.handSize} cartas na mão. Diminua a mão ou o número de jogadores.',
    );
  }

  final maos = <String, List<GameCard>>{};
  for (final jogador in sala.players) {
    maos[jogador.id] = [
      for (var i = 0; i < sala.handSize; i++) brancas.removeAt(0),
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
  Map<String, String> textos = const {},
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
  ].map((c) => c.emBranco ? c.comTexto(textoLivre(textos[c.id])) : c).toList();

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
    ...sala.submittedCards.values.expand((cs) => cs).map(_devolvida),
  ];
  final maos = <String, List<GameCard>>{};
  for (final p in sala.players) {
    final mao = [...?sala.hands[p.id]];
    while (mao.length < sala.handSize && brancas.isNotEmpty) {
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
    if (i >= brancas.length) return m[0]!;
    final texto = brancas[i++].text;
    // As brancas são escritas em minúscula para caber no meio da frase; no
    // começo dela (ou depois de . ? ! ou de aspas abrindo), ganham maiúscula.
    final antes = preta.text.substring(0, m.start).trimRight();
    final abreFrase = antes.isEmpty || '.?!"'.contains(antes[antes.length - 1]);
    return abreFrase ? _maiuscula(texto) : texto;
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

/// As reações rápidas, desenhadas em `lib/ui/icones.dart`.
const reacoes = ['risada', 'choro', 'caveira', 'coracao', 'chocado'];

/// O jogador manda uma reação, em qualquer fase: todos veem ela subir da
/// carinha dele.
GameRoom reagir(GameRoom sala, String jogadorId, String reacao) {
  if (!reacoes.contains(reacao)) {
    throw JogadaInvalida('Reação desconhecida: $reacao');
  }
  if (!sala.players.any((p) => p.id == jogadorId)) {
    throw JogadaInvalida('Você não está nesta sala');
  }
  return sala.copyWith(players: [
    for (final p in sala.players)
      p.id == jogadorId
          ? p.copyWith(reacao: reacao, reacaoVez: p.reacaoVez + 1)
          : p,
  ]);
}

/// Troca a carinha do jogador pela próxima do sorteio. Vale só na sala de
/// espera: na partida, a carinha é como o grupo reconhece cada um.
GameRoom sortearOutraCarinha(GameRoom sala, String jogadorId) {
  if (sala.phase != GamePhase.waitingForPlayers) {
    throw JogadaInvalida('A carinha só muda antes de o jogo começar');
  }
  if (!sala.players.any((p) => p.id == jogadorId)) {
    throw JogadaInvalida('Você não está nesta sala');
  }
  return sala.copyWith(players: [
    for (final p in sala.players)
      p.id == jogadorId ? p.copyWith(avatar: p.avatar + 1) : p,
  ]);
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

/// Sala nova, esperando jogadores, com o baralho inicial e a configuração
/// escolhida por quem criou.
GameRoom novaSala({
  required String roomId,
  required Player anfitriao,
  required Baralho baralho,
  int maxPoints = 5,
  int handSize = tamanhoDaMao,
}) {
  if (!opcoesDePontos.contains(maxPoints)) {
    throw JogadaInvalida('Pontos para vencer inválidos: $maxPoints');
  }
  if (!opcoesDeMao.contains(handSize)) {
    throw JogadaInvalida('Tamanho de mão inválido: $handSize');
  }
  return GameRoom(
    roomId: roomId,
    players: [anfitriao.copyWith(isHost: true, points: 0)],
    blackCards: baralho.pretas,
    whiteCards: [
      ...baralho.brancas,
      ...cartasEmBranco(baralho.brancas.length),
    ],
    currentJudgeId: anfitriao.id,
    maxPoints: maxPoints,
    handSize: handSize,
  );
}

/// Troca a mão inteira do jogador por cartas novas do monte, uma vez por
/// partida, antes de ele enviar a carta da rodada. As cartas devolvidas vão
/// para o fim do monte.
GameRoom trocarMao(GameRoom sala, String jogadorId) {
  if (sala.phase != GamePhase.playersSubmitting) {
    throw JogadaInvalida(
        'Só dá para trocar a mão enquanto as cartas são escolhidas');
  }
  if (sala.submittedCards.containsKey(jogadorId)) {
    throw JogadaInvalida('Você já enviou sua carta nesta rodada');
  }
  if (sala.handSwapsUsed.contains(jogadorId)) {
    throw JogadaInvalida('Você já trocou a mão nesta partida');
  }
  final mao = sala.hands[jogadorId];
  if (mao == null) throw JogadaInvalida('Você não está nesta partida');
  if (sala.whiteCards.length < mao.length) {
    throw JogadaInvalida(
        'Não há cartas suficientes no monte para trocar agora');
  }

  final monte = [...sala.whiteCards];
  final nova = [for (var i = 0; i < mao.length; i++) monte.removeAt(0)];
  return sala.copyWith(
    whiteCards: [...monte, ...mao],
    hands: {...sala.hands, jogadorId: nova},
    handSwapsUsed: [...sala.handSwapsUsed, jogadorId],
  );
}

/// Recomeça com o mesmo grupo: placar zerado, todas as cartas de volta ao
/// baralho e a sala esperando o anfitrião iniciar, para quem quiser entrar.
GameRoom jogarDeNovo(GameRoom sala, String quemPediu) {
  if (sala.phase != GamePhase.gameComplete) {
    throw JogadaInvalida('O jogo ainda não terminou');
  }
  if (!sala.players.any((p) => p.id == quemPediu && p.isHost)) {
    throw JogadaInvalida('Só o anfitrião recomeça o jogo');
  }
  return GameRoom(
    roomId: sala.roomId,
    players: [for (final p in sala.players) p.copyWith(points: 0)],
    blackCards: [
      ...sala.blackCards,
      if (sala.currentBlackCard != null) sala.currentBlackCard!,
    ],
    whiteCards: [
      ...sala.whiteCards,
      ...sala.hands.values.expand((m) => m),
      ...sala.submittedCards.values.expand((cs) => cs).map(_devolvida),
    ],
    currentJudgeId: sala.players.first.id,
    maxPoints: sala.maxPoints,
    handSize: sala.handSize,
  );
}

/// Gente de verdade, não bot (os bots têm id `bot-...`).
bool _pessoa(Player p) => !p.id.startsWith('bot-');

/// Se ainda há alguém de verdade na sala; sem ninguém, ela pode ser apagada.
bool temGenteNaSala(GameRoom sala) => sala.players.any(_pessoa);

/// O jogador sai da sala, em qualquer fase. As cartas dele voltam ao monte;
/// se era o anfitrião, a próxima pessoa assume; se era o juiz no meio da
/// rodada, o juiz passa adiante e a rodada recomeça com a mesma carta preta
/// (as cartas da mesa voltam para as mãos). Se sobram menos de
/// [minimoDeJogadores] no meio da partida, todo mundo volta para a sala de
/// espera, com o placar zerado, para chamar mais gente ou o Zé.
GameRoom sairDaSala(GameRoom sala, String jogadorId, {Random? random}) {
  final saindo = sala.players.where((p) => p.id == jogadorId).firstOrNull;
  if (saindo == null) throw JogadaInvalida('Você não está nesta sala');

  var restantes = [
    for (final p in sala.players)
      if (p.id != jogadorId) p,
  ];
  if (saindo.isHost) {
    final proximo = restantes.indexWhere(_pessoa);
    if (proximo >= 0) {
      restantes = [
        for (var i = 0; i < restantes.length; i++)
          i == proximo ? restantes[i].copyWith(isHost: true) : restantes[i],
      ];
    }
  }
  final devolvidas = [
    ...?sala.hands[jogadorId],
    ...?sala.submittedCards[jogadorId]?.map(_devolvida),
  ];
  final maos = {...sala.hands}..remove(jogadorId);
  final enviadas = {...sala.submittedCards}..remove(jogadorId);
  final juizSaiu = sala.currentJudgeId == jogadorId;
  final juiz = juizSaiu && restantes.isNotEmpty
      ? proximoJuiz(sala.players, jogadorId)
      : sala.currentJudgeId;
  final nova = sala.copyWith(
    players: restantes,
    hands: maos,
    submittedCards: enviadas,
    revealOrder: [
      for (final id in sala.revealOrder)
        if (id != jogadorId) id,
    ],
    whiteCards: [...sala.whiteCards, ...devolvidas],
    handSwapsUsed: [
      for (final id in sala.handSwapsUsed)
        if (id != jogadorId) id,
    ],
    currentJudgeId: juiz,
  );

  final emJogo = switch (sala.phase) {
    GamePhase.playersSubmitting ||
    GamePhase.judgeChoosing ||
    GamePhase.roundResult =>
      true,
    _ => false,
  };
  if (!emJogo || restantes.isEmpty) return nova;

  // Gente de menos para continuar: volta para a espera.
  if (restantes.length < minimoDeJogadores) {
    return GameRoom(
      roomId: sala.roomId,
      players: [for (final p in restantes) p.copyWith(points: 0)],
      blackCards: [
        ...sala.blackCards,
        if (sala.currentBlackCard != null) sala.currentBlackCard!,
      ],
      whiteCards: [
        ...nova.whiteCards,
        ...maos.values.expand((m) => m),
        ...enviadas.values.expand((cs) => cs).map(_devolvida),
      ],
      currentJudgeId: restantes.first.id,
      maxPoints: sala.maxPoints,
      handSize: sala.handSize,
    );
  }

  // O juiz saiu no meio da rodada: as cartas da mesa voltam para as mãos e a
  // rodada recomeça com o juiz novo (que também pega a dele de volta).
  if (juizSaiu &&
      (sala.phase == GamePhase.playersSubmitting ||
          sala.phase == GamePhase.judgeChoosing)) {
    return nova.copyWith(
      hands: {
        for (final p in restantes)
          p.id: [
            ...?maos[p.id],
            ...?enviadas[p.id]?.map(_devolvida),
          ],
      },
      submittedCards: const {},
      revealOrder: const [],
      phase: GamePhase.playersSubmitting,
    );
  }

  // Era o último que faltava enviar: a mesa vai para o juiz.
  if (sala.phase == GamePhase.playersSubmitting) {
    final faltam = restantes
        .where((p) => p.id != juiz)
        .any((p) => !enviadas.containsKey(p.id));
    if (!faltam && enviadas.isNotEmpty) {
      return nova.copyWith(
        revealOrder: enviadas.keys.toList()..shuffle(random ?? Random()),
        phase: GamePhase.judgeChoosing,
      );
    }
  }
  return nova;
}

/// O anfitrião tira alguém da sala (quem sumiu e está travando a rodada). O
/// resto é igual a sair: as cartas voltam ao monte, o juiz passa adiante e,
/// com menos de três, todos voltam para a espera.
GameRoom tirarDaSala(GameRoom sala, String quemPediu, String alvoId,
    {Random? random}) {
  if (!sala.players.any((p) => p.id == quemPediu && p.isHost)) {
    throw JogadaInvalida('Só o anfitrião tira alguém da sala');
  }
  if (quemPediu == alvoId) {
    throw JogadaInvalida('Para sair, use o botão de sair');
  }
  if (!sala.players.any((p) => p.id == alvoId)) {
    throw JogadaInvalida('Essa pessoa já não está na sala');
  }
  return sairDaSala(sala, alvoId, random: random);
}

String _maiuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

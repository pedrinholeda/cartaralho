import 'dart:math';

import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import 'baralho.dart';
import 'regras.dart';

/// Um adversário do modo solo. Cada um tem um pacote de cartas preferido: na
/// mão, tende a jogar as cartas dele; como juiz, tende a premiar quem jogou.
class Bot {
  final String id;
  final String nome;
  final String pacote;

  const Bot(this.id, this.nome, this.pacote);
}

/// Os bots, cada um fã de um pacote. Os ids começam com `bot-`.
const bots = [
  Bot('bot-tia', 'Tia do Zap', 'familia'),
  Bot('bot-coach', 'Coach Quântico', 'firma'),
  Bot('bot-tio', 'Tio do Pavê', 'basico'),
  Bot('bot-estagiario', 'Estagiário', 'internet'),
  Bot('bot-crush', 'Crush', 'amor'),
  Bot('bot-dj', 'DJ do Rolê', 'role'),
  Bot('bot-ze', 'Zé do Bar', 'brasilidades'),
];

/// O Zé Aleatório: completa uma sala online de duas pessoas. Não tem gosto
/// nenhum (pacote vazio), então joga e julga no puro sorteio.
const zeAleatorio = Bot('bot-ze-aleatorio', 'Zé Aleatório', '');

/// Opções de quantos bots jogam contra você.
const opcoesDeAdversarios = [2, 3, 4];

bool ehBot(String jogadorId) => jogadorId.startsWith('bot-');

Bot? botPorId(String id) =>
    [...bots, zeAleatorio].where((b) => b.id == id).firstOrNull;

/// O quanto o bot gosta de uma carta: bastante se ela é do pacote dele, e um
/// tanto de sorte, para ele não ser previsível.
double _gosto(Bot bot, GameCard carta, Random rng) =>
    // Bot não escreve: a carta em branco só vai quando não sobra outra.
    (carta.emBranco ? -10 : 0) +
    (pacoteDaCarta(carta) == bot.pacote ? 2 : 0) +
    rng.nextDouble() * 2.6;

/// O que o bot escreve se for obrigado a jogar uma carta em branco.
const _falasDoBot = [
  'um silêncio constrangedor',
  'a resposta que eu esqueci',
  'algo que não posso dizer aqui',
];

/// As cartas que o bot envia: as que ele mais gosta, quantas a preta pedir.
List<String> jogadaDoBot(GameRoom sala, String botId, Random rng) {
  final bot = botPorId(botId)!;
  final mao = [...?sala.hands[botId]];
  final pede = sala.currentBlackCard?.pick ?? 1;
  final notas = {for (final c in mao) c.id: _gosto(bot, c, rng)};
  mao.sort((a, b) => notas[b.id]!.compareTo(notas[a.id]!));
  return [for (final c in mao.take(pede)) c.id];
}

/// Quem o bot juiz escolhe: a jogada com mais cartas do pacote dele, com sorte
/// no meio.
String votoDoBot(GameRoom sala, String botId, Random rng) {
  final bot = botPorId(botId)!;
  String? melhor;
  var maior = double.negativeInfinity;
  for (final MapEntry(key: jogador, value: cartas)
      in sala.submittedCards.entries) {
    final nota =
        cartas.fold<double>(0, (soma, c) => soma + _gosto(bot, c, rng));
    if (nota > maior) {
      maior = nota;
      melhor = jogador;
    }
  }
  return melhor!;
}

/// A próxima jogada de algum bot, ou nulo quando a vez é de uma pessoa. Uma
/// por vez, para a mesa poder espaçar as jogadas no tempo.
GameRoom? passoDosBots(GameRoom sala, Random rng) {
  final juiz = sala.currentJudgeId;
  switch (sala.phase) {
    case GamePhase.playersSubmitting:
      for (final p in sala.players) {
        if (ehBot(p.id) &&
            p.id != juiz &&
            !sala.submittedCards.containsKey(p.id)) {
          final ids = jogadaDoBot(sala, p.id, rng);
          return enviarCarta(sala, p.id, ids, textos: {
            for (final id in ids)
              if (id.startsWith('livre-'))
                id: _falasDoBot[rng.nextInt(_falasDoBot.length)],
          });
        }
      }
      return null;
    case GamePhase.judgeChoosing:
      if (juiz != null && ehBot(juiz)) {
        return escolherVencedor(sala, juiz, votoDoBot(sala, juiz, rng));
      }
      return null;
    case GamePhase.roundResult:
      if (juiz != null && ehBot(juiz)) return proximaRodada(sala, juiz);
      return null;
    case GamePhase.waitingForPlayers:
    case GamePhase.gameComplete:
      return null;
  }
}

/// Uma partida solo já começada: você, que é o anfitrião e o primeiro juiz, e
/// [adversarios] bots sorteados.
GameRoom salaSolo({
  required String roomId,
  required Player voce,
  required Baralho baralho,
  int adversarios = 3,
  int maxPoints = 5,
  Random? random,
}) {
  if (!opcoesDeAdversarios.contains(adversarios)) {
    throw JogadaInvalida('Número de adversários inválido: $adversarios');
  }
  final rng = random ?? Random();
  final escolhidos = [...bots]..shuffle(rng);
  var sala = novaSala(
    roomId: roomId,
    anfitriao: voce,
    baralho: baralho,
    maxPoints: maxPoints,
  );
  for (final b in escolhidos.take(adversarios)) {
    sala = entrarNaSala(sala, Player(id: b.id, name: b.nome));
  }
  return iniciarJogo(sala, voce.id, random: rng);
}

/// Quanto o bot espera antes de jogar: rápido para mandar carta, mais devagar
/// para julgar, e o juiz bot deixa o resultado na tela uns segundos antes de
/// virar a rodada.
Duration pausaDosBots(GamePhase fase, Random rng) => switch (fase) {
      GamePhase.playersSubmitting =>
        Duration(milliseconds: 900 + rng.nextInt(1400)),
      GamePhase.judgeChoosing => const Duration(milliseconds: 2800),
      _ => const Duration(milliseconds: 5000),
    };

/// O anfitrião chama o Zé Aleatório para a sala, na espera, para dar o mínimo
/// de jogadores com duas pessoas.
GameRoom chamarZe(GameRoom sala, String quemPediu) {
  if (!sala.players.any((p) => p.id == quemPediu && p.isHost)) {
    throw JogadaInvalida('Só o anfitrião chama o Zé Aleatório');
  }
  if (sala.players.any((p) => p.id == zeAleatorio.id)) {
    throw JogadaInvalida('O Zé Aleatório já está na mesa');
  }
  return entrarNaSala(sala, Player(id: zeAleatorio.id, name: zeAleatorio.nome));
}

/// O anfitrião dispensa o Zé, ainda na espera (chegou a terceira pessoa).
GameRoom dispensarZe(GameRoom sala, String quemPediu) {
  if (!sala.players.any((p) => p.id == quemPediu && p.isHost)) {
    throw JogadaInvalida('Só o anfitrião dispensa o Zé Aleatório');
  }
  if (sala.phase != GamePhase.waitingForPlayers) {
    throw JogadaInvalida('Com o jogo começado, o Zé fica até o fim');
  }
  return sala.copyWith(
    players: [
      for (final p in sala.players)
        if (p.id != zeAleatorio.id) p,
    ],
  );
}

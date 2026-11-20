import 'card.dart';
import 'player.dart';

/// Fases da partida, na ordem em que acontecem. Gravadas pelo nome no Firestore.
enum GamePhase {
  /// Sala aberta, esperando o anfitrião iniciar.
  waitingForPlayers,

  /// Carta preta na mesa; cada jogador menos o juiz envia uma carta branca.
  playersSubmitting,

  /// Todos enviaram; o juiz escolhe a melhor.
  judgeChoosing,

  /// O juiz escolheu: todos veem a carta vencedora e quem enviou cada uma.
  roundResult,

  /// Alguém chegou a [GameRoom.maxPoints].
  gameComplete,
}

class GameRoom {
  final String roomId;
  final List<Player> players;

  /// Monte de cartas pretas ainda não viradas.
  final List<GameCard> blackCards;

  /// Monte de cartas brancas ainda não distribuídas.
  final List<GameCard> whiteCards;
  final GameCard? currentBlackCard;
  final GamePhase phase;
  final String? currentJudgeId;

  /// Mão de cada jogador, pelo id.
  final Map<String, List<GameCard>> hands;

  /// Cartas enviadas na rodada atual, na ordem das lacunas, pelo id de quem
  /// enviou.
  final Map<String, List<GameCard>> submittedCards;

  /// Ids de quem enviou, na ordem sorteada em que as cartas aparecem para o
  /// juiz e para a mesa. Vazio até todos enviarem.
  final List<String> revealOrder;

  /// Quem ganhou a última rodada, para a tela mostrar.
  final String? lastRoundWinnerId;
  final String? winnerId;
  final int maxPoints;

  GameRoom({
    required this.roomId,
    required this.players,
    required this.blackCards,
    required this.whiteCards,
    this.currentBlackCard,
    this.phase = GamePhase.waitingForPlayers,
    this.currentJudgeId,
    this.hands = const {},
    this.submittedCards = const {},
    this.revealOrder = const [],
    this.lastRoundWinnerId,
    this.winnerId,
    this.maxPoints = 5,
  });

  bool isJudge(String playerId) => playerId == currentJudgeId;

  /// As cartas enviadas na ordem em que aparecem na mesa, com o id de quem
  /// enviou. Segue [revealOrder]; antes do sorteio, a ordem do mapa.
  List<MapEntry<String, List<GameCard>>> get cardsOnTable {
    final ordem =
        revealOrder.isNotEmpty ? revealOrder : submittedCards.keys.toList();
    return [
      for (final id in ordem)
        if (submittedCards[id] != null) MapEntry(id, submittedCards[id]!),
    ];
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    List<GameCard> cartas(Object? lista) => (lista as List<dynamic>? ?? [])
        .map((c) => GameCard.fromJson(c as Map<String, dynamic>))
        .toList();

    return GameRoom(
      roomId: json['roomId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      blackCards: cartas(json['blackCards']),
      whiteCards: cartas(json['whiteCards']),
      currentBlackCard: json['currentBlackCard'] != null
          ? GameCard.fromJson(json['currentBlackCard'] as Map<String, dynamic>)
          : null,
      phase: GamePhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => GamePhase.waitingForPlayers,
      ),
      currentJudgeId: json['currentJudgeId'] as String?,
      hands: (json['hands'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, cartas(value))),
      // Até a 0.2 cada jogador enviava uma carta só, gravada como mapa; daí em
      // diante é uma lista na ordem das lacunas. Lê os dois formatos.
      submittedCards:
          (json['submittedCards'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          value is List
              ? cartas(value)
              : [GameCard.fromJson(value as Map<String, dynamic>)],
        ),
      ),
      revealOrder: (json['revealOrder'] as List<dynamic>? ?? []).cast<String>(),
      lastRoundWinnerId: json['lastRoundWinnerId'] as String?,
      winnerId: json['winnerId'] as String?,
      maxPoints: json['maxPoints'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'players': players.map((p) => p.toJson()).toList(),
      'blackCards': blackCards.map((c) => c.toJson()).toList(),
      'whiteCards': whiteCards.map((c) => c.toJson()).toList(),
      'currentBlackCard': currentBlackCard?.toJson(),
      'phase': phase.name,
      'currentJudgeId': currentJudgeId,
      'hands': hands.map(
        (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
      ),
      'submittedCards': submittedCards.map(
        (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
      ),
      'revealOrder': revealOrder,
      'lastRoundWinnerId': lastRoundWinnerId,
      'winnerId': winnerId,
      'maxPoints': maxPoints,
    };
  }

  GameRoom copyWith({
    String? roomId,
    List<Player>? players,
    List<GameCard>? blackCards,
    List<GameCard>? whiteCards,
    GameCard? currentBlackCard,
    GamePhase? phase,
    String? currentJudgeId,
    Map<String, List<GameCard>>? hands,
    Map<String, List<GameCard>>? submittedCards,
    List<String>? revealOrder,
    String? lastRoundWinnerId,
    String? winnerId,
    int? maxPoints,
  }) {
    return GameRoom(
      roomId: roomId ?? this.roomId,
      players: players ?? this.players,
      blackCards: blackCards ?? this.blackCards,
      whiteCards: whiteCards ?? this.whiteCards,
      currentBlackCard: currentBlackCard ?? this.currentBlackCard,
      phase: phase ?? this.phase,
      currentJudgeId: currentJudgeId ?? this.currentJudgeId,
      hands: hands ?? this.hands,
      submittedCards: submittedCards ?? this.submittedCards,
      revealOrder: revealOrder ?? this.revealOrder,
      lastRoundWinnerId: lastRoundWinnerId ?? this.lastRoundWinnerId,
      winnerId: winnerId ?? this.winnerId,
      maxPoints: maxPoints ?? this.maxPoints,
    );
  }
}

import 'player.dart';
import 'card.dart';

enum GamePhase {
  waitingForPlayers,
  choosingBlackCard,
  playersSubmitting,
  judgeChoosing,
  roundComplete,
  gameComplete,
}

class GameRoom {
  final String roomId;
  final List<Player> players;
  final List<GameCard> blackCards;
  final List<GameCard> whiteCards;
  final GameCard? currentBlackCard;
  final GamePhase phase;
  final String? currentJudgeId;
  final Map<String, GameCard> submittedCards;
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
    this.submittedCards = const {},
    this.winnerId,
    this.maxPoints = 5,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      roomId: json['roomId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      blackCards: (json['blackCards'] as List<dynamic>)
          .map((c) => GameCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      whiteCards: (json['whiteCards'] as List<dynamic>)
          .map((c) => GameCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      currentBlackCard: json['currentBlackCard'] != null
          ? GameCard.fromJson(json['currentBlackCard'] as Map<String, dynamic>)
          : null,
      phase: GamePhase.values.firstWhere(
        (e) => e.toString() == 'GamePhase.${json['phase']}',
        orElse: () => GamePhase.waitingForPlayers,
      ),
      currentJudgeId: json['currentJudgeId'] as String?,
      submittedCards: (json['submittedCards'] as Map<String, dynamic>? ?? {})
          .map((key, value) =>
              MapEntry(key, GameCard.fromJson(value as Map<String, dynamic>))),
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
      'phase': phase.toString().split('.').last,
      'currentJudgeId': currentJudgeId,
      'submittedCards':
          submittedCards.map((key, value) => MapEntry(key, value.toJson())),
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
    Map<String, GameCard>? submittedCards,
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
      submittedCards: submittedCards ?? this.submittedCards,
      winnerId: winnerId ?? this.winnerId,
      maxPoints: maxPoints ?? this.maxPoints,
    );
  }
}

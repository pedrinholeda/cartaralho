class Player {
  final String id;
  final String name;
  final int points;
  final bool isHost;

  /// Quantas vezes o jogador sorteou outra carinha; com o id, decide qual
  /// carinha ele tem (`Carinha.de`).
  final int avatar;

  Player({
    required this.id,
    required this.name,
    this.points = 0,
    this.isHost = false,
    this.avatar = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      points: json['points'] as int? ?? 0,
      isHost: json['isHost'] as bool? ?? false,
      avatar: json['avatar'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points,
      'isHost': isHost,
      'avatar': avatar,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    int? points,
    bool? isHost,
    int? avatar,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      isHost: isHost ?? this.isHost,
      avatar: avatar ?? this.avatar,
    );
  }
}

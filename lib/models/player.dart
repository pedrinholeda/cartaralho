class Player {
  final String id;
  final String name;
  final int points;
  final bool isHost;

  Player({
    required this.id,
    required this.name,
    this.points = 0,
    this.isHost = false,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      points: json['points'] as int? ?? 0,
      isHost: json['isHost'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points,
      'isHost': isHost,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    int? points,
    bool? isHost,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      isHost: isHost ?? this.isHost,
    );
  }
}

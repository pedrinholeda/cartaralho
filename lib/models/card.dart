enum CardType { black, white }

class GameCard {
  final String id;
  final String text;
  final CardType type;

  GameCard({
    required this.id,
    required this.text,
    required this.type,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] as String,
      text: json['text'] as String,
      type: CardType.values.firstWhere(
        (e) => e.toString() == 'CardType.${json['type']}',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.toString().split('.').last,
    };
  }
}

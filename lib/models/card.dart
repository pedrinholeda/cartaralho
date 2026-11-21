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

  /// Carta em branco: quem joga escreve a resposta. O id começa com `livre-`;
  /// no monte e na mão o texto é vazio, e na mesa é o que a pessoa escreveu.
  bool get emBranco => id.startsWith('livre-');

  /// A mesma carta com outro texto (a resposta escrita, ou vazia de novo).
  GameCard comTexto(String novo) => GameCard(id: id, text: novo, type: type);

  /// Quantas cartas brancas uma carta preta pede: uma por lacuna (`____`), e
  /// uma quando ela é uma pergunta sem lacuna.
  int get pick {
    final lacunas = RegExp('_{2,}').allMatches(text).length;
    return lacunas == 0 ? 1 : lacunas;
  }

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

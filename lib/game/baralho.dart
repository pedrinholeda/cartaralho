import 'dart:convert';

import '../models/card.dart';

/// Onde fica o baralho com que toda sala nova começa. Editar as cartas é
/// editar esse arquivo; `test/game/baralho_test.dart` confere as regras dele.
const arquivoDoBaralho = 'assets/baralhos/basico.json';

/// Um baralho: cartas pretas (as frases com lacuna) e brancas (as respostas).
class Baralho {
  final String nome;
  final List<GameCard> pretas;
  final List<GameCard> brancas;

  const Baralho({
    required this.nome,
    required this.pretas,
    required this.brancas,
  });

  /// Lê o JSON do baralho (`nome`, `pretas` e `brancas`, as duas listas de
  /// texto). Os ids saem da posição: `b1`, `b2`... e `w1`, `w2`...
  factory Baralho.fromJsonString(String conteudo) {
    final json = jsonDecode(conteudo) as Map<String, dynamic>;
    List<String> textos(String chave) =>
        (json[chave] as List<dynamic>).cast<String>();
    final pretas = textos('pretas');
    final brancas = textos('brancas');
    return Baralho(
      nome: json['nome'] as String,
      pretas: [
        for (var i = 0; i < pretas.length; i++)
          GameCard(id: 'b${i + 1}', text: pretas[i], type: CardType.black),
      ],
      brancas: [
        for (var i = 0; i < brancas.length; i++)
          GameCard(id: 'w${i + 1}', text: brancas[i], type: CardType.white),
      ],
    );
  }
}

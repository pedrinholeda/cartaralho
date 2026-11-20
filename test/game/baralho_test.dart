import 'package:cartaralho/game/baralho.dart';
import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/models/card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('há cartas brancas para o máximo de jogadores', () {
    expect(cartasBrancas().length,
        greaterThanOrEqualTo(maximoDeJogadores * tamanhoDaMao));
  });

  test('os ids não se repetem e o tipo bate com o monte', () {
    final pretas = cartasPretas();
    final brancas = cartasBrancas();
    final ids = [...pretas, ...brancas].map((c) => c.id);

    expect(ids.toSet().length, ids.length);
    expect(pretas.every((c) => c.type == CardType.black), isTrue);
    expect(brancas.every((c) => c.type == CardType.white), isTrue);
  });

  test('toda carta preta tem a lacuna', () {
    for (final c in cartasPretas()) {
      expect(c.text, contains('____'), reason: c.text);
    }
  });

  test('o texto das cartas brancas não se repete', () {
    final textos = cartasBrancas().map((c) => c.text.toLowerCase());
    expect(textos.toSet().length, textos.length);
  });
}

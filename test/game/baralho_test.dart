import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/models/card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio.dart';

/// Regras do arquivo assets/baralhos/basico.json. Quem edita as cartas roda
/// `flutter test test/game/baralho_test.dart` para conferir.
void main() {
  final baralho = baralhoDoArquivo();

  test('há cartas brancas para o máximo de jogadores com a maior mão', () {
    final maiorMao = opcoesDeMao.reduce((a, b) => a > b ? a : b);
    expect(baralho.brancas.length,
        greaterThanOrEqualTo(maximoDeJogadores * maiorMao));
  });

  test('os ids não se repetem e o tipo bate com o monte', () {
    final ids = [...baralho.pretas, ...baralho.brancas].map((c) => c.id);
    expect(ids.toSet().length, ids.length);
    expect(baralho.pretas.every((c) => c.type == CardType.black), isTrue);
    expect(baralho.brancas.every((c) => c.type == CardType.white), isTrue);
  });

  test('toda carta preta pede de uma a três brancas, e cabe na mão', () {
    for (final c in baralho.pretas) {
      expect(c.pick, inInclusiveRange(1, 3), reason: c.text);
      expect(c.pick, lessThanOrEqualTo(tamanhoDaMao), reason: c.text);
    }
  });

  test('a lacuna é sempre ____ (quatro sublinhados)', () {
    for (final c in baralho.pretas) {
      expect(
          RegExp(r'_+').allMatches(c.text).every((m) => m[0] == '____'), isTrue,
          reason: c.text);
    }
  });

  test('há cartas "Escolha 2" e "Escolha 3"', () {
    expect(baralho.pretas.where((c) => c.pick == 2), isNotEmpty);
    expect(baralho.pretas.where((c) => c.pick == 3), isNotEmpty);
  });

  test('nenhum texto se repete', () {
    for (final monte in [baralho.pretas, baralho.brancas]) {
      final textos = monte.map((c) => c.text.toLowerCase());
      expect(textos.toSet().length, textos.length);
    }
  });

  test('sem preposição que vira contração antes da lacuna', () {
    // As brancas trazem o artigo ("o cunhado"), então "fala de ____" vira
    // "fala de o cunhado" em vez de "do cunhado".
    final contrai =
        RegExp('(^|[^a-zà-ú])(de|em|por|a) +____', caseSensitive: false);
    for (final c in baralho.pretas) {
      expect(c.text, isNot(matches(contrai)), reason: c.text);
    }
  });

  test('carta branca não termina em ponto final', () {
    for (final c in baralho.brancas) {
      expect(c.text, isNot(endsWith('.')), reason: c.text);
    }
  });

  test('carta branca começa com minúscula, salvo nome próprio', () {
    // O jogo põe a maiúscula quando a lacuna abre a frase. Uma branca com
    // maiúscula fica estranha no meio dela ("meu problema é Uma planilha").
    // Artigos e palavras comuns no começo denunciam o erro.
    final comecoComum = RegExp(r'^(O|A|Os|As|Um|Uma|Meu|Minha|Seu|Sua) ');
    for (final c in baralho.brancas) {
      expect(c.text, isNot(matches(comecoComum)), reason: c.text);
    }
  });
}

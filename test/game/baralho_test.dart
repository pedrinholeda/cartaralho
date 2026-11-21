import 'dart:io';

import 'package:cartaralho/game/baralho.dart';
import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/models/card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio.dart';

/// Regras dos pacotes em assets/baralhos/. Quem edita as cartas roda
/// `flutter test test/game/baralho_test.dart` para conferir.
void main() {
  test('todo arquivo em assets/baralhos está no catálogo, e vice-versa', () {
    final arquivos = Directory('assets/baralhos')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.json'))
        .map((n) => n.replaceAll('.json', ''))
        .toSet();
    expect(arquivos, pacotes.toSet());
  });

  for (final id in pacotes) {
    group('pacote $id', () {
      final baralho = pacoteDoArquivo(id);

      test('tem nome e descrição', () {
        expect(baralho.nome, isNotEmpty);
        expect(baralho.descricao, isNotEmpty);
      });

      test('sozinho, tem brancas para o máximo de jogadores e a maior mão', () {
        final maiorMao = opcoesDeMao.reduce((a, b) => a > b ? a : b);
        expect(baralho.brancas.length,
            greaterThanOrEqualTo(maximoDeJogadores * maiorMao));
      });

      test('os ids levam o pacote e o tipo bate com o monte', () {
        expect(baralho.pretas.every((c) => c.type == CardType.black), isTrue);
        expect(baralho.brancas.every((c) => c.type == CardType.white), isTrue);
        for (final c in [...baralho.pretas, ...baralho.brancas]) {
          expect(pacoteDaCarta(c), id);
        }
      });

      test('toda carta preta pede de uma a três brancas, e cabe na mão', () {
        for (final c in baralho.pretas) {
          expect(c.pick, inInclusiveRange(1, 3), reason: c.text);
          expect(c.pick, lessThanOrEqualTo(tamanhoDaMao), reason: c.text);
        }
      });

      test('a lacuna é sempre ____ (quatro sublinhados), solta na frase', () {
        for (final c in baralho.pretas) {
          expect(RegExp(r'_+').allMatches(c.text).every((m) => m[0] == '____'),
              isTrue,
              reason: c.text);
          // "gestão d____" junta a letra com a branca: "gestão do cunhado"
          // só dá certo com algumas cartas.
          expect(c.text, isNot(matches(RegExp('[A-Za-zÀ-ú]____'))),
              reason: c.text);
        }
      });

      test('há cartas "Escolha 2" e "Escolha 3"', () {
        expect(baralho.pretas.where((c) => c.pick == 2), isNotEmpty);
        expect(baralho.pretas.where((c) => c.pick == 3), isNotEmpty);
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
    });
  }

  group('todos os pacotes juntos', () {
    final todos =
        Baralho.juntar([for (final id in pacotes) pacoteDoArquivo(id)]);

    test('os ids não se repetem', () {
      final ids = [...todos.pretas, ...todos.brancas].map((c) => c.id);
      expect(ids.toSet().length, ids.length);
    });

    test('nenhum texto se repete, nem de um pacote para outro', () {
      for (final monte in [todos.pretas, todos.brancas]) {
        final textos = monte.map((c) => c.text.toLowerCase());
        expect(textos.toSet().length, textos.length);
      }
    });
  });

  group('Baralho.juntar', () {
    final basico = pacoteDoArquivo('basico');
    final firma = pacoteDoArquivo('firma');

    test('soma as cartas e os nomes dos pacotes', () {
      final junto = Baralho.juntar([basico, firma]);
      expect(junto.pretas.length, basico.pretas.length + firma.pretas.length);
      expect(
          junto.brancas.length, basico.brancas.length + firma.brancas.length);
      expect(junto.nome, 'Básico, Firma');
    });

    test('um pacote só volta ele mesmo', () {
      expect(Baralho.juntar([firma]), same(firma));
    });

    test('sem pacote nenhum, recusa', () {
      expect(() => Baralho.juntar([]), throwsArgumentError);
    });
  });

  test('carta de sala antiga, sem prefixo no id, conta como do básico', () {
    final antiga = GameCard(id: 'w3', text: 'meu ex', type: CardType.white);
    expect(pacoteDaCarta(antiga), 'basico');
  });

  group('pacote +18', () {
    test('só o Sem filtro é adulto, e ele não vem marcado', () {
      final adultos = [
        for (final id in pacotes)
          if (pacoteDoArquivo(id).adulto) id,
      ];
      expect(adultos, ['sem-filtro']);
      expect(pacotesPadrao, isNot(contains('sem-filtro')));
      expect(pacotesPadrao.toSet(), {...pacotes}..remove('sem-filtro'));
    });

    test('juntar com o +18 marca o baralho como adulto', () {
      final junto = Baralho.juntar(
          [pacoteDoArquivo('leve'), pacoteDoArquivo('sem-filtro')]);
      expect(junto.adulto, isTrue);
      expect(Baralho.juntar([pacoteDoArquivo('leve')]).adulto, isFalse);
    });
  });

  test('juntarEscolhidos junta só os pacotes marcados, na ordem do catálogo',
      () {
    final todos = [for (final id in pacotes) pacoteDoArquivo(id)];
    final junto = juntarEscolhidos(todos, {'amor', 'basico'});
    expect(junto.nome, 'Básico, Amor e desamor');
    expect(junto.brancas.map(pacoteDaCarta).toSet(), {'basico', 'amor'});
  });
}

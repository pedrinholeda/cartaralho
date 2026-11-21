import 'package:cartaralho/models/player.dart';
import 'package:cartaralho/ui/icones.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:cartaralho/widgets/reacoes_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Player p) => MaterialApp(
      theme: tema,
      home: Scaffold(
        body: Center(
          child: ComReacao(
            jogador: p,
            roomId: null,
            meu: false,
            tamanho: 44,
            child: const SizedBox.square(dimension: 44),
          ),
        ),
      ),
    );

bool _subindo(WidgetTester tester, Desenho d) => find
    .byWidgetPredicate((w) => w is IconeFofo && w.desenho == d)
    .evaluate()
    .isNotEmpty;

void main() {
  testWidgets('a reação nova sobe da carinha e some', (tester) async {
    final antes = Player(id: 'a', name: 'Ana', reacao: 'risada', reacaoVez: 1);
    await tester.pumpWidget(_app(antes));
    // A que já estava quando a tela abriu não sobe.
    expect(_subindo(tester, Desenho.risada), isFalse);

    await tester
        .pumpWidget(_app(antes.copyWith(reacao: 'caveira', reacaoVez: 2)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_subindo(tester, Desenho.caveira), isTrue);

    await tester.pump(const Duration(seconds: 2));
    expect(_subindo(tester, Desenho.caveira), isFalse);
  });

  testWidgets('os desenhos das reações se pintam', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: Row(children: [
        for (final d in [
          Desenho.risada,
          Desenho.choro,
          Desenho.caveira,
          Desenho.coracao,
          Desenho.chocado,
        ])
          IconeFofo(d, tamanho: 32),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });
}

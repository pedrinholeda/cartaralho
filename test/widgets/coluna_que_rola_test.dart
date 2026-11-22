import 'package:cartaralho/widgets/coluna_que_rola.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fase de juiz, simplificada: lista que estica e o botão embaixo.
Widget _juiz(VoidCallback aoEscolher) => Column(
      children: [
        Expanded(child: ListView(children: const [Text('frase 1')])),
        ElevatedButton(
            onPressed: aoEscolher, child: const Text('Escolher vencedor')),
      ],
    );

Widget _tela(double alturaDoTopo, VoidCallback aoEscolher) => MaterialApp(
      home: Scaffold(
        body: ColunaQueRola(
          topo: [SizedBox(height: alturaDoTopo, child: const Text('topo'))],
          conteudo: _juiz(aoEscolher),
        ),
      ),
    );

void main() {
  testWidgets('com espaço, o conteúdo ocupa o resto e nada rola',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 664));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_tela(200, () {}));
    final rolagem =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(rolagem.position.maxScrollExtent, 0);
    // O botão fica colado no fim da tela, como antes.
    expect(
        tester.getBottomLeft(find.byType(ElevatedButton)).dy, closeTo(664, 1));
  });

  testWidgets('topo alto num celular baixo: rola até o botão do juiz',
      (tester) async {
    // O caso relatado: juiz no celular, sem achar "Escolher vencedor".
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var escolheu = false;
    await tester.pumpWidget(_tela(450, () => escolheu = true));
    expect(tester.takeException(), isNull, reason: 'sem estouro de layout');
    final botao = find.text('Escolher vencedor');
    // Arrasta a tela inteira (a rolagem de fora) até o fim.
    await tester.drag(find.text('topo'), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(botao);
    expect(escolheu, isTrue);
    expect(tester.getSize(find.byType(ListView)).height, greaterThan(250));
  });
}

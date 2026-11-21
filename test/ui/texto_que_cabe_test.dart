import 'package:cartaralho/ui/cartas.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fonte dos testes (Ahem) tem todo caractere quadrado, mais largo que a
  // Figtree: a palavra do teste é curta o bastante para caber acima do mínimo.
  testWidgets('numa carta estreita, a palavra longa não quebra no meio',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: const Center(
        child: SizedBox(
          width: 128,
          height: 180,
          child: CartaBranca(texto: 'o cancelado de ontem'),
        ),
      ),
    ));
    final texto = tester.widget<Text>(find.text('o cancelado de ontem'));
    // Antes a letra ficava em 15 e "cancelado" quebrava; agora encolhe.
    expect(texto.style!.fontSize, lessThan(15));
    final caixa = tester.getSize(find.text('o cancelado de ontem'));
    final largura = tester.getSize(find.byType(CartaBranca)).width;
    expect(caixa.width, lessThanOrEqualTo(largura));
    final palavra = TextPainter(
      text: TextSpan(text: 'cancelado', style: texto.style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(palavra.width, lessThanOrEqualTo(caixa.width + .5));
  });

  testWidgets('quando tudo cabe, a letra fica no tamanho normal',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: const Center(
        child: SizedBox(
          width: 128,
          height: 180,
          child: CartaBranca(texto: 'meu ex'),
        ),
      ),
    ));
    expect(tester.widget<Text>(find.text('meu ex')).style!.fontSize, 15);
  });
}

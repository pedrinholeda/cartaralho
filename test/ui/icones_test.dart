import 'package:cartaralho/ui/icones.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('todo desenho se pinta sem erro', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: Wrap(children: [
        for (final d in Desenho.values) IconeFofo(d),
        const IconeFofo(Desenho.coroa, gotejo: 0),
        const IconeFofo(Desenho.coroa, gotejo: .5),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem cor, usa a do IconTheme, como um Icon', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: const Center(
        child: IconTheme(
          data: IconThemeData(color: Color(0xFF123456), size: 30),
          child: IconeFofo(Desenho.dado),
        ),
      ),
    ));
    final pintor = tester
        .widget<CustomPaint>(find.descendant(
            of: find.byType(IconeFofo), matching: find.byType(CustomPaint)))
        .painter! as PintorDeIcone;
    expect(pintor.cor, const Color(0xFF123456));
    expect(tester.getSize(find.byType(IconeFofo)), const Size(30, 30));
  });
}

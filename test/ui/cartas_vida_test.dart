import 'package:cartaralho/ui/cartas.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _carta({bool parado = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: parado),
      child: MaterialApp(
        theme: tema,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 128,
              height: 180,
              child: CartaBranca(texto: 'meu ex', aoTocar: () {}),
            ),
          ),
        ),
      ),
    );

/// A matriz 3D em volta da carta (a da inclinação), se houver.
Matrix4? _inclinacao(WidgetTester tester) {
  final t = find.descendant(
      of: find.byType(CartaBranca),
      matching: find.byWidgetPredicate(
          (w) => w is Transform && w.transform.entry(3, 2) != 0));
  return t.evaluate().isEmpty
      ? null
      : tester.widget<Transform>(t.first).transform;
}

/// A inclinação é suave (140 ms): alguns quadros até ela chegar.
Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('a carta inclina sob o mouse e volta ao sair', (tester) async {
    await tester.pumpWidget(_carta());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final canto =
        tester.getTopLeft(find.byType(CartaBranca)) + const Offset(10, 10);
    await mouse.moveTo(canto);
    await _assentar(tester);
    final inclinada = _inclinacao(tester)!;
    expect(inclinada.isIdentity(), isFalse);

    await mouse.moveTo(const Offset(1, 1));
    await _assentar(tester);
    // Fora da carta: volta reta (só a perspectiva fica).
    final reta = _inclinacao(tester)!;
    expect(reta.entry(0, 2).abs() + reta.entry(1, 2).abs(), lessThan(1e-6));
  });

  testWidgets('com "reduzir movimento", a carta não inclina', (tester) async {
    await tester.pumpWidget(_carta(parado: true));
    expect(_inclinacao(tester), isNull);
  });

  testWidgets('o voo da carta termina e avisa', (tester) async {
    var terminou = false;
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: VooDasCartas(
        origens: const [(Rect.fromLTWH(10, 500, 128, 180), 'meu ex')],
        destino: const Rect.fromLTWH(20, 80, 360, 120),
        aoTerminar: () => terminou = true,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('meu ex'), findsOneWidget);
    expect(terminou, isFalse);
    await tester.pump(const Duration(milliseconds: 400));
    expect(terminou, isTrue);
  });
}

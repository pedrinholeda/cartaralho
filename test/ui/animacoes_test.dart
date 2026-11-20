import 'package:cartaralho/ui/animacoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta [filho] num app mínimo, com ou sem "reduzir movimento".
Widget app(Widget filho, {bool reduzir = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduzir),
      child: MaterialApp(home: Scaffold(body: filho)),
    );

double opacidadeDe(WidgetTester tester, Finder f) => tester
    .widget<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity)).first)
    .opacity;

void main() {
  group('Entrada', () {
    testWidgets('começa invisível e termina inteira', (tester) async {
      await tester.pumpWidget(app(const Entrada(child: Text('carta'))));
      expect(opacidadeDe(tester, find.text('carta')), 0);

      await tester.pumpAndSettle();
      expect(opacidadeDe(tester, find.text('carta')), 1);
    });

    testWidgets('com "reduzir movimento", aparece direto', (tester) async {
      await tester.pumpWidget(
        app(const Entrada(child: Text('carta')), reduzir: true),
      );
      await tester.pump();
      expect(opacidadeDe(tester, find.text('carta')), 1);
    });
  });

  group('Virada', () {
    testWidgets('mostra o verso e depois a frente', (tester) async {
      await tester.pumpWidget(app(const Virada(child: Text('frente'))));
      await tester.pump();
      expect(find.text('Cartaralho'), findsOneWidget, reason: 'o verso');

      await tester.pumpAndSettle();
      expect(find.text('Cartaralho'), findsNothing);
      expect(find.text('frente'), findsOneWidget);
    });

    testWidgets('com "reduzir movimento", já vem de frente', (tester) async {
      await tester.pumpWidget(
        app(const Virada(child: Text('frente')), reduzir: true),
      );
      await tester.pump();
      expect(find.text('Cartaralho'), findsNothing);
    });
  });

  group('Confete', () {
    testWidgets('cai e acaba sozinho', (tester) async {
      await tester.pumpWidget(app(const Confete()));
      expect(
        find.descendant(
          of: find.byType(Confete),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('com "reduzir movimento", não aparece', (tester) async {
      await tester.pumpWidget(app(const Confete(), reduzir: true));
      expect(
        find.descendant(
          of: find.byType(Confete),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });
}

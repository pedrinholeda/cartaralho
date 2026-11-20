import 'package:cartaralho/models/card.dart';
import 'package:cartaralho/ui/assombro.dart';
import 'package:cartaralho/ui/cartas.dart';
import 'package:cartaralho/ui/carinhas.dart';
import 'package:cartaralho/ui/jogadores.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:cartaralho/widgets/black_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget filho) =>
    MaterialApp(theme: tema, home: Scaffold(body: filho));

final _preta =
    GameCard(id: 'b1', text: 'O problema é ____.', type: CardType.black);

void main() {
  tearDown(() => agora = DateTime.now);

  group('ehMadrugada', () {
    test('das 3h às 4h59', () {
      expect(ehMadrugada(DateTime(2026, 1, 1, 2, 59)), isFalse);
      expect(ehMadrugada(DateTime(2026, 1, 1, 3)), isTrue);
      expect(ehMadrugada(DateTime(2026, 1, 1, 4, 59)), isTrue);
      expect(ehMadrugada(DateTime(2026, 1, 1, 5)), isFalse);
      expect(ehMadrugada(DateTime(2026, 1, 1, 15, 30)), isFalse);
    });
  });

  PintorDeCarinha pintorDoAvatar(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((c) => c.painter)
      .whereType<PintorDeCarinha>()
      .single;

  testWidgets('na madrugada a carinha fica assombrada e a carta pergunta',
      (tester) async {
    agora = () => DateTime(2026, 1, 1, 3, 30);
    await tester.pumpWidget(_app(Column(children: [
      const AvatarDeJogador(nome: 'Ana', indice: 0),
      BlackCardWidget(card: _preta),
    ])));
    expect(pintorDoAvatar(tester).assombrada, isTrue);
    expect(find.text(rodapeDaMadrugada), findsOneWidget);
  });

  testWidgets('de dia, nada disso', (tester) async {
    agora = () => DateTime(2026, 1, 1, 15);
    await tester.pumpWidget(_app(Column(children: [
      const AvatarDeJogador(nome: 'Ana', indice: 0),
      BlackCardWidget(card: _preta),
    ])));
    expect(pintorDoAvatar(tester).assombrada, isFalse);
    expect(find.text(rodapeDaMadrugada), findsNothing);
  });

  group('a lacuna que espera', () {
    testWidgets('abre um olho depois da espera, para quem não enviou',
        (tester) async {
      await tester
          .pumpWidget(_app(BlackCardWidget(card: _preta, esperando: true)));
      await tester.pump(esperaDaLacuna - const Duration(seconds: 1));
      expect(find.byType(OlhoNaLacuna), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(OlhoNaLacuna), findsOneWidget);
    });

    testWidgets('fecha quando o jogador envia', (tester) async {
      await tester
          .pumpWidget(_app(BlackCardWidget(card: _preta, esperando: true)));
      await tester.pump(esperaDaLacuna + const Duration(seconds: 1));
      await tester.pumpWidget(_app(BlackCardWidget(card: _preta)));
      await tester.pump();
      expect(find.byType(OlhoNaLacuna), findsNothing);
    });

    testWidgets('quem não está esperando nunca é olhado', (tester) async {
      await tester.pumpWidget(_app(BlackCardWidget(card: _preta)));
      await tester.pump(esperaDaLacuna * 2);
      expect(find.byType(OlhoNaLacuna), findsNothing);
    });

    testWidgets('com todas as lacunas preenchidas, não há onde abrir o olho',
        (tester) async {
      await tester.pumpWidget(_app(const CartaPreta(
        texto: 'O problema é ____.',
        respostas: ['o cunhado'],
        olho: true,
      )));
      expect(find.byType(OlhoNaLacuna), findsNothing);
    });

    testWidgets('com "reduzir movimento", o olho já vem aberto e parado',
        (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(const CartaPreta(texto: 'O problema é ____.', olho: true)),
      ));
      expect(find.byType(OlhoNaLacuna), findsOneWidget);
      // Nada fica em loop: assentar termina (com animação, travaria).
      await tester.pumpAndSettle();
    });
  });
}

import 'package:cartaralho/models/player.dart';
import 'package:cartaralho/ui/cartas.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:cartaralho/widgets/player_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget filho, {double largura = 400}) => MaterialApp(
      theme: tema,
      home: Scaffold(
        body: Center(child: SizedBox(width: largura, child: filho)),
      ),
    );

void main() {
  final jogadores = [
    Player(id: 'a', name: 'Ana', points: 2),
    Player(id: 'bot-coach', name: 'Coach Quântico', points: 1),
  ];

  testWidgets('no computador, o placar vem em lista com o nome inteiro',
      (tester) async {
    await tester.pumpWidget(_app(PlayerListWidget(
      players: jogadores,
      judgeId: 'a',
      vertical: true,
    )));
    await tester.pumpAndSettle();
    final nome = tester.widget<Text>(find.text('Coach Quântico'));
    expect(nome.maxLines, 1);
    // Cabe inteiro: a linha não foi cortada com reticências.
    final caixa =
        tester.renderObject<RenderParagraph>(find.text('Coach Quântico'));
    expect(caixa.didExceedMaxLines, isFalse);
    expect(find.text('2'), findsOneWidget);
  });

  Future<double> larguraDaCarta(WidgetTester tester, double largura) async {
    await tester.binding.setSurfaceSize(Size(largura + 100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(
      MaoEmLeque(
        quantidade: 3,
        construir: (_, i) => CartaBranca(texto: 'carta $i'),
      ),
      largura: largura,
    ));
    return tester.getSize(find.byType(CartaBranca).first).width;
  }

  testWidgets('a mão cresce quando há espaço', (tester) async {
    expect(await larguraDaCarta(tester, 390), MaoEmLeque.larguraDaCarta);
    expect(await larguraDaCarta(tester, 700), MaoEmLeque.larguraDaCartaGrande);
  });
}

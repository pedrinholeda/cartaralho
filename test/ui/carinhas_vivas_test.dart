import 'package:cartaralho/ui/carinhas.dart';
import 'package:cartaralho/ui/jogadores.dart';
import 'package:cartaralho/ui/olhar.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _trio({bool parado = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: parado),
      child: MaterialApp(
        theme: tema,
        home: const Scaffold(
          body: Center(
            child: GrupoDeCarinhas(
              quantidade: 3,
              eixo: Axis.horizontal,
              passo: 62,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AvatarDeJogador(nome: 'Ana', indice: 0, assombrado: false),
                  SizedBox(width: 6),
                  AvatarDeJogador(nome: 'Bia', indice: 1, assombrado: false),
                  SizedBox(width: 6),
                  AvatarDeJogador(nome: 'Caio', indice: 2, assombrado: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );

Iterable<PintorDeCarinha> _pintores(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((c) => c.painter)
    .whereType<PintorDeCarinha>();

void main() {
  tearDown(() => ondeOlhar.value = null);

  testWidgets('num grupo, uma carinha dá cascudo e a vizinha fica tonta',
      (tester) async {
    await tester.pumpWidget(_trio());
    var viuTonta = false;
    // O primeiro cascudo sai depois de uns 8 segundos.
    for (var i = 0; i < 100 && !viuTonta; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      viuTonta = _pintores(tester).any((p) => p.tonta);
    }
    expect(viuTonta, isTrue);
    // E passa: depois do golpe, ninguém fica tonto.
    await tester.pump(const Duration(seconds: 2));
    expect(_pintores(tester).any((p) => p.tonta), isFalse);
  });

  testWidgets('os olhos vão na direção do ponteiro', (tester) async {
    await tester.pumpWidget(_trio());
    await tester.pump(const Duration(milliseconds: 100));
    final centro = tester.getCenter(find.byType(AvatarDeJogador).first);
    ondeOlhar.value = centro + const Offset(300, 0);
    await tester.pump(const Duration(milliseconds: 16));
    expect(_pintores(tester).first.olhar.dx, greaterThan(.9));
    ondeOlhar.value = centro + const Offset(0, -300);
    await tester.pump(const Duration(milliseconds: 16));
    expect(_pintores(tester).first.olhar.dy, lessThan(-.9));
  });

  testWidgets('com "reduzir movimento", nada se mexe', (tester) async {
    await tester.pumpWidget(_trio(parado: true));
    ondeOlhar.value = const Offset(2000, 0);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      for (final p in _pintores(tester)) {
        expect(p.tonta, isFalse);
        expect(p.olhar, Offset.zero);
      }
    }
    // Nada em loop: a tela assenta.
    await tester.pumpAndSettle();
  });

  testWidgets('piscar, tonta e olhar se desenham sem erro', (tester) async {
    const c = Carinha(
        olhos: Olhos.pontos,
        boca: Boca.sorriso,
        enfeite: Enfeite.nada,
        bochechas: false);
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: Row(children: [
        for (final (piscando, tonta) in [(true, false), (false, true)])
          CustomPaint(
            size: const Size.square(40),
            painter: PintorDeCarinha(
              carinha: c,
              fundo: coresDeJogador.first.$1,
              tinta: coresDeJogador.first.$2,
              bochecha: Cores.noite.acao,
              branco: Cores.noite.carta,
              olhar: const Offset(1, -1),
              piscando: piscando,
              tonta: tonta,
            ),
          ),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });
}

import 'package:cartaralho/ui/carinhas.dart';
import 'package:cartaralho/ui/jogadores.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('misturar', () {
    test('dá sempre o mesmo número para o mesmo texto', () {
      // Valores fixos: se a conta mudar, a carinha de todo mundo muda junto.
      // Todas as contas ficam abaixo de 2^53, então a web dá o mesmo número.
      expect(misturar(''), misturar(''));
      expect(misturar('abc#0'), 799329970);
      expect(misturar('Ana'), 1598607006);
    });

    test('cabe em 31 bits', () {
      for (var i = 0; i < 500; i++) {
        final h = misturar('jogador-$i');
        expect(h, inInclusiveRange(0, 0x7fffffff));
      }
    });
  });

  group('Carinha.de', () {
    test('a mesma semente e variação dão a mesma carinha', () {
      expect(Carinha.de('uid-123', 2), Carinha.de('uid-123', 2));
    });

    test('sortear outra quase sempre muda a carinha', () {
      // Com 1.024 carinhas, repetir a anterior é raro; mudar só o enfeite
      // também conta, mas olhos, boca e enfeite têm de variar todos.
      var iguais = 0, olhos = 0, bocas = 0;
      for (var i = 0; i < 200; i++) {
        final a = Carinha.de('uid-$i'), b = Carinha.de('uid-$i', 1);
        if (a == b) iguais++;
        if (a.olhos != b.olhos) olhos++;
        if (a.boca != b.boca) bocas++;
      }
      expect(iguais, lessThan(5));
      expect(olhos, greaterThan(150));
      expect(bocas, greaterThan(150));
    });

    test('todas as opções aparecem', () {
      final vistas = <Object>{};
      for (var i = 0; i < 3000; i++) {
        final c = Carinha.de('jogador-$i');
        vistas
          ..add(c.olhos)
          ..add(c.boca)
          ..add(c.enfeite)
          ..add(c.bochechas);
      }
      expect(
        vistas,
        containsAll(<Object>[
          ...Olhos.values,
          ...Boca.values,
          ...Enfeite.values,
          true,
          false,
        ]),
      );
    });
  });

  testWidgets('toda combinação de olhos, boca e enfeite se desenha',
      (tester) async {
    const cores = Cores.noite;
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final o in Olhos.values)
              for (final b in Boca.values)
                for (final e in Enfeite.values)
                  CustomPaint(
                    size: const Size.square(20),
                    painter: PintorDeCarinha(
                      carinha: Carinha(
                        olhos: o,
                        boca: b,
                        enfeite: e,
                        bochechas: true,
                      ),
                      fundo: coresDeJogador.first.$1,
                      tinta: coresDeJogador.first.$2,
                      bochecha: cores.acao,
                      branco: cores.carta,
                    ),
                  ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a carinha anima ao trocar a variação', (tester) async {
    Widget avatar(int v) => MaterialApp(
          theme: tema,
          home: Center(
            child: AvatarDeJogador(
              nome: 'Ana',
              indice: 0,
              semente: 'uid-1',
              variacao: v,
            ),
          ),
        );
    await tester.pumpWidget(avatar(0));
    await tester.pumpWidget(avatar(1));
    await tester.pump(const Duration(milliseconds: 100));
    // No meio da troca as duas carinhas estão na tela.
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
    await tester.pump(const Duration(seconds: 1));
  });
}

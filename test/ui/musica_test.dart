import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/ui/musica.dart';
import 'package:cartaralho/ui/sons.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _carregado() async {
  final c = ProviderContainer();
  c.read(configDaMusicaProvider);
  c.read(mudoProvider);
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return c;
}

void main() {
  group('faixaDaFase', () {
    test('calma para escolher, tique-taque para o juiz, nada no fim', () {
      expect(faixaDaFase(GamePhase.waitingForPlayers), Faixa.escolha);
      expect(faixaDaFase(GamePhase.playersSubmitting), Faixa.escolha);
      expect(faixaDaFase(GamePhase.judgeChoosing), Faixa.juiz);
      expect(faixaDaFase(GamePhase.roundResult), Faixa.escolha);
      expect(faixaDaFase(GamePhase.gameComplete), isNull);
      expect(faixaDaFase(null), isNull);
    });

    test('na madrugada, a versão desafinada em todas as fases', () {
      expect(faixaDaFase(GamePhase.judgeChoosing, madrugada: true),
          Faixa.madrugada);
      expect(faixaDaFase(GamePhase.gameComplete, madrugada: true), isNull);
    });
  });

  test('a música começa ligada e baixa, e a escolha fica guardada', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await _carregado();
    addTearDown(c.dispose);
    expect(c.read(configDaMusicaProvider).ligada, isTrue);
    expect(c.read(configDaMusicaProvider).volume, closeTo(.35, 1e-9));

    await c.read(configDaMusicaProvider.notifier).ligar(false);
    await c.read(configDaMusicaProvider.notifier).mudarVolume(.8);
    final outra = await _carregado();
    addTearDown(outra.dispose);
    expect(outra.read(configDaMusicaProvider).ligada, isFalse);
    expect(outra.read(configDaMusicaProvider).volume, closeTo(.8, 1e-9));
  });

  testWidgets('o painel liga e desliga efeitos e música', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: tema,
        home: const Scaffold(body: PainelDeSom()),
      ),
    ));
    await tester.pump();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(PainelDeSom)));
    await tester.tap(find.text('Música de fundo'));
    await tester.pump();
    expect(container.read(configDaMusicaProvider).ligada, isFalse);
    // Com a música desligada, o volume não mexe.
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    await tester.tap(find.text('Efeitos'));
    await tester.pump();
    expect(container.read(mudoProvider), isTrue);
  });

  group('arquivos das músicas', () {
    for (final faixa in Faixa.values) {
      test('${faixa.name}: loop baixo, sem degrau na emenda', () {
        final bytes =
            File('assets/musicas/${faixa.name}.wav').readAsBytesSync();
        final d = ByteData.sublistView(bytes);
        expect(d.getUint16(22, Endian.little), 1, reason: 'mono');
        final taxa = d.getUint32(24, Endian.little);
        final a = [
          for (var i = 44; i + 1 < bytes.length; i += 2)
            d.getInt16(i, Endian.little) / 32768,
        ];
        final segundos = a.length / taxa;
        expect(segundos, inInclusiveRange(8, 20));
        final pico = a.map((v) => v.abs()).reduce(max);
        // Fundo: bem mais baixo que os efeitos (pico abaixo de -3 dBFS).
        expect(20 * log(pico) / ln10, lessThan(-3));
        // A emenda do loop é contínua: o fim encosta no começo.
        expect((a.last - a.first).abs(), lessThan(.03));
      });
    }
  });
}

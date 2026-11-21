import 'package:cartaralho/ui/dicas.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> carregado() async {
    final c = ProviderContainer();
    c.read(dicasProvider);
    // Espera o SharedPreferences responder.
    for (var i = 0; i < 10 && c.read(dicasProvider) == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return c;
  }

  test('enquanto carrega, nenhuma dica aparece', () {
    expect(deveMostrar(null, Dica.mao), isFalse);
    expect(deveMostrar(const {}, Dica.mao), isTrue);
    expect(deveMostrar(const {Dica.mao}, Dica.mao), isFalse);
  });

  test('primeira partida: todas as dicas aparecem', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await carregado();
    addTearDown(c.dispose);
    expect(c.read(dicasProvider), isEmpty);
  });

  test('vista uma vez, fica guardada no aparelho', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await carregado();
    addTearDown(c.dispose);
    await c.read(dicasProvider.notifier).marcar(Dica.mao);
    expect(c.read(dicasProvider), {Dica.mao});

    // Outra abertura do app lê do armazenamento.
    final outra = await carregado();
    addTearDown(outra.dispose);
    expect(outra.read(dicasProvider), {Dica.mao});
  });

  testWidgets('o balão mostra o texto e fecha no "Entendi"', (tester) async {
    var fechou = false;
    await tester.pumpWidget(MaterialApp(
      theme: tema,
      home: Scaffold(
        body: BalaoDeDica(
          texto: 'Toque numa carta',
          aoFechar: () => fechou = true,
        ),
      ),
    ));
    expect(find.text('Toque numa carta'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    expect(fechou, isTrue);
  });
}

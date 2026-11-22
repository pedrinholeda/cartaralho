import 'package:cartaralho/providers/auth_provider.dart';
import 'package:cartaralho/providers/game_provider.dart';
import 'package:cartaralho/widgets/retoma_sala.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _montar(
  WidgetTester tester, {
  bool ativo = true,
  String? guardada = 'ABC234',
  bool aindaNaSala = true,
}) async {
  final container = ProviderContainer(
    overrides: [logadoProvider.overrideWithValue(true)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: RetomaSala(
        ativo: ativo,
        lerGuardada: () async => guardada,
        aindaNaSala: (_) async => aindaNaSala,
        child: const Text('capa'),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('depois do refresh, volta para a sala em que ainda está',
      (tester) async {
    final c = await _montar(tester);
    expect(c.read(roomIdProvider), 'ABC234');
  });

  testWidgets('se já saiu da sala (ou ela acabou), fica na capa',
      (tester) async {
    final c = await _montar(tester, aindaNaSala: false);
    expect(c.read(roomIdProvider), isNull);
  });

  testWidgets('aberto por convite, o convite manda', (tester) async {
    final c = await _montar(tester, ativo: false);
    expect(c.read(roomIdProvider), isNull);
  });

  test('a partida solo não fica guardada', () async {
    SharedPreferences.setMockInitialValues({});
    await SalaGuardada.guardar('SOLO-AB12');
    expect(await SalaGuardada.ler(), isNull);
    await SalaGuardada.guardar('K7PX2M');
    expect(await SalaGuardada.ler(), 'K7PX2M');
    await SalaGuardada.guardar(null);
    expect(await SalaGuardada.ler(), isNull);
  });
}

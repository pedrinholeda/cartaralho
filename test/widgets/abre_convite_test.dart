import 'package:cartaralho/providers/auth_provider.dart';
import 'package:cartaralho/screens/join_room_screen.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:cartaralho/widgets/abre_convite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(bool logado, {String? codigo = 'ABC234'}) => ProviderScope(
      overrides: [logadoProvider.overrideWithValue(logado)],
      child: MaterialApp(
        theme: tema,
        home: AbreConvite(codigo: codigo, child: const Text('capa')),
      ),
    );

void main() {
  testWidgets('com o login já pronto ao abrir, o convite leva para a sala',
      (tester) async {
    // É o caso do celular: antes, só a mudança do login abria o convite, e
    // aqui ela nunca acontece.
    await tester.pumpWidget(_app(true));
    await tester.pumpAndSettle();
    final tela = tester.widget<JoinRoomScreen>(find.byType(JoinRoomScreen));
    expect(tela.codigoInicial, 'ABC234');
  });

  testWidgets('sem login, o convite espera', (tester) async {
    await tester.pumpWidget(_app(false));
    await tester.pumpAndSettle();
    expect(find.byType(JoinRoomScreen), findsNothing);
  });

  testWidgets('sem convite, fica na capa', (tester) async {
    await tester.pumpWidget(_app(true, codigo: null));
    await tester.pumpAndSettle();
    expect(find.byType(JoinRoomScreen), findsNothing);
    expect(find.text('capa'), findsOneWidget);
  });
}

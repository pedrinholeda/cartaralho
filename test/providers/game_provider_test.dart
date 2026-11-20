import 'package:cartaralho/providers/auth_provider.dart';
import 'package:cartaralho/providers/game_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sem sala (depois de "Voltar ao menu"), os providers não quebram', () {
    // Antes, `roomId!` lançava assim que o código da sala virava nulo, e a
    // tela de jogo ainda ouvia os providers.
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith((ref) => Stream.value(null)),
    ]);
    addTearDown(container.dispose);

    expect(container.read(roomIdProvider), isNull);
    expect(container.read(currentPlayerProvider), isNull);
    expect(container.read(isJudgeProvider), isFalse);
    expect(container.read(isHostProvider), isFalse);
    expect(container.read(gamePhaseProvider), isNull);
  });
}

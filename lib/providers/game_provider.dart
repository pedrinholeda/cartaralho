import 'package:cartaralho/models/player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

final roomIdProvider = StateProvider<String?>((ref) => null);

final gameRoomProvider =
    StreamProvider.family<GameRoom?, String>((ref, roomId) {
  return FirebaseService.watchRoom(roomId);
});

final currentPlayerProvider = Provider<Player?>((ref) {
  final authState = ref.watch(authProvider);
  final roomId = ref.watch(roomIdProvider);
  // Ao sair da sala o código vira nulo antes de a tela de jogo sumir.
  if (roomId == null) return null;
  final gameRoom = ref.watch(gameRoomProvider(roomId));

  return gameRoom.when(
    data: (room) {
      if (room == null || authState.value == null) return null;
      return room.players.firstWhere(
        (p) => p.id == authState.value!.uid,
        orElse: () => Player(id: '', name: ''),
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

final isHostProvider = Provider<bool>((ref) {
  final currentPlayer = ref.watch(currentPlayerProvider);
  return currentPlayer?.isHost ?? false;
});

final isJudgeProvider = Provider<bool>((ref) {
  final uid = ref.watch(authProvider).value?.uid;
  final roomId = ref.watch(roomIdProvider);
  if (roomId == null) return false;
  final room = ref.watch(gameRoomProvider(roomId)).value;
  return uid != null && room != null && room.isJudge(uid);
});

final gamePhaseProvider = Provider<GamePhase?>((ref) {
  final roomId = ref.watch(roomIdProvider);
  if (roomId == null) return null;
  final gameRoom = ref.watch(gameRoomProvider(roomId));
  return gameRoom.when(
    data: (room) => room?.phase,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// As cartas que o jogador está escolhendo nesta rodada, na ordem das lacunas.
/// A chave é sala e carta preta, então cada rodada começa vazia. A mão escreve
/// aqui, e a carta preta lê para mostrar a frase pronta.
final escolhidasProvider =
    StateProvider.autoDispose.family<List<GameCard>, String>(
  (ref, rodada) => const [],
);

String chaveDaRodada(GameRoom sala) =>
    '${sala.roomId}-${sala.currentBlackCard?.id}';

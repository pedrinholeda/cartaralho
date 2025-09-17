import 'package:cartaralho/models/player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final gameRoom = ref.watch(gameRoomProvider(roomId!));

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
  final currentPlayer = ref.watch(currentPlayerProvider);
  return currentPlayer?.isJudge ?? false;
});

final gamePhaseProvider = Provider<GamePhase?>((ref) {
  final roomId = ref.watch(roomIdProvider);
  final gameRoom = ref.watch(gameRoomProvider(roomId!));
  return gameRoom.when(
    data: (room) => room?.phase,
    loading: () => null,
    error: (_, __) => null,
  );
});

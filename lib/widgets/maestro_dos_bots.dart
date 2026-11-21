import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/bots.dart';
import '../models/game_room.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';

/// Numa sala online com bot (o Zé Aleatório), quem faz o bot jogar é o
/// aparelho do anfitrião: a cada mudança da sala, se for a vez de um bot,
/// espera a pausa e grava a jogada. Os outros aparelhos só veem a sala mudar.
class MaestroDosBots extends ConsumerStatefulWidget {
  final String roomId;
  final bool anfitriao;
  final Widget child;

  const MaestroDosBots({
    super.key,
    required this.roomId,
    required this.anfitriao,
    required this.child,
  });

  @override
  ConsumerState<MaestroDosBots> createState() => _MaestroDosBotsState();
}

class _MaestroDosBotsState extends ConsumerState<MaestroDosBots> {
  final _rng = Random();
  Timer? _proxima;

  void _avaliar(GameRoom? sala) {
    _proxima?.cancel();
    if (!widget.anfitriao || sala == null) return;
    if (!sala.players.any((p) => ehBot(p.id))) return;
    // Só pergunta se há jogada de bot; quem joga de verdade é a transação.
    if (passoDosBots(sala, Random(0)) == null) return;
    _proxima = Timer(pausaDosBots(sala.phase, _rng), () {
      FirebaseService.jogadaDosBots(widget.roomId).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _proxima?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      gameRoomProvider(widget.roomId),
      (_, depois) => _avaliar(depois.valueOrNull),
      onError: (_, __) {},
    );
    return widget.child;
  }
}

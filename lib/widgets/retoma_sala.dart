import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../services/mesa_local.dart';

const _chaveDaSala = 'salaAtual';

/// A sala online em que o jogador está, guardada no aparelho para sobreviver
/// a um refresh. A partida solo não entra: ela vive só na memória.
abstract final class SalaGuardada {
  static Future<String?> ler() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_chaveDaSala);
    } catch (_) {
      return null;
    }
  }

  static Future<void> guardar(String? roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (roomId == null || MesaLocal.eh(roomId)) {
        await prefs.remove(_chaveDaSala);
      } else {
        await prefs.setString(_chaveDaSala, roomId);
      }
    } catch (_) {}
  }
}

/// Em volta da capa: se o jogo foi recarregado no meio de uma partida, volta
/// direto para a sala guardada, desde que o jogador ainda esteja nela. Se ele
/// saiu (ou a sala acabou), esquece.
class RetomaSala extends ConsumerStatefulWidget {
  /// Desligado quando o jogo abriu por um convite: o convite manda.
  final bool ativo;
  final Future<String?> Function() lerGuardada;
  final Future<bool> Function(String roomId) aindaNaSala;
  final Widget child;

  const RetomaSala({
    super.key,
    required this.ativo,
    this.lerGuardada = SalaGuardada.ler,
    this.aindaNaSala = FirebaseService.estouNaSala,
    required this.child,
  });

  @override
  ConsumerState<RetomaSala> createState() => _RetomaSalaState();
}

class _RetomaSalaState extends ConsumerState<RetomaSala> {
  bool _tentou = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      logadoProvider,
      (_, logado) => _talvezVoltar(logado),
      fireImmediately: true,
    );
  }

  Future<void> _talvezVoltar(bool logado) async {
    if (!widget.ativo || !logado || _tentou) return;
    _tentou = true;
    final roomId = await widget.lerGuardada();
    if (roomId == null || !mounted || ref.read(roomIdProvider) != null) return;
    if (await widget.aindaNaSala(roomId)) {
      if (mounted && ref.read(roomIdProvider) == null) {
        ref.read(roomIdProvider.notifier).state = roomId;
      }
    } else {
      await SalaGuardada.guardar(null);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

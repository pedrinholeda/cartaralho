import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../screens/join_room_screen.dart';

/// Em volta da capa: quando o jogo abre por um link de convite (`?sala=`),
/// leva para a tela de entrar com o código preenchido, uma vez, assim que o
/// login estiver pronto.
///
/// Confere o login também na hora em que abre (`fireImmediately`): no celular
/// o login costuma terminar antes de a capa ficar pronta, e esperar só pela
/// mudança deixava o convite parado na capa.
class AbreConvite extends ConsumerStatefulWidget {
  final String? codigo;
  final Widget child;

  const AbreConvite({super.key, required this.codigo, required this.child});

  @override
  ConsumerState<AbreConvite> createState() => _AbreConviteState();
}

class _AbreConviteState extends ConsumerState<AbreConvite> {
  late String? _pendente = widget.codigo;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      logadoProvider,
      (_, logado) => _talvezAbrir(logado),
      fireImmediately: true,
    );
  }

  void _talvezAbrir(bool logado) {
    final codigo = _pendente;
    if (codigo == null || !logado) return;
    _pendente = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(roomIdProvider) != null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => JoinRoomScreen(codigoInicial: codigo),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

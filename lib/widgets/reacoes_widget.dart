import 'package:flutter/material.dart';

import '../game/regras.dart';
import '../models/player.dart';
import '../services/erros.dart';
import '../services/firebase_service.dart';
import '../ui/animacoes.dart';
import '../ui/icones.dart';
import '../ui/tema.dart';

/// O desenho e a cor de cada reação.
(Desenho, Color Function(Cores)) desenhoDaReacao(String reacao) =>
    switch (reacao) {
      'risada' => (Desenho.risada, (c) => c.destaque),
      'choro' => (Desenho.choro, (c) => c.carta),
      'caveira' => (Desenho.caveira, (c) => c.carta),
      'coracao' => (Desenho.coracao, (c) => c.acao),
      _ => (Desenho.chocado, (c) => c.destaque),
    };

const _nomeDaReacao = {
  'risada': 'Risada',
  'choro': 'Choro',
  'caveira': 'Morri',
  'coracao': 'Amei',
  'chocado': 'Chocado',
};

/// Em volta da carinha de um jogador no placar: faz a reação dele subir
/// flutuando a cada reação nova e, na carinha de quem está no aparelho, abre
/// a escolha de reação ao tocar.
class ComReacao extends StatefulWidget {
  final Player jogador;
  final String? roomId;
  final bool meu;
  final double tamanho;

  /// Quem está no aparelho é o anfitrião: tocar na carinha de outro jogador
  /// oferece tirá-lo da sala.
  final bool podeTirar;
  final Widget child;

  const ComReacao({
    super.key,
    required this.jogador,
    required this.roomId,
    required this.meu,
    required this.tamanho,
    this.podeTirar = false,
    required this.child,
  });

  @override
  State<ComReacao> createState() => _ComReacaoState();
}

class _ComReacaoState extends State<ComReacao>
    with SingleTickerProviderStateMixin {
  late final _subir = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didUpdateWidget(ComReacao antes) {
    super.didUpdateWidget(antes);
    // Só a reação nova sobe; a que já estava quando a tela abriu, não.
    if (widget.jogador.reacaoVez > antes.jogador.reacaoVez) {
      _subir.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _subir.dispose();
    super.dispose();
  }

  DateTime? _ultima;

  Future<void> _escolher() async {
    final roomId = widget.roomId;
    if (roomId == null) return;
    final cores = Cores.de(context);
    final escolhida = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cores.superficie,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final r in reacoes)
                IconButton(
                  tooltip: _nomeDaReacao[r],
                  iconSize: 44,
                  onPressed: () => Navigator.of(context).pop(r),
                  icon: IconeFofo(
                    desenhoDaReacao(r).$1,
                    tamanho: 44,
                    cor: desenhoDaReacao(r).$2(cores),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (escolhida == null) return;
    // Uma por segundo, no máximo: ninguém inunda a mesa.
    final agora = DateTime.now();
    if (_ultima != null && agora.difference(_ultima!).inMilliseconds < 1000) {
      return;
    }
    _ultima = agora;
    try {
      await FirebaseService.reagir(roomId, escolhida);
    } catch (_) {}
  }

  Future<void> _tirar() async {
    final roomId = widget.roomId;
    if (roomId == null) return;
    final nome = widget.jogador.name;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tirar $nome da sala?'),
        content: const Text(
          'Para quando alguém sumiu e a rodada travou esperando. As cartas '
          'dessa pessoa voltam para o monte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tirar da sala'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await FirebaseService.tirarDaSala(roomId, widget.jogador.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensagemDoErro(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final reacao = widget.jogador.reacao;
    final t = widget.tamanho;
    Widget conteudo = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        if (reacao != null && !movimentoReduzido(context))
          AnimatedBuilder(
            animation: _subir,
            builder: (context, _) {
              final v = _subir.value;
              if (!_subir.isAnimating || v == 0) return const SizedBox.shrink();
              final (desenho, cor) = desenhoDaReacao(reacao);
              return Positioned(
                // Sobe pouco: no placar do celular o teto fica perto.
                top: -t * .15 - v * t * .45,
                child: Opacity(
                  opacity: v < .75 ? 1 : (1 - v) / .25,
                  child: Transform.scale(
                    scale: v < .15 ? .4 + v / .15 * .6 : 1,
                    child: IconeFofo(desenho, tamanho: t * .6, cor: cor(cores)),
                  ),
                ),
              );
            },
          ),
      ],
    );
    if (!widget.meu && widget.podeTirar) {
      conteudo = Tooltip(
        message: 'Tirar ${widget.jogador.name} da sala',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tirar,
          child: conteudo,
        ),
      );
    }
    if (widget.meu) {
      conteudo = Tooltip(
        message: 'Mandar uma reação',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _escolher,
          child: conteudo,
        ),
      );
    }
    return conteudo;
  }
}

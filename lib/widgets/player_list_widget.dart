import 'package:flutter/material.dart';

import '../models/player.dart';
import '../ui/animacoes.dart';
import '../ui/tema.dart';

/// Placar: uma ficha por jogador, com nome e pontos. O juiz da rodada fica em
/// amarelo, com a coroa.
class PlayerListWidget extends StatelessWidget {
  final List<Player> players;
  final String? judgeId;

  const PlayerListWidget({
    super.key,
    required this.players,
    required this.judgeId,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Medidas.margem),
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: Medidas.espaco),
        itemBuilder: (context, index) {
          final player = players[index];
          final juiz = player.id == judgeId;
          final fundo = juiz ? cores.destaque : cores.carta;
          final tinta = juiz ? cores.tintaNoDestaque : cores.tintaNaCarta;
          final pontos =
              player.points == 1 ? '1 ponto' : '${player.points} pontos';

          // Quem entra na sala aparece com uma animação curta.
          return Entrada(
            key: ValueKey(player.id),
            deslocamento: 12,
            child: Semantics(
              label: '${player.name}, $pontos${juiz ? ', juiz da rodada' : ''}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: fundo,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    if (juiz) ...[
                      Icon(Icons.gavel_rounded, size: 18, color: tinta),
                      const SizedBox(width: 6),
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        player.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: tinta, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${player.points}',
                      style: TextStyle(
                        color: tinta,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

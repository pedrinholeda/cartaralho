import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/player.dart';
import '../ui/animacoes.dart';
import '../ui/jogadores.dart';
import '../ui/tema.dart';

/// Placar: um avatar por jogador, com o nome e os pontos embaixo. O juiz da
/// rodada tem o anel amarelo e o martelo.
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
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Medidas.margem),
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final player = players[index];
          final juiz = player.id == judgeId;
          final pontos =
              player.points == 1 ? '1 ponto' : '${player.points} pontos';

          // Quem entra na sala aparece com uma animação curta.
          return Entrada(
            key: ValueKey(player.id),
            deslocamento: 12,
            child: Semantics(
              label: '${player.name}, $pontos'
                  '${juiz ? ', juiz da rodada' : ''}',
              excludeSemantics: true,
              child: SizedBox(
                width: 60,
                child: Column(
                  children: [
                    AvatarDeJogador(
                      nome: player.name,
                      indice: index,
                      juiz: juiz,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.figtree(
                        color: cores.tintaSuave,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${player.points}',
                      style: GoogleFonts.figtree(
                        color: cores.tintaNaMesa,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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

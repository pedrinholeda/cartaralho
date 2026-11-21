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

  /// No computador: uma linha por jogador, com o nome inteiro.
  final bool vertical;

  const PlayerListWidget({
    super.key,
    required this.players,
    required this.judgeId,
    this.vertical = false,
  });

  Widget _emLista(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Medidas.margem, 8, Medidas.margem, 4),
      child: Column(
        children: [
          for (var i = 0; i < players.length; i++)
            Entrada(
              key: ValueKey(players[i].id),
              deslocamento: 12,
              child: Semantics(
                label: '${players[i].name}, '
                    '${players[i].points == 1 ? '1 ponto' : '${players[i].points} pontos'}'
                    '${players[i].id == judgeId ? ', juiz da rodada' : ''}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      AvatarDeJogador(
                        nome: players[i].name,
                        indice: i,
                        juiz: players[i].id == judgeId,
                        semente: players[i].id,
                        variacao: players[i].avatar,
                        tamanho: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          players[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textos.titleSmall?.copyWith(
                            color: cores.tintaNaMesa,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${players[i].points}',
                        style: GoogleFonts.figtree(
                          color: cores.tintaNaMesa,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (vertical) return _emLista(context);
    final cores = Cores.de(context);
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Em cima, espaço para o chapéu e o topete das carinhas.
        padding:
            const EdgeInsets.fromLTRB(Medidas.margem, 10, Medidas.margem, 0),
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
                      semente: player.id,
                      variacao: player.avatar,
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

import 'package:flutter/material.dart';

import '../game/regras.dart';
import '../models/game_room.dart';
import '../ui/animacoes.dart';
import '../ui/cartas.dart';
import '../ui/tema.dart';

/// As cartas enviadas, na ordem sorteada, para quem não é o juiz acompanhar
/// enquanto ele escolhe. Sem o nome de quem enviou: isso só aparece no
/// resultado da rodada.
class TableWidget extends StatelessWidget {
  final GameRoom room;

  const TableWidget({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final preta = room.currentBlackCard;
    final mesa = room.cardsOnTable;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Medidas.margem, 12, Medidas.margem, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O juiz está escolhendo a carta vencedora...',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: cores.tintaNaMesa),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: mesa.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final brancas = mesa[index].value;
                return Virada(
                  key: ValueKey(mesa[index].key),
                  atraso: Duration(milliseconds: 160 * index),
                  child: CartaBranca(
                    larga: true,
                    texto: preta == null
                        ? brancas.map((c) => c.text).join(' / ')
                        : fraseCompleta(preta, brancas),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

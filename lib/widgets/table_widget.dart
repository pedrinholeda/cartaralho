import 'package:flutter/material.dart';

import '../game/regras.dart';
import '../models/game_room.dart';

/// As cartas enviadas, na ordem sorteada, para quem não é o juiz acompanhar
/// enquanto ele escolhe. Sem o nome de quem enviou: isso só aparece no
/// resultado da rodada.
class TableWidget extends StatelessWidget {
  final GameRoom room;

  const TableWidget({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final preta = room.currentBlackCard;
    final cartas = room.cardsOnTable;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'O juiz está escolhendo a carta vencedora...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: cartas.length,
              itemBuilder: (context, index) {
                final carta = cartas[index].value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      preta == null
                          ? carta.text
                          : fraseCompleta(preta, [carta]),
                    ),
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

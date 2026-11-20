import 'package:flutter/material.dart';

import '../models/card.dart';
import '../ui/cartas.dart';
import '../ui/tema.dart';

/// A carta preta da rodada, no topo da tela de jogo.
class BlackCardWidget extends StatelessWidget {
  final GameCard card;

  const BlackCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.margem,
        12,
        Medidas.margem,
        4,
      ),
      child: CartaPreta(texto: card.text, pede: card.pick),
    );
  }
}

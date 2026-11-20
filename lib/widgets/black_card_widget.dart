import 'package:flutter/material.dart';

import '../models/card.dart';
import '../ui/cartas.dart';
import '../ui/tema.dart';

/// A carta preta da rodada, no topo da tela de jogo, com as [respostas] do
/// jogador no lugar das lacunas enquanto ele escolhe.
class BlackCardWidget extends StatelessWidget {
  final GameCard card;
  final List<String> respostas;

  const BlackCardWidget({
    super.key,
    required this.card,
    this.respostas = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.margem,
        8,
        Medidas.margem,
        4,
      ),
      child:
          CartaPreta(texto: card.text, pede: card.pick, respostas: respostas),
    );
  }
}

import 'package:flutter/material.dart';

/// Uma linha de opções da partida, como "Pontos para vencer: 3 5 7 10".
class LinhaDeOpcoes extends StatelessWidget {
  final String titulo;
  final List<int> opcoes;
  final int valor;
  final ValueChanged<int> aoEscolher;

  const LinhaDeOpcoes({
    super.key,
    required this.titulo,
    required this.opcoes,
    required this.valor,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final o in opcoes)
              ChoiceChip(
                label: Text('$o'),
                selected: o == valor,
                onSelected: (_) => aoEscolher(o),
              ),
          ],
        ),
      ],
    );
  }
}

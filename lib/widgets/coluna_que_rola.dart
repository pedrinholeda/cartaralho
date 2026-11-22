import 'dart:math';

import 'package:flutter/material.dart';

/// A tela de jogo no celular: o [topo] (placar, aviso, carta preta) e, embaixo,
/// o [conteudo] da fase (mão, mesa, juiz), que ocupa o resto da tela.
///
/// Quando o topo é alto demais (celular baixo, barra do navegador aberta,
/// carta preta comprida, dica na tela), o conteúdo fica com [alturaMinima] e
/// a tela inteira rola. Antes, o conteúdo encolhia até sumir e o botão de
/// enviar ou de escolher o vencedor ficava fora da tela, sem como chegar nele.
class ColunaQueRola extends StatelessWidget {
  final List<Widget> topo;
  final Widget conteudo;

  /// Altura que o conteúdo nunca perde: mão em leque com o botão embaixo.
  static const alturaMinima = 400.0;

  const ColunaQueRola({super.key, required this.topo, required this.conteudo});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // Sem "elástico" quando tudo cabe: a tela parece fixa como antes.
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: Column(children: topo)),
        SliverLayoutBuilder(
          builder: (context, c) {
            // O que sobra da tela depois do topo (estável: não muda ao rolar).
            final sobra = c.viewportMainAxisExtent - c.precedingScrollExtent;
            return SliverToBoxAdapter(
              child: SizedBox(
                height: max(sobra, alturaMinima),
                child: conteudo,
              ),
            );
          },
        ),
      ],
    );
  }
}

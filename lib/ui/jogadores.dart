import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'carinhas.dart';
import 'tema.dart';

/// Avatar redondo com a carinha do jogador, numa cor fixa pela posição dele
/// na sala ([coresDeJogador]). A carinha sai de [semente] (o id do jogador) e
/// [variacao] (quantas vezes ele pediu outra); sem semente, sai do nome. O
/// juiz da rodada ganha um anel amarelo e o martelo.
class AvatarDeJogador extends StatelessWidget {
  final String nome;
  final int indice;
  final bool juiz;
  final double tamanho;
  final String? semente;
  final int variacao;

  const AvatarDeJogador({
    super.key,
    required this.nome,
    required this.indice,
    this.juiz = false,
    this.tamanho = 44,
    this.semente,
    this.variacao = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final (fundo, tinta) = coresDeJogador[indice % coresDeJogador.length];
    final carinha = Carinha.de(semente ?? nome, variacao);

    return SizedBox(
      width: tamanho + 6,
      height: tamanho + 6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: tamanho + 6,
            height: tamanho + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: juiz ? cores.destaque : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          // A carinha muda com um pulinho quando o jogador sorteia outra.
          AnimatedSwitcher(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 260),
            transitionBuilder: (filho, animacao) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animacao,
                curve: Curves.easeOutBack,
              ),
              child: filho,
            ),
            child: CustomPaint(
              key: ValueKey(carinha),
              size: Size.square(tamanho),
              painter: PintorDeCarinha(
                carinha: carinha,
                fundo: fundo,
                tinta: tinta,
                bochecha: cores.acao,
                branco: cores.carta,
              ),
            ),
          ),
          if (juiz)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cores.destaque,
                  shape: BoxShape.circle,
                  border: Border.all(color: cores.mesa, width: 2),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  size: 12,
                  color: cores.tintaNoDestaque,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Um aviso curto sobre a mesa: de quem é a vez, o que fazer agora.
class AvisoDaVez extends StatelessWidget {
  final String texto;
  final IconData? icone;
  final bool destaque;

  const AvisoDaVez(this.texto, {super.key, this.icone, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final fundo = destaque ? cores.destaque : cores.superficie;
    final tinta = destaque ? cores.tintaNoDestaque : cores.tintaNaMesa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 16, color: tinta),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              texto,
              style: GoogleFonts.figtree(
                color: tinta,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tema.dart';

/// Avatar redondo com a inicial do jogador, numa cor fixa pela posição dele
/// na sala ([coresDeJogador]). O juiz da rodada ganha um anel amarelo e o
/// martelo.
class AvatarDeJogador extends StatelessWidget {
  final String nome;
  final int indice;
  final bool juiz;
  final double tamanho;

  const AvatarDeJogador({
    super.key,
    required this.nome,
    required this.indice,
    this.juiz = false,
    this.tamanho = 44,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final (fundo, tinta) = coresDeJogador[indice % coresDeJogador.length];
    final inicial = nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();

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
          CircleAvatar(
            radius: tamanho / 2,
            backgroundColor: fundo,
            child: Text(
              inicial,
              style: GoogleFonts.figtree(
                color: tinta,
                fontSize: tamanho * 0.42,
                fontWeight: FontWeight.w800,
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

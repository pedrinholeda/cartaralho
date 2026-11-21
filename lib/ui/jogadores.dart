import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'animacoes.dart';
import 'assombro.dart';
import 'carinhas.dart';
import 'icones.dart';
import 'olhar.dart';
import 'tema.dart';

/// O que a carinha está sentindo na partida.
enum Humor {
  normal,

  /// Escolhendo a carta: balão de "…".
  pensando,

  /// Já enviou: uma cartinha branca na mão.
  enviou,

  /// Juiz decidindo: olhos para cima.
  julgando,

  /// O juiz está demorando: treme e solta um "!".
  impaciente,

  /// Ganhou a rodada: pulinhos.
  comemorando,
}

/// Avatar redondo com a carinha do jogador, numa cor fixa pela posição dele
/// na sala ([coresDeJogador]). A carinha sai de [semente] (o id do jogador) e
/// [variacao] (quantas vezes ele pediu outra); sem semente, sai do nome. O
/// juiz da rodada ganha um anel amarelo e o martelo.
///
/// A carinha é viva: flutua num ritmo próprio, pisca de vez em quando, olha
/// para o ponteiro ([ondeOlhar]) e, dentro de um [GrupoDeCarinhas], dá e leva
/// cascudo. Com "reduzir movimento", fica parada.
class AvatarDeJogador extends StatefulWidget {
  final String nome;
  final int indice;
  final bool juiz;
  final double tamanho;
  final String? semente;
  final int variacao;

  /// Força (ou impede) a carinha da madrugada; sem valor, vale a hora certa.
  final bool? assombrado;

  /// O que a carinha mostra sobre a partida.
  final Humor humor;

  /// Quem lidera a partida usa a coroa derretendo.
  final bool lider;

  const AvatarDeJogador({
    super.key,
    required this.nome,
    required this.indice,
    this.juiz = false,
    this.tamanho = 44,
    this.semente,
    this.variacao = 0,
    this.assombrado,
    this.humor = Humor.normal,
    this.lider = false,
  });

  @override
  State<AvatarDeJogador> createState() => _AvatarDeJogadorState();
}

class _AvatarDeJogadorState extends State<AvatarDeJogador>
    with TickerProviderStateMixin {
  /// O ritmo de flutuar e piscar sai da semente: cada carinha no seu.
  late final int _sorte = misturar(widget.semente ?? widget.nome);
  late final _vida = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 3200 + _sorte % 1500),
  );
  late final _golpe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  GrupoInfo? _grupo;
  Cascudo? _cascudo;
  bool _parado = false;

  /// Piscar: uma vez a cada 3 a 6 voltas de flutuar, por 4% da volta.
  late final int _voltasEntrePiscadas = 1 + _sorte % 3;
  int _voltas = 0;

  @override
  void initState() {
    super.initState();
    _vida.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _voltas++;
        _vida.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parado = movimentoReduzido(context);
    if (_parado) {
      _vida.stop();
    } else if (!_vida.isAnimating) {
      _vida.forward(from: (_sorte % 100) / 100);
    }
    final grupo = GrupoDeCarinhas.de(context);
    if (grupo != _grupo) {
      _grupo?.cascudo.removeListener(_aoCascudo);
      _grupo = grupo;
      _grupo?.cascudo.addListener(_aoCascudo);
    }
  }

  void _aoCascudo() {
    final c = _grupo?.cascudo.value;
    if (c == null || _parado) return;
    if (c.agressor != widget.indice && c.vitima != widget.indice) return;
    _cascudo = c;
    _golpe.forward(from: 0);
  }

  @override
  void dispose() {
    _grupo?.cascudo.removeListener(_aoCascudo);
    _vida.dispose();
    _golpe.dispose();
    super.dispose();
  }

  /// Para onde olhar: a direção do ponteiro, mais forte quanto mais longe.
  Offset _olhar(Offset? ponteiro) {
    if (ponteiro == null || _parado) return Offset.zero;
    final caixa = context.findRenderObject();
    if (caixa is! RenderBox || !caixa.hasSize || !caixa.attached) {
      return Offset.zero;
    }
    final d = ponteiro - caixa.localToGlobal(caixa.size.center(Offset.zero));
    final distancia = d.distance;
    if (distancia < 1) return Offset.zero;
    return d / distancia * min(1.0, distancia / 160);
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final indice = widget.indice;
    final (fundo, tinta) = coresDeJogador[indice % coresDeJogador.length];
    final carinha = Carinha.de(widget.semente ?? widget.nome, widget.variacao);
    final tamanho = widget.tamanho;

    return SizedBox(
      width: tamanho + 6,
      height: tamanho + 6,
      child: AnimatedBuilder(
        animation: Listenable.merge([_vida, _golpe, ondeOlhar]),
        builder: (context, _) {
          final t = _vida.value;
          final g = _golpe.value;
          var deslocar = Offset(0, sin(t * 2 * pi) * tamanho * .05);
          var girar = sin(t * 2 * pi + 1) * .035;
          var tonta = false;
          final c = _cascudo;
          final grupo = _grupo;
          if (c != null && grupo != null && _golpe.isAnimating) {
            // Para que lado está o outro: +1 se ele vem depois, -1 se antes.
            final outro = c.agressor == indice ? c.vitima : c.agressor;
            final lado = (outro - indice).sign.toDouble();
            final eixo = grupo.eixo == Axis.horizontal
                ? Offset(lado, 0)
                : Offset(0, lado);
            if (c.agressor == indice) {
              // Vai até a vizinha, bate e volta.
              final ida = g < .3
                  ? Curves.easeIn.transform(g / .3)
                  : g < .45
                      ? 1.0
                      : 1 - Curves.easeOut.transform((g - .45) / .55);
              deslocar += eixo * grupo.passo * .42 * ida;
              girar += lado * .3 * ida;
            } else if (g >= .3) {
              // Leva o cascudo: é empurrada, balança e fica tonta.
              final empurrao = g < .4 ? (g - .3) / .1 : 1 - (g - .4) / .6;
              deslocar += eixo * 7 * empurrao;
              girar += lado * .2 * empurrao * cos((g - .3) * 30);
              tonta = g < .95;
            }
          }
          final humor = widget.humor;
          if (!_parado) {
            if (humor == Humor.comemorando) {
              // Pulinhos: quatro por volta.
              deslocar += Offset(0, -sin(t * 8 * pi).abs() * tamanho * .22);
            } else if (humor == Humor.impaciente) {
              deslocar += Offset(sin(t * 60 * pi) * 2.2, 0);
            }
          }
          final olhar = humor == Humor.julgando
              ? const Offset(.5, -1)
              : humor == Humor.pensando
                  ? const Offset(-.6, -.9)
                  : _olhar(ondeOlhar.value);
          final piscando = !_parado &&
              _voltas % (_voltasEntrePiscadas + 2) == 0 &&
              t > .6 &&
              t < .64;
          return Transform.translate(
            offset: _parado ? Offset.zero : deslocar,
            child: Transform.rotate(
              angle: _parado ? 0 : girar,
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
                        color:
                            widget.juiz ? cores.destaque : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  // A carinha muda com um pulinho quando o jogador sorteia
                  // outra.
                  AnimatedSwitcher(
                    duration: _parado
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
                        assombrada: widget.assombrado ?? ehMadrugada(agora()),
                        olhar: olhar,
                        piscando: piscando,
                        tonta: tonta,
                      ),
                    ),
                  ),
                  if (widget.lider)
                    Positioned(
                      top: -tamanho * .42,
                      child: IconeFofo(
                        Desenho.coroa,
                        tamanho: tamanho * .5,
                        cor: cores.destaque,
                        gotejo: .6,
                      ),
                    ),
                  if (humor == Humor.pensando)
                    Positioned(
                      right: -tamanho * .32,
                      top: -tamanho * .18,
                      child: _Balao(
                        texto: '…',
                        cores: cores,
                        tamanho: tamanho,
                        pulo: _parado ? 0 : sin(t * 6 * pi),
                      ),
                    ),
                  if (humor == Humor.impaciente)
                    Positioned(
                      right: -tamanho * .28,
                      top: -tamanho * .2,
                      child: _Balao(
                        texto: '!',
                        cores: cores,
                        tamanho: tamanho,
                        pulo: 0,
                        destaque: true,
                      ),
                    ),
                  if (humor == Humor.enviou)
                    Positioned(
                      left: -tamanho * .12,
                      bottom: -tamanho * .06,
                      child: Transform.rotate(
                        angle: -.25,
                        child: Container(
                          width: tamanho * .26,
                          height: tamanho * .36,
                          decoration: BoxDecoration(
                            color: cores.carta,
                            borderRadius: BorderRadius.circular(tamanho * .05),
                            border: Border.all(color: cores.mesa, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  if (widget.juiz)
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
                        child: IconeFofo(
                          Desenho.juiz,
                          tamanho: 13,
                          cor: cores.tintaNoDestaque,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// O balãozinho sobre a carinha ("…" pensando, "!" impaciente).
class _Balao extends StatelessWidget {
  final String texto;
  final Cores cores;
  final double tamanho;
  final double pulo;
  final bool destaque;

  const _Balao({
    required this.texto,
    required this.cores,
    required this.tamanho,
    required this.pulo,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final fundo = destaque ? cores.destaque : cores.carta;
    final tinta = destaque ? cores.tintaNoDestaque : cores.tintaNaCarta;
    return Transform.translate(
      offset: Offset(0, pulo * 1.5),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tamanho * .1,
          vertical: tamanho * .01,
        ),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(tamanho * .3),
          border: Border.all(color: cores.mesa, width: 1.5),
        ),
        child: Text(
          texto,
          style: GoogleFonts.figtree(
            color: tinta,
            fontSize: tamanho * .3,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

/// Um aviso curto sobre a mesa: de quem é a vez, o que fazer agora.
class AvisoDaVez extends StatelessWidget {
  final String texto;
  final Desenho? icone;
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
            IconeFofo(icone!, tamanho: 18, cor: tinta),
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

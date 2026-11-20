import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tema.dart';

/// Texto de carta: Archivo pesada, como impresso em papel cartão.
TextStyle _textoDeCarta(Color cor, double tamanho) => GoogleFonts.archivo(
      color: cor,
      fontSize: tamanho,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

/// A carta preta da rodada. As lacunas `____` viram uma linha contínua, e a
/// carta que pede mais de uma branca diz quantas.
class CartaPreta extends StatelessWidget {
  final String texto;
  final int pede;

  const CartaPreta({super.key, required this.texto, this.pede = 1});

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Semantics(
      label: 'Carta preta: ${texto.replaceAll(RegExp('_{2,}'), 'lacuna')}'
          '${pede > 1 ? '. Escolha $pede cartas.' : ''}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: cores.cartaPreta,
          borderRadius: BorderRadius.circular(Medidas.raioCarta),
          boxShadow: const [
            BoxShadow(
              color: Medidas.sombra,
              blurRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              texto.replaceAll(RegExp('_{2,}'), '________'),
              style: _textoDeCarta(cores.tintaNaCartaPreta, 22),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Cartaralho',
                  style: GoogleFonts.archivoNarrow(
                    color: cores.tintaNaCartaPreta.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (pede > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: cores.tintaNaCartaPreta,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Escolha $pede',
                      style: TextStyle(
                        color: cores.cartaPreta,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma carta branca. Na mão ela tem proporção de carta de baralho e sobe
/// quando escolhida; na mesa e no resultado ela é larga, com o nome de quem
/// enviou embaixo quando a rodada termina.
class CartaBranca extends StatelessWidget {
  final String texto;

  /// Escolhida pelo jogador (na mão) ou pelo juiz (na mesa).
  final bool selecionada;

  /// Posição na ordem das lacunas, quando a carta preta pede mais de uma.
  final int? ordem;

  /// Quem enviou, mostrado no resultado.
  final String? autor;

  /// Carta vencedora da rodada.
  final bool vencedora;

  /// Larga, para frases inteiras (mesa, juiz, resultado). Senão, carta de mão.
  final bool larga;

  final VoidCallback? aoTocar;

  const CartaBranca({
    super.key,
    required this.texto,
    this.selecionada = false,
    this.ordem,
    this.autor,
    this.vencedora = false,
    this.larga = false,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final reduzir = MediaQuery.of(context).disableAnimations;
    final fundo = vencedora ? cores.destaque : cores.carta;
    final tinta = vencedora ? cores.tintaNoDestaque : cores.tintaNaCarta;

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
          larga ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
      children: [
        Text(texto, style: _textoDeCarta(tinta, larga ? 18 : 15)),
        if (autor != null) ...[
          const SizedBox(height: 8),
          Text(
            autor!,
            style: TextStyle(
              color: tinta.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    final carta = AnimatedContainer(
      duration: reduzir ? Duration.zero : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform:
          Matrix4.translationValues(0, selecionada && !larga ? -8 : 0, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(Medidas.raioCarta),
        border: Border.all(
          color: selecionada ? cores.cartaPreta : Colors.transparent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Medidas.sombraLeve,
            blurRadius: 0,
            offset: Offset(0, selecionada ? 6 : 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          larga ? conteudo : SizedBox.expand(child: conteudo),
          if (ordem != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: cores.cartaPreta,
                child: Text(
                  '$ordem',
                  style: TextStyle(
                    color: cores.tintaNaCartaPreta,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: aoTocar != null,
      selected: selecionada,
      // Leitor de tela e Enter no navegador acionam a carta por aqui.
      onTap: aoTocar,
      label: [
        texto,
        if (autor != null) 'enviada por $autor',
        if (vencedora) 'vencedora',
      ].join(', '),
      excludeSemantics: true,
      child:
          aoTocar == null ? carta : _Tocavel(aoTocar: aoTocar!, child: carta),
    );
  }
}

/// Torna a carta tocável pelo dedo, pelo mouse e pelo teclado (Tab até ela,
/// Enter ou Espaço para escolher), com um contorno amarelo quando ela tem o
/// foco do teclado.
class _Tocavel extends StatefulWidget {
  final VoidCallback aoTocar;
  final Widget child;

  const _Tocavel({required this.aoTocar, required this.child});

  @override
  State<_Tocavel> createState() => _TocavelState();
}

class _TocavelState extends State<_Tocavel> {
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      // Na web o Flutter só liga Espaço ao "ativar"; Enter também tem que escolher.
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      onShowFocusHighlight: (v) => setState(() => _foco = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.aoTocar();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.aoTocar,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Medidas.raioCarta + 3),
            border: Border.all(
              color: _foco ? cores.destaque : Colors.transparent,
              width: 3,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Grade da mão: cartas com proporção de carta de baralho, quantas couberem
/// lado a lado (duas no celular, mais em tela larga).
class GradeDeCartas extends StatelessWidget {
  final int quantidade;
  final Widget Function(BuildContext, int) construir;

  const GradeDeCartas({
    super.key,
    required this.quantidade,
    required this.construir,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        childAspectRatio: Medidas.proporcaoCarta,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: quantidade,
      itemBuilder: construir,
    );
  }
}

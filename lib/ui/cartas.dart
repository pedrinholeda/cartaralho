import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'animacoes.dart';
import 'tema.dart';

/// Texto de carta: Figtree pesada, como impresso em papel cartão.
TextStyle _textoDeCarta(Color cor, double tamanho) => GoogleFonts.figtree(
      color: cor,
      fontSize: tamanho,
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: -0.2,
    );

final _lacuna = RegExp('_{2,}');

/// A carta preta da rodada, com a faixa vermelha do jogo no topo. Enquanto o
/// jogador escolhe, as [respostas] aparecem no lugar das lacunas, em vermelho,
/// para ele ler a frase pronta antes de enviar.
class CartaPreta extends StatelessWidget {
  final String texto;
  final int pede;
  final List<String> respostas;

  /// A primeira lacuna vazia abre um olho (para quem demora a escolher).
  final bool olho;

  /// Uma linha pequena embaixo da frase, como o "ainda acordado?" da
  /// madrugada.
  final String? rodape;

  /// Tamanho da letra da frase: maior no computador, onde a carta tem a
  /// coluna dela.
  final double tamanhoDoTexto;

  const CartaPreta({
    super.key,
    required this.texto,
    this.pede = 1,
    this.respostas = const [],
    this.olho = false,
    this.rodape,
    this.tamanhoDoTexto = 21,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final estilo = _textoDeCarta(cores.tintaNaCartaPreta, tamanhoDoTexto);

    // Partes do texto entre lacunas; cada lacuna vira a resposta ou um traço.
    final partes = texto.split(_lacuna);
    final spans = <InlineSpan>[];
    var olhoPosto = false;
    for (var i = 0; i < partes.length; i++) {
      spans.add(TextSpan(text: partes[i]));
      if (i < partes.length - 1) {
        final resposta = i < respostas.length ? respostas[i] : null;
        if (resposta == null && olho && !olhoPosto) {
          olhoPosto = true;
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: OlhoNaLacuna(cor: cores.tintaNaCartaPreta),
            ),
          );
          continue;
        }
        spans.add(
          resposta == null
              ? TextSpan(
                  text: '      ',
                  style: estilo.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: cores.tintaNaCartaPreta,
                    decorationThickness: 2,
                  ),
                )
              : TextSpan(
                  text: resposta,
                  style: estilo.copyWith(color: cores.acao),
                ),
        );
      }
    }
    if (_lacuna.allMatches(texto).isEmpty && respostas.isNotEmpty) {
      spans.add(
        TextSpan(
          text: ' ${respostas.join(' / ')}',
          style: estilo.copyWith(color: cores.acao),
        ),
      );
    }

    return Semantics(
      label: 'Carta preta: ${texto.replaceAll(_lacuna, 'lacuna')}'
          '${pede > 1 ? '. Escolha $pede cartas.' : ''}'
          '${rodape != null ? '. $rodape' : ''}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cores.cartaPreta,
          borderRadius: BorderRadius.circular(Medidas.raioPainel),
          boxShadow: const [
            BoxShadow(
              color: Medidas.sombra,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 5, color: cores.acao),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(style: estilo, children: spans)),
                  if (rodape != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      rodape!,
                      style: GoogleFonts.figtree(
                        color: cores.tintaSuave,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (pede > 1) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cores.acao,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Escolha $pede',
                        style: GoogleFonts.figtree(
                          color: cores.tintaNaAcao,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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

  /// Carta em branco ainda não escrita: texto apagado e em itálico.
  final bool emBranco;

  const CartaBranca({
    super.key,
    required this.texto,
    this.emBranco = false,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          texto,
          style: emBranco
              ? _textoDeCarta(tinta.withValues(alpha: .55), 14).copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                )
              : _textoDeCarta(tinta, larga ? 17 : 15),
        ),
        if (autor != null) ...[
          const SizedBox(height: 8),
          Text(
            autor!,
            style: GoogleFonts.figtree(
              color: tinta.withValues(alpha: 0.65),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );

    final carta = AnimatedContainer(
      duration: reduzir ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      transform:
          Matrix4.translationValues(0, selecionada && !larga ? -16 : 0, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(Medidas.raioCarta),
        border: Border.all(
          color: selecionada ? cores.acao : Colors.transparent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: selecionada ? Medidas.sombra : Medidas.sombraLeve,
            blurRadius: selecionada ? 22 : 12,
            offset: Offset(0, selecionada ? 12 : 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          larga
              ? SizedBox(width: double.infinity, child: conteudo)
              : SizedBox.expand(child: conteudo),
          if (ordem != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: cores.acao,
                child: Text(
                  '$ordem',
                  style: GoogleFonts.figtree(
                    color: cores.tintaNaAcao,
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
        onTap: () {
          HapticFeedback.selectionClick();
          widget.aoTocar();
        },
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

/// A mão em leque: as cartas lado a lado numa faixa que se arrasta para os
/// lados, levemente inclinadas, como seguradas na mão. Em tela larga, todas
/// cabem sem arrastar.
class MaoEmLeque extends StatelessWidget {
  final int quantidade;
  final Widget Function(BuildContext, int) construir;

  const MaoEmLeque({
    super.key,
    required this.quantidade,
    required this.construir,
  });

  static const larguraDaCarta = 128.0;

  /// No computador (mão com 640 px ou mais), a carta cresce.
  static const larguraDaCartaGrande = 168.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, espaco) => _leque(
        context,
        espaco.maxWidth >= 640 ? larguraDaCartaGrande : larguraDaCarta,
      ),
    );
  }

  Widget _leque(BuildContext context, double larguraDaCarta) {
    final alturaDaCarta = larguraDaCarta / Medidas.proporcaoCarta;
    final reduzir = MediaQuery.of(context).disableAnimations;
    final meio = (quantidade - 1) / 2;
    return SizedBox(
      // Espaço extra em cima para a carta escolhida subir sem cortar.
      height: alturaDaCarta + 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.fromLTRB(Medidas.margem, 24, Medidas.margem, 10),
        itemCount: quantidade,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final angulo = reduzir ? 0.0 : (i - meio) * 0.025;
          return Transform.rotate(
            angle: max(-0.08, min(0.08, angulo)),
            child: SizedBox(
              width: larguraDaCarta,
              height: alturaDaCarta,
              child: construir(context, i),
            ),
          );
        },
      ),
    );
  }
}

/// O olho que se abre na lacuna da carta preta: a pálpebra sobe e a pupila
/// vermelha olha de um lado para o outro, devagar.
class OlhoNaLacuna extends StatefulWidget {
  final Color cor;

  const OlhoNaLacuna({super.key, required this.cor});

  @override
  State<OlhoNaLacuna> createState() => _OlhoNaLacunaState();
}

class _OlhoNaLacunaState extends State<OlhoNaLacuna>
    with TickerProviderStateMixin {
  late final _abrir = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _olhar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (movimentoReduzido(context)) {
      _abrir.value = 1;
      _olhar.value = .5;
    } else if (!_abrir.isAnimating && _abrir.value == 0) {
      _abrir.forward();
      _olhar.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _abrir.dispose();
    _olhar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      width: 66,
      height: 26,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.cor, width: 2)),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_abrir, _olhar]),
        builder: (context, _) => CustomPaint(
          painter: _PintorDoOlho(
            abertura: Curves.easeOutBack.transform(_abrir.value),
            olhar: Curves.easeInOut.transform(_olhar.value) * 2 - 1,
            branco: widget.cor,
            iris: cores.acao,
            pupila: cores.cartaPreta,
          ),
        ),
      ),
    );
  }
}

class _PintorDoOlho extends CustomPainter {
  final double abertura;
  final double olhar;
  final Color branco;
  final Color iris;
  final Color pupila;

  const _PintorDoOlho({
    required this.abertura,
    required this.olhar,
    required this.branco,
    required this.iris,
    required this.pupila,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final meiaLargura = size.width * .3;
    final meiaAltura = size.height * .38 * abertura.clamp(0.0, 1.2);
    if (meiaAltura <= .5) return;
    final olho = Path()
      ..moveTo(c.dx - meiaLargura, c.dy)
      ..quadraticBezierTo(c.dx, c.dy - meiaAltura * 2, c.dx + meiaLargura, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + meiaAltura * 2, c.dx - meiaLargura, c.dy)
      ..close();
    canvas.drawPath(olho, Paint()..color = branco);
    canvas.save();
    canvas.clipPath(olho);
    final centro = c + Offset(olhar * meiaLargura * .45, 0);
    canvas.drawCircle(centro, size.height * .26, Paint()..color = iris);
    canvas.drawCircle(centro, size.height * .11, Paint()..color = pupila);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorDoOlho old) =>
      old.abertura != abertura || old.olhar != olhar;
}

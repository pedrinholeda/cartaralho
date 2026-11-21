import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'animacoes.dart';
import 'tema.dart';

/// As dicas da primeira partida. Cada uma aparece uma vez por aparelho: some
/// quando a pessoa faz o que ela pede, ou toca em "Entendi".
enum Dica {
  /// Sobre a mão: tocar numa carta.
  mao,

  /// Sobre o botão de enviar, com a carta escolhida.
  enviar,

  /// Para o juiz, na hora de escolher.
  juiz,
}

const _chaveDicas = 'dicasVistas';

/// As dicas já vistas neste aparelho. Nulo enquanto carrega, para nenhuma
/// piscar na tela antes de saber se já foi vista.
class DicasNotifier extends StateNotifier<Set<Dica>?> {
  DicasNotifier() : super(null) {
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nomes = prefs.getStringList(_chaveDicas) ?? const [];
      state = {
        for (final d in Dica.values)
          if (nomes.contains(d.name)) d,
      };
    } catch (_) {
      // Sem armazenamento (janela anônima restrita): não mostra dica, para
      // não repetir a cada partida.
      state = {...Dica.values};
    }
  }

  Future<void> marcar(Dica dica) async {
    final vistas = state;
    if (vistas == null || vistas.contains(dica)) return;
    state = {...vistas, dica};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_chaveDicas, [for (final d in state!) d.name]);
    } catch (_) {}
  }
}

final dicasProvider = StateNotifierProvider<DicasNotifier, Set<Dica>?>(
  (ref) => DicasNotifier(),
);

/// Se a [dica] ainda deve aparecer.
bool deveMostrar(Set<Dica>? vistas, Dica dica) =>
    vistas != null && !vistas.contains(dica);

/// O balão da dica: amarelo, com uma setinha para baixo (para o que ele
/// aponta) e o "Entendi" para fechar. Pula de leve para chamar o olho.
class BalaoDeDica extends StatefulWidget {
  final String texto;
  final VoidCallback aoFechar;

  const BalaoDeDica({super.key, required this.texto, required this.aoFechar});

  @override
  State<BalaoDeDica> createState() => _BalaoDeDicaState();
}

class _BalaoDeDicaState extends State<BalaoDeDica>
    with SingleTickerProviderStateMixin {
  late final _pulo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (movimentoReduzido(context)) {
      _pulo.stop();
    } else if (!_pulo.isAnimating) {
      _pulo.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final balao = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
          decoration: BoxDecoration(
            color: cores.destaque,
            borderRadius: BorderRadius.circular(Medidas.raioPainel),
            boxShadow: const [
              BoxShadow(color: Medidas.sombra, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.texto,
                  style: GoogleFonts.figtree(
                    color: cores.tintaNoDestaque,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.aoFechar,
                style: TextButton.styleFrom(
                  foregroundColor: cores.tintaNoDestaque,
                  minimumSize: const Size(44, 36),
                ),
                child: const Text('Entendi'),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(18, 9),
          painter: _Setinha(cores.destaque),
        ),
      ],
    );
    return Semantics(
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _pulo,
        builder: (context, filho) => Transform.translate(
          offset: Offset(0, -4 * Curves.easeInOut.transform(_pulo.value)),
          child: filho,
        ),
        child: balao,
      ),
    );
  }
}

class _Setinha extends CustomPainter {
  final Color cor;

  const _Setinha(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = cor,
    );
  }

  @override
  bool shouldRepaint(_Setinha old) => old.cor != cor;
}

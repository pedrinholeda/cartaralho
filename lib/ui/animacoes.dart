import 'dart:math';

import 'package:flutter/material.dart';

import 'tema.dart';

/// Movimento só quando ele mostra o que mudou: carta chegando na mão, carta
/// virando na mesa, confete para quem ganhou. Com "reduzir movimento" ligado
/// no sistema, tudo aparece direto, sem animação.
bool movimentoReduzido(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// A carta entra subindo e aparecendo, como se fosse dada na mão. Anima só na
/// primeira vez que aparece: dê uma `key` por carta para as novas animarem e
/// as que ficaram na mão, não.
class Entrada extends StatefulWidget {
  final Widget child;
  final Duration atraso;

  /// Distância, em pixels, de onde a carta vem (positivo: de baixo).
  final double deslocamento;

  const Entrada({
    super.key,
    required this.child,
    this.atraso = Duration.zero,
    this.deslocamento = 32,
  });

  @override
  State<Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<Entrada> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    if (movimentoReduzido(context)) {
      _c.value = 1;
    } else {
      Future.delayed(widget.atraso, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.deslocamento * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// A carta começa de costas e vira, como na hora de abrir as respostas para o
/// juiz. O verso é vermelho, com o nome do jogo.
class Virada extends StatefulWidget {
  final Widget child;
  final Duration atraso;

  const Virada({super.key, required this.child, this.atraso = Duration.zero});

  @override
  State<Virada> createState() => _ViradaState();
}

class _ViradaState extends State<Virada> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    if (movimentoReduzido(context)) {
      _c.value = 1;
    } else {
      Future.delayed(widget.atraso, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        final angulo = pi * (1 - t);
        final deCostas = angulo > pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(deCostas ? angulo - pi : angulo),
          child: deCostas ? _Verso(child: child!) : child,
        );
      },
    );
  }
}

/// O verso da carta: ocupa o mesmo espaço da frente, para a lista não pular.
class _Verso extends StatelessWidget {
  final Widget child;

  const _Verso({required this.child});

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Stack(
      children: [
        Opacity(opacity: 0, child: child),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: cores.cartaPreta,
              borderRadius: BorderRadius.circular(Medidas.raioCarta),
              border: Border.all(color: cores.mesa, width: 6),
            ),
            alignment: Alignment.center,
            child: Text(
              'Cartaralho',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: cores.tintaNaCartaPreta,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Confete caindo por cima da tela, uma vez, para quem venceu. Não captura
/// toques. Com "reduzir movimento", não aparece.
class Confete extends StatefulWidget {
  /// Quantos papéis caem. A vitória do jogo merece mais que a da rodada.
  final int quantidade;
  final Duration duracao;

  const Confete({
    super.key,
    this.quantidade = 70,
    this.duracao = const Duration(milliseconds: 2400),
  });

  @override
  State<Confete> createState() => _ConfeteState();
}

class _ConfeteState extends State<Confete> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duracao);
  late final List<_Papel> _papeis;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _papeis = [
      for (var i = 0; i < widget.quantidade; i++)
        _Papel(
          x: rng.nextDouble(),
          atraso: rng.nextDouble() * 0.35,
          velocidade: 0.7 + rng.nextDouble() * 0.6,
          balanco: rng.nextDouble() * 2 * pi,
          giro: (rng.nextDouble() - 0.5) * 12,
          cor: rng.nextInt(3),
          largura: 6 + rng.nextDouble() * 6,
        ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!movimentoReduzido(context) && !_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (movimentoReduzido(context)) return const SizedBox.shrink();
    final cores = Cores.de(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _PintorDeConfete(
            papeis: _papeis,
            t: _c.value,
            cores: [cores.destaque, cores.carta, cores.acao],
          ),
        ),
      ),
    );
  }
}

class _Papel {
  final double x, atraso, velocidade, balanco, giro, largura;
  final int cor;

  const _Papel({
    required this.x,
    required this.atraso,
    required this.velocidade,
    required this.balanco,
    required this.giro,
    required this.cor,
    required this.largura,
  });
}

class _PintorDeConfete extends CustomPainter {
  final List<_Papel> papeis;
  final double t;
  final List<Color> cores;

  _PintorDeConfete(
      {required this.papeis, required this.t, required this.cores});

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final pincel = Paint();
    for (final p in papeis) {
      final local = ((t - p.atraso) / (1 - p.atraso)).clamp(0.0, 1.0);
      if (local == 0) continue;
      final y = -20 + (size.height + 40) * local * p.velocidade;
      final x = size.width * p.x + sin(p.balanco + local * 8) * 18;
      // Some no último quarto, para não terminar de repente.
      final opacidade = local < 0.75 ? 1.0 : (1 - local) / 0.25;
      pincel.color = cores[p.cor].withValues(alpha: opacidade);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.giro * local)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.largura,
            height: p.largura * 0.5,
          ),
          pincel,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_PintorDeConfete old) => old.t != t;
}

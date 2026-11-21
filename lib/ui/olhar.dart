import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'animacoes.dart';

/// Onde está o ponteiro, em coordenadas da tela: o mouse no computador, o
/// último toque no celular. As carinhas olham para lá.
final ondeOlhar = ValueNotifier<Offset?>(null);

/// Fica em volta do app inteiro e anota onde o ponteiro anda, sem atrapalhar
/// nenhum toque.
class RastreadorDeOlhar extends StatelessWidget {
  final Widget child;

  const RastreadorDeOlhar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    void anotar(PointerEvent e) => ondeOlhar.value = e.position;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: anotar,
      onPointerMove: anotar,
      onPointerDown: anotar,
      child: child,
    );
  }
}

/// Um cascudo em andamento: quem dá, quem leva e um número para cada vez.
@immutable
class Cascudo {
  final int agressor;
  final int vitima;
  final int vez;

  const Cascudo(this.agressor, this.vitima, this.vez);
}

/// Um grupo de carinhas lado a lado (o placar, a sala de espera, a capa). De
/// tempos em tempos, uma dá um cascudo na vizinha. Os avatares do grupo
/// acham o grupo pelo contexto e fazem a parte deles.
class GrupoDeCarinhas extends StatefulWidget {
  final int quantidade;

  /// Para que lado fica a vizinha: à direita (horizontal) ou embaixo.
  final Axis eixo;

  /// Distância de uma carinha à próxima, em pixels.
  final double passo;

  /// Quantas cabem por linha, quando o grupo quebra linha (sala de espera):
  /// o cascudo nunca atravessa a quebra.
  final int? porLinha;

  final Widget child;

  const GrupoDeCarinhas({
    super.key,
    required this.quantidade,
    required this.eixo,
    required this.passo,
    this.porLinha,
    required this.child,
  });

  /// O grupo em volta, se houver.
  static GrupoInfo? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GrupoInfo>();

  @override
  State<GrupoDeCarinhas> createState() => _GrupoDeCarinhasState();
}

class _GrupoDeCarinhasState extends State<GrupoDeCarinhas>
    with SingleTickerProviderStateMixin {
  final _cascudo = ValueNotifier<Cascudo?>(null);
  final _rng = Random();
  late final Ticker _relogio = createTicker(_tique);
  Duration _proximo = const Duration(seconds: 8);
  int _vez = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (movimentoReduzido(context)) {
      _relogio.stop();
    } else if (!_relogio.isActive) {
      _relogio.start();
    }
  }

  /// O primeiro cascudo sai uns segundos depois de abrir; os outros, de 18 a
  /// 35 segundos depois do anterior.
  void _tique(Duration agora) {
    if (agora < _proximo) return;
    _proximo = agora + Duration(seconds: 18 + _rng.nextInt(18));
    final pares = [
      for (var i = 0; i < widget.quantidade - 1; i++)
        if (widget.porLinha == null ||
            i ~/ widget.porLinha! == (i + 1) ~/ widget.porLinha!)
          i,
    ];
    if (pares.isEmpty) return;
    final i = pares[_rng.nextInt(pares.length)];
    // Tanto faz quem começa: às vezes o da esquerda, às vezes o da direita.
    _cascudo.value =
        _rng.nextBool() ? Cascudo(i, i + 1, ++_vez) : Cascudo(i + 1, i, ++_vez);
  }

  @override
  void dispose() {
    _relogio.dispose();
    _cascudo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GrupoInfo(
        cascudo: _cascudo,
        eixo: widget.eixo,
        passo: widget.passo,
        child: widget.child,
      );
}

class GrupoInfo extends InheritedWidget {
  final ValueNotifier<Cascudo?> cascudo;
  final Axis eixo;
  final double passo;

  const GrupoInfo({
    super.key,
    required this.cascudo,
    required this.eixo,
    required this.passo,
    required super.child,
  });

  @override
  bool updateShouldNotify(GrupoInfo old) =>
      old.cascudo != cascudo || old.eixo != eixo || old.passo != passo;
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/card.dart';
import '../ui/assombro.dart';
import '../ui/cartas.dart';
import '../ui/tema.dart';

/// A carta preta da rodada, no topo da tela de jogo, com as [respostas] do
/// jogador no lugar das lacunas enquanto ele escolhe.
class BlackCardWidget extends StatefulWidget {
  final GameCard card;
  final List<String> respostas;

  /// O jogador ainda não enviou: depois de [esperaDaLacuna], a lacuna abre
  /// um olho.
  final bool esperando;

  const BlackCardWidget({
    super.key,
    required this.card,
    this.respostas = const [],
    this.esperando = false,
  });

  @override
  State<BlackCardWidget> createState() => _BlackCardWidgetState();
}

class _BlackCardWidgetState extends State<BlackCardWidget> {
  Timer? _relogio;
  bool _olhando = false;

  @override
  void initState() {
    super.initState();
    _armar();
  }

  @override
  void didUpdateWidget(BlackCardWidget antes) {
    super.didUpdateWidget(antes);
    if (antes.card.id != widget.card.id ||
        antes.esperando != widget.esperando) {
      _armar();
    }
  }

  /// Recomeça a contagem a cada carta nova; quem já enviou não é olhado.
  void _armar() {
    _relogio?.cancel();
    _olhando = false;
    if (!widget.esperando) return;
    _relogio = Timer(esperaDaLacuna, () {
      if (mounted) setState(() => _olhando = true);
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.margem,
        8,
        Medidas.margem,
        4,
      ),
      child: CartaPreta(
        texto: card.text,
        pede: card.pick,
        respostas: widget.respostas,
        olho: _olhando && widget.esperando,
        rodape: ehMadrugada(agora()) ? rodapeDaMadrugada : null,
      ),
    );
  }
}

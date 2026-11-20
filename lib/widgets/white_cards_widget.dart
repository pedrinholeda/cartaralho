import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/regras.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';
import '../ui/cartas.dart';
import '../ui/tema.dart';

/// A mão do jogador. Ele escolhe quantas cartas a carta preta pede, na ordem
/// das lacunas, e vê a frase sendo montada antes de enviar.
class WhiteCardsWidget extends ConsumerStatefulWidget {
  final GameRoom room;
  final Player currentPlayer;

  const WhiteCardsWidget({
    super.key,
    required this.room,
    required this.currentPlayer,
  });

  @override
  ConsumerState<WhiteCardsWidget> createState() => _WhiteCardsWidgetState();
}

class _WhiteCardsWidgetState extends ConsumerState<WhiteCardsWidget> {
  /// Cartas escolhidas, na ordem em que vão preencher as lacunas.
  final List<GameCard> _escolhidas = [];
  bool _isSubmitting = false;
  bool _trocando = false;

  List<GameCard> get _mao =>
      widget.room.hands[widget.currentPlayer.id] ?? const [];

  int get _pede => widget.room.currentBlackCard?.pick ?? 1;

  @override
  void didUpdateWidget(WhiteCardsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Numa rodada nova as cartas escolhidas antes já não estão na mão, e a
    // carta preta pode pedir outra quantidade.
    _escolhidas.removeWhere((e) => !_mao.any((c) => c.id == e.id));
    if (_escolhidas.length > _pede) _escolhidas.clear();
  }

  void _tocar(GameCard carta) {
    setState(() {
      if (_escolhidas.any((c) => c.id == carta.id)) {
        _escolhidas.removeWhere((c) => c.id == carta.id);
      } else if (_pede == 1) {
        _escolhidas
          ..clear()
          ..add(carta);
      } else if (_escolhidas.length < _pede) {
        _escolhidas.add(carta);
      }
    });
  }

  Future<void> _enviar() async {
    setState(() => _isSubmitting = true);
    try {
      await FirebaseService.submitWhiteCards(
        widget.room.roomId,
        [for (final c in _escolhidas) c.id],
      );
    } catch (e) {
      _avisar('Não deu para enviar: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _trocarMao() async {
    setState(() => _trocando = true);
    try {
      await FirebaseService.swapHand(widget.room.roomId);
      _escolhidas.clear();
    } catch (e) {
      _avisar('Não deu para trocar a mão: $e');
    } finally {
      if (mounted) setState(() => _trocando = false);
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    final preta = widget.room.currentBlackCard;
    final enviadas = widget.room.submittedCards[widget.currentPlayer.id];

    if (enviadas != null) {
      final frase = preta == null
          ? enviadas.map((c) => c.text).join(' / ')
          : fraseCompleta(preta, enviadas);
      return Padding(
        padding: const EdgeInsets.all(Medidas.margem),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CartaBranca(texto: frase, larga: true),
            const SizedBox(height: 16),
            Text(
              'Enviada. Esperando os outros jogadores.',
              style: textos.titleMedium?.copyWith(color: cores.tintaNaMesa),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final mao = _mao;
    final pede = _pede;
    final pronto = _escolhidas.length == pede;
    final podeTrocar =
        !widget.room.handSwapsUsed.contains(widget.currentPlayer.id);

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Medidas.margem, 12, Medidas.margem, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pede == 1
                ? 'Escolha uma carta branca:'
                : 'Escolha $pede cartas brancas, na ordem:',
            style: textos.titleLarge?.copyWith(color: cores.tintaNaMesa),
          ),
          if (_escolhidas.isNotEmpty && preta != null) ...[
            const SizedBox(height: 6),
            Text(
              fraseCompleta(preta, _escolhidas),
              style: textos.bodyLarge?.copyWith(
                color: cores.tintaNaMesa,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          Expanded(
            child: GradeDeCartas(
              quantidade: mao.length,
              construir: (context, index) {
                final carta = mao[index];
                final posicao = _escolhidas.indexWhere((c) => c.id == carta.id);
                return CartaBranca(
                  texto: carta.text,
                  selecionada: posicao >= 0,
                  ordem: posicao >= 0 && pede > 1 ? posicao + 1 : null,
                  aoTocar: () => _tocar(carta),
                );
              },
            ),
          ),
          if (podeTrocar)
            Align(
              child: TextButton.icon(
                onPressed: _trocando ? null : _trocarMao,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Trocar minha mão (uma vez por partida)'),
              ),
            ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: pronto && !_isSubmitting ? _enviar : null,
            child: _isSubmitting
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      color: cores.tintaNaCartaPreta,
                      strokeWidth: 3,
                    ),
                  )
                : Text(pede == 1 ? 'Enviar Carta' : 'Enviar Cartas'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/regras.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao trocar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _trocando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preta = widget.room.currentBlackCard;
    final enviadas = widget.room.submittedCards[widget.currentPlayer.id];
    if (enviadas != null) {
      final frase = preta == null
          ? enviadas.map((c) => c.text).join(' / ')
          : fraseCompleta(preta, enviadas);
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'Você enviou "$frase". Esperando os outros jogadores.',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final mao = _mao;
    final pede = _pede;
    final pronto = _escolhidas.length == pede;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            pede == 1
                ? 'Escolha uma carta branca:'
                : 'Escolha $pede cartas brancas, na ordem:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_escolhidas.isNotEmpty && preta != null) ...[
            const SizedBox(height: 8),
            Text(
              fraseCompleta(preta, _escolhidas),
              style: const TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: mao.length,
              itemBuilder: (context, index) {
                final carta = mao[index];
                final posicao = _escolhidas.indexWhere((c) => c.id == carta.id);
                final escolhida = posicao >= 0;

                return Semantics(
                  button: true,
                  selected: escolhida,
                  label: carta.text,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => _tocar(carta),
                    child: Card(
                      color: escolhida ? const Color(0xFF6A1B9A) : Colors.white,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.center,
                            child: Text(
                              carta.text,
                              style: TextStyle(
                                color: escolhida ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (escolhida && pede > 1)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.white,
                                child: Text(
                                  '${posicao + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6A1B9A),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!widget.room.handSwapsUsed.contains(widget.currentPlayer.id))
            TextButton.icon(
              onPressed: _trocando ? null : _trocarMao,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Trocar minha mão (uma vez por partida)'),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: pronto && !_isSubmitting ? _enviar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      pede == 1 ? 'Enviar Carta' : 'Enviar Cartas',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

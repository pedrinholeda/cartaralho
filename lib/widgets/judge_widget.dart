import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/regras.dart';
import '../models/game_room.dart';
import '../services/firebase_service.dart';
import '../ui/cartas.dart';
import '../ui/tema.dart';

/// O juiz lê as frases da mesa, na ordem sorteada, e escolhe a melhor.
class JudgeWidget extends ConsumerStatefulWidget {
  final GameRoom room;

  const JudgeWidget({super.key, required this.room});

  @override
  ConsumerState<JudgeWidget> createState() => _JudgeWidgetState();
}

class _JudgeWidgetState extends ConsumerState<JudgeWidget> {
  /// Id de quem enviou a carta escolhida.
  String? _selectedWinner;
  bool _isChoosing = false;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final mesa = widget.room.cardsOnTable;
    final preta = widget.room.currentBlackCard;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Medidas.margem, 12, Medidas.margem, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escolha a carta vencedora:',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: cores.tintaNaMesa),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: mesa.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cartas = mesa[index].value;
                final playerId = mesa[index].key;
                return CartaBranca(
                  larga: true,
                  texto: preta == null
                      ? cartas.map((c) => c.text).join(' / ')
                      : fraseCompleta(preta, cartas),
                  selecionada: _selectedWinner == playerId,
                  aoTocar: () => setState(() => _selectedWinner = playerId),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                _selectedWinner != null && !_isChoosing ? _chooseWinner : null,
            child: _isChoosing
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      color: cores.tintaNaCartaPreta,
                      strokeWidth: 3,
                    ),
                  )
                : const Text('Escolher Vencedor'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseWinner() async {
    if (_selectedWinner == null) return;
    setState(() => _isChoosing = true);
    try {
      await FirebaseService.chooseWinner(widget.room.roomId, _selectedWinner!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não deu para escolher: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChoosing = false);
    }
  }
}

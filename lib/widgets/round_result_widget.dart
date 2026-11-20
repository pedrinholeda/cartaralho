import 'package:flutter/material.dart';

import '../game/regras.dart';
import '../models/game_room.dart';
import '../services/firebase_service.dart';

/// O fim da rodada: a frase vencedora, quem a enviou e o que cada um jogou.
/// O juiz fecha com "Próxima rodada" quando o grupo terminou de ler.
class RoundResultWidget extends StatefulWidget {
  final GameRoom room;
  final bool isJudge;

  const RoundResultWidget({
    super.key,
    required this.room,
    required this.isJudge,
  });

  @override
  State<RoundResultWidget> createState() => _RoundResultWidgetState();
}

class _RoundResultWidgetState extends State<RoundResultWidget> {
  bool _avancando = false;

  String _nome(String id) =>
      widget.room.players.where((p) => p.id == id).firstOrNull?.name ?? '?';

  Future<void> _proximaRodada() async {
    setState(() => _avancando = true);
    try {
      await FirebaseService.nextRound(widget.room.roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _avancando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final preta = room.currentBlackCard;
    final vencedorId = room.lastRoundWinnerId;
    final juiz = _nome(room.currentJudgeId ?? '');
    String frase(String id) => preta == null
        ? room.submittedCards[id]!.map((c) => c.text).join(' / ')
        : fraseCompleta(preta, room.submittedCards[id]!);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            vencedorId == null
                ? 'Rodada encerrada'
                : '${_nome(vencedorId)} ganhou a rodada!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final entrada in room.cardsOnTable)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: entrada.key == vencedorId
                        ? const Color(0xFF6A1B9A)
                        : null,
                    child: ListTile(
                      title: Text(
                        frase(entrada.key),
                        style: TextStyle(
                          color:
                              entrada.key == vencedorId ? Colors.white : null,
                          fontWeight: entrada.key == vencedorId
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        _nome(entrada.key),
                        style: TextStyle(
                          color:
                              entrada.key == vencedorId ? Colors.white70 : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.isJudge)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _avancando ? null : _proximaRodada,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _avancando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Próxima rodada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            )
          else
            Text(
              'Esperando $juiz começar a próxima rodada.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

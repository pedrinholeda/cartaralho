import 'package:flutter/material.dart';

import '../game/regras.dart';
import '../models/game_room.dart';
import '../services/firebase_service.dart';
import '../ui/cartas.dart';
import '../ui/tema.dart';

/// O fim da rodada: a frase vencedora em amarelo, quem a enviou e o que cada
/// um jogou. O juiz fecha com "Próxima rodada" quando o grupo terminou de ler.
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
          SnackBar(content: Text('Não deu para avançar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _avancando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    final room = widget.room;
    final preta = room.currentBlackCard;
    final vencedorId = room.lastRoundWinnerId;
    final juiz = _nome(room.currentJudgeId ?? '');
    String frase(String id) {
      final cartas = room.submittedCards[id]!;
      return preta == null
          ? cartas.map((c) => c.text).join(' / ')
          : fraseCompleta(preta, cartas);
    }

    // A vencedora primeiro, depois as outras na ordem da mesa.
    final mesa = [
      ...room.cardsOnTable.where((e) => e.key == vencedorId),
      ...room.cardsOnTable.where((e) => e.key != vencedorId),
    ];

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Medidas.margem, 12, Medidas.margem, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vencedorId == null
                ? 'Rodada encerrada'
                : '${_nome(vencedorId)} ganhou a rodada!',
            style: textos.headlineSmall?.copyWith(color: cores.tintaNaMesa),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: mesa.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final id = mesa[index].key;
                return CartaBranca(
                  larga: true,
                  texto: frase(id),
                  autor: _nome(id),
                  vencedora: id == vencedorId,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (widget.isJudge)
            ElevatedButton(
              onPressed: _avancando ? null : _proximaRodada,
              child: _avancando
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        color: cores.tintaNaCartaPreta,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text('Próxima rodada'),
            )
          else
            Text(
              'Esperando $juiz começar a próxima rodada.',
              style: textos.bodyLarge?.copyWith(color: cores.tintaNaMesa),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

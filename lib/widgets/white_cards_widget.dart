import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../models/card.dart';
import '../services/firebase_service.dart';

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
  GameCard? _selectedCard;
  bool _isSubmitting = false;

  List<GameCard> get _playerWhiteCards {
    // Simular cartas do jogador (em uma implementação real, isso viria do Firestore)
    final shuffledWhiteCards = List<GameCard>.from(widget.room.whiteCards)
      ..shuffle();
    return shuffledWhiteCards.take(5).toList();
  }

  Future<void> _submitCard() async {
    if (_selectedCard == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseService.submitWhiteCard(
        widget.room.roomId,
        widget.currentPlayer.id,
        _selectedCard!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar carta: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerCards = _playerWhiteCards;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Escolha uma carta branca:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: playerCards.length,
              itemBuilder: (context, index) {
                final card = playerCards[index];
                final isSelected = _selectedCard?.id == card.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCard = card;
                    });
                  },
                  child: Card(
                    color: isSelected ? const Color(0xFF6A1B9A) : Colors.white,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          card.text,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _selectedCard != null && !_isSubmitting ? _submitCard : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Enviar Carta',
                      style: TextStyle(
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

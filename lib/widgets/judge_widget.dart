import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_room.dart';
import '../services/firebase_service.dart';

class JudgeWidget extends ConsumerStatefulWidget {
  final GameRoom room;

  const JudgeWidget({
    super.key,
    required this.room,
  });

  @override
  ConsumerState<JudgeWidget> createState() => _JudgeWidgetState();
}

class _JudgeWidgetState extends ConsumerState<JudgeWidget> {
  /// Id de quem enviou a carta escolhida.
  String? _selectedWinner;
  bool _isChoosing = false;

  @override
  Widget build(BuildContext context) {
    final submittedCards = widget.room.submittedCards.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Escolha a carta vencedora:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: submittedCards.length,
              itemBuilder: (context, index) {
                final card = submittedCards[index].value;
                final playerId = submittedCards[index].key;
                final isSelected = _selectedWinner == playerId;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isSelected ? const Color(0xFF6A1B9A) : Colors.white,
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedWinner = playerId;
                      });
                    },
                    title: Text(
                      card.text,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.white)
                        : const Icon(Icons.radio_button_unchecked),
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
              onPressed: _selectedWinner != null && !_isChoosing
                  ? _chooseWinner
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isChoosing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Escolher Vencedor',
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

  Future<void> _chooseWinner() async {
    if (_selectedWinner == null) return;

    setState(() {
      _isChoosing = true;
    });

    try {
      await FirebaseService.chooseWinner(widget.room.roomId, _selectedWinner!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao escolher vencedor: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChoosing = false;
        });
      }
    }
  }
}

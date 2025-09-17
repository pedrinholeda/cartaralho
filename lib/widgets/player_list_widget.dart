import 'package:flutter/material.dart';
import '../models/player.dart';

class PlayerListWidget extends StatelessWidget {
  final List<Player> players;

  const PlayerListWidget({
    super.key,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            child: Card(
              color: player.isJudge ? Colors.amber : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: player.isJudge ? Colors.black : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${player.points}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                player.isJudge ? Colors.black : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (player.isJudge)
                      const Text(
                        'JUIZ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

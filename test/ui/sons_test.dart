import 'dart:io';

import 'package:cartaralho/models/card.dart';
import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:cartaralho/ui/sons.dart';
import 'package:flutter_test/flutter_test.dart';

GameRoom sala(GamePhase fase, {String preta = 'b1'}) => GameRoom(
      roomId: 'ABC234',
      players: [Player(id: 'p0', name: 'Ana', isHost: true)],
      blackCards: const [],
      whiteCards: const [],
      currentBlackCard:
          GameCard(id: preta, text: '____.', type: CardType.black),
      phase: fase,
    );

void main() {
  group('somDaMudanca', () {
    test('cada fase nova tem o seu som', () {
      expect(
        somDaMudanca(
          sala(GamePhase.waitingForPlayers),
          sala(GamePhase.playersSubmitting),
        ),
        Som.distribuir,
      );
      expect(
        somDaMudanca(
          sala(GamePhase.playersSubmitting),
          sala(GamePhase.judgeChoosing),
        ),
        Som.virar,
      );
      expect(
        somDaMudanca(
            sala(GamePhase.judgeChoosing), sala(GamePhase.roundResult)),
        Som.rodada,
      );
      expect(
        somDaMudanca(
          sala(GamePhase.judgeChoosing),
          sala(GamePhase.gameComplete),
        ),
        Som.vitoria,
      );
    });

    test('rodada nova distribui de novo', () {
      expect(
        somDaMudanca(
          sala(GamePhase.roundResult, preta: 'b1'),
          sala(GamePhase.playersSubmitting, preta: 'b2'),
        ),
        Som.distribuir,
      );
    });

    test('mudança dentro da mesma fase não toca nada', () {
      // Por exemplo, outro jogador enviou a carta dele.
      expect(
        somDaMudanca(
          sala(GamePhase.playersSubmitting),
          sala(GamePhase.playersSubmitting),
        ),
        isNull,
      );
    });

    test('abrir a sala não toca nada', () {
      expect(somDaMudanca(null, sala(GamePhase.judgeChoosing)), isNull);
    });

    test('voltar para a espera não toca nada', () {
      expect(
        somDaMudanca(
          sala(GamePhase.gameComplete),
          sala(GamePhase.waitingForPlayers),
        ),
        isNull,
      );
    });
  });

  test('todo som tem o seu arquivo em assets/sons/', () {
    for (final som in Som.values) {
      final arquivo = File('assets/sons/${som.name}.wav');
      expect(arquivo.existsSync(), isTrue, reason: arquivo.path);
      expect(arquivo.lengthSync(), greaterThan(1000), reason: arquivo.path);
    }
  });
}

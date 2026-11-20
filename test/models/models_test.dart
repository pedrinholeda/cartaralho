import 'package:cartaralho/models/card.dart';
import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCard', () {
    test('grava o tipo pelo nome e lê de volta', () {
      final carta =
          GameCard(id: 'b1', text: '____ é bom.', type: CardType.black);
      final json = carta.toJson();

      expect(json, {'id': 'b1', 'text': '____ é bom.', 'type': 'black'});
      final lida = GameCard.fromJson(json);
      expect(lida.id, 'b1');
      expect(lida.text, '____ é bom.');
      expect(lida.type, CardType.black);
    });
  });

  group('Player', () {
    test('campos ausentes no Firestore viram os padrões', () {
      final p = Player.fromJson({'id': 'u1', 'name': 'Ana'});
      expect(p.points, 0);
      expect(p.isHost, isFalse);
      expect(p.avatar, 0);
    });

    test('a carinha sorteada vai e volta do Firestore', () {
      final p = Player(id: 'u1', name: 'Ana', avatar: 4);
      expect(Player.fromJson(p.toJson()).avatar, 4);
      expect(p.copyWith(points: 1).avatar, 4);
    });

    test('copyWith troca só o que foi pedido', () {
      final p = Player(id: 'u1', name: 'Ana', isHost: true);
      final q = p.copyWith(points: 3);
      expect(q.points, 3);
      expect(q.name, 'Ana');
      expect(q.isHost, isTrue);
    });
  });

  group('GameRoom', () {
    GameRoom sala() => GameRoom(
          roomId: 'ABC234',
          players: [Player(id: 'u1', name: 'Ana', isHost: true)],
          blackCards: [
            GameCard(id: 'b1', text: '____?', type: CardType.black),
          ],
          whiteCards: [
            GameCard(id: 'w1', text: 'Pizza', type: CardType.white),
          ],
          currentJudgeId: 'u1',
          phase: GamePhase.judgeChoosing,
          submittedCards: {
            'u2': [GameCard(id: 'w2', text: 'Café', type: CardType.white)],
          },
          hands: {
            'u2': [GameCard(id: 'w3', text: 'TikTok', type: CardType.white)],
          },
          lastRoundWinnerId: 'u2',
          revealOrder: ['u2'],
        );

    test('ida e volta pelo JSON preserva a sala', () {
      final lida = GameRoom.fromJson(sala().toJson());

      expect(lida.roomId, 'ABC234');
      expect(lida.players.single.name, 'Ana');
      expect(lida.blackCards.single.id, 'b1');
      expect(lida.whiteCards.single.id, 'w1');
      expect(lida.phase, GamePhase.judgeChoosing);
      expect(lida.currentJudgeId, 'u1');
      expect(lida.submittedCards['u2']!.single.text, 'Café');
      expect(lida.hands['u2']!.single.text, 'TikTok');
      expect(lida.lastRoundWinnerId, 'u2');
      expect(lida.revealOrder, ['u2']);
      expect(lida.maxPoints, 5);
    });

    test('fase desconhecida volta para a espera', () {
      final json = sala().toJson()..['phase'] = 'faseQueNaoExiste';
      expect(GameRoom.fromJson(json).phase, GamePhase.waitingForPlayers);
    });

    test('lê cartas enviadas no formato antigo, uma carta por jogador', () {
      final json = sala().toJson()
        ..['submittedCards'] = {
          'u2': {'id': 'w2', 'text': 'Café', 'type': 'white'},
        };
      expect(GameRoom.fromJson(json).submittedCards['u2']!.single.text, 'Café');
    });

    test('sem submittedCards no documento, a sala lê um mapa vazio', () {
      final json = sala().toJson()..remove('submittedCards');
      expect(GameRoom.fromJson(json).submittedCards, isEmpty);
    });
  });
}

import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:cartaralho/services/validade.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a sala vai para o Firestore com prazo de 24 h a partir de agora', () {
    final sala = GameRoom(
      roomId: 'K7PX2M',
      players: [Player(id: 'a', name: 'Ana', isHost: true)],
      blackCards: const [],
      whiteCards: const [],
    );
    final agora = DateTime.utc(2026, 11, 22, 10);
    final json = salaComValidade(sala, agora);
    expect((json['expiraEm'] as Timestamp).toDate().toUtc(),
        DateTime.utc(2026, 11, 23, 10));
    // O resto do documento é o de sempre, e quem lê ignora o campo novo.
    expect(json['roomId'], 'K7PX2M');
    expect(GameRoom.fromJson(json).roomId, 'K7PX2M');
  });
}

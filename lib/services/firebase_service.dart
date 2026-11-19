import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../models/card.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  static Future<User?> signInAnonymously() async {
    try {
      print('Iniciando login anônimo...');
      final userCredential = await _auth.signInAnonymously().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: Login anônimo demorou mais de 30 segundos');
        },
      );
      print('Login anônimo bem-sucedido: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('Erro detalhado no login anônimo: $e');
      throw Exception('Erro ao fazer login anônimo: $e');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  // Room Management
  static Future<String> createRoom(String playerName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final roomId = _generateRoomId();
      final player = Player(
        id: user.uid,
        name: playerName,
        isHost: true,
        isJudge: true,
      );

      final gameRoom = GameRoom(
        roomId: roomId,
        players: [player],
        blackCards: _getMockBlackCards(),
        whiteCards: _getMockWhiteCards(),
        currentJudgeId: user.uid,
      );

      await _firestore.collection('rooms').doc(roomId).set(gameRoom.toJson());
      return roomId;
    } catch (e) {
      throw Exception('Erro ao criar sala: $e');
    }
  }

  static Future<void> joinRoom(String roomId, String playerName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) {
        throw Exception('Sala não encontrada');
      }

      final gameRoom = GameRoom.fromJson(roomDoc.data()!);

      // Verificar se o jogador já está na sala
      if (gameRoom.players.any((p) => p.id == user.uid)) {
        return; // Jogador já está na sala
      }

      final newPlayer = Player(id: user.uid, name: playerName);
      final updatedPlayers = [...gameRoom.players, newPlayer];

      await _firestore.collection('rooms').doc(roomId).update({
        'players': updatedPlayers.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Erro ao entrar na sala: $e');
    }
  }

  static Stream<GameRoom?> watchRoom(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return GameRoom.fromJson(snapshot.data()!);
    });
  }

  static Future<void> startGame(String roomId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) throw Exception('Sala não encontrada');

      final gameRoom = GameRoom.fromJson(roomDoc.data()!);

      // Escolher primeira carta preta
      final shuffledBlackCards = List<GameCard>.from(gameRoom.blackCards)
        ..shuffle();
      final firstBlackCard = shuffledBlackCards.first;

      await _firestore.collection('rooms').doc(roomId).update({
        'phase': 'choosingBlackCard',
        'currentBlackCard': firstBlackCard.toJson(),
        'blackCards': shuffledBlackCards.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Erro ao iniciar jogo: $e');
    }
  }

  static Future<void> submitWhiteCard(
      String roomId, String playerId, GameCard whiteCard) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'submittedCards.$playerId': whiteCard.toJson(),
        'phase': 'judgeChoosing',
      });
    } catch (e) {
      throw Exception('Erro ao enviar carta: $e');
    }
  }

  static Future<void> chooseWinner(String roomId, String winnerId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) throw Exception('Sala não encontrada');

      final gameRoom = GameRoom.fromJson(roomDoc.data()!);
      final updatedPlayers = gameRoom.players.map((player) {
        if (player.id == winnerId) {
          return player.copyWith(points: player.points + 1);
        }
        return player;
      }).toList();

      // Verificar se alguém ganhou o jogo
      final winner = updatedPlayers.firstWhere(
        (p) => p.points >= gameRoom.maxPoints,
        orElse: () => Player(id: '', name: ''),
      );

      if (winner.id.isNotEmpty) {
        // Jogo terminou
        await _firestore.collection('rooms').doc(roomId).update({
          'players': updatedPlayers.map((p) => p.toJson()).toList(),
          'phase': 'gameComplete',
          'winnerId': winner.id,
        });
      } else {
        // Próxima rodada
        final nextJudgeIndex =
            (gameRoom.players.indexWhere((p) => p.isJudge) + 1) %
                gameRoom.players.length;
        final nextJudge = gameRoom.players[nextJudgeIndex];

        final shuffledBlackCards = List<GameCard>.from(gameRoom.blackCards)
          ..shuffle();
        final nextBlackCard = shuffledBlackCards.first;

        await _firestore.collection('rooms').doc(roomId).update({
          'players': updatedPlayers.map((p) => p.toJson()).toList(),
          'phase': 'choosingBlackCard',
          'currentBlackCard': nextBlackCard.toJson(),
          'currentJudgeId': nextJudge.id,
          'submittedCards': {},
        });
      }
    } catch (e) {
      throw Exception('Erro ao escolher vencedor: $e');
    }
  }

  // Helper methods
  static String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < 6; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  static List<GameCard> _getMockBlackCards() {
    return [
      GameCard(
          id: 'b1',
          text: '____ é a melhor coisa do mundo.',
          type: CardType.black),
      GameCard(
          id: 'b2', text: 'Não consigo viver sem ____.', type: CardType.black),
      GameCard(
          id: 'b3', text: 'Ontem eu vi ____ no mercado.', type: CardType.black),
      GameCard(
          id: 'b4',
          text: 'A razão pela qual eu acordei hoje foi ____.',
          type: CardType.black),
      GameCard(
          id: 'b5',
          text: '____ é a resposta para todos os problemas.',
          type: CardType.black),
    ];
  }

  static List<GameCard> _getMockWhiteCards() {
    return [
      GameCard(id: 'w1', text: 'Cachorros', type: CardType.white),
      GameCard(id: 'w2', text: 'Pizza', type: CardType.white),
      GameCard(id: 'w3', text: 'Meu ex', type: CardType.white),
      GameCard(id: 'w4', text: 'Café', type: CardType.white),
      GameCard(id: 'w5', text: 'TikTok', type: CardType.white),
      GameCard(id: 'w6', text: 'Inteligência Artificial', type: CardType.white),
      GameCard(id: 'w7', text: 'Netflix', type: CardType.white),
      GameCard(id: 'w8', text: 'Chocolate', type: CardType.white),
      GameCard(id: 'w9', text: 'Viagem', type: CardType.white),
      GameCard(id: 'w10', text: 'Música', type: CardType.white),
      GameCard(id: 'w11', text: 'Futebol', type: CardType.white),
      GameCard(id: 'w12', text: 'Tecnologia', type: CardType.white),
      GameCard(id: 'w13', text: 'Família', type: CardType.white),
      GameCard(id: 'w14', text: 'Dinheiro', type: CardType.white),
      GameCard(id: 'w15', text: 'Amor', type: CardType.white),
    ];
  }
}

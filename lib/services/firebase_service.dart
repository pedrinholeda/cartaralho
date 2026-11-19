import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../game/baralho.dart';
import '../game/regras.dart' as regras;

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
      );

      final gameRoom = GameRoom(
        roomId: roomId,
        players: [player],
        blackCards: cartasPretas(),
        whiteCards: cartasBrancas(),
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
    final user = _usuarioLogado();
    await _alterarSala(roomId, (sala) => regras.iniciarJogo(sala, user.uid));
  }

  static Future<void> submitWhiteCard(String roomId, String cardId) async {
    final user = _usuarioLogado();
    await _alterarSala(
      roomId,
      (sala) => regras.enviarCarta(sala, user.uid, cardId),
    );
  }

  static Future<void> chooseWinner(String roomId, String winnerId) async {
    final user = _usuarioLogado();
    await _alterarSala(
      roomId,
      (sala) => regras.escolherVencedor(sala, user.uid, winnerId),
    );
  }

  static User _usuarioLogado() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    return user;
  }

  /// Lê a sala, aplica [regra] e grava o resultado numa transação. Se outro
  /// jogador mudar a sala no meio, o Firestore repete a leitura e a regra, e
  /// nenhuma jogada se perde.
  static Future<void> _alterarSala(
    String roomId,
    GameRoom Function(GameRoom sala) regra,
  ) async {
    final ref = _firestore.collection('rooms').doc(roomId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw Exception('Sala não encontrada');
      tx.set(ref, regra(GameRoom.fromJson(doc.data()!)).toJson());
    });
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
}

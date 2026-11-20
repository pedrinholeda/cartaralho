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

      final player = Player(
        id: user.uid,
        name: playerName,
        isHost: true,
      );

      // Com 31^6 códigos possíveis a colisão é rara, mas uma sala viva nunca é
      // sobrescrita: a transação confere se o código está livre antes de gravar.
      for (var tentativa = 0; tentativa < 5; tentativa++) {
        final roomId = regras.gerarCodigoSala();
        final ref = _firestore.collection('rooms').doc(roomId);
        final criou = await _firestore.runTransaction((tx) async {
          if ((await tx.get(ref)).exists) return false;
          final gameRoom = GameRoom(
            roomId: roomId,
            players: [player],
            blackCards: cartasPretas(),
            whiteCards: cartasBrancas(),
            currentJudgeId: user.uid,
          );
          tx.set(ref, gameRoom.toJson());
          return true;
        });
        if (criou) return roomId;
      }
      throw Exception('Não foi possível gerar um código de sala livre');
    } catch (e) {
      throw Exception('Erro ao criar sala: $e');
    }
  }

  static Future<void> joinRoom(String roomId, String playerName) async {
    final user = _usuarioLogado();
    await _alterarSala(
      roomId,
      (sala) =>
          regras.entrarNaSala(sala, Player(id: user.uid, name: playerName)),
    );
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

  static Future<void> nextRound(String roomId) async {
    final user = _usuarioLogado();
    await _alterarSala(
      roomId,
      (sala) => regras.proximaRodada(sala, user.uid),
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
}

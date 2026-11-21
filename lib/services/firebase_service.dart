import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../game/baralho.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../game/bots.dart' as bots;
import '../game/regras.dart' as regras;
import 'dart:math';
import 'mesa_local.dart';

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

  /// Sai da sala. Da partida solo, só fecha a mesa; de uma sala online,
  /// faz logout (o próximo login é outro jogador).
  static Future<void> sair(String roomId) async {
    if (MesaLocal.eh(roomId)) {
      MesaLocal.fechar(roomId);
      return;
    }
    await signOut();
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  // Room Management
  static Future<String> createRoom(
    String playerName, {
    required Baralho baralho,
    int maxPoints = 5,
    int handSize = regras.tamanhoDaMao,
  }) async {
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
          final gameRoom = regras.novaSala(
            roomId: roomId,
            anfitriao: player,
            baralho: baralho,
            maxPoints: maxPoints,
            handSize: handSize,
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

  static Future<void> sortearOutraCarinha(String roomId) async {
    final user = _usuarioLogado();
    await _alterarSala(
      roomId,
      (sala) => regras.sortearOutraCarinha(sala, user.uid),
    );
  }

  static Future<void> reagir(String roomId, String reacao) async {
    final user = _usuarioLogado();
    await _alterarSala(roomId, (sala) => regras.reagir(sala, user.uid, reacao));
  }

  static Future<void> chamarZe(String roomId) async {
    final user = _usuarioLogado();
    await _alterarSala(roomId, (sala) => bots.chamarZe(sala, user.uid));
  }

  static Future<void> dispensarZe(String roomId) async {
    final user = _usuarioLogado();
    await _alterarSala(roomId, (sala) => bots.dispensarZe(sala, user.uid));
  }

  static final _sorteDosBots = Random();

  /// A próxima jogada de algum bot da sala online, feita pelo aparelho do
  /// anfitrião. Na transação, a sala é lida de novo: se já não é a vez de um
  /// bot (alguém jogou antes), nada muda.
  static Future<void> jogadaDosBots(String roomId) async {
    await _alterarSala(
      roomId,
      (sala) => bots.passoDosBots(sala, _sorteDosBots) ?? sala,
    );
  }

  static Stream<GameRoom?> watchRoom(String roomId) {
    if (MesaLocal.eh(roomId)) return MesaLocal.observar(roomId);
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

  static Future<void> submitWhiteCards(
    String roomId,
    List<String> cardIds, {
    Map<String, String> textos = const {},
  }) async {
    final user = _usuarioLogado();
    await _alterarSala(
      roomId,
      (sala) => regras.enviarCarta(sala, user.uid, cardIds, textos: textos),
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

  static Future<void> swapHand(String roomId) async {
    final user = _usuarioLogado();
    await _alterarSala(roomId, (sala) => regras.trocarMao(sala, user.uid));
  }

  static Future<void> playAgain(String roomId) async {
    final user = _usuarioLogado();
    await _alterarSala(roomId, (sala) => regras.jogarDeNovo(sala, user.uid));
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
    // Partida solo: a sala está neste aparelho, e a regra roda na hora.
    if (MesaLocal.eh(roomId)) return MesaLocal.alterar(roomId, regra);
    final ref = _firestore.collection('rooms').doc(roomId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw Exception('Sala não encontrada');
      tx.set(ref, regra(GameRoom.fromJson(doc.data()!)).toJson());
    });
  }
}

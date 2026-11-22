import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../game/baralho.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../game/bots.dart' as bots;
import '../game/regras.dart' as regras;
import 'dart:async';
import 'dart:math';
import 'erros.dart';
import 'mesa_local.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Authentication
  static Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('login anônimo');
        },
      );
      return userCredential.user;
    } catch (e) {
      registrar('login anônimo falhou: $e');
      rethrow;
    }
  }

  /// Sai da sala. Da partida solo, só fecha a mesa; de uma sala online, tira
  /// o jogador de verdade (`sairDaSala`) e, se não sobrar ninguém além de
  /// bots, apaga a sala. O login continua: voltar a uma sala é o mesmo
  /// jogador.
  static Future<void> sair(String roomId) async {
    if (MesaLocal.eh(roomId)) {
      MesaLocal.fechar(roomId);
      return;
    }
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _firestore.collection('rooms').doc(roomId);
    try {
      await _firestore.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (!doc.exists) return;
        final sala = GameRoom.fromJson(doc.data()!);
        if (!sala.players.any((p) => p.id == user.uid)) return;
        final depois = regras.sairDaSala(sala, user.uid);
        if (regras.temGenteNaSala(depois)) {
          tx.set(ref, depois.toJson());
        } else {
          tx.delete(ref);
        }
      });
    } catch (_) {
      // Sem rede, a saída não chega: a sala segue até alguém sair dela.
    }
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
      if (user == null) throw ErroDoJogo('Ainda conectando. Tente de novo.');

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
      throw ErroDoJogo('Não deu para gerar um código de sala. Tente de novo.');
    } catch (e) {
      registrar('criar sala falhou: $e');
      rethrow;
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

  /// Se quem está logado ainda faz parte da sala (para voltar a ela depois
  /// de um refresh). Qualquer falha conta como "não".
  static Future<bool> estouNaSala(String roomId) async {
    final user = _auth.currentUser;
    if (user == null || MesaLocal.eh(roomId)) return false;
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (!doc.exists) return false;
      return GameRoom.fromJson(doc.data()!)
          .players
          .any((p) => p.id == user.uid);
    } catch (_) {
      return false;
    }
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
    if (user == null) throw ErroDoJogo('Ainda conectando. Tente de novo.');
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
    // Na web, um erro lançado de dentro da transação chega embrulhado e a
    // mensagem se perde ("Dart exception thrown from converted Future"). Por
    // isso a recusa é guardada aqui e lançada depois que a transação termina.
    Object? recusa;
    await _firestore.runTransaction((tx) async {
      recusa = null;
      final doc = await tx.get(ref);
      if (!doc.exists) {
        recusa = ErroDoJogo('Essa sala não existe mais. Confira o código.');
        return;
      }
      try {
        tx.set(ref, regra(GameRoom.fromJson(doc.data()!)).toJson());
      } on regras.JogadaInvalida catch (e) {
        recusa = e;
      }
    });
    if (recusa != null) throw recusa!;
  }
}

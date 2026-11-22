import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_room.dart';

/// Quanto tempo uma sala parada fica no Firestore. Cada jogada empurra o prazo;
/// a política TTL do campo `expiraEm` (firestore.indexes.json) apaga a sala
/// quando ele passa. Ninguém joga 24 horas sem mexer.
const validadeDaSala = Duration(hours: 24);

/// O documento da sala como vai para o Firestore, com o prazo de validade
/// contado a partir de [agora].
Map<String, dynamic> salaComValidade(GameRoom sala, DateTime agora) => {
      ...sala.toJson(),
      'expiraEm': Timestamp.fromDate(agora.add(validadeDaSala)),
    };

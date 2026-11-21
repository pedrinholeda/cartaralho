import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_room.dart';

/// Os efeitos sonoros do jogo, em assets/sons/ (gerados por
/// tool/gerar_sons.mjs, sem arquivo de terceiros).
enum Som {
  /// Cartas novas na mão, no começo de cada rodada.
  distribuir,

  /// O jogador enviou as cartas da rodada.
  enviar,

  /// As respostas viraram para o juiz escolher.
  virar,

  /// Saiu o resultado da rodada.
  rodada,

  /// Alguém venceu o jogo.
  vitoria,
}

/// Que som a mudança da sala de [antes] para [depois] merece, ou nenhum.
/// Função pura: quem toca é [Sons]. O som de enviar não sai daqui: ele toca
/// na hora do toque, no aparelho de quem enviou.
Som? somDaMudanca(GameRoom? antes, GameRoom depois) {
  if (antes == null) return null;
  final novaRodada = antes.currentBlackCard?.id != depois.currentBlackCard?.id;
  if (depois.phase == antes.phase && !novaRodada) return null;
  return switch (depois.phase) {
    GamePhase.playersSubmitting => Som.distribuir,
    GamePhase.judgeChoosing => Som.virar,
    GamePhase.roundResult => Som.rodada,
    GamePhase.gameComplete => Som.vitoria,
    GamePhase.waitingForPlayers => null,
  };
}

/// Toca os sons, se o jogador não silenciou. Na web o navegador só deixa
/// tocar depois do primeiro toque na página; como todo som vem depois de
/// "Criar Sala" ou "Entrar na Sala", isso nunca atrapalha.
class Sons {
  Sons(this._mudo);

  final bool Function() _mudo;
  final _tocador = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  Future<void> tocar(Som som) async {
    if (_mudo()) return;
    try {
      await _tocador.stop();
      await _tocador.play(AssetSource('sons/${som.name}.wav'));
    } catch (_) {
      // Som é enfeite: se o navegador recusar, o jogo segue em silêncio.
    }
  }
}

const _chaveMudo = 'mudo';

/// Se o som está desligado. Começa ligado e lembra a escolha entre partidas.
class MudoNotifier extends StateNotifier<bool> {
  MudoNotifier() : super(false) {
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_chaveMudo) ?? false;
    } catch (_) {
      // Sem armazenamento (janela anônima restrita): fica com o som ligado.
    }
  }

  Future<void> alternar() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chaveMudo, state);
    } catch (_) {}
  }
}

final mudoProvider =
    StateNotifierProvider<MudoNotifier, bool>((ref) => MudoNotifier());

final sonsProvider =
    Provider<Sons>((ref) => Sons(() => ref.read(mudoProvider)));

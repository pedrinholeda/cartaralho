import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_room.dart';
import 'icones.dart';
import 'sons.dart';
import 'tema.dart';

/// As músicas de fundo, em assets/musicas/ (geradas por
/// tool/gerar_musicas.mjs, sem arquivo de terceiros). Todas em loop.
enum Faixa {
  /// Lo-fi fofinho, enquanto todo mundo escolhe.
  escolha,

  /// Menor, com tique-taque, enquanto o juiz decide.
  juiz,

  /// A escolha lenta e desafinada, das 3h às 5h.
  madrugada,
}

/// Que faixa toca em cada fase, ou nenhuma. No fim de jogo a música para e
/// fica só a fanfarra da vitória.
Faixa? faixaDaFase(GamePhase? fase, {bool madrugada = false}) {
  if (fase == null || fase == GamePhase.gameComplete) return null;
  if (madrugada) return Faixa.madrugada;
  return fase == GamePhase.judgeChoosing ? Faixa.juiz : Faixa.escolha;
}

/// A música ligada ou não, e o volume dela (de 0 a 1). Começa ligada e baixa.
@immutable
class ConfigDaMusica {
  final bool ligada;
  final double volume;

  const ConfigDaMusica({this.ligada = true, this.volume = .35});

  ConfigDaMusica copyWith({bool? ligada, double? volume}) => ConfigDaMusica(
        ligada: ligada ?? this.ligada,
        volume: volume ?? this.volume,
      );
}

const _chaveLigada = 'musicaLigada';
const _chaveVolume = 'volumeMusica';

/// Guarda a escolha da música entre partidas (localStorage na web).
class MusicaNotifier extends StateNotifier<ConfigDaMusica> {
  MusicaNotifier() : super(const ConfigDaMusica()) {
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = ConfigDaMusica(
        ligada: prefs.getBool(_chaveLigada) ?? true,
        volume: (prefs.getDouble(_chaveVolume) ?? .35).clamp(0, 1),
      );
    } catch (_) {}
  }

  Future<void> ligar(bool ligada) async {
    state = state.copyWith(ligada: ligada);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chaveLigada, ligada);
    } catch (_) {}
  }

  Future<void> mudarVolume(double volume) async {
    state = state.copyWith(volume: volume.clamp(0, 1));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_chaveVolume, state.volume);
    } catch (_) {}
  }
}

final configDaMusicaProvider =
    StateNotifierProvider<MusicaNotifier, ConfigDaMusica>(
  (ref) => MusicaNotifier(),
);

/// Toca a faixa da vez em loop, no volume escolhido. Trocar de faixa para a
/// anterior e começa a nova; a mesma faixa continua de onde estava.
class Musica {
  Musica(this._config);

  final ConfigDaMusica Function() _config;
  final _tocador = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  Faixa? _atual;

  Future<void> tocar(Faixa? faixa) async {
    final config = _config();
    final alvo = config.ligada ? faixa : null;
    try {
      if (alvo == null) {
        _atual = null;
        await _tocador.stop();
        return;
      }
      await _tocador.setVolume(config.volume);
      if (alvo == _atual) return;
      _atual = alvo;
      await _tocador.stop();
      await _tocador.play(AssetSource('musicas/${alvo.name}.wav'),
          volume: config.volume);
    } catch (_) {
      // Música é enfeite: se o navegador recusar, o jogo segue em silêncio.
    }
  }

  /// Aplica volume e liga/desliga sem mudar de faixa.
  Future<void> aplicar(Faixa? faixaDaVez) => tocar(faixaDaVez);

  Future<void> parar() => tocar(null);
}

final musicaProvider = Provider<Musica>(
  (ref) => Musica(() => ref.read(configDaMusicaProvider)),
);

/// O botão de som: abre o painel com os efeitos, a música e o volume dela.
class BotaoDeSom extends ConsumerWidget {
  const BotaoDeSom({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mudo = ref.watch(mudoProvider);
    final musica = ref.watch(configDaMusicaProvider);
    final tudoDesligado = mudo && !musica.ligada;
    return IconButton(
      tooltip: 'Som',
      icon: IconeFofo(tudoDesligado ? Desenho.mudo : Desenho.som),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Cores.de(context).superficie,
        builder: (_) => const PainelDeSom(),
      ),
    );
  }
}

/// Efeitos ligados ou não, música ligada ou não, e o volume da música.
class PainelDeSom extends ConsumerWidget {
  const PainelDeSom({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    final mudo = ref.watch(mudoProvider);
    final musica = ref.watch(configDaMusicaProvider);
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(Medidas.margem, 16, Medidas.margem, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Som', style: textos.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Efeitos'),
              subtitle: Text(
                'Cartas, rodada, vitória',
                style: textos.bodySmall?.copyWith(color: cores.tintaSuave),
              ),
              value: !mudo,
              onChanged: (_) => ref.read(mudoProvider.notifier).alternar(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Música de fundo'),
              subtitle: Text(
                'Toca baixinho durante a partida',
                style: textos.bodySmall?.copyWith(color: cores.tintaSuave),
              ),
              value: musica.ligada,
              onChanged: (v) =>
                  ref.read(configDaMusicaProvider.notifier).ligar(v),
            ),
            Row(
              children: [
                Text('Volume da música', style: textos.bodyMedium),
                Expanded(
                  child: Slider(
                    value: musica.volume,
                    label: '${(musica.volume * 100).round()}%',
                    divisions: 10,
                    onChanged: musica.ligada
                        ? (v) => ref
                            .read(configDaMusicaProvider.notifier)
                            .mudarVolume(v)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

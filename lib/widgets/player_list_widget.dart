import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_room.dart';
import '../models/player.dart';
import '../ui/animacoes.dart';
import '../ui/jogadores.dart';
import '../ui/olhar.dart';
import '../ui/tema.dart';
import 'reacoes_widget.dart';

/// Placar: um avatar por jogador, com o nome e os pontos embaixo. O juiz da
/// rodada tem o anel amarelo e o martelo.
/// Quanto o juiz pode pensar antes de os outros ficarem impacientes.
const pacienciaComOJuiz = Duration(seconds: 20);

/// O humor de cada carinha no placar, pela fase da partida.
Humor humorNoPlacar(GameRoom? sala, String jogadorId,
    {bool juizDemorando = false}) {
  if (sala == null) return Humor.normal;
  final juiz = sala.currentJudgeId == jogadorId;
  switch (sala.phase) {
    case GamePhase.playersSubmitting:
      if (juiz) return Humor.julgando;
      return sala.submittedCards.containsKey(jogadorId)
          ? Humor.enviou
          : Humor.pensando;
    case GamePhase.judgeChoosing:
      if (juiz) return Humor.julgando;
      return juizDemorando ? Humor.impaciente : Humor.enviou;
    case GamePhase.roundResult:
      return sala.lastRoundWinnerId == jogadorId
          ? Humor.comemorando
          : Humor.normal;
    case GamePhase.gameComplete:
      return sala.winnerId == jogadorId ? Humor.comemorando : Humor.normal;
    case GamePhase.waitingForPlayers:
      return Humor.normal;
  }
}

/// Quem lidera a partida sozinho, com ao menos um ponto; empate não tem coroa.
String? liderDaSala(List<Player> jogadores) {
  if (jogadores.isEmpty) return null;
  final maior = jogadores.map((p) => p.points).reduce((a, b) => a > b ? a : b);
  if (maior == 0) return null;
  final lideres = jogadores.where((p) => p.points == maior).toList();
  return lideres.length == 1 ? lideres.single.id : null;
}

class PlayerListWidget extends StatefulWidget {
  final List<Player> players;
  final String? judgeId;

  /// A sala, para cada carinha reagir à partida. Sem ela, todas ficam normais.
  final GameRoom? sala;

  /// Quem está no aparelho: tocar na própria carinha manda uma reação.
  final String? meuId;

  /// No computador: uma linha por jogador, com o nome inteiro.
  final bool vertical;

  const PlayerListWidget({
    super.key,
    required this.players,
    required this.judgeId,
    this.vertical = false,
    this.sala,
    this.meuId,
  });

  @override
  State<PlayerListWidget> createState() => _PlayerListWidgetState();
}

class _PlayerListWidgetState extends State<PlayerListWidget> {
  Timer? _paciencia;
  String? _chaveDaEspera;
  bool _juizDemorando = false;

  List<Player> get players => widget.players;
  String? get judgeId => widget.judgeId;
  bool get vertical => widget.vertical;

  /// Conta o tempo do juiz a cada vez que a mesa vai para ele.
  void _vigiarJuiz() {
    final sala = widget.sala;
    final chave = sala != null && sala.phase == GamePhase.judgeChoosing
        ? '${sala.roomId}-${sala.currentBlackCard?.id}'
        : null;
    if (chave == _chaveDaEspera) return;
    _chaveDaEspera = chave;
    _paciencia?.cancel();
    _juizDemorando = false;
    if (chave != null) {
      _paciencia = Timer(pacienciaComOJuiz, () {
        if (mounted) setState(() => _juizDemorando = true);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _vigiarJuiz();
  }

  @override
  void didUpdateWidget(PlayerListWidget antes) {
    super.didUpdateWidget(antes);
    _vigiarJuiz();
  }

  @override
  void dispose() {
    _paciencia?.cancel();
    super.dispose();
  }

  Humor _humor(String id) =>
      humorNoPlacar(widget.sala, id, juizDemorando: _juizDemorando);

  Widget _emLista(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    return GrupoDeCarinhas(
      quantidade: players.length,
      eixo: Axis.vertical,
      passo: 54,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(Medidas.margem, 8, Medidas.margem, 4),
        child: Column(
          children: [
            for (var i = 0; i < players.length; i++)
              Entrada(
                key: ValueKey(players[i].id),
                deslocamento: 12,
                child: Semantics(
                  label: '${players[i].name}, '
                      '${players[i].points == 1 ? '1 ponto' : '${players[i].points} pontos'}'
                      '${players[i].id == judgeId ? ', juiz da rodada' : ''}',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        ComReacao(
                          jogador: players[i],
                          roomId: widget.sala?.roomId,
                          meu: players[i].id == widget.meuId,
                          tamanho: 38,
                          child: AvatarDeJogador(
                            nome: players[i].name,
                            indice: i,
                            juiz: players[i].id == judgeId,
                            semente: players[i].id,
                            variacao: players[i].avatar,
                            tamanho: 38,
                            humor: _humor(players[i].id),
                            lider: players[i].id == liderDaSala(players),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            players[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textos.titleSmall?.copyWith(
                              color: cores.tintaNaMesa,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${players[i].points}',
                          style: GoogleFonts.figtree(
                            color: cores.tintaNaMesa,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (vertical) return _emLista(context);
    final cores = Cores.de(context);
    return GrupoDeCarinhas(
      quantidade: players.length,
      eixo: Axis.horizontal,
      passo: 74,
      child: SizedBox(
        height: 102,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          // A reação e a coroa passam da borda de cima sem ser cortadas.
          clipBehavior: Clip.none,
          // Em cima, espaço para o chapéu e o topete das carinhas.
          padding:
              const EdgeInsets.fromLTRB(Medidas.margem, 10, Medidas.margem, 0),
          itemCount: players.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final player = players[index];
            final juiz = player.id == judgeId;
            final pontos =
                player.points == 1 ? '1 ponto' : '${player.points} pontos';

            // Quem entra na sala aparece com uma animação curta.
            return Entrada(
              key: ValueKey(player.id),
              deslocamento: 12,
              child: Semantics(
                label: '${player.name}, $pontos'
                    '${juiz ? ', juiz da rodada' : ''}'
                    '${player.id == widget.meuId ? '. Toque para mandar uma reação' : ''}',
                excludeSemantics: player.id != widget.meuId,
                child: SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      ComReacao(
                        jogador: player,
                        roomId: widget.sala?.roomId,
                        meu: player.id == widget.meuId,
                        tamanho: 44,
                        child: AvatarDeJogador(
                          nome: player.name,
                          indice: index,
                          juiz: juiz,
                          semente: player.id,
                          variacao: player.avatar,
                          humor: _humor(player.id),
                          lider: player.id == liderDaSala(players),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.figtree(
                          color: cores.tintaSuave,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${player.points}',
                        style: GoogleFonts.figtree(
                          color: cores.tintaNaMesa,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

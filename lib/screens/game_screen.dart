import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/convite.dart';
import '../game/regras.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../ui/animacoes.dart';
import '../ui/cartas.dart';
import '../ui/jogadores.dart';
import '../ui/sons.dart';
import '../ui/tema.dart';
import 'tutorial_screen.dart';
import '../widgets/black_card_widget.dart';
import '../widgets/judge_widget.dart';
import '../widgets/player_list_widget.dart';
import '../widgets/round_result_widget.dart';
import '../widgets/table_widget.dart';
import '../widgets/white_cards_widget.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(roomIdProvider);
    final gameRoom = ref.watch(gameRoomProvider(roomId!));
    final currentPlayer = ref.watch(currentPlayerProvider);
    final isHost = ref.watch(isHostProvider);
    final isJudge = ref.watch(isJudgeProvider);
    final gamePhase = ref.watch(gamePhaseProvider);

    // Cada mudança de fase que todo mundo vê tem um som (lib/ui/sons.dart).
    ref.listen(gameRoomProvider(roomId), (antes, depois) {
      final sala = depois.valueOrNull;
      if (sala == null) return;
      final som = somDaMudanca(antes?.valueOrNull, sala);
      if (som != null) ref.read(sonsProvider).tocar(som);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sala $roomId',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: 'Como jogar',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => abrirTutorial(context),
          ),
          const BotaoDeSom(),
          IconButton(
            tooltip: 'Sair da sala',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(roomIdProvider.notifier).state = null;
              FirebaseService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: gameRoom.when(
          data: (room) {
            if (room == null) {
              return const _Aviso('Essa sala não existe mais.');
            }
            final aviso = _avisoDaVez(room, currentPlayer, isJudge);
            final topo = [
              const SizedBox(height: 4),
              if (room.phase != GamePhase.waitingForPlayers)
                PlayerListWidget(
                  players: room.players,
                  judgeId: room.currentJudgeId,
                ),
              if (aviso != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.margem,
                    4,
                    Medidas.margem,
                    8,
                  ),
                  child: Align(alignment: Alignment.centerLeft, child: aviso),
                ),
              if (room.currentBlackCard != null &&
                  room.phase != GamePhase.waitingForPlayers)
                BlackCardWidget(
                  card: room.currentBlackCard!,
                  respostas:
                      _respostasNaCarta(ref, room, currentPlayer, isJudge),
                ),
            ];
            // Cada fase (e cada rodada) entra com um fade curto, para o
            // jogador perceber que a tela mudou.
            final conteudo = AnimatedSwitcher(
              duration: movimentoReduzido(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              // Só a tela nova aparece: sobrepor a antiga embaralha os textos.
              layoutBuilder: (atual, anteriores) =>
                  atual ?? const SizedBox.shrink(),
              child: KeyedSubtree(
                key: ValueKey(
                  '${room.phase.name}-${room.currentBlackCard?.id}',
                ),
                child: _conteudo(
                  context,
                  ref,
                  room,
                  currentPlayer,
                  isHost,
                  isJudge,
                  gamePhase,
                ),
              ),
            );

            return LayoutBuilder(
              builder: (context, espaco) {
                // Tela larga: carta preta e placar à esquerda, a jogada à
                // direita. Celular: tudo numa coluna só.
                if (espaco.maxWidth >= Medidas.larguraDuasColunas) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 400,
                          child: Column(children: topo),
                        ),
                        Expanded(child: conteudo),
                      ],
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: Medidas.larguraMaxima),
                  child: Column(
                    children: [...topo, Expanded(child: conteudo)],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _Aviso('Não deu para abrir a sala: $error'),
        ),
      ),
    );
  }

  /// O que vai nas lacunas da carta preta: o que o jogador está escolhendo,
  /// ou o que ele já enviou nesta rodada.
  List<String> _respostasNaCarta(
    WidgetRef ref,
    GameRoom room,
    Player? jogador,
    bool isJudge,
  ) {
    if (room.phase != GamePhase.playersSubmitting ||
        isJudge ||
        jogador == null) {
      return const [];
    }
    final enviadas = room.submittedCards[jogador.id];
    final List<GameCard> cartas =
        enviadas ?? ref.watch(escolhidasProvider(chaveDaRodada(room)));
    return [for (final c in cartas) c.text];
  }

  /// O aviso curto de quem é a vez, embaixo do placar.
  Widget? _avisoDaVez(GameRoom room, Player? jogador, bool isJudge) {
    final juiz = room.players
        .where((p) => p.id == room.currentJudgeId)
        .firstOrNull
        ?.name;
    switch (room.phase) {
      case GamePhase.playersSubmitting:
        if (isJudge) {
          return const AvisoDaVez(
            'Você é o juiz desta rodada',
            icone: Icons.gavel_rounded,
            destaque: true,
          );
        }
        return AvisoDaVez('Juiz da rodada: $juiz', icone: Icons.gavel_rounded);
      case GamePhase.judgeChoosing:
        if (isJudge) {
          return const AvisoDaVez(
            'Sua vez de julgar',
            icone: Icons.gavel_rounded,
            destaque: true,
          );
        }
        return AvisoDaVez('Juiz da rodada: $juiz', icone: Icons.gavel_rounded);
      case GamePhase.waitingForPlayers:
      case GamePhase.roundResult:
      case GamePhase.gameComplete:
        return null;
    }
  }

  Widget _conteudo(
    BuildContext context,
    WidgetRef ref,
    GameRoom room,
    Player? currentPlayer,
    bool isHost,
    bool isJudge,
    GamePhase? gamePhase,
  ) {
    switch (gamePhase) {
      case null:
        return const Center(child: CircularProgressIndicator());
      case GamePhase.waitingForPlayers:
        return _SalaDeEspera(
          room: room,
          isHost: isHost,
          meuId: currentPlayer?.id,
        );
      case GamePhase.playersSubmitting:
        if (currentPlayer == null) {
          return const _Aviso('Você não está nesta partida.');
        }
        if (isJudge) {
          final faltam = room.players.length - 1 - room.submittedCards.length;
          return _Aviso(
            'Esperando $faltam '
            '${faltam == 1 ? 'jogador enviar a carta' : 'jogadores enviarem as cartas'}.',
          );
        }
        return WhiteCardsWidget(room: room, currentPlayer: currentPlayer);
      case GamePhase.judgeChoosing:
        return isJudge ? JudgeWidget(room: room) : TableWidget(room: room);
      case GamePhase.roundResult:
        return RoundResultWidget(room: room, isJudge: isJudge);
      case GamePhase.gameComplete:
        return _FimDeJogo(room: room, isHost: isHost);
    }
  }
}

/// Texto centralizado sobre a mesa, para esperas e avisos.
class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso(this.texto);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Medidas.margem * 1.5),
        child: Text(
          texto,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SalaDeEspera extends StatelessWidget {
  final GameRoom room;
  final bool isHost;

  final String? meuId;

  const _SalaDeEspera({
    required this.room,
    required this.isHost,
    required this.meuId,
  });

  Future<void> _sortearCarinha(BuildContext context) async {
    try {
      await FirebaseService.sortearOutraCarinha(room.roomId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não deu para trocar a carinha: $e')),
        );
      }
    }
  }

  Future<void> _copiar(BuildContext context, String texto, String aviso) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(aviso)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    final faltam = minimoDeJogadores - room.players.length;

    return Padding(
      padding: const EdgeInsets.all(Medidas.margem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Aguardando jogadores...', style: textos.headlineSmall),
          const SizedBox(height: 4),
          Text(
            faltam > 0
                ? 'São precisos ao menos $minimoDeJogadores para começar. '
                    'Passe o código da sala: ${room.roomId}'
                : 'Jogadores na sala: ${room.players.length}. '
                    'Já dá para começar.',
            style: textos.bodyLarge?.copyWith(color: cores.tintaSuave),
          ),
          const SizedBox(height: 16),
          // O código e o convite, num painel só.
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cores.superficie,
              borderRadius: BorderRadius.circular(Medidas.raioPainel),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código da sala',
                  style: textos.bodyMedium?.copyWith(color: cores.tintaSuave),
                ),
                SelectableText(
                  room.roomId,
                  style: textos.displaySmall?.copyWith(letterSpacing: 6),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copiar(
                          context,
                          textoDoConvite(Uri.base, room.roomId),
                          'Convite copiado. Cole no grupo da galera.',
                        ),
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Copiar convite'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Copiar código',
                      style: IconButton.styleFrom(
                        backgroundColor: cores.mesa,
                        foregroundColor: cores.tintaNaMesa,
                        minimumSize: const Size(56, 56),
                      ),
                      onPressed: () =>
                          _copiar(context, room.roomId, 'Código copiado.'),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Jogadores na sala: ${room.players.length}',
            style: textos.titleMedium,
          ),
          // Espaço para o chapéu e o topete que saem da cabeça.
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 26,
            children: [
              for (var i = 0; i < room.players.length; i++)
                _JogadorNaEspera(
                  jogador: room.players[i],
                  indice: i,
                  eu: room.players[i].id == meuId,
                  aoSortear: () => _sortearCarinha(context),
                ),
              // Os lugares que ainda faltam para dar o mínimo.
              for (var i = 0; i < faltam; i++)
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cores.superficie, width: 2),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 20,
                    color: cores.tintaSuave,
                  ),
                ),
            ],
          ),
          if (meuId != null && room.players.any((p) => p.id == meuId)) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _sortearCarinha(context),
                icon: const Icon(Icons.casino_rounded, size: 20),
                label: const Text('Sortear outra carinha'),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Até ${room.maxPoints} pontos, ${room.handSize} cartas na mão',
            style: textos.bodyMedium?.copyWith(color: cores.tintaSuave),
          ),
          const Spacer(),
          if (isHost)
            ElevatedButton(
              onPressed: faltam > 0
                  ? null
                  : () async {
                      try {
                        await FirebaseService.startGame(room.roomId);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Não deu para iniciar: $e')),
                          );
                        }
                      }
                    },
              child: Text(
                faltam > 0
                    ? 'Faltam $faltam para iniciar jogo'
                    : 'Iniciar jogo',
              ),
            )
          else
            Text(
              'O anfitrião inicia o jogo quando todo mundo entrar.',
              style: textos.bodyLarge?.copyWith(color: cores.tintaSuave),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _FimDeJogo extends ConsumerWidget {
  final GameRoom room;
  final bool isHost;

  const _FimDeJogo({required this.room, required this.isHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final winner = room.players.firstWhere(
      (p) => p.id == room.winnerId,
      orElse: () => room.players.first,
    );
    final cartaFinal = room.submittedCards[room.lastRoundWinnerId];
    final preta = room.currentBlackCard;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(Medidas.margem),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Fim de jogo!', style: textos.titleLarge),
              Text(
                'Vencedor: ${winner.name}',
                style: textos.displaySmall,
              ),
              Text('Pontos: ${winner.points}', style: textos.bodyLarge),
              if (cartaFinal != null && preta != null) ...[
                const SizedBox(height: 16),
                CartaBranca(
                  larga: true,
                  vencedora: true,
                  texto: '"${fraseCompleta(preta, cartaFinal)}"',
                  autor: winner.name,
                ),
              ],
              const Spacer(flex: 2),
              if (isHost) ...[
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseService.playAgain(room.roomId);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Não deu para recomeçar: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Jogar de novo'),
                ),
              ] else
                Text(
                  'O anfitrião pode começar outra partida com o mesmo grupo.',
                  style: textos.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(roomIdProvider.notifier).state = null,
                child: const Text('Voltar ao menu'),
              ),
            ],
          ),
        ),
        const Positioned.fill(child: Confete(quantidade: 140)),
      ],
    );
  }
}

/// Um jogador na sala de espera: a carinha e o nome. A própria carinha se
/// troca com um toque.
class _JogadorNaEspera extends StatelessWidget {
  final Player jogador;
  final int indice;
  final bool eu;
  final VoidCallback aoSortear;

  const _JogadorNaEspera({
    required this.jogador,
    required this.indice,
    required this.eu,
    required this.aoSortear,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final avatar = AvatarDeJogador(
      nome: jogador.name,
      indice: indice,
      semente: jogador.id,
      variacao: jogador.avatar,
      tamanho: 56,
    );
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          if (eu)
            Tooltip(
              message: 'Sortear outra carinha',
              child: InkResponse(
                onTap: aoSortear,
                radius: 30,
                child: avatar,
              ),
            )
          else
            avatar,
          const SizedBox(height: 4),
          Text(
            eu ? 'Você' : jogador.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cores.tintaSuave,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

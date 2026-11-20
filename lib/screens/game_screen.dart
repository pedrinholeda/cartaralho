import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/regras.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../ui/animacoes.dart';
import '../ui/cartas.dart';
import '../ui/sons.dart';
import '../ui/tema.dart';
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Medidas.larguraMaxima),
          child: gameRoom.when(
            data: (room) {
              if (room == null) {
                return const _Aviso('Essa sala não existe mais.');
              }
              return Column(
                children: [
                  const SizedBox(height: 4),
                  PlayerListWidget(
                    players: room.players,
                    judgeId: room.currentJudgeId,
                  ),
                  if (room.currentBlackCard != null &&
                      room.phase != GamePhase.waitingForPlayers)
                    BlackCardWidget(card: room.currentBlackCard!),
                  Expanded(
                    // Cada fase (e cada rodada) entra com um fade curto, para o
                    // jogador perceber que a tela mudou.
                    child: AnimatedSwitcher(
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
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                _Aviso('Não deu para abrir a sala: $error'),
          ),
        ),
      ),
    );
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
        return _SalaDeEspera(room: room, isHost: isHost);
      case GamePhase.playersSubmitting:
        if (currentPlayer == null) {
          return const _Aviso('Você não está nesta partida.');
        }
        if (isJudge) {
          final faltam = room.players.length - 1 - room.submittedCards.length;
          return _Aviso(
            'Você é o juiz desta rodada! Esperando $faltam '
            '${faltam == 1 ? 'jogador' : 'jogadores'} enviar a carta.',
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

  const _SalaDeEspera({required this.room, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final faltam = minimoDeJogadores - room.players.length;

    return Padding(
      padding: const EdgeInsets.all(Medidas.margem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text('Aguardando jogadores...', style: textos.headlineSmall),
          const SizedBox(height: 4),
          Text('Código da sala', style: textos.bodyLarge),
          SelectableText(
            room.roomId,
            style: textos.displaySmall?.copyWith(
              fontSize: 64,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Jogadores na sala: ${room.players.length}',
            style: textos.bodyLarge,
          ),
          Text(
            'Até ${room.maxPoints} pontos, ${room.handSize} cartas na mão',
            style: textos.bodyLarge,
          ),
          if (faltam > 0) ...[
            const SizedBox(height: 12),
            Text(
              'São precisos ao menos $minimoDeJogadores para começar. '
              'Passe o código da sala: ${room.roomId}',
              style: textos.bodyLarge,
            ),
          ],
          const Spacer(flex: 2),
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
              child: const Text('Iniciar Jogo'),
            )
          else
            Text(
              'O anfitrião inicia o jogo quando todo mundo entrar.',
              style: textos.bodyLarge,
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
              Text('Jogo Finalizado!', style: textos.titleLarge),
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
                child: const Text('Voltar ao Menu'),
              ),
            ],
          ),
        ),
        const Positioned.fill(child: Confete(quantidade: 140)),
      ],
    );
  }
}

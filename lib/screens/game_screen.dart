import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/game_room.dart';
import '../services/firebase_service.dart';
import '../widgets/player_list_widget.dart';
import '../widgets/black_card_widget.dart';
import '../widgets/white_cards_widget.dart';
import '../widgets/judge_widget.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Sala: $roomId'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              ref.read(roomIdProvider.notifier).state = null;
              FirebaseService.signOut();
            },
          ),
        ],
      ),
      body: gameRoom.when(
        data: (room) {
          if (room == null) {
            return const Center(
              child: Text('Sala não encontrada'),
            );
          }

          return Column(
            children: [
              // Lista de jogadores
              PlayerListWidget(players: room.players),

              // Carta preta atual
              if (room.currentBlackCard != null)
                BlackCardWidget(card: room.currentBlackCard!),

              // Conteúdo principal baseado na fase do jogo
              Expanded(
                child: _buildGameContent(
                  context,
                  ref,
                  room,
                  currentPlayer,
                  isHost,
                  isJudge,
                  gamePhase,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro: $error'),
        ),
      ),
    );
  }

  Widget _buildGameContent(
    BuildContext context,
    WidgetRef ref,
    GameRoom room,
    currentPlayer,
    bool isHost,
    bool isJudge,
    GamePhase? gamePhase,
  ) {
    switch (gamePhase) {
      case GamePhase.waitingForPlayers:
        return _buildWaitingForPlayers(context, ref, room, isHost);

      case GamePhase.choosingBlackCard:
        return _buildChoosingBlackCard(context, ref, room, isJudge);

      case GamePhase.playersSubmitting:
        return _buildPlayersSubmitting(context, ref, room, currentPlayer);

      case GamePhase.judgeChoosing:
        return _buildJudgeChoosing(context, ref, room, isJudge);

      case GamePhase.roundComplete:
        return _buildRoundComplete(context, ref, room);

      case GamePhase.gameComplete:
        return _buildGameComplete(context, ref, room);

      default:
        return const Center(child: Text('Fase desconhecida'));
    }
  }

  Widget _buildWaitingForPlayers(
      BuildContext context, WidgetRef ref, GameRoom room, bool isHost) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people,
            size: 80,
            color: Color(0xFF6A1B9A),
          ),
          const SizedBox(height: 24),
          Text(
            'Aguardando jogadores...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Jogadores na sala: ${room.players.length}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          if (isHost)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseService.startGame(room.roomId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Iniciar Jogo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChoosingBlackCard(
      BuildContext context, WidgetRef ref, GameRoom room, bool isJudge) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isJudge)
            const Text(
              'Você é o juiz! Aguarde os outros jogadores enviarem suas cartas.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            )
          else
            const Text(
              'Aguarde o juiz escolher uma carta preta...',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildPlayersSubmitting(
      BuildContext context, WidgetRef ref, GameRoom room, currentPlayer) {
    if (currentPlayer == null) {
      return const Center(child: Text('Erro: Jogador não encontrado'));
    }

    return WhiteCardsWidget(
      room: room,
      currentPlayer: currentPlayer,
    );
  }

  Widget _buildJudgeChoosing(
      BuildContext context, WidgetRef ref, GameRoom room, bool isJudge) {
    if (isJudge) {
      return JudgeWidget(room: room);
    } else {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'O juiz está escolhendo a carta vencedora...',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildRoundComplete(
      BuildContext context, WidgetRef ref, GameRoom room) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            'Rodada finalizada!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Próxima rodada em breve...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildGameComplete(
      BuildContext context, WidgetRef ref, GameRoom room) {
    final winner = room.players.firstWhere(
      (p) => p.id == room.winnerId,
      orElse: () => room.players.first,
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 100,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            'Jogo Finalizado!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Vencedor: ${winner.name}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF6A1B9A),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pontos: ${winner.points}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(roomIdProvider.notifier).state = null;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Voltar ao Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/convite.dart';
import '../game/regras.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../services/erros.dart';
import '../services/firebase_service.dart';
import '../services/mesa_local.dart';
import '../ui/animacoes.dart';
import '../ui/assombro.dart';
import '../ui/cartas.dart';
import '../ui/icones.dart';
import '../ui/jogadores.dart';
import '../ui/olhar.dart';
import '../ui/musica.dart';
import '../ui/sons.dart';
import '../ui/tema.dart';
import 'tutorial_screen.dart';
import '../game/bots.dart';
import '../widgets/black_card_widget.dart';
import '../widgets/coluna_que_rola.dart';
import '../widgets/maestro_dos_bots.dart';
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
    // Saindo da sala: a capa assume no próximo quadro.
    if (roomId == null) return const SizedBox.shrink();
    final gameRoom = ref.watch(gameRoomProvider(roomId));
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

    // A música de fundo acompanha a fase (e a madrugada), e obedece ao painel
    // de som na hora. A sala sempre vai de "carregando" para "com dados" ao
    // abrir, e essa primeira mudança já põe a música.
    Faixa? faixaDaVez() => faixaDaFase(
          ref.read(gameRoomProvider(roomId)).valueOrNull?.phase,
          madrugada: ehMadrugada(agora()),
        );
    ref.listen(gameRoomProvider(roomId), (_, __) {
      ref.read(musicaProvider).tocar(faixaDaVez());
    });
    ref.listen(configDaMusicaProvider, (_, __) {
      ref.read(musicaProvider).aplicar(faixaDaVez());
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          MesaLocal.eh(roomId) ? 'Jogo solo' : 'Sala $roomId',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: 'Como jogar',
            icon: const IconeFofo(Desenho.ajuda, tamanho: 26),
            onPressed: () => abrirTutorial(context),
          ),
          const BotaoDeSom(),
          IconButton(
            tooltip: 'Sair da sala',
            icon: const IconeFofo(Desenho.sair, tamanho: 26),
            onPressed: () {
              ref.read(roomIdProvider.notifier).state = null;
              FirebaseService.sair(roomId);
            },
          ),
        ],
      ),
      body: MaestroDosBots(
        roomId: roomId,
        anfitriao: isHost && !MesaLocal.eh(roomId),
        child: Center(
          child: gameRoom.when(
            data: (room) {
              if (room == null) {
                return const _Aviso('Essa sala não existe mais.');
              }
              final aviso = _avisoDaVez(room, currentPlayer, isJudge);
              List<Widget> topoDe({required bool largo}) => [
                    const SizedBox(height: 4),
                    if (room.phase != GamePhase.waitingForPlayers)
                      PlayerListWidget(
                        players: room.players,
                        judgeId: room.currentJudgeId,
                        vertical: largo,
                        sala: room,
                        meuId: currentPlayer?.id,
                      ),
                    if (aviso != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Medidas.margem,
                          4,
                          Medidas.margem,
                          8,
                        ),
                        child: Align(
                            alignment: Alignment.centerLeft, child: aviso),
                      ),
                    if (room.currentBlackCard != null &&
                        room.phase != GamePhase.waitingForPlayers)
                      BlackCardWidget(
                        card: room.currentBlackCard!,
                        respostas: _respostasNaCarta(
                            ref, room, currentPlayer, isJudge),
                        esperando: room.phase == GamePhase.playersSubmitting &&
                            currentPlayer != null &&
                            !isJudge &&
                            !room.submittedCards.containsKey(currentPlayer.id),
                        grande: largo,
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
                          // Com oito jogadores o placar cresce: a coluna rola.
                          SizedBox(
                            width: 420,
                            child: SingleChildScrollView(
                              child: Column(children: topoDe(largo: true)),
                            ),
                          ),
                          Expanded(child: conteudo),
                        ],
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: Medidas.larguraMaxima),
                    child: ColunaQueRola(
                      topo: topoDe(largo: false),
                      conteudo: conteudo,
                    ),
                  );
                },
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
            icone: Desenho.juiz,
            destaque: true,
          );
        }
        return AvisoDaVez('Juiz da rodada: $juiz', icone: Desenho.juiz);
      case GamePhase.judgeChoosing:
        if (isJudge) {
          return const AvisoDaVez(
            'Sua vez de julgar',
            icone: Desenho.juiz,
            destaque: true,
          );
        }
        return AvisoDaVez('Juiz da rodada: $juiz', icone: Desenho.juiz);
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

  List<Widget> _botaoDoZe(BuildContext context, int faltam) {
    final temZe = room.players.any((p) => p.id == zeAleatorio.id);
    final pessoas = room.players.where((p) => !ehBot(p.id)).length;
    Future<void> tentar(Future<void> Function(String) acao) async {
      try {
        await acao(room.roomId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(mensagemDoErro(e))));
        }
      }
    }

    if (!temZe && faltam == 1) {
      return [
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => tentar(FirebaseService.chamarZe),
          icon: const IconeFofo(Desenho.dado, tamanho: 22),
          label: const Text('Chamar o Zé Aleatório'),
        ),
        const SizedBox(height: 6),
        Text(
          'Só vocês dois? O Zé completa a mesa e joga uma carta qualquer '
          'por rodada. Às vezes ganha.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Cores.de(context).tintaSuave),
        ),
      ];
    }
    if (temZe && pessoas >= minimoDeJogadores) {
      return [
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => tentar(FirebaseService.dispensarZe),
          child: const Text('Dispensar o Zé Aleatório'),
        ),
      ];
    }
    return const [];
  }

  Future<void> _sortearCarinha(BuildContext context) async {
    try {
      await FirebaseService.sortearOutraCarinha(room.roomId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemDoErro(e))),
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
          Text('Chama a galera', style: textos.headlineSmall),
          const SizedBox(height: 4),
          Text(
            faltam > 0
                ? '${faltam == 1 ? 'Falta 1 pessoa' : 'Faltam $faltam pessoas'}. '
                    'A mesa já está com fome.'
                : '${room.players.length} na mesa. Já dá para começar.',
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
                        icon: const IconeFofo(Desenho.convite, tamanho: 24),
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
                      icon: const IconeFofo(Desenho.copiar, tamanho: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Na mesa', style: textos.titleMedium),
          // Espaço para o chapéu e o topete que saem da cabeça.
          const SizedBox(height: 24),
          // Até 4 por linha num celular: o cascudo nunca atravessa a quebra.
          LayoutBuilder(
            builder: (context, espaco) => GrupoDeCarinhas(
              quantidade: room.players.length,
              eixo: Axis.horizontal,
              passo: 86,
              porLinha: max(1, (espaco.maxWidth + 14) ~/ 86),
              child: Wrap(
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
                  for (var i = 0; i < faltam; i++) const _LugarVazio(),
                ],
              ),
            ),
          ),
          if (meuId != null && room.players.any((p) => p.id == meuId)) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _sortearCarinha(context),
                icon: const IconeFofo(Desenho.dado, tamanho: 24),
                label: const Text('Sortear outra carinha'),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Até ${room.maxPoints} pontos, ${room.handSize} cartas na mão',
            style: textos.bodyMedium?.copyWith(color: cores.tintaSuave),
          ),
          // Com duas pessoas, o anfitrião pode chamar o Zé Aleatório para
          // completar a mesa; chegou a terceira, pode dispensar.
          if (isHost) ..._botaoDoZe(context, faltam),
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
                            SnackBar(content: Text(mensagemDoErro(e))),
                          );
                        }
                      }
                    },
              child: Text(
                faltam > 0
                    ? 'Falta${faltam == 1 ? '' : 'm'} $faltam para começar'
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
    final cores = Cores.de(context);
    final eu = ref.watch(currentPlayerProvider);
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
              Text(
                'Fim de jogo',
                style: textos.titleMedium?.copyWith(color: cores.tintaSuave),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const _CoroaQueDerrete(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          winner.id == eu?.id
                              ? 'Você venceu.'
                              : '${winner.name} venceu.',
                          style: textos.headlineMedium,
                        ),
                        // Quem venceu se orgulha; o resto lamenta.
                        Text(
                          winner.id == eu?.id ? 'Que orgulho.' : 'Que pena.',
                          style: textos.headlineMedium
                              ?.copyWith(color: cores.destaque),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          winner.points == 1
                              ? '1 ponto'
                              : '${winner.points} pontos',
                          style: textos.bodyLarge
                              ?.copyWith(color: cores.tintaSuave),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                          SnackBar(content: Text(mensagemDoErro(e))),
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
                onPressed: () {
                  ref.read(roomIdProvider.notifier).state = null;
                  FirebaseService.sair(room.roomId);
                },
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

/// Um lugar que ainda falta na mesa: um buraco escuro onde dois olhinhos
/// esperam, e piscam de vez em quando.
class _LugarVazio extends StatefulWidget {
  const _LugarVazio();

  @override
  State<_LugarVazio> createState() => _LugarVazioState();
}

class _LugarVazioState extends State<_LugarVazio>
    with SingleTickerProviderStateMixin {
  late final _piscar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (movimentoReduzido(context)) {
      _piscar.stop();
    } else if (!_piscar.isAnimating) {
      _piscar.repeat();
    }
  }

  @override
  void dispose() {
    _piscar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final olho = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: cores.destaque,
        shape: BoxShape.circle,
      ),
    );
    return Semantics(
      label: 'Lugar vazio',
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Color.lerp(cores.mesa, cores.cartaPreta, .45),
                shape: BoxShape.circle,
                border: Border.all(color: cores.superficie, width: 2),
              ),
              child: AnimatedBuilder(
                animation: _piscar,
                // Fecha os olhos num instante perto do fim de cada volta.
                builder: (context, filho) => Transform.scale(
                  scaleY: _piscar.value > .94 ? .15 : 1,
                  child: filho,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [olho, const SizedBox(width: 8), olho],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vazio…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cores.tintaSuave,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A coroa de quem venceu: sorri e derrete devagar enquanto o confete cai.
class _CoroaQueDerrete extends StatefulWidget {
  const _CoroaQueDerrete();

  @override
  State<_CoroaQueDerrete> createState() => _CoroaQueDerreteState();
}

class _CoroaQueDerreteState extends State<_CoroaQueDerrete>
    with SingleTickerProviderStateMixin {
  late final _gotejo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (movimentoReduzido(context)) {
      _gotejo.value = 1;
    } else if (_gotejo.value == 0 && !_gotejo.isAnimating) {
      _gotejo.forward();
    }
  }

  @override
  void dispose() {
    _gotejo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gotejo,
      builder: (context, _) => IconeFofo(
        Desenho.coroa,
        tamanho: 84,
        cor: Cores.de(context).destaque,
        gotejo: Curves.easeIn.transform(_gotejo.value),
      ),
    );
  }
}

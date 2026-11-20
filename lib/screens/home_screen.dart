import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/convite.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';
import 'tutorial_screen.dart';
import 'game_screen.dart';
import '../ui/cartas.dart';
import '../ui/icones.dart';
import '../ui/jogadores.dart';
import '../ui/sons.dart';
import '../ui/tema.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Código do link de convite (`?sala=`), aberto uma vez quando o login ficar
  /// pronto.
  String? _convite = codigoDoConvite(Uri.base);

  @override
  void initState() {
    super.initState();
    // Fazer login anônimo automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _signInAnonymously();
      // Na primeira visita, o tutorial abre sozinho (menos para quem chegou
      // por um convite: esse vai direto para a sala).
      if (_convite == null && await tutorialPendente() && mounted) {
        abrirTutorial(context);
      }
    });
  }

  Future<void> _signInAnonymously() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        print('Tentativa ${attempts + 1} de login anônimo...');
        await FirebaseService.signInAnonymously();
        print('Login anônimo realizado com sucesso');
        return;
      } catch (e) {
        attempts++;
        print('Erro no login anônimo (tentativa $attempts): $e');

        if (attempts < maxAttempts) {
          print('Aguardando 2 segundos antes da próxima tentativa...');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          print('Falha no login após $maxAttempts tentativas');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final roomId = ref.watch(roomIdProvider);

    ref.listen(authProvider, (antes, depois) {
      final codigo = _convite;
      if (codigo == null || depois.valueOrNull == null) return;
      _convite = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || ref.read(roomIdProvider) != null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JoinRoomScreen(codigoInicial: codigo),
          ),
        );
      });
    });

    // Com uma sala escolhida, a tela é a do jogo.
    if (roomId != null) {
      return const GameScreen();
    }

    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Medidas.larguraMaxima),
            child: Padding(
              padding: const EdgeInsets.all(Medidas.margem),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => abrirTutorial(context),
                        icon: const IconeFofo(Desenho.ajuda, tamanho: 24),
                        label: const Text('Como jogar'),
                      ),
                      const Spacer(),
                      const BotaoDeSom(),
                    ],
                  ),
                  const Spacer(),
                  const _CartasDaCapa(),
                  const SizedBox(height: 36),
                  Text(
                    'Carinhas fofas. Cartas horríveis. '
                    'Cada um joga no seu celular.',
                    style: textos.titleMedium?.copyWith(
                      color: Cores.de(context).tintaSuave,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(flex: 2),
                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (authState.hasError) ...[
                    Text('Erro ao conectar', style: textos.titleMedium),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => FirebaseService.signInAnonymously(),
                      child: const Text('Tentar novamente'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRoomScreen(),
                        ),
                      ),
                      child: const Text('Criar sala'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JoinRoomScreen(),
                        ),
                      ),
                      child: const Text('Entrar na sala'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A capa: uma carta preta e a branca que a completa, jogadas de lado na mesa.
class _CartasDaCapa extends StatelessWidget {
  const _CartasDaCapa();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Cartaralho',
      excludeSemantics: true,
      child: SizedBox(
        height: 250,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 48,
              top: 0,
              child: Transform.rotate(
                angle: -0.06,
                child: const CartaPreta(texto: 'O jogo de hoje é ____.'),
              ),
            ),
            // Três carinhas espiam por trás da carta do nome.
            Positioned(
              left: 96,
              top: 86,
              child: Transform.rotate(
                angle: 0.05,
                child: const Row(
                  children: [
                    AvatarDeJogador(nome: 'Ana', indice: 0, tamanho: 52),
                    SizedBox(width: 4),
                    AvatarDeJogador(nome: 'Bia', indice: 1, tamanho: 52),
                    SizedBox(width: 4),
                    AvatarDeJogador(nome: 'Caio', indice: 2, tamanho: 52),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 72,
              right: 0,
              top: 128,
              child: Transform.rotate(
                angle: 0.05,
                child: const _CartaDoNome(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaDoNome extends StatelessWidget {
  const _CartaDoNome();

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        color: cores.carta,
        borderRadius: BorderRadius.circular(Medidas.raioCarta),
        boxShadow: const [
          BoxShadow(color: Medidas.sombra, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        'Cartaralho',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: cores.tintaNaCarta,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

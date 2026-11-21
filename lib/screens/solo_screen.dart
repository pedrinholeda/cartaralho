import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/baralho.dart';
import '../game/bots.dart';
import '../game/regras.dart' as regras;
import '../models/player.dart';
import '../providers/baralhos_provider.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../services/mesa_local.dart';
import '../ui/icones.dart';
import '../ui/jogadores.dart';
import '../ui/opcoes.dart';
import '../ui/tema.dart';
import '../widgets/escolha_de_baralhos.dart';

/// Jogar sozinho contra bots. A partida roda neste aparelho (`MesaLocal`),
/// com todos os baralhos, e começa direto, com você de juiz.
class SoloScreen extends ConsumerStatefulWidget {
  const SoloScreen({super.key});

  @override
  ConsumerState<SoloScreen> createState() => _SoloScreenState();
}

class _SoloScreenState extends ConsumerState<SoloScreen> {
  final _nome = TextEditingController();
  int _adversarios = 3;
  int _pontos = 5;
  bool _abrindo = false;
  final _escolhidos = {...pacotesPadrao};

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _comecar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu nome')),
      );
      return;
    }
    if (_escolhidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha ao menos um baralho')),
      );
      return;
    }
    final eu = FirebaseService.currentUser;
    if (eu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ainda conectando. Tente de novo.')),
      );
      return;
    }
    setState(() => _abrindo = true);
    try {
      final rng = Random();
      final roomId =
          '${MesaLocal.prefixo}${regras.gerarCodigoSala(random: rng, tamanho: 4)}';
      MesaLocal.abrir(
        salaSolo(
          roomId: roomId,
          voce: Player(id: eu.uid, name: nome),
          baralho: juntarEscolhidos(
            await ref.read(baralhosProvider.future),
            _escolhidos,
          ),
          adversarios: _adversarios,
          maxPoints: _pontos,
          random: rng,
        ),
        random: rng,
      );
      ref.read(roomIdProvider.notifier).state = roomId;
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não deu para começar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _abrindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Medidas.margem),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Medidas.larguraMaxima),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Jogar sozinho', style: textos.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Você contra os bots. Cada um tem o seu gosto: a Tia do Zap '
                  'adora as cartas do grupo da família, o Coach Quântico, as '
                  'da firma. Sem o baralho preferido na mesa, eles jogam na '
                  'sorte.',
                  style: textos.bodyLarge?.copyWith(color: cores.tintaSuave),
                ),
                const SizedBox(height: 20),
                // Os bots, para conhecer a mesa antes de sentar.
                Wrap(
                  spacing: 10,
                  runSpacing: 18,
                  children: [
                    for (var i = 0; i < bots.length; i++)
                      SizedBox(
                        width: 72,
                        child: Column(
                          children: [
                            AvatarDeJogador(
                              nome: bots[i].nome,
                              indice: i + 1,
                              semente: bots[i].id,
                              tamanho: 48,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bots[i].nome,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: textos.bodySmall?.copyWith(
                                color: cores.tintaSuave,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nome,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: IconeFofo(Desenho.pessoa, tamanho: 22),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                LinhaDeOpcoes(
                  titulo: 'Bots na mesa',
                  opcoes: opcoesDeAdversarios,
                  valor: _adversarios,
                  aoEscolher: (v) => setState(() => _adversarios = v),
                ),
                const SizedBox(height: 16),
                LinhaDeOpcoes(
                  titulo: 'Pontos para vencer',
                  opcoes: regras.opcoesDePontos,
                  valor: _pontos,
                  aoEscolher: (v) => setState(() => _pontos = v),
                ),
                const SizedBox(height: 24),
                EscolhaDeBaralhos(
                  escolhidos: _escolhidos,
                  perguntaDoAdulto: 'Você topa?',
                  aoMudar: (novos) => setState(() {
                    _escolhidos
                      ..clear()
                      ..addAll(novos);
                  }),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _abrindo ? null : _comecar,
                  child: const Text('Começar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

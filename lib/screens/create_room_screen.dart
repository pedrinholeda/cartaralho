import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/baralho.dart';
import '../game/regras.dart' as regras;
import '../providers/baralhos_provider.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../ui/icones.dart';
import '../ui/opcoes.dart';
import '../ui/tema.dart';
import '../widgets/escolha_de_baralhos.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _nameController = TextEditingController();
  bool _isCreating = false;
  int _pontos = 5;
  int _mao = regras.tamanhoDaMao;
  final _escolhidos = {...pacotesPadrao};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
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

    setState(() {
      _isCreating = true;
    });

    try {
      final todos = await ref.read(baralhosProvider.future);
      final roomId = await FirebaseService.createRoom(
        _nameController.text.trim(),
        baralho: juntarEscolhidos(todos, _escolhidos),
        maxPoints: _pontos,
        handSize: _mao,
      );
      ref.read(roomIdProvider.notifier).state = roomId;

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Criar nova sala',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Você vira o anfitrião e recebe um código para passar aos outros.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
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
                  titulo: 'Pontos para vencer',
                  opcoes: regras.opcoesDePontos,
                  valor: _pontos,
                  aoEscolher: (v) => setState(() => _pontos = v),
                ),
                const SizedBox(height: 16),
                LinhaDeOpcoes(
                  titulo: 'Cartas na mão',
                  opcoes: regras.opcoesDeMao,
                  valor: _mao,
                  aoEscolher: (v) => setState(() => _mao = v),
                ),
                const SizedBox(height: 24),
                EscolhaDeBaralhos(
                  escolhidos: _escolhidos,
                  aoMudar: (novos) => setState(() {
                    _escolhidos
                      ..clear()
                      ..addAll(novos);
                  }),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isCreating ? null : _createRoom,
                  child: _isCreating
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            color: Cores.de(context).tintaNaCartaPreta,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Criar sala'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

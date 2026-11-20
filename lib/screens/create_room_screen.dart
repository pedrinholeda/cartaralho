import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/regras.dart' as regras;
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../ui/tema.dart';

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

    setState(() {
      _isCreating = true;
    });

    try {
      final roomId = await FirebaseService.createRoom(
        _nameController.text.trim(),
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
                Text('Criar Nova Sala',
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
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                _Opcoes(
                  titulo: 'Pontos para vencer',
                  opcoes: regras.opcoesDePontos,
                  valor: _pontos,
                  aoEscolher: (v) => setState(() => _pontos = v),
                ),
                const SizedBox(height: 16),
                _Opcoes(
                  titulo: 'Cartas na mão',
                  opcoes: regras.opcoesDeMao,
                  valor: _mao,
                  aoEscolher: (v) => setState(() => _mao = v),
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
                      : const Text('Criar Sala'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma linha de opções da partida, como "Pontos para vencer: 3 5 7 10".
class _Opcoes extends StatelessWidget {
  final String titulo;
  final List<int> opcoes;
  final int valor;
  final ValueChanged<int> aoEscolher;

  const _Opcoes({
    required this.titulo,
    required this.opcoes,
    required this.valor,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final o in opcoes)
              ChoiceChip(
                label: Text('$o'),
                selected: o == valor,
                onSelected: (_) => aoEscolher(o),
              ),
          ],
        ),
      ],
    );
  }
}

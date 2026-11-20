import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/regras.dart' as regras;
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';

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
      appBar: AppBar(
        title: const Text('Criar Sala'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 80,
                color: Color(0xFF6A1B9A),
              ),
              const SizedBox(height: 32),
              const Text(
                'Criar Nova Sala',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Digite seu nome para criar uma nova sala de jogo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Seu nome',
                  border: OutlineInputBorder(),
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Criar Sala',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
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

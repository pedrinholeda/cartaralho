import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../services/firebase_service.dart';
import '../ui/tema.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _roomIdController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _roomIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (_roomIdController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await FirebaseService.joinRoom(
        _roomIdController.text.trim().toUpperCase(),
        _nameController.text.trim(),
      );
      ref.read(roomIdProvider.notifier).state =
          _roomIdController.text.trim().toUpperCase();

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
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Entrar na Sala', style: textos.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Peça o código de seis letras e números a quem criou a sala.',
                  style: textos.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _roomIdController,
                  decoration: const InputDecoration(
                    labelText: 'Código da sala',
                    prefixIcon: Icon(Icons.vpn_key),
                    hintText: 'Ex: K7PX2M',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isJoining ? null : _joinRoom,
                  child: _isJoining
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            color: Cores.de(context).tintaNaCartaPreta,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Entrar na Sala'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

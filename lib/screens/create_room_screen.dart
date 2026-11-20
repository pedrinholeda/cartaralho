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
        baralho: Baralho.juntar(
          [
            for (final b in todos)
              if (_escolhidos.contains(b.id)) b
          ],
        ),
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
                _Baralhos(
                  escolhidos: _escolhidos,
                  aoTrocar: (id) => setState(() {
                    if (!_escolhidos.remove(id)) _escolhidos.add(id);
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

/// Os pacotes de cartas, para marcar quais entram na partida.
class _Baralhos extends ConsumerWidget {
  final Set<String> escolhidos;
  final ValueChanged<String> aoTrocar;

  const _Baralhos({required this.escolhidos, required this.aoTrocar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final cores = Cores.de(context);
    final baralhos = ref.watch(baralhosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Baralhos', style: textos.titleSmall),
        const SizedBox(height: 8),
        ...baralhos.when(
          loading: () => [
            const Center(child: CircularProgressIndicator()),
          ],
          error: (e, _) => [Text('Não deu para carregar os baralhos: $e')],
          data: (lista) {
            final marcados = lista.where((b) => escolhidos.contains(b.id));
            final cartas = marcados.fold<int>(
                0, (soma, b) => soma + b.pretas.length + b.brancas.length);
            return [
              for (final b in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Pacote(
                    baralho: b,
                    marcado: escolhidos.contains(b.id),
                    aoTocar: () => aoTrocar(b.id),
                  ),
                ),
              Text(
                marcados.isEmpty
                    ? 'Marque ao menos um baralho.'
                    : '${marcados.length} '
                        '${marcados.length == 1 ? 'baralho' : 'baralhos'}, '
                        '$cartas cartas',
                style: textos.bodyMedium?.copyWith(color: cores.tintaSuave),
              ),
            ];
          },
        ),
      ],
    );
  }
}

class _Pacote extends StatelessWidget {
  final Baralho baralho;
  final bool marcado;
  final VoidCallback aoTocar;

  const _Pacote({
    required this.baralho,
    required this.marcado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    final raio = BorderRadius.circular(Medidas.raioCarta);

    return Semantics(
      checked: marcado,
      button: true,
      child: Material(
        color: cores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: raio,
          side: BorderSide(
            color: marcado ? cores.acao : cores.superficie,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: raio,
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baralho.nome,
                        style: textos.titleMedium?.copyWith(
                          color: cores.tintaNaMesa,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        baralho.descricao,
                        style: textos.bodyMedium?.copyWith(
                          color: cores.tintaSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: marcado ? cores.acao : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: marcado ? cores.acao : cores.tintaSuave,
                      width: 2,
                    ),
                  ),
                  child: marcado
                      ? Icon(Icons.check_rounded,
                          size: 18, color: cores.tintaNaAcao)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

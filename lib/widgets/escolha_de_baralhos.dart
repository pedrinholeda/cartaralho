import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/baralho.dart';
import '../providers/baralhos_provider.dart';
import '../ui/tema.dart';

/// Os pacotes de cartas, para marcar quais entram na partida (criar sala e
/// jogar sozinho). Marcar o +18 pede confirmação antes.
class EscolhaDeBaralhos extends ConsumerWidget {
  final Set<String> escolhidos;
  final ValueChanged<Set<String>> aoMudar;

  /// A pergunta do aviso do +18 ("Todo mundo na sala topa?").
  final String perguntaDoAdulto;

  const EscolhaDeBaralhos({
    super.key,
    required this.escolhidos,
    required this.aoMudar,
    this.perguntaDoAdulto = 'Todo mundo na sala topa?',
  });

  /// Marca ou desmarca um pacote. O +18 só entra depois de confirmar.
  Future<void> _trocar(BuildContext context, Baralho pacote) async {
    if (escolhidos.contains(pacote.id)) {
      aoMudar({...escolhidos}..remove(pacote.id));
      return;
    }
    if (pacote.adulto) {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(pacote.nome),
          content: Text(
            'Cartas sobre sexo e bebida, para maiores de 18. $perguntaDoAdulto',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Melhor não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Topo'),
            ),
          ],
        ),
      );
      if (confirmou != true) return;
    }
    aoMudar({...escolhidos, pacote.id});
  }

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
                    aoTocar: () => _trocar(context, b),
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

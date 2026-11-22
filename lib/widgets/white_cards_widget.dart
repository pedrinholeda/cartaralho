import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/regras.dart';
import '../models/card.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../services/erros.dart';
import '../services/firebase_service.dart';
import '../ui/animacoes.dart';
import '../ui/icones.dart';
import '../ui/cartas.dart';
import '../ui/dicas.dart';
import '../ui/sons.dart';
import '../ui/tema.dart';

/// A mão do jogador, em leque embaixo da tela. Ele escolhe quantas cartas a
/// carta preta pede, na ordem das lacunas; a frase aparece pronta na própria
/// carta preta (via [escolhidasProvider]) antes de enviar.
class WhiteCardsWidget extends ConsumerStatefulWidget {
  final GameRoom room;
  final Player currentPlayer;

  const WhiteCardsWidget({
    super.key,
    required this.room,
    required this.currentPlayer,
  });

  @override
  ConsumerState<WhiteCardsWidget> createState() => _WhiteCardsWidgetState();
}

class _WhiteCardsWidgetState extends ConsumerState<WhiteCardsWidget> {
  bool _isSubmitting = false;
  bool _trocando = false;

  /// Uma chave por carta da mão, para saber onde ela está quando voar.
  final _chaves = <String, GlobalKey>{};

  Rect? _lugar(String cartaId) {
    final caixa = _chaves[cartaId]?.currentContext?.findRenderObject();
    if (caixa is! RenderBox || !caixa.hasSize || !caixa.attached) return null;
    return caixa.localToGlobal(Offset.zero) & caixa.size;
  }

  List<GameCard> get _mao =>
      widget.room.hands[widget.currentPlayer.id] ?? const [];

  int get _pede => widget.room.currentBlackCard?.pick ?? 1;

  StateController<List<GameCard>> get _escolha =>
      ref.read(escolhidasProvider(chaveDaRodada(widget.room)).notifier);

  Future<void> _tocar(GameCard carta) async {
    ref.read(dicasProvider.notifier).marcar(Dica.mao);
    final atual = [..._escolha.state];
    if (atual.any((c) => c.id == carta.id)) {
      atual.removeWhere((c) => c.id == carta.id);
      _escolha.state = atual;
      return;
    }
    if (_pede > 1 && atual.length >= _pede) return;
    if (carta.emBranco) {
      // A carta em branco entra na escolha já com o texto escrito.
      final escrito = await _escrever();
      if (escrito == null || !mounted) return;
      carta = carta.comTexto(escrito);
    }
    if (_pede == 1) {
      atual
        ..clear()
        ..add(carta);
    } else if (atual.length < _pede) {
      atual.add(carta);
    }
    _escolha.state = atual;
  }

  /// Pede o texto da carta em branco. Nulo quando a pessoa desiste.
  Future<String?> _escrever() async {
    final campo = TextEditingController();
    final escrito = await showDialog<String>(
      context: context,
      builder: (context) {
        void usar() {
          try {
            Navigator.of(context).pop(textoLivre(campo.text));
          } on JogadaInvalida catch (e) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.mensagem)));
          }
        }

        return AlertDialog(
          title: const Text('Carta em branco'),
          content: TextField(
            controller: campo,
            autofocus: true,
            maxLength: maximoDoTextoLivre,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'Sua resposta',
              hintText: 'o que só você teria coragem de escrever',
            ),
            onSubmitted: (_) => usar(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(onPressed: usar, child: const Text('Usar')),
          ],
        );
      },
    );
    campo.dispose();
    return escrito;
  }

  Future<void> _enviar(List<GameCard> escolhidas) async {
    // As escolhidas voam até a carta preta, enquanto o envio vai.
    final destino = retanguloDaCartaPreta.value;
    if (destino != null) {
      voarCartas(
        context,
        [
          for (final c in escolhidas)
            if (_lugar(c.id) case final lugar?) (lugar, c.text),
        ],
        destino,
      );
    }
    setState(() => _isSubmitting = true);
    try {
      await FirebaseService.submitWhiteCards(
        widget.room.roomId,
        [for (final c in escolhidas) c.id],
        textos: {
          for (final c in escolhidas)
            if (c.emBranco) c.id: c.text,
        },
      );
      HapticFeedback.mediumImpact();
      ref.read(sonsProvider).tocar(Som.enviar);
      ref.read(dicasProvider.notifier).marcar(Dica.enviar);
    } catch (e) {
      _avisar(mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _trocarMao() async {
    setState(() => _trocando = true);
    try {
      await FirebaseService.swapHand(widget.room.roomId);
      _escolha.state = const [];
    } catch (e) {
      _avisar(mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _trocando = false);
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    final preta = widget.room.currentBlackCard;
    final enviadas = widget.room.submittedCards[widget.currentPlayer.id];

    if (enviadas != null) {
      final frase = preta == null
          ? enviadas.map((c) => c.text).join(' / ')
          : fraseCompleta(preta, enviadas);
      return Padding(
        padding: const EdgeInsets.all(Medidas.margem),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Entrada(
              deslocamento: 80,
              child: CartaBranca(texto: frase, larga: true),
            ),
            const SizedBox(height: 16),
            Text(
              'Enviada. Esperando os outros jogadores.',
              style: textos.titleMedium?.copyWith(color: cores.tintaSuave),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final mao = _mao;
    final pede = _pede;
    final escolhidas = ref
        .watch(escolhidasProvider(chaveDaRodada(widget.room)))
        // Uma carta que saiu da mão (troca) deixa de valer.
        .where((e) => mao.any((c) => c.id == e.id))
        .toList();
    final pronto = escolhidas.length == pede;
    final podeTrocar =
        !widget.room.handSwapsUsed.contains(widget.currentPlayer.id);
    final dicas = ref.watch(dicasProvider);
    final dicaDaMao = escolhidas.isEmpty && deveMostrar(dicas, Dica.mao);
    final dicaDeEnviar =
        pronto && !_isSubmitting && deveMostrar(dicas, Dica.enviar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Medidas.margem),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pede == 1
                      ? 'Escolha uma carta branca:'
                      : 'Escolha $pede cartas brancas, na ordem:',
                  style: textos.titleMedium?.copyWith(color: cores.tintaSuave),
                ),
              ),
              if (podeTrocar)
                Tooltip(
                  message: 'Troca todas as cartas da mão, uma vez por partida',
                  child: TextButton.icon(
                    onPressed: _trocando ? null : _trocarMao,
                    icon: const IconeFofo(Desenho.trocar, tamanho: 22),
                    label: const Text('Trocar mão'),
                  ),
                ),
            ],
          ),
        ),
        if (dicaDaMao)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(Medidas.margem, 0, Medidas.margem, 6),
            child: BalaoDeDica(
              texto: pede == 1
                  ? 'Toque numa carta para ver a frase pronta lá em cima.'
                  : 'Toque nas cartas na ordem das lacunas. Arraste para ver as outras.',
              aoFechar: () => ref.read(dicasProvider.notifier).marcar(Dica.mao),
            ),
          ),
        MaoEmLeque(
          quantidade: mao.length,
          construir: (context, index) {
            final carta = mao[index];
            final posicao = escolhidas.indexWhere((c) => c.id == carta.id);
            // A em branco mostra o que foi escrito, ou o convite para
            // escrever.
            final texto = !carta.emBranco
                ? carta.text
                : posicao >= 0
                    ? escolhidas[posicao].text
                    : 'carta em branco: toque para escrever';
            // Uma key por carta: as que chegam na mão animam, as que ficam não.
            return Entrada(
              key: ValueKey(carta.id),
              atraso: Duration(milliseconds: 60 * index),
              child: CartaBranca(
                key: _chaves.putIfAbsent(carta.id, GlobalKey.new),
                texto: texto,
                emBranco: carta.emBranco && posicao < 0,
                selecionada: posicao >= 0,
                ordem: posicao >= 0 && pede > 1 ? posicao + 1 : null,
                aoTocar: () => _tocar(carta),
              ),
            );
          },
        ),
        if (dicaDeEnviar)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(Medidas.margem, 6, Medidas.margem, 0),
            child: BalaoDeDica(
              texto:
                  'Gostou da frase? Envie. Dá para trocar antes, é só tocar em outra.',
              aoFechar: () =>
                  ref.read(dicasProvider.notifier).marcar(Dica.enviar),
            ),
          ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(Medidas.margem, 4, Medidas.margem, 20),
          child: ElevatedButton(
            onPressed:
                pronto && !_isSubmitting ? () => _enviar(escolhidas) : null,
            child: _isSubmitting
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      color: cores.tintaNaAcao,
                      strokeWidth: 3,
                    ),
                  )
                : Text(pede == 1 ? 'Enviar carta' : 'Enviar cartas'),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/cartas.dart';
import '../ui/jogadores.dart';
import '../ui/tema.dart';

const _chaveTutorialVisto = 'tutorialVisto';

/// Se o tutorial ainda não foi visto neste aparelho. Sem armazenamento (janela
/// anônima restrita), considera visto, para não abrir toda vez.
Future<bool> tutorialPendente() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_chaveTutorialVisto) ?? false);
  } catch (_) {
    return false;
  }
}

Future<void> _marcarVisto() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveTutorialVisto, true);
  } catch (_) {}
}

/// Abre o tutorial por cima da tela atual.
Future<void> abrirTutorial(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const TutorialScreen(),
      ),
    );

/// Como jogar, em três telas: chamar a galera, responder a frase, o juiz
/// escolher. Cada tela mostra as cartas de verdade do jogo, num exemplo.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _paginas = PageController();
  int _atual = 0;

  static const _passos = [
    (
      'Chame a galera',
      'Uma pessoa cria a sala e manda o convite. Cada um joga no próprio '
          'celular; de 3 a 8 jogadores.',
    ),
    (
      'Complete a frase',
      'A cada rodada sai uma carta preta com uma lacuna. Escolha na sua mão a '
          'carta branca que deixa a frase mais absurda.',
    ),
    (
      'O juiz escolhe',
      'Quem é o juiz lê as frases sem saber de quem é cada uma e escolhe a '
          'melhor. Quem enviou ganha o ponto, e o juiz passa para o próximo.',
    ),
  ];

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  Future<void> _fechar() async {
    await _marcarVisto();
    if (mounted) Navigator.of(context).pop();
  }

  void _avancar() {
    if (_atual == _passos.length - 1) {
      _fechar();
      return;
    }
    _paginas.nextPage(
      duration: MediaQuery.of(context).disableAnimations
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final textos = Theme.of(context).textTheme;
    final ultimo = _atual == _passos.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Medidas.larguraMaxima),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _fechar,
                    child: const Text('Pular'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _paginas,
                    itemCount: _passos.length,
                    onPageChanged: (i) => setState(() => _atual = i),
                    itemBuilder: (context, i) {
                      final (titulo, texto) = _passos[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Medidas.margem,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              // Em tela baixa a ilustração encolhe para caber.
                              child: LayoutBuilder(
                                builder: (context, espaco) => Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: SizedBox(
                                      width: espaco.maxWidth,
                                      child: _Exemplo(passo: i),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(titulo, style: textos.headlineMedium),
                            const SizedBox(height: 10),
                            Text(
                              texto,
                              style: textos.bodyLarge?.copyWith(
                                color: cores.tintaSuave,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.margem,
                    0,
                    Medidas.margem,
                    20,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < _passos.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: i == _atual ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _atual ? cores.acao : cores.superficie,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      const Spacer(),
                      SizedBox(
                        width: 170,
                        child: ElevatedButton(
                          onPressed: _avancar,
                          child: Text(ultimo ? 'Bora jogar' : 'Próximo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A ilustração de cada passo, montada com os componentes do próprio jogo.
class _Exemplo extends StatelessWidget {
  final int passo;

  const _Exemplo({required this.passo});

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    switch (passo) {
      case 0:
        const nomes = ['Ana', 'Bia', 'Caio', 'Duda'];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < nomes.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AvatarDeJogador(
                      nome: nomes[i],
                      indice: i,
                      tamanho: 56,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: cores.superficie,
                borderRadius: BorderRadius.circular(Medidas.raioPainel),
              ),
              child: Text(
                'K7PX2M',
                style: GoogleFonts.figtree(
                  color: cores.tintaNaMesa,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
            ),
          ],
        );
      case 1:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartaPreta(
              texto: 'O segredo de um casamento feliz é ____.',
              respostas: ['o tio do pavê'],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CartaPequena('a sogra', angulo: -0.06),
                  _CartaPequena('o tio do pavê', escolhida: true),
                  _CartaPequena('Pix errado', angulo: 0.06),
                ],
              ),
            ),
          ],
        );
      default:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartaBranca(
              larga: true,
              vencedora: true,
              texto: 'O segredo de um casamento feliz é o tio do pavê.',
              autor: 'Bia',
            ),
            SizedBox(height: 12),
            CartaBranca(
              larga: true,
              texto: 'O segredo de um casamento feliz é Pix errado.',
              autor: 'Caio',
            ),
          ],
        );
    }
  }
}

class _CartaPequena extends StatelessWidget {
  final String texto;
  final double angulo;
  final bool escolhida;

  const _CartaPequena(this.texto, {this.angulo = 0, this.escolhida = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Transform.rotate(
        angle: angulo,
        child: SizedBox(
          width: 96,
          height: 134,
          child: CartaBranca(texto: texto, selecionada: escolhida),
        ),
      ),
    );
  }
}

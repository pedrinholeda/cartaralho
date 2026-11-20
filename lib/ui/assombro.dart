/// Os sustos pequenos do jogo: fofo por fora, ácido por dentro, e de vez em
/// quando a mesa olha de volta. Cada um dura pouco e nunca atrapalha a
/// jogada. Ver docs/DESIGN.md, "Momentos creepy".
library;

/// A hora de agora. Os testes trocam por uma hora fixa.
DateTime Function() agora = DateTime.now;

/// Das 3h às 5h as carinhas desbotam, ficam de olhos fundos, e a carta preta
/// pergunta se você ainda está acordado.
bool ehMadrugada(DateTime hora) => hora.hour >= 3 && hora.hour < 5;

/// Quanto tempo o jogador pode pensar antes de a lacuna da carta preta abrir
/// um olho para ele.
const esperaDaLacuna = Duration(seconds: 40);

/// O rodapé da carta preta na madrugada.
const rodapeDaMadrugada = 'ainda acordado?';

# Design do Cartaralho

O jogo acontece numa mesa. Tudo que se lê fica numa carta: a carta preta com a frase, as
brancas com as respostas. A mesa é vermelha, a cor dos três logos em [`marca/`](marca), e é
o único lugar onde o visual ousa; o resto fica quieto para as frases aparecerem.

<p>
  <img src="imagens/inicio.png" width="220" alt="Tela inicial: carta preta 'O jogo de hoje é ____.' e, inclinada embaixo, uma carta branca escrita Cartaralho, sobre a mesa vermelha">
  <img src="imagens/escolha-2.png" width="220" alt="Mão do jogador numa carta Escolha 2: duas cartas brancas escolhidas com contorno preto e os números 1 e 2, e a frase montada acima">
  <img src="imagens/resultado-escuro.png" width="220" alt="Resultado da rodada no tema escuro: a frase vencedora numa carta amarela com o nome de quem enviou, a outra numa carta clara">
</p>

## Logo

[`marca/logo-carta-escura.png`](marca/logo-carta-escura.png): a carta branca com cara de
malandra e o ponto de exclamação vermelho, sobre fundo preto. As outras duas propostas
ficam em `marca/` como registro. Os ícones do app (web e Android) saem dele com
`dart run flutter_launcher_icons`, configurado no `pubspec.yaml`; trocou o logo, rode de novo.

## Princípios

- **Carta é para ler, mesa é para estar.** Texto longo nunca fica direto na mesa: vai numa
  carta. Na mesa só ficam títulos curtos e avisos.
- **Uma ousadia só.** A mesa vermelha de ponta a ponta. Cartas, botões e placar ficam em
  preto, branco e, raramente, amarelo.
- **Amarelo quer dizer "é você" ou "ganhou".** Só o juiz da rodada e a carta vencedora usam
  o amarelo do confete. Nada mais.
- **Carta tem cara de carta.** Proporção de baralho (63 × 88 mm) na mão, cantos de 14 px,
  sombra seca embaixo, como papel cartão em cima da mesa. Botão é redondo para não ser
  confundido com carta.
- **Movimento mostra o que mudou.** A carta escolhida sobe; as cartas novas entram na mão uma
  a uma; as respostas viram de costas para frente quando o juiz vai escolher; a fase nova
  entra com um fade curto; quem ganha leva confete. Nada se mexe sem motivo, e com "reduzir
  movimento" ligado no sistema tudo aparece direto.

## Tokens

Em [`lib/ui/tema.dart`](../lib/ui/tema.dart), na extensão `Cores` do tema. Widget nenhum usa
cor em hexadecimal: pede `Cores.de(context)`.

| token | claro | escuro | uso |
|---|---|---|---|
| `mesa` | `#D7282F` | `#2B0B0E` | fundo de todas as telas |
| `tintaNaMesa` | `#FFFFFF` | `#F4DADB` | texto e ícones sobre a mesa |
| `carta` | `#FFFFFF` | `#ECECEC` | carta branca, campos de texto, ficha do placar |
| `tintaNaCarta` | `#000000` | `#000000` | texto da carta branca |
| `cartaPreta` | `#000000` | `#000000` | carta preta, botão principal, contorno da carta escolhida |
| `tintaNaCartaPreta` | `#FFFFFF` | `#FFFFFF` | texto da carta preta e do botão |
| `destaque` | `#FFC23A` | `#FFC23A` | juiz da rodada, carta vencedora |

No tema escuro a mesa vira vinho e a carta branca perde um pouco de brilho, para não
ofuscar numa sala escura; a carta preta continua preta.

Medidas em `Medidas`: espaço de 8, margem de 20, raio de carta 14, raio de botão 28,
largura máxima do conteúdo 560 (em tela larga o jogo fica centralizado).

## Tipografia

- **Archivo Narrow 700** nos títulos e no nome do jogo: estreita e pesada como as letras
  dos logos.
- **Archivo 800** no texto das cartas; **Archivo** normal no resto.

As fontes vêm do Google Fonts pelo pacote `google_fonts`, baixadas no primeiro uso. O jogo
já precisa de internet para falar com o Firebase, então isso não cria uma dependência nova.

## Componentes

[`lib/ui/cartas.dart`](../lib/ui/cartas.dart):

- `CartaPreta`: a frase da rodada. A lacuna `____` vira uma linha longa; a carta que pede
  mais de uma branca mostra "Escolha 2".
- `CartaBranca`: carta da mão (proporção de baralho; sobe e ganha contorno preto quando
  escolhida; mostra a ordem quando a preta pede mais de uma) ou carta larga com a frase
  inteira (mesa, juiz, resultado; com o nome de quem enviou e em amarelo quando venceu).
- `GradeDeCartas`: a mão, com quantas cartas couberem lado a lado (duas no celular).

[`lib/ui/animacoes.dart`](../lib/ui/animacoes.dart):

- `Entrada`: a carta sobe e aparece, uma vez, na primeira vez que é montada (uma `key` por
  carta faz só as novas animarem).
- `Virada`: a carta começa de costas (verso preto com borda da cor da mesa) e vira.
- `Confete`: papéis amarelos, brancos e pretos caindo por cima da tela, sem capturar toque.
- `movimentoReduzido(context)`: verdadeiro quando o sistema pede menos movimento; os três
  componentes já respeitam.

## Decisões

- **Por que não preto e branco com Helvetica.** É o visual de outro jogo de cartas muito
  conhecido; o Cartaralho precisa ser reconhecido como ele mesmo. A mesa vermelha e a
  Archivo fazem isso.
- **Por que não feltro verde.** É mesa de cassino, não de festa em casa.
- **Sombra seca, sem desfoque.** Lembra papel em cima de mesa e não o cartão flutuante
  genérico de app.
- **Brancas em minúscula.** O texto da carta branca vai para o meio da frase; o jogo põe a
  maiúscula quando ela abre a frase (`fraseCompleta`).

## Pendências

No [roadmap](ROADMAP.md), fase 3:
efeitos sonoros, sala de espera com compartilhamento e layout próprio para tela larga.

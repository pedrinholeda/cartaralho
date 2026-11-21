# Desenvolvendo o Cartaralho

Um app Flutter sem servidor próprio: o estado de cada sala é um documento no Firestore, e
todo aparelho na sala escuta esse documento e redesenha a tela quando ele muda.

## Requisitos

- Flutter 3.50 (a versão do CI; outra versão pode mudar o resultado do lint)
- Um projeto Firebase configurado, para rodar o app ([FIREBASE.md](FIREBASE.md)). Lint,
  testes e build não precisam dele.
- Android: Android SDK e um JDK compatível com o Gradle do projeto (ver
  [limites](#limites-conhecidos)). iOS: macOS com Xcode.

## Setup e o dia a dia

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

```bash
flutter analyze
```

```bash
dart format lib test
```

```bash
flutter test
```

Para testar uma partida sozinho, abra o app em três origens diferentes, por exemplo
`http://localhost:PORTA`, `http://a.localhost:PORTA` e `http://b.localhost:PORTA` (o Chrome
resolve `*.localhost` para a própria máquina). Cada origem guarda o próprio login anônimo e
vira um jogador. Três abas na mesma origem **não** servem: elas dividem o login e viram o
mesmo jogador. Uma janela anônima também conta como origem separada.

### Testes

`test/` cobre o que é código puro: as regras da partida (`test/game/regras_test.dart`:
distribuir as mãos, enviar carta, escolher o vencedor, rodar o juiz, fim de jogo), o
baralho, a conversão dos modelos para o formato do Firestore e as animações
(`test/ui/`, inclusive com "reduzir movimento"). Não há teste das telas nem de integração
com o Firebase: elas se conferem à mão, numa partida com três jogadores.

## Arquitetura

```mermaid
flowchart LR
  T["Telas e widgets"] -->|ação do jogador| S["FirebaseService"]
  S -->|sala atual| R["lib/game/regras.dart"]
  R -->|sala nova| S
  S -->|transação| F[("Firestore: rooms/{código}")]
  F -->|snapshots| P["gameRoomProvider"]
  P --> D["providers derivados: jogador, juiz, fase"]
  D --> T
```

A tela nunca muda o próprio estado da partida: ela pede ao `FirebaseService`, que lê a sala,
aplica a regra e grava numa transação; a mudança volta para todos pelo stream.

### Fases da partida

`GamePhase`, em [`lib/models/game_room.dart`](../lib/models/game_room.dart):

```mermaid
stateDiagram-v2
  [*] --> waitingForPlayers
  waitingForPlayers --> playersSubmitting: iniciarJogo
  playersSubmitting --> judgeChoosing: última carta (enviarCarta)
  judgeChoosing --> roundResult: escolherVencedor
  judgeChoosing --> gameComplete: alguém chegou ao máximo de pontos
  roundResult --> playersSubmitting: proximaRodada (o juiz avança)
  gameComplete --> waitingForPlayers: jogarDeNovo (o anfitrião)
```

Uma carta preta pede uma branca por lacuna (`GameCard.pick`, de 1 a 3); cada jogador envia
essa quantidade, na ordem, e `submittedCards` guarda a lista. Salas gravadas antes da 0.3,
com uma carta por jogador, ainda são lidas.

Quando a última carta chega, a ordem da mesa é sorteada e gravada em `revealOrder`, para
todos verem as cartas na mesma ordem e ninguém saber quem enviou qual.

### Módulos

| arquivo | responsabilidade |
|---|---|
| [`lib/main.dart`](../lib/main.dart) | Inicializa o Firebase (com timeout de 30 s) e abre o app dentro do `ProviderScope`. |
| [`lib/firebase_options.dart`](../lib/firebase_options.dart) | Opções do Firebase por plataforma, geradas pelo FlutterFire CLI. |
| [`lib/models/`](../lib/models) | `GameCard`, `Player` e `GameRoom`, imutáveis, com `fromJson`/`toJson`/`copyWith`. `GamePhase` lista as fases da partida. |
| [`lib/game/regras.dart`](../lib/game/regras.dart) | As regras como funções puras: `novaSala` (que põe as `cartasEmBranco` no monte), `textoLivre` (confere o que foi escrito numa carta em branco), `entrarNaSala`, `sortearOutraCarinha`, `iniciarJogo`, `enviarCarta`, `trocarMao`, `escolherVencedor`, `proximaRodada`, `jogarDeNovo`, o sorteio do código da sala e `fraseCompleta` (a carta preta com as brancas no lugar das lacunas). Recebem a sala e devolvem a sala nova, ou lançam `JogadaInvalida`. |
| [`lib/game/convite.dart`](../lib/game/convite.dart) | O link de convite (`?sala=CÓDIGO`): ler o código do link, montar o link e o texto para colar no grupo. |
| [`lib/game/bots.dart`](../lib/game/bots.dart) | Os bots do modo solo (`bots`, cada um fã de um pacote), a jogada e o voto de cada um (`jogadaDoBot`, `votoDoBot`), `passoDosBots` (a próxima jogada de algum bot, ou nulo quando a vez é de uma pessoa) e `salaSolo`, a partida já começada. Também o Zé Aleatório (`zeAleatorio`, `chamarZe`, `dispensarZe`) e a pausa antes de cada jogada de bot (`pausaDosBots`). Funções puras, como as regras. |
| [`lib/game/baralho.dart`](../lib/game/baralho.dart) | O catálogo de pacotes (`pacotes`), a leitura de um pacote do JSON (`Baralho.fromJsonString`), a junção dos escolhidos num baralho só (`Baralho.juntar`) e de que pacote veio uma carta (`pacoteDaCarta`). |
| [`assets/baralhos/`](../assets/baralhos) | Um JSON por pacote. O Básico tem 31 pretas e 82 brancas; Brasilidades, Grupo da família, Firma, Rolê, Internet e Amor e desamor têm 25 pretas (4 de duas ou três lacunas) e 62 brancas cada. Sozinho, cada um dá para 8 jogadores com mão de 7. As regras de escrita estão em `test/game/baralho_test.dart`. |
| [`lib/providers/baralhos_provider.dart`](../lib/providers/baralhos_provider.dart) | Lê todos os pacotes dos assets uma vez, para a tela de criar sala mostrar e juntar os escolhidos. |
| [`lib/services/firebase_service.dart`](../lib/services/firebase_service.dart) | Login anônimo, criar sala (conferindo numa transação que o código está livre) e o stream da sala. Entrar na sala e as jogadas passam por `_alterarSala`, que roda a regra numa transação. |
| [`lib/services/mesa_local.dart`](../lib/services/mesa_local.dart) | As partidas solo, guardadas no aparelho. Código começa com `SOLO-`; o `FirebaseService` manda para cá as leituras e jogadas dessas salas. Depois de cada mudança, se for a vez de um bot, ele joga após uma pausa (1 a 2 s para enviar, quase 3 s para julgar, 5 s com o resultado na tela). |
| [`lib/widgets/maestro_dos_bots.dart`](../lib/widgets/maestro_dos_bots.dart) | Numa sala online com o Zé, o aparelho do anfitrião espera a pausa e grava a jogada do bot (`FirebaseService.jogadaDosBots`, numa transação que lê a sala de novo). Os outros aparelhos só veem a sala mudar. |
| [`lib/providers/auth_provider.dart`](../lib/providers/auth_provider.dart) | Stream do usuário logado. |
| [`lib/providers/game_provider.dart`](../lib/providers/game_provider.dart) | Código da sala atual, stream da sala e o que deriva dela: jogador atual, se é anfitrião, se é juiz, fase. |
| [`lib/screens/home_screen.dart`](../lib/screens/home_screen.dart) | Faz o login anônimo (três tentativas) e mostra criar/entrar; com uma sala escolhida, mostra a `GameScreen`. |
| [`lib/screens/game_screen.dart`](../lib/screens/game_screen.dart) | Escolhe o que mostrar pela fase da partida. |
| [`lib/screens/tutorial_screen.dart`](../lib/screens/tutorial_screen.dart) | O tutorial de três telas; abre sozinho na primeira visita (`tutorialPendente`) e pelo "Como jogar" (`abrirTutorial`). |
| [`lib/ui/tema.dart`](../lib/ui/tema.dart) | Tema claro e escuro: as cores (`Cores`), as medidas (`Medidas`) e a tipografia. Ver [DESIGN.md](DESIGN.md). |
| [`lib/ui/cartas.dart`](../lib/ui/cartas.dart) | `CartaPreta` (com a frase montada ao vivo), `CartaBranca` e `MaoEmLeque`, usadas em todas as telas. |
| [`lib/ui/jogadores.dart`](../lib/ui/jogadores.dart) | `AvatarDeJogador` (a carinha na cor do jogador, anel amarelo no juiz) e `AvisoDaVez` (a pílula de quem é a vez). |
| [`lib/ui/carinhas.dart`](../lib/ui/carinhas.dart) | As carinhas: `Carinha.de(id, variacao)` sorteia olhos, boca, enfeite e bochechas de forma estável (`misturar`, a mesma conta no celular e na web) e `PintorDeCarinha` desenha. |
| [`lib/ui/icones.dart`](../lib/ui/icones.dart) | `IconeFofo` e `PintorDeIcone`: os ícones do jogo desenhados no traço das carinhas, no lugar dos ícones do Material. |
| [`lib/ui/assombro.dart`](../lib/ui/assombro.dart) | Os momentos creepy: `ehMadrugada`, `esperaDaLacuna` e a hora em `agora()`, que os testes trocam. |
| [`lib/ui/animacoes.dart`](../lib/ui/animacoes.dart) | `Entrada`, `Virada` e `Confete`, todas respeitando "reduzir movimento". |
| [`lib/ui/sons.dart`](../lib/ui/sons.dart) | Que som cada mudança de fase toca (`somDaMudanca`, função pura), o tocador e o botão de mudo, lembrado entre partidas. |
| [`tool/gerar_sons.mjs`](../tool/gerar_sons.mjs) | Gera os `.wav` de `assets/sons/` por síntese. Rode com `node tool/gerar_sons.mjs`. |
| [`lib/widgets/`](../lib/widgets) | Lista de jogadores com pontos, carta preta, mão de cartas brancas, escolha do juiz, a mesa que os outros veem enquanto ele escolhe e o resultado da rodada. |

### Decisões que não são óbvias

- **Sem backend.** A regra do jogo roda no aparelho de quem faz a jogada e grava direto no
  documento da sala. É simples e barato, mas o servidor não impede trapaça (ver o roadmap).
- **Regra pura, gravada em transação.** Dois jogadores enviam carta quase ao mesmo tempo; a
  transação do Firestore repete a regra com a sala atualizada e nenhuma jogada se perde. A
  regra não sabe de Firebase, então é testada sem ele.
- **Uma sala, um documento, inclusive as mãos.** É o jeito mais simples de todo mundo ver o
  mesmo estado, mas qualquer jogador consegue ler a mão dos outros pelo Firestore (ver o
  roadmap).
- **As cartas jogadas voltam ao fim do monte.** Assim o baralho não acaba em partidas
  longas; uma carta pode reaparecer depois de o monte dar a volta.
- **Login anônimo.** Ninguém cria conta para jogar; o `uid` anônimo identifica o jogador
  na sala. Sair do app com logout gera outro `uid`, ou seja, outro jogador.
- **Navegação pela sala, não por rota.** A `HomeScreen` mostra a `GameScreen` quando
  `roomIdProvider` tem valor; limpar o provider volta ao início.

### Limites conhecidos

Os principais, todos com item no [roadmap](ROADMAP.md):

- O macOS não tem app registrado no Firebase e para na inicialização.
- O projeto iOS não tem `Runner.xcodeproj`, então não compila.
- O build Android usa o formato antigo do plugin do Flutter e o Gradle 8.10, que não roda
  com JDK 25.

## Releases

O [release-please](https://github.com/googleapis/release-please) lê os Conventional
Commits da `main` e mantém um PR de release com o `CHANGELOG.md` e a versão nova no
`pubspec.yaml`. O merge desse PR cria a tag `vX.Y.Z` e a Release no GitHub.

A web é publicada em https://cartaralho.web.app a cada merge na `main` pelo workflow
`deploy-web.yml` (detalhes e o segredo que ele precisa em [FIREBASE.md](FIREBASE.md#publicar-a-web)).
Ainda não há build de Android nem de iOS no CI, nem publicação em loja.

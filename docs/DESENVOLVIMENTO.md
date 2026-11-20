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
| [`lib/game/regras.dart`](../lib/game/regras.dart) | As regras como funções puras: `novaSala`, `entrarNaSala`, `iniciarJogo`, `enviarCarta`, `trocarMao`, `escolherVencedor`, `proximaRodada`, `jogarDeNovo`, o sorteio do código da sala e `fraseCompleta` (a carta preta com as brancas no lugar das lacunas). Recebem a sala e devolvem a sala nova, ou lançam `JogadaInvalida`. |
| [`lib/game/baralho.dart`](../lib/game/baralho.dart) | Lê o baralho do JSON (`Baralho.fromJsonString`). |
| [`assets/baralhos/basico.json`](../assets/baralhos/basico.json) | As cartas com que toda sala começa: 31 pretas (6 de duas ou três lacunas) e 82 brancas, para até 8 jogadores com mão de 7. As regras de escrita estão no próprio arquivo e em `test/game/baralho_test.dart`. |
| [`lib/services/firebase_service.dart`](../lib/services/firebase_service.dart) | Login anônimo, criar sala (conferindo numa transação que o código está livre) e o stream da sala. Entrar na sala e as jogadas passam por `_alterarSala`, que roda a regra numa transação. |
| [`lib/providers/auth_provider.dart`](../lib/providers/auth_provider.dart) | Stream do usuário logado. |
| [`lib/providers/game_provider.dart`](../lib/providers/game_provider.dart) | Código da sala atual, stream da sala e o que deriva dela: jogador atual, se é anfitrião, se é juiz, fase. |
| [`lib/screens/home_screen.dart`](../lib/screens/home_screen.dart) | Faz o login anônimo (três tentativas) e mostra criar/entrar; com uma sala escolhida, mostra a `GameScreen`. |
| [`lib/screens/game_screen.dart`](../lib/screens/game_screen.dart) | Escolhe o que mostrar pela fase da partida. |
| [`lib/ui/tema.dart`](../lib/ui/tema.dart) | Tema claro e escuro: as cores (`Cores`), as medidas (`Medidas`) e a tipografia. Ver [DESIGN.md](DESIGN.md). |
| [`lib/ui/cartas.dart`](../lib/ui/cartas.dart) | `CartaPreta`, `CartaBranca` e `GradeDeCartas`, usadas em todas as telas. |
| [`lib/ui/animacoes.dart`](../lib/ui/animacoes.dart) | `Entrada`, `Virada` e `Confete`, todas respeitando "reduzir movimento". |
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
`pubspec.yaml`. O merge desse PR cria a tag `vX.Y.Z` e a Release no GitHub. Ainda não há
build de Android, iOS ou web na tag nem publicação em loja.

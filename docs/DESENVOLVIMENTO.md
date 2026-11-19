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

Para testar uma partida sozinho, abra três abas do navegador: cada aba faz o próprio login
anônimo e vira um jogador diferente.

### Testes

`test/` cobre o que é código puro: a conversão dos modelos para o formato do Firestore. Não
há teste de tela nem de integração com o Firebase; o fluxo da partida se confere à mão, com
três jogadores.

## Arquitetura

```mermaid
flowchart LR
  T["Telas e widgets"] -->|ação do jogador| S["FirebaseService"]
  S -->|grava| F[("Firestore: rooms/{código}")]
  F -->|snapshots| P["gameRoomProvider"]
  P --> D["providers derivados: jogador, juiz, fase"]
  D --> T
```

A tela nunca muda o próprio estado da partida: ela pede ao `FirebaseService`, o documento
muda no Firestore e a mudança volta para todos pelo stream.

### Módulos

| arquivo | responsabilidade |
|---|---|
| [`lib/main.dart`](../lib/main.dart) | Inicializa o Firebase (com timeout de 30 s) e abre o app dentro do `ProviderScope`. |
| [`lib/firebase_options.dart`](../lib/firebase_options.dart) | Opções do Firebase por plataforma, geradas pelo FlutterFire CLI. |
| [`lib/models/`](../lib/models) | `GameCard`, `Player` e `GameRoom`, imutáveis, com `fromJson`/`toJson`/`copyWith`. `GamePhase` lista as fases da partida. |
| [`lib/services/firebase_service.dart`](../lib/services/firebase_service.dart) | Login anônimo, criar e entrar em sala, iniciar o jogo, enviar carta, escolher o vencedor. Também guarda o baralho inicial. |
| [`lib/providers/auth_provider.dart`](../lib/providers/auth_provider.dart) | Stream do usuário logado. |
| [`lib/providers/game_provider.dart`](../lib/providers/game_provider.dart) | Código da sala atual, stream da sala e o que deriva dela: jogador atual, se é anfitrião, se é juiz, fase. |
| [`lib/screens/home_screen.dart`](../lib/screens/home_screen.dart) | Faz o login anônimo (três tentativas) e mostra criar/entrar; com uma sala escolhida, mostra a `GameScreen`. |
| [`lib/screens/game_screen.dart`](../lib/screens/game_screen.dart) | Escolhe o que mostrar pela fase da partida. |
| [`lib/widgets/`](../lib/widgets) | Lista de jogadores com pontos, carta preta, mão de cartas brancas, escolha do juiz. |

### Decisões que não são óbvias

- **Sem backend.** A regra do jogo roda no aparelho de quem faz a jogada e grava direto no
  documento da sala. É simples e barato, mas o servidor não impede trapaça (ver o roadmap).
- **Login anônimo.** Ninguém cria conta para jogar; o `uid` anônimo identifica o jogador
  na sala. Sair do app com logout gera outro `uid`, ou seja, outro jogador.
- **Navegação pela sala, não por rota.** A `HomeScreen` mostra a `GameScreen` quando
  `roomIdProvider` tem valor; limpar o provider volta ao início.

### Limites conhecidos

Os principais, todos com item no [roadmap](ROADMAP.md):

- A partida não passa da primeira rodada: nada leva a sala da fase `choosingBlackCard` para
  `playersSubmitting`.
- A mão de cada jogador é sorteada de novo a cada redesenho da tela e não fica gravada.
- O juiz não roda: `isJudge` nunca muda, então o jogador seguinte é sempre o mesmo.
- Na web, `DefaultFirebaseOptions` não tem opções e o login falha; no iOS e no macOS as
  opções são de exemplo, de outro projeto.
- O projeto iOS não tem `Runner.xcodeproj`, então não compila.
- O build Android usa o formato antigo do plugin do Flutter e o Gradle 8.10, que não roda
  com JDK 25.

## Releases

O [release-please](https://github.com/googleapis/release-please) lê os Conventional
Commits da `main` e mantém um PR de release com o `CHANGELOG.md` e a versão nova no
`pubspec.yaml`. O merge desse PR cria a tag `vX.Y.Z` e a Release no GitHub. Ainda não há
build de Android, iOS ou web na tag nem publicação em loja.

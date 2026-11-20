# AGENTS.md

Orientação para agentes de IA e contribuidores do **Cartaralho**: jogo de cartas para
grupos, em Flutter, com as salas sincronizadas em tempo real pelo Firestore.

## Layout

```
lib/
  main.dart             inicializa o Firebase e abre a HomeScreen dentro do ProviderScope
  firebase_options.dart opções do Firebase por plataforma (gerado pelo FlutterFire CLI)
  game/                 regras da partida (funções puras) e o baralho inicial
  models/               GameCard, Player, GameRoom: dados e conversão para o Firestore
  services/             FirebaseService: login anônimo e todas as leituras e escritas da sala
  providers/            providers Riverpod: usuário logado, sala atual, jogador atual
  screens/              telas: início, criar sala, entrar na sala, jogo
  widgets/              peças da tela de jogo: jogadores, carta preta, mão, escolha do juiz
  ui/                   tema (cores, medidas, fontes) e os componentes de carta
test/                   testes (flutter_test), espelhando lib/
assets/baralhos/        as cartas do jogo, em JSON
docs/                   documentação longa, roadmap e imagens
android/ ios/ macos/ web/  projetos de plataforma
```

## Stack

- **Flutter 3.50** (fixado no CI). Material 3, interface só em português.
- **Riverpod 2** (`flutter_riverpod`): estado com `Provider`, `StateProvider` e
  `StreamProvider`, sem geração de código.
- **Firebase**: Auth anônima e um documento por sala na coleção `rooms` do Firestore. Não
  há backend próprio: toda regra roda no app e o documento da sala é a fonte da verdade.

## Convenções

- Modelos são imutáveis, com `fromJson`, `toJson` e `copyWith`. Campo novo no modelo entra
  nos três e tem padrão no `fromJson`, porque salas antigas no Firestore não têm o campo.
- Enum vai para o Firestore pelo nome (`'black'`, `'judgeChoosing'`), nunca pelo índice.
- Telas não falam com o Firestore direto: chamam o `FirebaseService`.
- Regra do jogo é função pura em `lib/game/regras.dart`: recebe a `GameRoom`, devolve a
  `GameRoom` nova ou lança `JogadaInvalida`. Nada de Firebase nem de `DateTime.now()` lá
  dentro; sorteio recebe um `Random` opcional, para o teste fixar a semente.
- Quem é o juiz vem de `GameRoom.currentJudgeId` (`room.isJudge(id)`), não de um campo
  do jogador.
- Cor só pelo tema: `Cores.de(context).mesa`, `.carta`, `.cartaPreta`... Nada de
  `Color(0x...)` nem `Colors.xxx` (fora `Colors.transparent`) em tela ou widget. Carta se
  desenha com `CartaPreta` e `CartaBranca` (`lib/ui/cartas.dart`). Regras visuais em
  `docs/DESIGN.md`.
- Texto de interface em português do Brasil. Comentário explica por quê, não o quê.

## Adicionando uma jogada

1. Escreva a regra em `lib/game/regras.dart`, validando fase e jogador com `JogadaInvalida`.
2. Teste em `test/game/regras_test.dart`: o caminho certo e cada recusa.
3. No `FirebaseService`, um método que chama `_alterarSala(roomId, (sala) => regra(...))`.
4. Na tela, chame o método e mostre o erro num `SnackBar`.
5. Campo novo na sala? `fromJson` com padrão, `toJson`, `copyWith` e o teste em
   `test/models/`.
6. Atualize `docs/DESENVOLVIMENTO.md` e rode `flutter analyze` e `flutter test`.

## Editando as cartas

1. Edite `assets/baralhos/basico.json`: `pretas` têm de uma a três lacunas `____`;
   `brancas` começam com minúscula (salvo nome próprio) e não terminam em ponto.
2. Rode `flutter test test/game/baralho_test.dart`, que confere essas regras e se há
   brancas para 8 jogadores com mão de 7.
3. Os ids saem da posição (`b1`, `w1`...): trocar a ordem muda os ids, o que não afeta
   salas novas.

## Comandos

```bash
flutter pub get
flutter run -d chrome
flutter analyze
dart format lib test
flutter test
flutter build web
dart run flutter_launcher_icons   # regera os ícones depois de trocar o logo
```

## Faça / Não faça

| Faça | Não faça |
|---|---|
| Mudar o documento da sala numa transação quando o valor novo depende do lido | Ler, montar a lista e gravar com `update` em duas etapas (dois jogadores ao mesmo tempo perdem um) |
| Dar padrão a todo campo novo no `fromJson` | Supor que o documento da sala sempre tem o campo |
| Rodar `flutter analyze` e `flutter test` antes de dizer que terminou | Editar `CHANGELOG.md`, `ios/Flutter/Generated.xcconfig` ou `GeneratedPluginRegistrant.*` (gerados) |

## Armadilhas

- `flutter test` quebra com `FileSystemException: Cannot resolve symbolic links` no
  Windows → o caminho do SDK ou do projeto tem acento (como `C:\Users\João`). Mapeie uma
  letra com `subst P: <pasta>` e rode a partir dela.
- Três abas abertas no mesmo endereço viram o mesmo jogador → o login anônimo é guardado
  por origem. Use `localhost`, `a.localhost` e `b.localhost`, ou uma janela anônima.
- `flutter analyze` não mostra uso de API obsoleta → o aviso está desligado no
  `analysis_options.yaml` até a migração para `material_ui`; tire a linha para conferir.

## Workflow

- Commits em Conventional Commits, em português, uma ideia por commit. Escopos no
  [CONTRIBUTING](CONTRIBUTING.md#commits).
- Uma branch e um PR por mudança; docs atualizadas no mesmo PR.
- Antes de dizer que terminou: `flutter analyze`, `dart format lib test`, `flutter test`, e
  diga o que não foi verificado (partida real, Android, iOS).
- Mudou a estrutura, um comando ou uma convenção? Atualize este arquivo.

# AGENTS.md

Orientação para agentes de IA e contribuidores do **Cartaralho**: jogo de cartas para
grupos, em Flutter, com as salas sincronizadas em tempo real pelo Firestore.

## Layout

```
lib/
  main.dart             inicializa o Firebase e abre a HomeScreen dentro do ProviderScope
  firebase_options.dart opções do Firebase por plataforma (gerado pelo FlutterFire CLI)
  game/                 regras da partida (funções puras) e os pacotes de cartas
  models/               GameCard, Player, GameRoom: dados e conversão para o Firestore
  services/             FirebaseService: login anônimo e todas as leituras e escritas da sala
  providers/            providers Riverpod: usuário logado, sala atual, jogador atual
  screens/              telas: início, criar sala, entrar na sala, jogo
  widgets/              peças da tela de jogo: jogadores, carta preta, mão, escolha do juiz
  ui/                   tema (cores, medidas, fonte), cartas, carinhas, ícones, animações,
                        sons e os momentos creepy (assombro.dart)
test/                   testes (flutter_test), espelhando lib/
assets/baralhos/        as cartas do jogo, um JSON por pacote
assets/sons/            efeitos sonoros (.wav), gerados por tool/gerar_sons.mjs
tool/                   scripts de apoio (Node), fora do app
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
- Cor só pelo tema: `Cores.de(context).mesa`, `.acao`, `.carta`... Nada de
  `Color(0x...)` nem `Colors.xxx` (fora `Colors.transparent`) em tela ou widget. Carta se
  desenha com `CartaPreta` e `CartaBranca` (`lib/ui/cartas.dart`). Regras visuais em
  `docs/DESIGN.md`.
- Ícone é `IconeFofo(Desenho.xxx)` (`lib/ui/icones.dart`), não `Icons.xxx`. Precisa de um
  novo? Desenhe no mesmo traço e com olhinhos, se couber.
- Rótulo de botão em frase normal ("Criar sala", "Enviar carta"), nunca em Caixa De Título.
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

1. Cada pacote é um `assets/baralhos/<id>.json` (`nome`, `descricao`, `pretas`, `brancas`).
   `pretas` têm de uma a três lacunas `____`, sem preposição que contrai antes dela (`de`,
   `em`, `por`, `a`) e sem letra colada nela; `brancas` começam com minúscula (salvo nome
   próprio) e não terminam em ponto.
2. Pacote novo entra também na lista `pacotes` de `lib/game/baralho.dart`.
3. Rode `flutter test test/game/baralho_test.dart`, que confere essas regras, se cada pacote
   sozinho tem brancas para 8 jogadores com mão de 7 e se nenhum texto se repete entre
   pacotes.
4. Os ids saem do pacote e da posição (`firma-b1`, `firma-w1`): trocar a ordem muda os ids,
   o que não afeta salas novas. O prefixo diz de que pacote a carta veio
   (`pacoteDaCarta`).

## Comandos

```bash
flutter pub get
flutter run -d chrome
flutter analyze
dart format lib test
flutter test
flutter build web
dart run flutter_launcher_icons   # regera os ícones depois de trocar o logo
node tool/gerar_sons.mjs          # regera os sons depois de mexer no script
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

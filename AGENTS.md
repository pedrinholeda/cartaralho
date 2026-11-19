# AGENTS.md

Orientação para agentes de IA e contribuidores do **Cartaralho**: jogo de cartas para
grupos, em Flutter, com as salas sincronizadas em tempo real pelo Firestore.

## Layout

```
lib/
  main.dart             inicializa o Firebase e abre a HomeScreen dentro do ProviderScope
  firebase_options.dart opções do Firebase por plataforma (gerado pelo FlutterFire CLI)
  models/               GameCard, Player, GameRoom: dados e conversão para o Firestore
  services/             FirebaseService: login anônimo e todas as leituras e escritas da sala
  providers/            providers Riverpod: usuário logado, sala atual, jogador atual
  screens/              telas: início, criar sala, entrar na sala, jogo
  widgets/              peças da tela de jogo: jogadores, carta preta, mão, escolha do juiz
test/                   testes (flutter_test), espelhando lib/
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
- Texto de interface em português do Brasil. Comentário explica por quê, não o quê.

## Comandos

```bash
flutter pub get
flutter run -d chrome
flutter analyze
dart format lib test
flutter test
flutter build web
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
- `flutter analyze` não mostra uso de API obsoleta → o aviso está desligado no
  `analysis_options.yaml` até a migração para `material_ui`; tire a linha para conferir.

## Workflow

- Commits em Conventional Commits, em português, uma ideia por commit. Escopos no
  [CONTRIBUTING](CONTRIBUTING.md#commits).
- Uma branch e um PR por mudança; docs atualizadas no mesmo PR.
- Antes de dizer que terminou: `flutter analyze`, `dart format lib test`, `flutter test`, e
  diga o que não foi verificado (partida real, Android, iOS).
- Mudou a estrutura, um comando ou uma convenção? Atualize este arquivo.

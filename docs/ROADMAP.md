# Roadmap

Primeiro o que impede uma partida de chegar ao fim, depois as plataformas que não
compilam ou não conectam, depois segurança e robustez, e por último conteúdo e acabamento.
Cada item vira um ou mais PRs e uma entrada no [CHANGELOG](../CHANGELOG.md).

Legenda: `[ ]` pendente · `[x]` feito

## Fase 0 — organização do repositório

- [x] **Higiene**: `.gitignore` e `.gitattributes`, arquivos gerados e `build/` fora do
  git, propostas de logo em `docs/marca/`, `main_simple.dart` removido
- [x] **Lint** zerado, dependências sem uso removidas, teste quebrado do modelo removido
- [x] **Testes** dos modelos no formato do Firestore
- [x] **CI** com lint, formatação, testes e build web; **release-please**
- [x] **Docs**: README, CONTRIBUTING, AGENTS.md, LICENSE, `docs/`, regras do Firestore
  versionadas

## Fase 1 — partida jogável do começo ao fim

- [x] **A rodada sai da primeira fase**: `startGame` grava `choosingBlackCard` e nada leva
  a sala para `playersSubmitting`, então ninguém consegue enviar carta
- [x] **O juiz só escolhe quando todos enviaram**: `submitWhiteCard` passa para
  `judgeChoosing` já na primeira carta
- [x] **Mão de cartas gravada**: a mão é sorteada de novo a cada redesenho
  (`WhiteCardsWidget._playerWhiteCards`) e duas pessoas podem ter a mesma carta
- [x] **Juiz roda entre os jogadores**: `chooseWinner` atualiza `currentJudgeId` mas não
  `isJudge`, que é o que a tela lê, e calcula o próximo a partir de `isJudge`
- [x] **Regras do jogo como funções puras e testadas**, chamadas pelo `FirebaseService`
  dentro de transação
- [ ] **Código de sala aleatório**: `_generateRoomId` usa o relógio e gera letras
  consecutivas (`ABCDEF`, `BCDEFG`); duas salas no mesmo milissegundo colidem
- [ ] **Entrar na sala sem perder jogador**: `joinRoom` lê e grava em dois passos, e duas
  entradas ao mesmo tempo apagam uma; também deixa entrar depois que o jogo começou
- [ ] **Web conecta ao Firebase**: `DefaultFirebaseOptions` lança erro na web; o
  `web/index.html` carrega à toa o SDK JS compat 9.0.0
- [ ] **iOS e macOS com as opções reais**: `firebase_options.dart` tem valores de exemplo
  de outro projeto (`cartaralho-app`), diferentes do `GoogleService-Info.plist`
- [x] **Baralho para até 8 jogadores**: eram 15 brancas e cada mão tem 5, então mais de três
  jogadores não começavam

## Fase 2 — plataformas

- [ ] **Projeto iOS completo**: falta o `Runner.xcodeproj` (recriar com
  `flutter create --platforms=ios .` e conferir num Mac)
- [ ] **Gradle moderno**: `android/` usa `apply from: flutter.gradle` (formato antigo) e
  Gradle 8.10, que não roda com JDK 25; o build de release assina com a chave de debug
- [ ] Build de Android e web no CI e na tag de release
- [ ] `web/index.html` no formato atual (`flutter_bootstrap.js`), ícones e cores do
  `manifest.json`

## Fase 3 — segurança e robustez

- [ ] **Regras do Firestore de verdade**: hoje qualquer usuário logado grava qualquer
  sala; restringir a membros e validar a mudança de fase
- [ ] **Mão escondida dos outros jogadores**: enquanto tudo vive num documento, todos podem
  ler as mãos; mover para uma subcoleção por jogador
- [ ] **Sair da sala**: o botão de sair faz logout (o jogador vira outro `uid`) e não tira
  o jogador da sala
- [ ] Mensagens de erro legíveis (hoje aparece `Erro: Exception: Erro ao ...: Exception:`)
- [ ] Log com `debugPrint` ou um logger no lugar de `print`
- [ ] Apagar salas antigas (TTL do Firestore)
- [ ] Testes de widget das telas principais

## Fase 4 — conteúdo e acabamento

- [ ] Baralho num arquivo JSON em `assets/`, fora do código; baralhos customizados
- [ ] Cores e tamanhos como tema (hoje `0xFF6A1B9A` se repete em cada tela) e tema escuro
- [ ] Escolher o logo entre as propostas em [`docs/marca/`](marca) e gerar os ícones do app
- [ ] Migrar de `package:flutter/material.dart` para `material_ui` e religar o aviso de
  API obsoleta no `analysis_options.yaml`
- [ ] Atualizar Firebase (`firebase_core` 2 → atual) e Riverpod 3

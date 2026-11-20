# Roadmap

Primeiro o que impede uma partida de chegar ao fim. Com o jogo rodando na web, vêm a
jogabilidade e as cartas (o que deixa a partida divertida), depois o redesign, ainda só na
web. As plataformas nativas, a segurança e a manutenção ficam para depois que o jogo estiver
gostoso de jogar.
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
- [x] **Código de sala aleatório**: `_generateRoomId` usa o relógio e gera letras
  consecutivas (`ABCDEF`, `BCDEFG`); duas salas no mesmo milissegundo colidem
- [x] **Entrar na sala sem perder jogador**: `joinRoom` lê e grava em dois passos, e duas
  entradas ao mesmo tempo apagam uma; também deixa entrar depois que o jogo começou
- [x] **Web conecta ao Firebase**: `DefaultFirebaseOptions` lança erro na web; o
  `web/index.html` carrega à toa o SDK JS compat 9.0.0
- [x] **iOS com as opções reais**: `firebase_options.dart` tinha valores de exemplo de outro
  projeto (`cartaralho-app`), diferentes do `GoogleService-Info.plist`
- [x] **A página web carrega**: o `index.html` só incluía `flutter.js`, que não inicia o app
  no Flutter atual (achado no teste no navegador)
- [x] **Baralho para até 8 jogadores**: eram 15 brancas e cada mão tem 5, então mais de três
  jogadores não começavam

## Fase 2 — jogabilidade e cartas

O que hoje atrapalha uma partida entre amigos, achado jogando e lendo o código.

- [x] **Cartas pretas com mais de um espaço** ("Escolha 2"): o jogo só aceitava uma carta
  branca por jogador. Agora a carta preta conta as lacunas, o jogador escolhe na ordem e vê
  a frase montada, e o juiz vê o conjunto
- [x] **Resultado da rodada**: o juiz escolhe e a tela já pula para a rodada seguinte;
  ninguém vê qual carta ganhou nem quem a jogou (`lastRoundWinnerId` é gravado e nunca
  mostrado). Uma fase curta de resultado, com a frase completa e o nome do vencedor
- [x] **Todos veem as cartas enviadas** enquanto o juiz escolhe (hoje só o juiz vê), para o
  grupo ler e rir junto
- [x] **Ordem das cartas embaralhada para o juiz**: hoje vêm na ordem do id de quem enviou,
  sempre igual, e o juiz aprende quem é quem depois de algumas rodadas
- [x] **Frase completa na carta**: a carta preta com as brancas encaixadas nos espaços, na
  escolha do jogador, na do juiz, na mesa e no resultado
- [x] **Configurar a partida** ao criar a sala: pontos para vencer (3, 5, 7 ou 10) e
  tamanho da mão (5 ou 7)
- [x] **Trocar cartas**: uma vez por partida, descartar a mão e pegar outra, para quem tirou
  só carta ruim
- [x] **Jogar de novo** com o mesmo grupo, zerando o placar, em vez de "Voltar ao Menu"
- [ ] **Revisão do baralho**: mais cartas pretas (com 15, elas se repetem depois de 15
  rodadas), cartas brancas mais engraçadas e menos genéricas ("Música", "Tecnologia"),
  e regras de texto (uma lacuna por espaço, sem ponto final duplo, tamanho máximo). As
  brancas começam com maiúscula e ficam estranhas no meio da frase ("meu problema é Uma
  planilha de Excel"): escrever em minúscula, salvo nome próprio, e pôr maiúscula quando a
  lacuna abre a frase
- [ ] Baralho num arquivo JSON em `assets/`, fora do código, validado por teste;
  baralhos customizados depois

## Fase 3 — redesign (web primeiro)

Deixar o jogo bonito e animado. Tudo testado no navegador, em tela de celular e de
computador, no tema claro e no escuro, com print no PR.

- [ ] **Identidade**: escolher o logo entre as propostas em [`docs/marca/`](marca) e tirar
  dele a paleta (vermelho, preto e branco das cartas) e a tipografia; ícones e cores do
  `manifest.json` da web
- [ ] **Tema e tokens**: cores, espaçamentos, raios e tipografia num `ThemeData` próprio
  (hoje `0xFF6A1B9A` se repete em cada tela) e tema escuro; registrar em `docs/DESIGN.md`
- [ ] **Cartas com cara de carta**: proporção de carta de baralho, carta preta e branca com
  estilo próprio, a lacuna desenhada como linha
- [ ] **Animações**: cartas sendo distribuídas, a carta enviada voando para a mesa, as cartas
  virando para o juiz, transição entre as fases e a revelação do vencedor com confete
- [ ] **Efeitos sonoros** curtos (distribuir, enviar, virar, vencer a rodada, vencer o jogo),
  com botão de mudo lembrado entre partidas. Na web o navegador só toca som depois do
  primeiro toque na página, então o primeiro som vem depois de "Criar Sala" ou "Entrar na
  Sala". Sons com licença livre (CC0), guardados em `assets/sons/` com a origem anotada
- [ ] **Sala de espera viva**: código grande com botão de copiar e de compartilhar o link,
  jogadores aparecendo conforme entram
- [ ] **Cartão do juiz na lista de jogadores**: a estrela some (âmbar sobre âmbar) e o rótulo
  "JUIZ" vaza para fora do cartão de 80 px (achado no teste no navegador)
- [ ] **Layout de computador**: hoje a tela é de celular esticada; mão em leque e mesa no
  centro em tela larga
- [ ] **Acessibilidade**: as cartas brancas não têm rótulo de acessibilidade (o teste de
  ponta a ponta precisou de clique forçado), contraste revisado, animações respeitando
  "reduzir movimento"

## Fase 4 — plataformas

- [ ] **Projeto iOS completo**: falta o `Runner.xcodeproj` (recriar com
  `flutter create --platforms=ios .` e conferir num Mac)
- [ ] **Gradle moderno**: `android/` usa `apply from: flutter.gradle` (formato antigo) e
  Gradle 8.10, que não roda com JDK 25; o build de release assina com a chave de debug
- [ ] Build de Android e web no CI e na tag de release; publicar a web (Firebase Hosting)
- [ ] macOS: registrar o app no Firebase ou tirar a pasta `macos/`

## Fase 5 — segurança e robustez

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
- [ ] Teste de ponta a ponta no CI: uma partida com três jogadores contra o emulador do
  Firestore

## Fase 6 — manutenção

- [ ] Migrar de `package:flutter/material.dart` para `material_ui` e religar o aviso de
  API obsoleta no `analysis_options.yaml`
- [ ] Atualizar Firebase (`firebase_core` 2 → atual) e Riverpod 3

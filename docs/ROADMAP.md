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
- [x] **Revisão do baralho**: 31 pretas (eram 15 e se repetiam depois de 15 rodadas), 82
  brancas menos genéricas, escritas em minúscula salvo nome próprio, com maiúscula automática
  quando a lacuna abre a frase (antes saía "meu problema é Uma planilha de Excel"). Regras
  do arquivo conferidas por teste; tamanho máximo do texto ainda não
- [x] **Baralho num arquivo JSON** em `assets/baralhos/basico.json`, fora do código, validado
  por teste
- [x] **Cartas sem contração errada**: "fala de ____" virava "fala de o cunhado"; as cartas
  foram reescritas e um teste recusa preposição contraível antes da lacuna (achado no teste
  no navegador)
- [x] Escolher os baralhos ao criar a sala (na [Fase 3c](#fase-3c--mais-cartas-e-jogo-para-poucos))
- [ ] Criar o próprio baralho dentro do jogo

## Fase 3 — redesign (web primeiro)

Deixar o jogo bonito e animado. Tudo testado no navegador, em tela de celular e de
computador, com print no PR. A primeira versão (mesa vermelha, 0.4 e 0.5) foi refeita na
fase 3b.

- [x] **Identidade**: paleta e tipografia (vermelho, preto e branco dos logos, Archivo), logo
  escolhido (`docs/marca/logo-carta-escura.png`) e ícones da web e do Android gerados dele;
  o `manifest.json` apontava para ícones que não existiam
- [x] **Tema e tokens**: cores, espaçamentos, raios e tipografia em `lib/ui/tema.dart`, tema
  escuro, e tudo registrado em [`docs/DESIGN.md`](DESIGN.md)
- [x] **Cartas com cara de carta**: proporção de carta de baralho, carta preta e branca com
  estilo próprio, a lacuna desenhada como linha
- [x] **Animações**: cartas sendo distribuídas, a carta enviada voando para a mesa, as cartas
  virando para o juiz, transição entre as fases e a revelação do vencedor com confete
- [x] **Efeitos sonoros** curtos (distribuir, enviar, virar, vencer a rodada, vencer o jogo),
  com botão de mudo lembrado entre partidas. Em vez de sons de terceiros, gerados por
  `tool/gerar_sons.mjs`, sem licença a conferir
- [x] **Sala de espera viva**: código grande, botões de copiar o código e o convite (um link
  `?sala=CÓDIGO` que abre o jogo na tela de entrar com o código preenchido), e os jogadores
  aparecendo conforme entram
- [x] **Cartão do juiz na lista de jogadores**: a estrela sumia (âmbar sobre âmbar) e o rótulo
  "JUIZ" vazava do cartão; agora é uma ficha amarela com martelo
- [x] **Layout de computador**: a partir de 900 px, carta preta e placar à esquerda e a jogada
  à direita; a mão usa mais colunas. A mão em leque ficou de fora: a grade já resolve
- [x] **Acessibilidade**: cartas, placar e carta preta com rótulo; cartas escolhidas pelo
  teclado (Tab até a carta, Enter ou Espaço), com contorno amarelo de foco; contraste das
  cores do tema conferido por teste (WCAG AA); animações respeitam "reduzir movimento"

## Fase 3b — Noite de jogo

A mesa vermelha ainda tinha cara de app Android básico: componentes padrão do Material,
vermelho demais, amarelo berrante, mão em grade com metade da tela vazia e ninguém
explicando o jogo. Entre três direções desenhadas, a escolhida foi a Noite de jogo
([DESIGN.md](DESIGN.md)).

- [x] **Mesa escura** com as cartas em destaque, vermelho só na ação e amarelo no juiz;
  um tema só; contraste conferido por teste
- [x] **Figtree** no lugar da Archivo; botões em frase normal, mais altos, que encolhem ao
  apertar
- [x] **Placar de avatares** com a inicial na cor de cada jogador e o juiz com anel amarelo
- [x] **Aviso de quem é a vez** embaixo do placar
- [x] **Frase montada ao vivo** na carta preta enquanto o jogador escolhe
- [x] **Mão em leque** que se arrasta, com o botão de enviar fixo embaixo
- [x] **Sala de espera** com o código num painel, convite em destaque e lugares vazios até o
  mínimo
- [x] **Tutorial** de três telas, na primeira visita e pelo "Como jogar" na capa e "?" no jogo
- [x] Vibração leve ao escolher e enviar carta (no celular)
- [x] **Dicas na primeira partida**: um balão amarelo sobre a mão ("toque numa carta"), outro
  sobre o botão de enviar quando a carta está escolhida e um para o juiz; cada um aparece uma
  vez por aparelho e some quando a pessoa faz o que ele pede ou toca em "Entendi"
- [x] **Sons medidos e ajustados**: `tool/medir_sons.mjs` mede volume, pico e pontas sem
  precisar ouvir. Os sons frequentes ficaram mais discretos (-16 dBFS), a rodada no meio
  (-14) e a vitória, que estava a mais baixa, mais alta (-11); as notas terminam com fade e
  todo som começa e acaba no zero. Um teste confere os arquivos
- [ ] Ouvir os sons num celular de verdade (o ajuste foi por medida; ninguém ouviu ainda)
- [x] **Layout de duas colunas revisado**: no computador o placar vira lista (nome inteiro e
  pontos), a carta preta ganha letra maior na coluna dela e as cartas da mão crescem (168 px)
  quando a mão tem 640 px ou mais

## Fase 3c — mais cartas e jogo para poucos

Com 31 pretas, as frases se repetiam em uma ou duas partidas; e o jogo pedia três pessoas,
cada uma com o seu celular. Ideias vindas de outros jogos do gênero e das regras caseiras
que a turma inventa. Nenhuma carta é copiada de outro jogo: as licenças deles não combinam
com a MIT, e o humor tem que ser daqui.

- [x] **Baralhos temáticos**: seis pacotes novos (Brasilidades, Grupo da família, Firma,
  Rolê, Internet, Amor e desamor), 25 pretas e 62 brancas cada, escolhidos ao criar a sala;
  todos vêm marcados. Teste confere cada pacote e que nenhum texto se repete entre eles
- [x] **Pacotes Para toda a família e Sem filtro (+18)**: o primeiro sem palavrão nem
  baixaria; o segundo com sexo e bebida, fora dos marcados por padrão, com confirmação ao
  marcar ("Todo mundo topa?") e fora do modo solo. Humor adulto, mas sem preconceito e sem
  nada que envolva falta de consentimento
- [x] **Carta em branco**: o monte de toda sala ganha cartas em branco (uma para cada 12
  brancas, ao menos 4); quem tira uma escreve a resposta (até 60 caracteres) e ela vai para
  a mesa com o texto; depois da rodada volta vazia. Os bots só jogam a em branco sem saída
- [x] **Carinhas**: cada jogador ganha uma carinha desenhada pelo jogo (olhos, boca, enfeite
  e bochechas sorteados pelo id, 1.024 combinações), a mesma em todos os aparelhos, com
  "Sortear outra carinha" na sala de espera
- [x] **Fofo por fora, ácido por dentro**: ícones desenhados no traço das carinhas, com
  olhinhos; capa com carinhas espiando; sala de espera com lugares vazios que olham. E três
  sustos pequenos: carinhas assombradas na madrugada, a lacuna que abre um olho para quem
  demora e a coroa que derrete no fim de jogo. Direção desenhada num canva antes
- [x] **Jogar sozinho contra bots**: você e 2 a 4 bots (Tia do Zap, Coach Quântico, Tio do
  Pavê, Estagiário, Crush, DJ do Rolê, Zé do Bar), cada um fã de um pacote: na mão, tende a
  jogar as cartas dele; como juiz, a premiar quem jogou. A partida roda no aparelho
  (`MesaLocal`), pelas mesmas regras, sem Firestore; ainda pede o login anônimo da capa
- [x] Voltar ao menu não quebra mais os providers da sala (o código virava nulo e
  `roomId!` lançava)
- [x] **Zé Aleatório**: com 2 pessoas na sala, o anfitrião chama o Zé, que completa o mínimo
  e joga e julga no sorteio. O aparelho do anfitrião faz as jogadas dele (`MaestroDosBots`);
  se o anfitrião sair, o Zé para

## Fase 3d — mais vida

Ajustes pedidos jogando: o app parecia parado demais, faltava trilha e o modo solo não
deixava escolher o baralho.

- [x] **Escolher os baralhos no modo solo**: a mesma lista de "Criar sala"
  (`EscolhaDeBaralhos`), com a confirmação do +18
- [x] **Carinhas vivas**: flutuam num ritmo próprio, piscam, os olhos seguem o mouse (ou o
  último toque) e, no placar, na sala de espera e na capa, de vez em quando uma dá um cascudo
  na vizinha, que fica tonta. Tudo para com "reduzir movimento"
- [x] **Carinhas que reagem ao jogo**: balão de "…" em quem escolhe, cartinha na mão de quem
  enviou, juiz de olhos para cima, pulinhos de quem ganha a rodada, impaciência ("!" e
  tremedeira) quando o juiz passa de 20 s, e coroa derretendo em quem lidera sozinho
- [x] **Reações rápidas**: tocar na própria carinha no placar abre cinco reações desenhadas
  (risada, choro, caveira, coração, chocado); a escolhida sobe da carinha na tela de todos.
  Passa pela regra `reagir`, então vale também no modo solo; uma por segundo, no máximo
- [x] **Cartas com vida**: as cartas da mão inclinam em 3D sob o mouse (no celular, sob o
  dedo), as largas de leve, e as enviadas voam em arco até a carta preta
- [x] **Música de fundo**: três loops sintetizados (`tool/gerar_musicas.mjs`), um lo-fi
  calmo enquanto escolhem, um com tique-taque enquanto o juiz decide e a versão lenta e
  desafinada na madrugada; para no fim de jogo. O botão de som abre o painel com efeitos,
  música e volume da música, guardados no aparelho. Ninguém ouviu ainda

- [x] **Baralho Em alta e Básico revisado**: pacote novo com o que bombou em 2025 e 2026
  (bebê reborn, morango do amor, Labubu, tigrinho, brainrot, canetinha emagrecedora, IA
  para tudo); o Básico perdeu as cartas com pessoas reais. As cartas do Cards Against
  Humanity não foram traduzidas: a licença delas (CC BY-NC-SA) não combina com a MIT, e o
  humor tem que ser daqui. O Em alta envelhece rápido: rever uma vez por ano

- [x] **Correções do teste no celular**: o link de convite abre a sala de primeira; a tela
  de jogo rola quando falta espaço (o botão do juiz não some mais); recarregar a página no
  meio da partida volta para a sala

## Fase 4 — plataformas

- [ ] **Projeto iOS completo**: falta o `Runner.xcodeproj` (recriar com
  `flutter create --platforms=ios .` e conferir num Mac)
- [ ] **Gradle moderno**: `android/` usa `apply from: flutter.gradle` (formato antigo) e
  Gradle 8.10, que não roda com JDK 25; o build de release assina com a chave de debug
- [x] **Publicar a web** no Firebase Hosting a cada merge na `main`: o workflow `deploy-web.yml`
  publica sozinho desde que o segredo `FIREBASE_SERVICE_ACCOUNT_CARTARALHO` foi criado
- [ ] Build de Android no CI e na tag de release
- [ ] macOS: registrar o app no Firebase ou tirar a pasta `macos/`

## Fase 5 — segurança e robustez

- [ ] **Trazer as regras publicadas para o repositório**: o `firestore.rules` diz que
  qualquer usuário logado grava tudo, mas as regras publicadas no projeto são outras (achado
  ao testar o TTL). O arquivo precisa voltar a ser a fonte da verdade antes de mexer nelas
- [ ] **Regras do Firestore de verdade**: hoje qualquer usuário logado grava qualquer
  sala; restringir a membros e validar a mudança de fase
- [ ] **Mão escondida dos outros jogadores**: enquanto tudo vive num documento, todos podem
  ler as mãos; mover para uma subcoleção por jogador
- [x] **Sair da sala de verdade**: o botão de sair tira o jogador da sala (`sairDaSala`) em
  vez de fazer logout. As cartas dele voltam ao monte; o anfitrião passa para a próxima
  pessoa; se o juiz sai no meio da rodada, o juiz passa adiante e as cartas da mesa voltam
  às mãos; com menos de três, todos voltam para a espera; sem ninguém (só bots), a sala é
  apagada. Quem fecha a aba sem sair ainda fica na sala (precisaria de presença)
- [x] **Mensagens de erro legíveis**: toda tela mostra `mensagemDoErro(e)` (a recusa da regra
  como está, rede e Firebase como frase curta, o resto como "tente de novo"). Na web, o erro
  lançado dentro da transação chegava embrulhado ("Dart exception thrown from converted
  Future"); agora a recusa é guardada e lançada depois da transação
- [x] **Logger**: `registrar()` no lugar de `print`, só em modo de desenvolvimento; o
  `avoid_print` voltou a valer na análise
- [ ] **Apagar salas antigas** (TTL do Firestore): pronto no PR em rascunho
  [#58](https://github.com/pedrinholeda/cartaralho/pull/58) (o app grava `expiraEm`, 24 h,
  e a política fica em `firestore.indexes.json`). Travado porque as regras publicadas no
  projeto não são as do `firestore.rules` e recusam o campo novo ao atualizar (403). Para
  destravar: copiar as regras publicadas (console do Firebase → Firestore → Regras) para o
  `firestore.rules`, liberar `expiraEm` e publicar regras e índices juntos
- [ ] Testes de widget das telas principais
- [ ] Teste de ponta a ponta no CI: uma partida com três jogadores contra o emulador do
  Firestore

## Fase 6 — manutenção

- [ ] Migrar de `package:flutter/material.dart` para `material_ui` e religar o aviso de
  API obsoleta no `analysis_options.yaml`
- [ ] Atualizar Firebase (`firebase_core` 2 → atual) e Riverpod 3

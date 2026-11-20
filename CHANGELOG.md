# Changelog

## [0.3.0](https://github.com/pedrinholeda/cartaralho/compare/v0.2.0...v0.3.0) (2026-11-20)


### ⚠ BREAKING CHANGES

* **jogo:** no documento da sala, submittedCards guarda uma lista de cartas por jogador, em vez de uma carta. O app lê os dois formatos, mas uma versão anterior não lê salas gravadas por esta.

### Novidades

* **baralho:** baralho revisado em assets/baralhos/basico.json ([47c68d6](https://github.com/pedrinholeda/cartaralho/commit/47c68d64c0327a56e6fe5c0a68e578a4f08694fe))
* **jogo:** cartas pretas com duas ou três lacunas ("Escolha 2") ([01d1181](https://github.com/pedrinholeda/cartaralho/commit/01d1181074e0819208eeef709c879d86a3251c75))
* **jogo:** jogar de novo com o mesmo grupo ([36af8e7](https://github.com/pedrinholeda/cartaralho/commit/36af8e760cc322c5e3188534a202ddffce0eb887))
* **jogo:** resultado da rodada, mesa visível para todos e ordem sorteada ([7a4242e](https://github.com/pedrinholeda/cartaralho/commit/7a4242e9546579589ba5db88a7b3ecb2b5d8f8d4))
* **jogo:** trocar a mão uma vez por partida ([8416a4f](https://github.com/pedrinholeda/cartaralho/commit/8416a4f6c720e29ba9d2cc07b144c43fd05922ed))
* **sala:** escolher pontos para vencer e cartas na mão ao criar a sala ([e3cbaf8](https://github.com/pedrinholeda/cartaralho/commit/e3cbaf8d3358ddaabc3d28955cb20cc593a32e3a))


### Documentação

* cartas "Escolha 2" no README, no guia de desenvolvimento e no roadmap ([3f7c222](https://github.com/pedrinholeda/cartaralho/commit/3f7c222dbac99573052abd06323df8536306d1ec))
* como editar as cartas, e o baralho em JSON no guia e no roadmap ([3c8b92f](https://github.com/pedrinholeda/cartaralho/commit/3c8b92ff34fe5eb227aeea3256712f23cc42732b))
* configuração da sala, troca de mão e jogar de novo ([1f7876a](https://github.com/pedrinholeda/cartaralho/commit/1f7876ab64f5fef9139ed28752d64c15a5d0d9ba))
* fases da partida, resultado da rodada e itens da fase 2 no roadmap ([61b4a66](https://github.com/pedrinholeda/cartaralho/commit/61b4a663af7fd13cf7510a38f46b127f6de7961b))
* roadmap com as fases de jogabilidade e de redesign ([1cc00c9](https://github.com/pedrinholeda/cartaralho/commit/1cc00c940aebd2ac742f1bc765c3f5d3ae1928ff))

## [0.2.0](https://github.com/pedrinholeda/cartaralho/compare/v0.1.0...v0.2.0) (2026-11-20)


### Novidades

* **baralho:** baralho de 15 pretas e 48 brancas, para até 8 jogadores ([a06da8c](https://github.com/pedrinholeda/cartaralho/commit/a06da8cdff67fa92e605443d947092bb3e378dc7))


### Correções

* **firebase:** a web e o iOS conectam ao projeto certo ([812f094](https://github.com/pedrinholeda/cartaralho/commit/812f0942c804a7411e4cb190f963175b5ea1d792))
* **jogo:** a partida fecha a rodada, com mão gravada e juiz que roda ([0bacb1f](https://github.com/pedrinholeda/cartaralho/commit/0bacb1fe3bfab238cffa0f7f076118bcb28b948d))
* **sala:** código de sala aleatório e entrada que não perde jogador ([6379fcf](https://github.com/pedrinholeda/cartaralho/commit/6379fcf72398fb361cb4aed7edeafe103761c954))
* **web:** a página carrega o app com flutter_bootstrap.js ([a018870](https://github.com/pedrinholeda/cartaralho/commit/a0188709d71501954c81074566041df39e79b189))


### Documentação

* adiciona a licença MIT ([d7e8f1a](https://github.com/pedrinholeda/cartaralho/commit/d7e8f1a3221571eb40a3f7c3f7b28fb6d2ce457c))
* AGENTS.md para agentes de IA, com CLAUDE.md importando ele ([5723338](https://github.com/pedrinholeda/cartaralho/commit/5723338e993b8a6e91af0f57a192e0f16eeb2547))
* CONTRIBUTING com setup, verificações e formato dos commits ([c491f47](https://github.com/pedrinholeda/cartaralho/commit/c491f475edd5aef7997f33a3af9c18b8cc54ae94))
* explica as regras em lib/game e marca a fase 1 no roadmap ([9fdac55](https://github.com/pedrinholeda/cartaralho/commit/9fdac556a3867f5d8ef57958cc798ab73fba3d51))
* guia de desenvolvimento com arquitetura, módulos e limites conhecidos ([ea12ada](https://github.com/pedrinholeda/cartaralho/commit/ea12ada526fda8a3969cc14cbd8857dfaa2e2009))
* marca o código e a entrada na sala no roadmap ([8fc3204](https://github.com/pedrinholeda/cartaralho/commit/8fc320440835afb8c7fe29f73c242e84556c0868))
* modelos de PR e de issue (bug e melhoria) ([cddaacd](https://github.com/pedrinholeda/cartaralho/commit/cddaacd8e3e585667ad15e55b2e16b306a67fc48))
* move o guia do Firebase para docs/ e corrige o passo a passo ([cb5affd](https://github.com/pedrinholeda/cartaralho/commit/cb5affd956728e8eadeebe7ba6a307aa736da401))
* README de produto, com status honesto e detalhes em docs/ ([dcdb8b2](https://github.com/pedrinholeda/cartaralho/commit/dcdb8b20c0d2a32a6e79c6fcf75db1508cc09b3d))
* roadmap com os problemas encontrados na revisão ([2210ba5](https://github.com/pedrinholeda/cartaralho/commit/2210ba5340ec54a8ed4ac3bd0d5371cb7866515e))
* web e iOS conectados, e como testar com três jogadores de verdade ([b16e890](https://github.com/pedrinholeda/cartaralho/commit/b16e890f566045754e58c4196fae66b06f0186e4))

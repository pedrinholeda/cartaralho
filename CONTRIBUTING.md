# Contribuindo com o Cartaralho

O Cartaralho é um jogo para jogar com amigos na mesma sala, cada um no seu celular. O que
mais importa: uma rodada nunca pode travar no meio, e todo mundo tem que ver o mesmo estado
da sala.

## Reportar bug

Abra uma issue com o modelo **Bug**: o que você fez, o que esperava, o que aconteceu, a
plataforma e quantos jogadores estavam na sala. Se a rodada travou, diga em que fase (envio
de cartas, escolha do juiz) e o código da sala.

## Setup

Requisitos: Flutter 3.50 (a mesma versão do CI) e, para rodar o app, acesso a um projeto
Firebase com Authentication anônima e Firestore ligados. O passo a passo está em
[docs/FIREBASE.md](docs/FIREBASE.md).

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

## Antes de abrir o PR

```bash
flutter analyze
```

```bash
dart format lib test
```

```bash
flutter test
```

O CI roda os três e o `flutter build web` em todo PR. Ele não abre o app nem fala com o
Firebase: mudança no fluxo do jogo precisa de uma partida de teste com três jogadores (veja como em
[docs/DESENVOLVIMENTO.md](docs/DESENVOLVIMENTO.md#setup-e-o-dia-a-dia)) e isso vai descrito no PR.

## Estilo

- Siga o código em volta: nomes, estrutura, formatação. O `dart format` decide o resto.
- **Regra do jogo mora em [`lib/game/regras.dart`](lib/game/regras.dart)**, como função
  pura que recebe a sala e devolve a sala nova. O `FirebaseService` só lê, chama a regra e
  grava numa transação. Regra nova vem com teste em `test/game/`.
- Textos da interface em português do Brasil.
- Comentário explica **por quê**, não o quê.
- Sem dependência nova sem motivo, e o motivo no PR.

## Cartas

Quer sugerir carta? Edite o baralho do tema em [`assets/baralhos/`](assets/baralhos) e rode
`flutter test test/game/baralho_test.dart`. Carta preta tem de uma a três lacunas `____`;
carta branca começa com minúscula (o jogo põe a maiúscula quando ela abre a frase) e não
termina em ponto. Antes da lacuna, nada de preposição que vira contração (`de`, `em`, `por`,
`a`): "fala de ____" viraria "fala de o cunhado". Um texto não se repete em outro baralho. Humor ácido é bem-vindo; ataque a grupos de pessoas, não. Nada de pessoas reais com nome
(envelhece mal e pode ofender): prefira o tipo ("o narrador emocionado demais"). Carta de
outro jogo não entra, nem traduzida: as licenças não combinam com a MIT. Sexo e bebida vão no Sem filtro
(+18), nunca em cena sem consentimento; o Para toda a família não tem palavrão.

## Docs

Mudou comportamento ou configuração? Atualize no mesmo PR o README, o arquivo certo em
`docs/`, o `AGENTS.md` (se a estrutura mudou) e marque o item no `docs/ROADMAP.md`. O
`CHANGELOG.md` é gerado pelo release-please; não edite à mão.

## Commits

Commits pequenos, uma ideia cada, em português e no formato
[Conventional Commits](https://www.conventionalcommits.org/pt-br/):

```
feat(baralho): cartas carregadas de um arquivo JSON
fix(jogo): a rodada passa para o juiz quando todos enviaram
docs: explica como configurar o Firebase
```

| tipo | quando | entra no changelog |
|---|---|---|
| `feat` | algo novo para quem joga | sim, sobe a minor |
| `fix` | correção de bug | sim, sobe a patch |
| `perf` | mais rápido ou mais barato | sim |
| `docs` | só documentação | sim |
| `refactor` | muda o código, não o comportamento | sim |
| `test`, `build`, `chore`, `style`, `ci` | testes, dependências, manutenção, formatação, CI | não |

Escopos usados: `jogo` (regras e fluxo da partida), `sala` (criar, entrar, sair), `baralho`,
`ui`, `firebase`, `web`, `android`, `ios`. Quebra de compatibilidade leva `!` e um parágrafo
`BREAKING CHANGE:` (por exemplo, quando o formato do documento da sala no Firestore muda).

## Branches, merge e releases

- Uma branch por mudança: `feat/...`, `fix/...`, `docs/...`.
- PR para `main`; merge **só com o CI verde no último commit**.
- Merge com **merge commit** e corpo vazio (`gh pr merge N --merge --body ""`): cada commit
  convencional chega à `main` e o release-please não duplica itens.
- O release-please mantém um PR de release aberto; o merge dele cria a tag e a Release.

## Licença

Ao contribuir, você concorda que seu trabalho sai sob a [licença MIT](LICENSE).

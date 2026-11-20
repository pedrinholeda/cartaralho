# Configurando o Firebase

O Cartaralho não tem servidor próprio: usa o Firebase Authentication (login anônimo) e um
documento por sala no Cloud Firestore. Este guia liga um projeto Firebase ao app, do zero.

O repositório já vem apontando para o projeto `cartaralho` do autor (as chaves estão em
`lib/firebase_options.dart`, `android/app/google-services.json` e
`ios/Runner/GoogleService-Info.plist`). Chave de cliente do Firebase não é segredo: quem
protege os dados são as [regras do Firestore](../firestore.rules). Para jogar no seu próprio
projeto, siga os passos abaixo e os arquivos são regerados.

## 1. Criar o projeto

1. No [Firebase Console](https://console.firebase.google.com/), crie um projeto.
2. Em **Authentication → Sign-in method**, ative **Anônimo**.
3. Em **Firestore Database**, crie o banco na região mais próxima dos jogadores.

## 2. Publicar as regras

As regras ficam em [`firestore.rules`](../firestore.rules). Com o
[Firebase CLI](https://firebase.google.com/docs/cli) instalado e logado:

```bash
firebase use --add
```

```bash
firebase deploy --only firestore:rules
```

Não use o "modo de teste" do console por muito tempo: ele libera o banco para qualquer um,
mesmo sem login, e expira em 30 dias.

## 3. Ligar o app ao projeto

O caminho recomendado é o [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup),
que registra os apps no projeto e gera `lib/firebase_options.dart`,
`android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` de uma vez:

```bash
dart pub global activate flutterfire_cli
```

```bash
flutterfire configure --platforms=android,ios,web
```

Os identificadores do app são `com.pedro.cartaralho` no Android e no iOS. Se trocar, troque
também em `android/app/build.gradle` (`applicationId` e `namespace`) e em
`ios/Runner/Config.xcconfig`.

O plugin `com.google.gms.google-services` já está aplicado em `android/app/build.gradle`.

## 4. Conferir

```bash
flutter run -d chrome
```

A tela inicial deve mostrar os botões **Criar Sala** e **Entrar na Sala**. Se aparecer
**Erro ao conectar**, o login anônimo falhou: confira se ele está ativo no console e se
`lib/firebase_options.dart` tem as opções da plataforma em que você está rodando. O log do
navegador (ou o `flutter run`) mostra a mensagem do Firebase.

## Formato do documento da sala

Cada sala é um documento `rooms/{código}`, com o código de seis caracteres como id. Os campos
são os de [`GameRoom.toJson`](../lib/models/game_room.dart): jogadores, os dois baralhos, a
carta preta da vez, a fase, o juiz, as cartas enviadas, o vencedor e o limite de pontos.

## Publicar a web

O jogo fica em https://cartaralho.web.app, no Firebase Hosting do projeto `cartaralho`
(configurado em [`firebase.json`](../firebase.json) e [`.firebaserc`](../.firebaserc)).

**Automático.** O workflow [`deploy-web.yml`](../.github/workflows/deploy-web.yml) monta a
web e publica a cada merge na `main`. Ele também pode ser disparado à mão na aba Actions
("Publicar web" → "Run workflow"). Para publicar, ele precisa do segredo
`FIREBASE_SERVICE_ACCOUNT_CARTARALHO` no repositório; sem o segredo, monta a web e só avisa
no resumo do run.

Para criar o segredo, uma vez, quem é dono do projeto Firebase roda:

```bash
npx firebase-tools login
```

```bash
npx firebase-tools init hosting:github
```

O segundo comando pergunta o repositório (`pedrinholeda/cartaralho`), cria uma conta de
serviço com permissão só de publicar e grava o segredo no GitHub sozinho. Ele também oferece
criar workflows próprios: responda **não** às perguntas de workflow, porque o
`deploy-web.yml` já faz isso.

**À mão**, de uma máquina logada:

```bash
flutter build web --release
```

```bash
npx firebase-tools deploy --only hosting
```

`--only hosting` não mexe nas regras do Firestore. Para publicar as regras, veja o passo 2.

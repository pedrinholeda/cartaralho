# Configuração do Firebase

## 1. Criar Projeto no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em "Adicionar projeto"
3. Digite o nome: `cartaralho`
4. Ative o Google Analytics (opcional)
5. Clique em "Criar projeto"

## 2. Configurar Authentication

1. No menu lateral, clique em "Authentication"
2. Vá para a aba "Sign-in method"
3. Ative "Anônimo" (Anonymous)
4. Clique em "Salvar"

## 3. Configurar Firestore Database

1. No menu lateral, clique em "Firestore Database"
2. Clique em "Criar banco de dados"
3. Escolha "Iniciar no modo de teste"
4. Selecione a localização mais próxima
5. Clique em "Concluído"

### Regras do Firestore (coleção 'rooms')

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rooms/{roomId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 4. Configurar Aplicações

### Android

1. No menu lateral, clique no ícone Android
2. Digite o package name: `com.pedro.cartaralho`
3. Baixe o arquivo `google-services.json`
4. Coloque o arquivo em `android/app/google-services.json`
5. Adicione no `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### iOS

1. No menu lateral, clique no ícone iOS
2. Digite o bundle ID: `com.pedro.cartaralho`
3. Baixe o arquivo `GoogleService-Info.plist`
4. Adicione ao projeto no Xcode ou coloque em `ios/Runner/GoogleService-Info.plist`
5. **Importante**: O bundle ID `com.pedro.cartaralho` já está configurado nos arquivos `.xcconfig`

### Web

1. No menu lateral, clique no ícone Web
2. Digite o nome do app: `cartaralho`
3. Copie a configuração do Firebase
4. Substitua em `web/index.html`:

```javascript
var firebaseConfig = {
  apiKey: "sua-api-key-aqui",
  authDomain: "cartaralho.firebaseapp.com",
  projectId: "cartaralho",
  storageBucket: "cartaralho.appspot.com",
  messagingSenderId: "123456789",
  appId: "sua-app-id-aqui",
};
```

## 5. Testar a Configuração

Após configurar tudo, execute:

```bash
flutter pub get
flutter run
```

O app deve fazer login anônimo automaticamente e estar pronto para criar/entrar em salas!

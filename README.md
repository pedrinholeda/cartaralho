# Cartaralho

Uma versão Flutter do jogo de cartas mais divertido e politicamente incorreto com integração Firebase em tempo real.

## 🎮 Funcionalidades

- **Autenticação anônima** via Firebase Auth
- **Salas em tempo real** usando Firestore
- **Multiplataforma**: Android, iOS e Web
- **Gerenciamento de estado** com Riverpod
- **Interface moderna** com Material Design 3

## 🚀 Como Executar

### Pré-requisitos

1. **Flutter SDK** (versão 3.0.0 ou superior)
2. **Firebase Project** configurado
3. **Android Studio** (para Android) ou **Xcode** (para iOS)

### 1. Configuração do Firebase

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Crie um novo projeto ou use um existente
3. Ative os seguintes serviços:
   - **Authentication** (modo anônimo)
   - **Firestore Database** (modo de teste)

### 2. Configuração do Projeto

1. **Clone e instale dependências:**

   ```bash
   cd cartaralho
   flutter pub get
   ```

2. **Configure Firebase para Android:**

   - Baixe o arquivo `google-services.json` do Firebase Console
   - Coloque em `android/app/google-services.json`
   - Adicione o plugin no `android/app/build.gradle`:
     ```gradle
     apply plugin: 'com.google.gms.google-services'
     ```

3. **Configure Firebase para iOS:**

   - Baixe o arquivo `GoogleService-Info.plist` do Firebase Console
   - Adicione ao projeto iOS no Xcode
   - Ou coloque em `ios/Runner/GoogleService-Info.plist`
   - Bundle ID: `com.pedro.cartaralho`

4. **Configure Firebase para Web:**
   - No Firebase Console, vá em "Configurações do projeto" > "Geral"
   - Na seção "Seus aplicativos", adicione um app Web
   - Copie a configuração e substitua em `web/index.html`:
     ```javascript
     var firebaseConfig = {
       apiKey: "sua-api-key",
       authDomain: "seu-projeto.firebaseapp.com",
       projectId: "seu-projeto-id",
       storageBucket: "seu-projeto.appspot.com",
       messagingSenderId: "123456789",
       appId: "seu-app-id",
     };
     ```

### 3. Executar o Projeto

```bash
# Para Android
flutter run -d android

# Para iOS
flutter run -d ios

# Para Web
flutter run -d web
```

## 🎯 Como Jogar

1. **Criar Sala**: Um jogador cria uma nova sala e vira o host
2. **Entrar na Sala**: Outros jogadores entram usando o código da sala
3. **Iniciar Jogo**: O host inicia o jogo quando todos estiverem prontos
4. **Rodadas**:
   - O juiz vê uma carta preta
   - Outros jogadores escolhem uma carta branca
   - O juiz escolhe a combinação mais engraçada
   - O vencedor ganha 1 ponto
5. **Vitória**: Primeiro jogador a atingir 5 pontos vence!

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada
├── models/                   # Modelos de dados
│   ├── card.dart
│   ├── player.dart
│   └── game_room.dart
├── services/                 # Serviços
│   └── firebase_service.dart
├── providers/                # Providers Riverpod
│   ├── auth_provider.dart
│   └── game_provider.dart
├── screens/                  # Telas
│   ├── home_screen.dart
│   ├── create_room_screen.dart
│   ├── join_room_screen.dart
│   └── game_screen.dart
└── widgets/                  # Widgets reutilizáveis
    ├── player_list_widget.dart
    ├── black_card_widget.dart
    ├── white_cards_widget.dart
    └── judge_widget.dart
```

## 🔧 Tecnologias Utilizadas

- **Flutter** - Framework de desenvolvimento
- **Riverpod** - Gerenciamento de estado
- **Firebase Auth** - Autenticação anônima
- **Cloud Firestore** - Banco de dados em tempo real
- **Material Design 3** - Design system

## 📱 Plataformas Suportadas

- ✅ Android (API 21+)
- ✅ iOS (iOS 11.0+)
- ✅ Web (Chrome, Firefox, Safari)

## 🎨 Recursos do Jogo

- **Cartas Mock**: Baralho inicial com cartas preta e branca
- **Sincronização em Tempo Real**: Estado do jogo sincronizado via Firestore
- **Interface Responsiva**: Adapta-se a diferentes tamanhos de tela
- **Design Moderno**: UI/UX inspirada no Material Design 3

## 🚧 Próximas Funcionalidades

- [ ] Baralhos customizados
- [ ] Chat em tempo real
- [ ] Estatísticas de jogo
- [ ] Modo offline
- [ ] Notificações push
- [ ] Temas personalizáveis

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🐛 Problemas Conhecidos

- As cartas brancas dos jogadores são simuladas (não persistem no Firestore)
- Não há validação de entrada para códigos de sala
- Interface pode precisar de ajustes em telas muito pequenas

## 📞 Suporte

Se encontrar algum problema, abra uma issue no GitHub ou entre em contato.

---

**Divirta-se jogando Cartaralho! 🎉**

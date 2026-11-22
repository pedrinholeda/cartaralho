import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/erros.dart';
import 'ui/olhar.dart';
import 'ui/tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception(
            'Timeout: Firebase demorou mais de 30 segundos para inicializar');
      },
    );
  } catch (e) {
    registrar('Firebase não iniciou: $e');
    // Continuar mesmo com erro para não travar o app
  }

  runApp(const ProviderScope(child: CartaralhoApp()));
}

class CartaralhoApp extends StatelessWidget {
  const CartaralhoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartaralho',
      theme: tema,
      home: const HomeScreen(),
      // Anota onde o ponteiro anda, para as carinhas olharem para lá.
      builder: (context, filho) =>
          RastreadorDeOlhar(child: filho ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
    );
  }
}

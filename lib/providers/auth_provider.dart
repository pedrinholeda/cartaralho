import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/erros.dart';
import '../services/firebase_service.dart';

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges().handleError((error) {
    registrar('login: $error');
    throw error;
  });
});

final authServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Se o login anônimo já terminou. Separado do [authProvider] para as telas
/// (e os testes) não dependerem da classe `User` do Firebase.
final logadoProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).valueOrNull != null,
);

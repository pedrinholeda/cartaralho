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

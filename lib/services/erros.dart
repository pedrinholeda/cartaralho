import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../game/regras.dart';

/// Escreve no console só em modo de desenvolvimento; na versão publicada,
/// nada (nem id de usuário, nem erro cru) vai para o console de ninguém.
void registrar(String mensagem) {
  if (kDebugMode) debugPrint('[cartaralho] $mensagem');
}

/// Erro com mensagem para gente, pronta para aparecer na tela.
class ErroDoJogo implements Exception {
  ErroDoJogo(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// A frase que o jogador vê para qualquer erro: as recusas das regras e os
/// erros do jogo passam como estão; os do Firebase e da rede viram frases
/// curtas; o resto vira um "tente de novo", sem stack nem código.
String mensagemDoErro(Object erro) {
  if (erro is JogadaInvalida) return erro.mensagem;
  if (erro is ErroDoJogo) return erro.mensagem;
  if (erro is TimeoutException) {
    return 'Demorou demais para responder. Confira a internet e tente de novo.';
  }
  if (erro is FirebaseException) {
    return switch (erro.code) {
      'unavailable' ||
      'network-request-failed' =>
        'Sem conexão. Confira a internet e tente de novo.',
      'permission-denied' => 'Isso não é permitido nesta sala.',
      'not-found' => 'Essa sala não existe mais. Confira o código.',
      'aborted' ||
      'failed-precondition' =>
        'Alguém mexeu na sala ao mesmo tempo. Tente de novo.',
      _ => 'Algo deu errado. Tente de novo.',
    };
  }
  return 'Algo deu errado. Tente de novo.';
}

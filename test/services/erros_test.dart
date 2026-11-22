import 'dart:async';

import 'package:cartaralho/game/regras.dart';
import 'package:cartaralho/services/erros.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a recusa das regras aparece como está', () {
    expect(mensagemDoErro(JogadaInvalida('Você já enviou sua carta')),
        'Você já enviou sua carta');
    expect(mensagemDoErro(ErroDoJogo('Essa sala não existe mais.')),
        'Essa sala não existe mais.');
  });

  test('erro de rede e do Firebase viram frase curta', () {
    expect(mensagemDoErro(TimeoutException('x')), contains('internet'));
    expect(
        mensagemDoErro(
            FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')),
        contains('Sem conexão'));
    expect(
        mensagemDoErro(FirebaseException(
            plugin: 'cloud_firestore', code: 'permission-denied')),
        contains('não é permitido'));
  });

  test('o resto vira "tente de novo", sem stack nem texto cru', () {
    final m = mensagemDoErro(
        Exception('Dart exception thrown from converted Future'));
    expect(m, 'Algo deu errado. Tente de novo.');
    expect(m, isNot(contains('Exception')));
  });
}

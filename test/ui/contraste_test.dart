import 'package:cartaralho/ui/tema.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Razão de contraste da WCAG entre duas cores (de 1 a 21).
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (claro, escuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + 0.05) / (escuro + 0.05);
}

void main() {
  const cores = Cores.noite;

  // Texto comum pede 4,5:1 (WCAG AA).
  final texto = {
    'texto na mesa': (cores.tintaNaMesa, cores.mesa),
    'texto na superfície': (cores.tintaNaMesa, cores.superficie),
    'texto de apoio na mesa': (cores.tintaSuave, cores.mesa),
    'texto de apoio na superfície': (cores.tintaSuave, cores.superficie),
    'texto na carta branca': (cores.tintaNaCarta, cores.carta),
    'texto na carta preta': (cores.tintaNaCartaPreta, cores.cartaPreta),
    'texto no botão de ação': (cores.tintaNaAcao, cores.acao),
    'texto no destaque': (cores.tintaNoDestaque, cores.destaque),
  };
  for (final MapEntry(key: par, value: (tinta, fundo)) in texto.entries) {
    test('$par tem contraste de ao menos 4,5:1', () {
      expect(contraste(tinta, fundo), greaterThanOrEqualTo(4.5));
    });
  }

  // Borda de componente e contorno de foco pedem 3:1 contra o que está em
  // volta (WCAG 1.4.11).
  final bordas = {
    'contorno de foco (destaque) sobre a mesa': (cores.destaque, cores.mesa),
    'carta escolhida (contorno da ação) sobre a carta': (
      cores.acao,
      cores.carta
    ),
    'botão de ação sobre a mesa': (cores.acao, cores.mesa),
    'carta branca sobre a mesa': (cores.carta, cores.mesa),
  };
  for (final MapEntry(key: par, value: (borda, fundo)) in bordas.entries) {
    test('$par tem contraste de ao menos 3:1', () {
      expect(contraste(borda, fundo), greaterThanOrEqualTo(3));
    });
  }

  test('os traços da carinha se leem sobre a cor do avatar', () {
    for (final (fundo, tinta) in coresDeJogador) {
      expect(contraste(tinta, fundo), greaterThanOrEqualTo(4.5));
    }
  });
}

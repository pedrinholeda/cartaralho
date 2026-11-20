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
  for (final (nome, cores) in [
    ('claro', Cores.claro),
    ('escuro', Cores.escuro)
  ]) {
    group('tema $nome', () {
      // Texto comum pede 4,5:1 (WCAG AA).
      final pares = {
        'texto na mesa': (cores.tintaNaMesa, cores.mesa),
        'texto na carta branca': (cores.tintaNaCarta, cores.carta),
        'texto na carta preta': (cores.tintaNaCartaPreta, cores.cartaPreta),
        'texto no destaque': (cores.tintaNoDestaque, cores.destaque),
      };
      for (final MapEntry(key: par, value: (texto, fundo)) in pares.entries) {
        test('$par tem contraste de ao menos 4,5:1', () {
          expect(contraste(texto, fundo), greaterThanOrEqualTo(4.5));
        });
      }

      // Contorno de foco e borda de componente pedem 3:1 contra o que está em
      // volta (WCAG 1.4.11).
      test('o contorno de foco (destaque) aparece sobre a mesa', () {
        expect(contraste(cores.destaque, cores.mesa), greaterThanOrEqualTo(3));
      });

      test('a carta escolhida (contorno preto) aparece sobre a carta', () {
        expect(
          contraste(cores.cartaPreta, cores.carta),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }
}

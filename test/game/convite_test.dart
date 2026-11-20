import 'package:cartaralho/game/convite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final jogo = Uri.parse('https://cartaralho.web.app/');

  group('codigoDoConvite', () {
    test('lê o código do link', () {
      expect(
          codigoDoConvite(Uri.parse('https://x.app/?sala=K7PX2M')), 'K7PX2M');
    });

    test('aceita minúsculas e espaços', () {
      expect(codigoDoConvite(Uri.parse('https://x.app/?sala=%20k7px2m%20')),
          'K7PX2M');
    });

    test('sem código, ou com código inválido, não há convite', () {
      expect(codigoDoConvite(jogo), isNull);
      expect(codigoDoConvite(Uri.parse('https://x.app/?sala=ABC')), isNull);
      expect(codigoDoConvite(Uri.parse('https://x.app/?sala=ABC-12')), isNull);
    });
  });

  group('linkDoConvite', () {
    test('põe o código no endereço do jogo', () {
      expect(linkDoConvite(jogo, 'K7PX2M').toString(),
          'https://cartaralho.web.app/?sala=K7PX2M');
    });

    test('troca o código antigo e tira a âncora', () {
      final aberto = Uri.parse('http://localhost:5173/?sala=AAAAAA#/x');
      expect(linkDoConvite(aberto, 'K7PX2M').toString(),
          'http://localhost:5173/?sala=K7PX2M');
    });

    test('o link volta a dar o mesmo código', () {
      expect(codigoDoConvite(linkDoConvite(jogo, 'K7PX2M')), 'K7PX2M');
    });
  });

  test('o texto do convite tem o código e o link', () {
    final texto = textoDoConvite(jogo, 'K7PX2M');
    expect(texto, contains('K7PX2M'));
    expect(texto, contains('https://cartaralho.web.app/?sala=K7PX2M'));
  });
}

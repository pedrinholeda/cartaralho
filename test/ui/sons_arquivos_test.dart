import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// O volume médio que cada som deve ter (dBFS, RMS da parte que soa). Os que
/// tocam toda hora são mais baixos; a vitória, mais alta. Mesmo critério de
/// tool/gerar_sons.mjs e tool/medir_sons.mjs.
const alvos = {
  'distribuir': -16.0,
  'enviar': -16.0,
  'virar': -16.0,
  'rodada': -14.0,
  'vitoria': -11.0,
};

double _db(double x) => 20 * log(x) / ln10;

/// As amostras de um WAV mono de 16 bits, entre -1 e 1.
List<double> _amostras(File arquivo) {
  final bytes = arquivo.readAsBytesSync();
  final dados = ByteData.sublistView(bytes);
  expect(dados.getUint16(22, Endian.little), 1, reason: 'mono');
  expect(dados.getUint32(24, Endian.little), 22050, reason: 'taxa');
  expect(dados.getUint16(34, Endian.little), 16, reason: '16 bits');
  return [
    for (var i = 44; i + 1 < bytes.length; i += 2)
      dados.getInt16(i, Endian.little) / 32768,
  ];
}

double _volumeMedio(List<double> a) {
  final pico = a.map((v) => v.abs()).reduce(max);
  const janela = 220; // 10 ms
  var soma = 0.0;
  var conta = 0;
  for (var i = 0; i + janela <= a.length; i += janela) {
    var q = 0.0;
    for (var k = i; k < i + janela; k++) {
      q += a[k] * a[k];
    }
    final rms = sqrt(q / janela);
    if (rms > pico * 0.05) {
      soma += rms * rms;
      conta++;
    }
  }
  return sqrt(soma / conta);
}

void main() {
  for (final MapEntry(key: nome, value: alvo) in alvos.entries) {
    group(nome, () {
      late List<double> a;
      setUpAll(() => a = _amostras(File('assets/sons/$nome.wav')));

      test('soa no volume combinado', () {
        expect(_db(_volumeMedio(a)), closeTo(alvo, 0.5));
      });

      test('o pico não passa de -1 dBFS', () {
        expect(_db(a.map((v) => v.abs()).reduce(max)), lessThan(-0.9));
      });

      test('começa e termina no zero, sem estalo', () {
        // A primeira e a última amostra no zero; as vizinhas ainda baixas
        // (subindo ou descendo, não num degrau).
        expect(a.first.abs(), lessThan(0.002));
        expect(a.last.abs(), lessThan(0.002));
        for (final v in [...a.take(5), ...a.skip(a.length - 5)]) {
          expect(v.abs(), lessThan(0.05));
        }
      });
    });
  }

  test('todo som da pasta tem volume combinado', () {
    final arquivos = Directory('assets/sons')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.wav'))
        .map((n) => n.replaceAll('.wav', ''))
        .toSet();
    expect(arquivos, alvos.keys.toSet());
  });
}

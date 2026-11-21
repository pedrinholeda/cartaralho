import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Os olhos, a boca e o enfeite de uma carinha. São oito opções de cada,
/// mais bochecha ou não: 1.024 carinhas.
enum Olhos {
  pontos,
  sono,
  feliz,
  vesgo,
  arregalados,
  piscando,
  apaixonado,
  malandro
}

enum Boca { sorriso, risada, susto, lingua, reta, enjoada, dentuca, deLado }

enum Enfeite { nada, oculos, bone, festa, bigode, fone, topete, gravata }

/// Uma carinha, sorteada de forma estável a partir de uma [semente] (o id do
/// jogador) e de uma [variacao] (quantas vezes ele pediu outra). O mesmo
/// jogador vê a mesma carinha em todos os aparelhos.
@immutable
class Carinha {
  final Olhos olhos;
  final Boca boca;
  final Enfeite enfeite;
  final bool bochechas;

  const Carinha({
    required this.olhos,
    required this.boca,
    required this.enfeite,
    required this.bochechas,
  });

  factory Carinha.de(String semente, [int variacao = 0]) {
    var h = misturar('$semente#$variacao');
    int tirar(int n) {
      final v = h % n;
      h ~/= n;
      return v;
    }

    return Carinha(
      olhos: Olhos.values[tirar(Olhos.values.length)],
      boca: Boca.values[tirar(Boca.values.length)],
      enfeite: Enfeite.values[tirar(Enfeite.values.length)],
      bochechas: tirar(2) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Carinha &&
      other.olhos == olhos &&
      other.boca == boca &&
      other.enfeite == enfeite &&
      other.bochechas == bochechas;

  @override
  int get hashCode => Object.hash(olhos, boca, enfeite, bochechas);

  @override
  String toString() => 'Carinha($olhos, $boca, $enfeite, $bochechas)';
}

/// Um número de 31 bits a partir do texto, igual no celular e na web.
/// `String.hashCode` não serve: muda entre plataformas. As contas ficam abaixo
/// de 2^53 para o JavaScript não perder precisão, e as rodadas de mistura
/// fazem uma letra diferente mudar o número inteiro, não só o fim dele.
int misturar(String texto) {
  var h = 7;
  for (final c in texto.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  for (var i = 0; i < 4; i++) {
    h = ((h ^ (h >> 15)) * 0x5bd1) & 0x7fffffff;
    h = ((h ^ (h >> 12)) * 0x6a3b) & 0x7fffffff;
  }
  return h;
}

/// Desenha a [carinha] num círculo de cor [fundo], com os traços em [tinta].
/// [bochecha] pinta as bochechas e a língua; [branco], o olho arregalado, o
/// dente e o brilho dos óculos.
class PintorDeCarinha extends CustomPainter {
  final Carinha carinha;
  final Color fundo;
  final Color tinta;
  final Color bochecha;
  final Color branco;

  /// Na madrugada: cor desbotada e olhos fundos, seja qual for a carinha.
  final bool assombrada;

  /// Para onde a carinha olha, de -1 a 1 em cada eixo (o ponteiro).
  final Offset olhar;

  /// No meio de uma piscada: olhos fechados.
  final bool piscando;

  /// Acabou de levar um cascudo: olhos em X e uma estrelinha.
  final bool tonta;

  const PintorDeCarinha({
    required this.carinha,
    required this.fundo,
    required this.tinta,
    required this.bochecha,
    required this.branco,
    this.assombrada = false,
    this.olhar = Offset.zero,
    this.piscando = false,
    this.tonta = false,
  });

  /// A cor do avatar quase sem cor e um pouco mais escura.
  static Color desbotar(Color cor) {
    final hsl = HSLColor.fromColor(cor);
    return hsl
        .withSaturation(hsl.saturation * .25)
        .withLightness(hsl.lightness * .8)
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.scale(s);
    // Daqui em diante tudo é desenhado num quadrado de 1 x 1.
    final circulo = Path()
      ..addOval(Rect.fromCircle(center: const Offset(.5, .5), radius: .5));
    canvas.drawPath(
        circulo, Paint()..color = assombrada ? desbotar(fundo) : fundo);
    canvas.save();
    canvas.clipPath(circulo);

    final traco = Paint()
      ..color = tinta
      ..style = PaintingStyle.stroke
      ..strokeWidth = .055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cheio = Paint()..color = tinta;

    if (carinha.bochechas && !assombrada) {
      final p = Paint()..color = bochecha.withValues(alpha: .45);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(.24, .62), width: .14, height: .08),
          p);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(.76, .62), width: .14, height: .08),
          p);
    }

    // Os olhos andam um pouco na direção do ponteiro.
    canvas.save();
    canvas.translate(olhar.dx * .04, olhar.dy * .03);
    if (tonta) {
      _olhosTontos(canvas, traco);
    } else if (piscando) {
      _olhosFechados(canvas, traco);
    } else if (assombrada) {
      _olhosFundos(canvas, cheio);
    } else {
      _olhos(canvas, traco, cheio);
    }
    canvas.restore();
    _boca(canvas, traco, cheio);
    _enfeite(canvas, traco, cheio);
    canvas.restore();
    // Chapéu, topete, fone e aba do boné saem da cabeça: ficam fora do recorte
    // do círculo, e o avatar deixa espaço em volta para eles.
    _enfeiteDeFora(canvas, cheio);
    if (tonta) _estrelinha(canvas, const Offset(.86, .04), .11);
    canvas.restore();
  }

  void _enfeiteDeFora(Canvas c, Paint cheio) {
    switch (carinha.enfeite) {
      case Enfeite.bone:
        c.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(.42, .18, .66, .1),
                const Radius.circular(.05)),
            cheio);
      case Enfeite.festa:
        final chapeu = Path()
          ..moveTo(.26, .2)
          ..lineTo(.56, -.3)
          ..lineTo(.74, .16)
          ..quadraticBezierTo(.5, .1, .26, .2)
          ..close();
        c.drawPath(chapeu, cheio);
        final listra = Paint()
          ..color = fundo
          ..strokeWidth = .05
          ..strokeCap = StrokeCap.round;
        c.drawLine(const Offset(.38, .01), const Offset(.65, -.04), listra);
        c.drawLine(const Offset(.47, -.15), const Offset(.6, -.17), listra);
        c.drawCircle(const Offset(.56, -.3), .075, Paint()..color = branco);
      case Enfeite.fone:
        c.drawArc(
            const Rect.fromLTWH(-.02, -.08, 1.04, 1.04),
            math.pi * 1.05,
            math.pi * .9,
            false,
            Paint()
              ..color = tinta
              ..style = PaintingStyle.stroke
              ..strokeWidth = .07);
        for (final x in [-.07, .93]) {
          c.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(x, .34, .14, .28), const Radius.circular(.06)),
              cheio);
        }
      case Enfeite.topete:
        // Uma franja que cobre o alto da cabeça e termina num cacho para cima.
        final p = Path()
          ..moveTo(.12, .34)
          ..quadraticBezierTo(.12, -.02, .5, -.04)
          ..quadraticBezierTo(.7, -.05, .74, -.2)
          ..quadraticBezierTo(.92, -.02, .8, .14)
          ..quadraticBezierTo(.9, .22, .88, .34)
          ..quadraticBezierTo(.6, .14, .12, .34)
          ..close();
        c.drawPath(p, cheio);
      default:
        break;
    }
  }

  void _olhosFechados(Canvas c, Paint traco) {
    for (final x in [.34, .66]) {
      c.drawLine(Offset(x - .07, .47), Offset(x + .07, .47), traco);
    }
  }

  void _olhosTontos(Canvas c, Paint traco) {
    for (final x in [.34, .66]) {
      c.drawLine(Offset(x - .06, .41), Offset(x + .06, .53), traco);
      c.drawLine(Offset(x + .06, .41), Offset(x - .06, .53), traco);
    }
  }

  void _estrelinha(Canvas c, Offset centro, double raio) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? raio : raio * .4;
      final a = -math.pi / 2 + i * math.pi / 4;
      final ponto = centro + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(ponto.dx, ponto.dy) : p.lineTo(ponto.dx, ponto.dy);
    }
    c.drawPath(p..close(), Paint()..color = branco);
  }

  /// Dois buracos escuros com um pontinho de luz; cada carinha olha um pouco
  /// para um lado.
  void _olhosFundos(Canvas c, Paint cheio) {
    final desvio = (carinha.olhos.index - 3.5) * .006;
    for (final x in [.34, .66]) {
      c.drawOval(
          Rect.fromCenter(center: Offset(x, .46), width: .2, height: .24),
          cheio);
      c.drawCircle(Offset(x + desvio, .47), .022, Paint()..color = branco);
    }
  }

  void _olhos(Canvas c, Paint traco, Paint cheio) {
    const e = Offset(.34, .46), d = Offset(.66, .46);
    switch (carinha.olhos) {
      case Olhos.pontos:
        c.drawCircle(e, .05, cheio);
        c.drawCircle(d, .05, cheio);
      case Olhos.sono:
        for (final o in [e, d]) {
          c.drawArc(Rect.fromCenter(center: o, width: .14, height: .1), 0,
              math.pi, false, traco);
        }
      case Olhos.feliz:
        for (final o in [e, d]) {
          c.drawArc(
              Rect.fromCenter(
                  center: o + const Offset(0, .03), width: .14, height: .12),
              math.pi,
              math.pi,
              false,
              traco);
        }
      case Olhos.vesgo:
        for (final (o, dx) in [(e, .03), (d, -.03)]) {
          c.drawCircle(o, .075, Paint()..color = fundo);
          c.drawCircle(o, .075, traco);
          c.drawCircle(o + Offset(dx, 0), .035, cheio);
        }
      case Olhos.arregalados:
        for (final o in [e, d]) {
          c.drawCircle(o, .09, Paint()..color = branco);
          c.drawCircle(o, .09, traco);
          c.drawCircle(o, .04, cheio);
        }
      case Olhos.piscando:
        c.drawCircle(e, .05, cheio);
        c.drawLine(d - const Offset(.06, 0), d + const Offset(.06, 0), traco);
      case Olhos.apaixonado:
        for (final o in [e, d]) {
          c.drawPath(_coracao(o, .14), cheio);
        }
      case Olhos.malandro:
        for (final o in [e, d]) {
          c.drawCircle(o + const Offset(0, .015), .045, cheio);
          c.drawLine(
              o + const Offset(-.07, -.03), o + const Offset(.07, -.03), traco);
        }
    }
  }

  void _boca(Canvas c, Paint traco, Paint cheio) {
    const centro = Offset(.5, .7);
    switch (carinha.boca) {
      case Boca.sorriso:
        c.drawArc(
            Rect.fromCenter(
                center: centro - const Offset(0, .05), width: .3, height: .2),
            .15 * math.pi,
            .7 * math.pi,
            false,
            traco);
      case Boca.risada:
        final r = Rect.fromCenter(
            center: centro - const Offset(0, .04), width: .32, height: .26);
        c.drawArc(r, 0, math.pi, true, cheio);
      case Boca.susto:
        c.drawOval(
            Rect.fromCenter(center: centro, width: .12, height: .15), cheio);
      case Boca.lingua:
        c.drawArc(
            Rect.fromCenter(
                center: centro - const Offset(0, .05), width: .3, height: .2),
            .1 * math.pi,
            .8 * math.pi,
            false,
            traco);
        c.drawArc(
            Rect.fromCenter(
                center: centro + const Offset(.04, .05),
                width: .11,
                height: .14),
            0,
            math.pi,
            true,
            Paint()..color = bochecha);
        c.drawArc(
            Rect.fromCenter(
                center: centro + const Offset(.04, .05),
                width: .11,
                height: .14),
            0,
            math.pi,
            false,
            traco..strokeWidth = .035);
        traco.strokeWidth = .055;
      case Boca.reta:
        c.drawLine(centro - const Offset(.11, 0), centro + const Offset(.11, 0),
            traco);
      case Boca.enjoada:
        final p = Path()..moveTo(centro.dx - .14, centro.dy);
        for (var i = 0; i < 4; i++) {
          final x = centro.dx - .14 + i * .07;
          p.quadraticBezierTo(x + .035, centro.dy + (i.isEven ? -.05 : .05),
              x + .07, centro.dy);
        }
        c.drawPath(p, traco);
      case Boca.dentuca:
        c.drawArc(
            Rect.fromCenter(
                center: centro - const Offset(0, .05), width: .3, height: .2),
            .15 * math.pi,
            .7 * math.pi,
            false,
            traco);
        final dente =
            Rect.fromLTWH(centro.dx - .045, centro.dy + .04, .07, .08);
        c.drawRect(dente, Paint()..color = branco);
        c.drawRect(dente, traco..strokeWidth = .03);
        traco.strokeWidth = .055;
      case Boca.deLado:
        final p = Path()
          ..moveTo(centro.dx - .12, centro.dy + .02)
          ..quadraticBezierTo(centro.dx + .02, centro.dy + .05, centro.dx + .13,
              centro.dy - .05);
        c.drawPath(p, traco);
    }
  }

  void _enfeite(Canvas c, Paint traco, Paint cheio) {
    switch (carinha.enfeite) {
      case Enfeite.nada:
        break;
      case Enfeite.oculos:
        for (final x in [.34, .66]) {
          c.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(x, .46), width: .24, height: .15),
                  const Radius.circular(.05)),
              cheio);
          c.drawLine(
              Offset(x - .07, .42),
              Offset(x - .02, .42),
              Paint()
                ..color = branco.withValues(alpha: .6)
                ..strokeWidth = .025
                ..strokeCap = StrokeCap.round);
        }
        c.drawLine(const Offset(.46, .44), const Offset(.54, .44), traco);
      case Enfeite.bone:
        c.drawRect(const Rect.fromLTWH(0, 0, 1, .24), cheio);
      case Enfeite.festa || Enfeite.fone || Enfeite.topete:
        break; // desenhados em _enfeiteDeFora
      case Enfeite.bigode:
        final p = Path()
          ..moveTo(.5, .6)
          ..quadraticBezierTo(.38, .54, .27, .62)
          ..quadraticBezierTo(.4, .63, .5, .62)
          ..quadraticBezierTo(.6, .63, .73, .62)
          ..quadraticBezierTo(.62, .54, .5, .6)
          ..close();
        c.drawPath(p, cheio);
      case Enfeite.gravata:
        final p = Path()
          ..moveTo(.5, .92)
          ..lineTo(.36, .85)
          ..lineTo(.36, .99)
          ..close()
          ..moveTo(.5, .92)
          ..lineTo(.64, .85)
          ..lineTo(.64, .99)
          ..close();
        c.drawPath(p, cheio);
        c.drawCircle(const Offset(.5, .92), .035, cheio);
    }
  }

  Path _coracao(Offset centro, double largura) {
    final w = largura, x = centro.dx, y = centro.dy;
    return Path()
      ..moveTo(x, y + w * .4)
      ..cubicTo(
          x - w * .9, y - w * .1, x - w * .35, y - w * .75, x, y - w * .25)
      ..cubicTo(x + w * .35, y - w * .75, x + w * .9, y - w * .1, x, y + w * .4)
      ..close();
  }

  @override
  bool shouldRepaint(PintorDeCarinha old) =>
      old.carinha != carinha ||
      old.fundo != fundo ||
      old.tinta != tinta ||
      old.bochecha != bochecha ||
      old.branco != branco ||
      old.assombrada != assombrada ||
      old.olhar != olhar ||
      old.piscando != piscando ||
      old.tonta != tonta;
}

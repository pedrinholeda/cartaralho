import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tema.dart';

/// Os ícones do jogo, desenhados no mesmo traço das carinhas: grosso, de ponta
/// redonda, e quase todos com olhinhos. Ver docs/DESIGN.md.
enum Desenho {
  ajuda,
  som,
  mudo,
  sair,
  trocar,
  juiz,
  dado,
  convite,
  copiar,
  coroa,
  pessoa,
  chave,
  risada,
  choro,
  caveira,
  coracao,
  chocado,
}

/// Um [Desenho] no tamanho e na cor pedidos. Sem cor, usa a do `IconTheme`,
/// então funciona dentro de `IconButton` e `TextButton.icon` como um `Icon`.
class IconeFofo extends StatelessWidget {
  final Desenho desenho;
  final double? tamanho;
  final Color? cor;

  /// Na coroa, quanto as gotas já escorreram (0 a 1).
  final double gotejo;

  const IconeFofo(
    this.desenho, {
    super.key,
    this.tamanho,
    this.cor,
    this.gotejo = 1,
  });

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final lado = tamanho ?? tema.size ?? 24;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(lado),
        painter: PintorDeIcone(
          desenho: desenho,
          cor: cor ?? tema.color ?? Cores.de(context).tintaNaMesa,
          espiao: Cores.de(context).destaque,
          gotejo: gotejo,
        ),
      ),
    );
  }
}

/// Desenha um [Desenho] num quadrado de 32 x 32, escalado para o tamanho.
/// [espiao] é a cor dos olhos que espiam pela porta de sair.
class PintorDeIcone extends CustomPainter {
  final Desenho desenho;
  final Color cor;
  final Color espiao;
  final double gotejo;

  const PintorDeIcone({
    required this.desenho,
    required this.cor,
    required this.espiao,
    this.gotejo = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.shortestSide / 32);
    final t = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final f = Paint()..color = cor;
    void ponto(double x, double y, [double r = 1]) =>
        canvas.drawCircle(Offset(x, y), r, f);
    void sorriso(double x1, double y, double x2, double fundo) =>
        canvas.drawPath(
            Path()
              ..moveTo(x1, y)
              ..quadraticBezierTo((x1 + x2) / 2, fundo, x2, y),
            t);

    switch (desenho) {
      case Desenho.ajuda:
        canvas.drawPath(
            Path()
              ..moveTo(6, 9)
              ..arcToPoint(const Offset(11, 4),
                  radius: const Radius.circular(5))
              ..lineTo(21, 4)
              ..arcToPoint(const Offset(26, 9),
                  radius: const Radius.circular(5))
              ..lineTo(26, 15)
              ..arcToPoint(const Offset(21, 20),
                  radius: const Radius.circular(5))
              ..lineTo(15, 20)
              ..lineTo(10, 25)
              ..lineTo(10, 19.7)
              ..arcToPoint(const Offset(6, 15),
                  radius: const Radius.circular(5))
              ..close(),
            t);
        ponto(12.5, 11);
        ponto(19.5, 11);
        sorriso(14, 15, 18, 16.8);
      case Desenho.som || Desenho.mudo:
        canvas.drawPath(
            Path()
              ..moveTo(4, 12.5)
              ..arcToPoint(const Offset(6, 10.5),
                  radius: const Radius.circular(2))
              ..lineTo(9.5, 10.5)
              ..lineTo(15, 6)
              ..lineTo(15, 26)
              ..lineTo(9.5, 21.5)
              ..lineTo(6, 21.5)
              ..arcToPoint(const Offset(4, 19.5),
                  radius: const Radius.circular(2))
              ..close(),
            t);
        if (desenho == Desenho.som) {
          ponto(9, 14.5, .9);
          sorriso(8, 18, 10.4, 19.2);
          canvas.drawPath(
              Path()
                ..moveTo(19.5, 12.5)
                ..arcToPoint(const Offset(19.5, 19.5),
                    radius: const Radius.circular(4.5)),
              t);
          canvas.drawPath(
              Path()
                ..moveTo(23, 9)
                ..arcToPoint(const Offset(23, 23),
                    radius: const Radius.circular(9)),
              t);
        } else {
          // Mudo: o alto-falante dorme.
          canvas.drawLine(const Offset(7.8, 14.6), const Offset(10, 14.6), t);
          canvas.drawLine(const Offset(19, 12), const Offset(26, 19), t);
          canvas.drawLine(const Offset(26, 12), const Offset(19, 19), t);
        }
      case Desenho.sair:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(8, 4, 16, 24), const Radius.circular(3)),
            t);
        canvas.drawPath(
            Path()
              ..moveTo(8, 4)
              ..lineTo(17, 7.5)
              ..lineTo(17, 28),
            t);
        // Alguém espia pela fresta da porta.
        final olho = Paint()..color = espiao;
        canvas.drawCircle(const Offset(19.6, 15), 1.3, olho);
        canvas.drawCircle(const Offset(22, 15), 1.3, olho);
      case Desenho.trocar:
        for (final (cx, angulo) in [(10.0, -10.0), (22.0, 10.0)]) {
          canvas.save();
          canvas.translate(cx, 16);
          canvas.rotate(angulo * math.pi / 180);
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(center: Offset.zero, width: 11, height: 16),
                  const Radius.circular(2.5)),
              t);
          canvas.restore();
        }
        canvas.drawPath(
            Path()
              ..moveTo(11, 4.5)
              ..quadraticBezierTo(16, 1.5, 21, 4.5)
              ..moveTo(19, 3.3)
              ..lineTo(21, 4.5)
              ..lineTo(19.8, 6.5),
            t);
        canvas.drawPath(
            Path()
              ..moveTo(21, 27.5)
              ..quadraticBezierTo(16, 30.5, 11, 27.5)
              ..moveTo(13, 28.7)
              ..lineTo(11, 27.5)
              ..lineTo(12.2, 25.5),
            t);
      case Desenho.juiz:
        canvas.save();
        canvas.translate(19, 9.5);
        canvas.rotate(math.pi / 4);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: 14, height: 9.5),
                const Radius.circular(3.5)),
            t);
        canvas.drawCircle(const Offset(-2.6, -.4), 1.1, f);
        canvas.drawCircle(const Offset(2.6, -.4), 1.1, f);
        canvas.restore();
        canvas.drawLine(const Offset(14.5, 14.5), const Offset(5.5, 23.5), t);
        canvas.drawLine(const Offset(15, 27.5), const Offset(27, 27.5), t);
      case Desenho.dado:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(5, 5, 22, 22), const Radius.circular(6)),
            t);
        ponto(12, 13, 1.6);
        ponto(20, 13, 1.6);
        sorriso(11.5, 19, 20.5, 22.5);
      case Desenho.convite:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(4, 9, 24, 16), const Radius.circular(3.5)),
            t);
        canvas.drawPath(
            Path()
              ..moveTo(5, 11)
              ..lineTo(16, 18.5)
              ..lineTo(27, 11),
            t);
        canvas.drawPath(
            Path()
              ..moveTo(16, 7.5)
              ..cubicTo(14.4, 4.9, 11, 6.3, 12.4, 8.9)
              ..lineTo(16, 12)
              ..lineTo(19.6, 8.9)
              ..cubicTo(21, 6.3, 17.6, 4.9, 16, 7.5)
              ..close(),
            f);
      case Desenho.copiar:
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(10, 10, 16, 18),
                const Radius.circular(3.5)),
            t);
        canvas.drawPath(
            Path()
              ..moveTo(6, 21)
              ..lineTo(6, 8)
              ..arcToPoint(const Offset(9, 5), radius: const Radius.circular(3))
              ..lineTo(19, 5),
            t);
        ponto(15, 17.5, 1);
        ponto(21, 17.5, 1);
      case Desenho.coroa:
        canvas.drawPath(
            Path()
              ..moveTo(6, 21)
              ..lineTo(4.5, 9.5)
              ..lineTo(10.5, 14.5)
              ..lineTo(16, 7)
              ..lineTo(21.5, 14.5)
              ..lineTo(27.5, 9.5)
              ..lineTo(26, 21)
              ..close(),
            t);
        // As gotas de quem venceu: a coroa derrete aos poucos.
        final g = gotejo.clamp(0.0, 1.0);
        for (final (x, comprimento) in [(9.5, 3.5), (16.0, 6.0), (22.5, 2.5)]) {
          if (g > 0) {
            canvas.drawLine(Offset(x, 21), Offset(x, 21 + comprimento * g), t);
          }
        }
        ponto(13, 16.5, .9);
        ponto(19, 16.5, .9);
      case Desenho.pessoa:
        canvas.drawCircle(const Offset(16, 16), 11, t);
        ponto(12.5, 14, 1.3);
        ponto(19.5, 14, 1.3);
        sorriso(12.5, 19, 19.5, 22);
      case Desenho.risada:
        canvas.drawCircle(const Offset(16, 16), 12, t);
        // Olhos fechados de tanto rir e a boca aberta.
        sorriso(9.5, 13, 14, 10.5);
        sorriso(18, 13, 22.5, 10.5);
        canvas.drawPath(
            Path()
              ..moveTo(9.5, 17.5)
              ..quadraticBezierTo(16, 27, 22.5, 17.5)
              ..close(),
            f);
      case Desenho.choro:
        canvas.drawCircle(const Offset(16, 16), 12, t);
        canvas.drawLine(const Offset(9.5, 13), const Offset(13.5, 13), t);
        canvas.drawLine(const Offset(18.5, 13), const Offset(22.5, 13), t);
        // Lágrimas caindo e a boca para baixo.
        ponto(11, 17.5, 1.4);
        ponto(21, 17.5, 1.4);
        canvas.drawPath(
            Path()
              ..moveTo(12, 23)
              ..quadraticBezierTo(16, 19, 20, 23),
            t);
      case Desenho.caveira:
        canvas.drawPath(
            Path()
              ..moveTo(8, 15)
              ..arcToPoint(const Offset(24, 15),
                  radius: const Radius.circular(8))
              ..lineTo(24, 19)
              ..lineTo(21, 21)
              ..lineTo(21, 26)
              ..lineTo(11, 26)
              ..lineTo(11, 21)
              ..lineTo(8, 19)
              ..close(),
            t);
        ponto(12.5, 15.5, 2.3);
        ponto(19.5, 15.5, 2.3);
        canvas.drawLine(const Offset(14.5, 26), const Offset(14.5, 23), t);
        canvas.drawLine(const Offset(17.5, 26), const Offset(17.5, 23), t);
      case Desenho.coracao:
        canvas.drawPath(
            Path()
              ..moveTo(16, 26)
              ..cubicTo(2, 17, 7, 4, 16, 11)
              ..cubicTo(25, 4, 30, 17, 16, 26)
              ..close(),
            f);
      case Desenho.chocado:
        canvas.drawCircle(const Offset(16, 16), 12, t);
        canvas.drawCircle(const Offset(12, 13), 2.4, t);
        canvas.drawCircle(const Offset(20, 13), 2.4, t);
        canvas.drawOval(
            Rect.fromCenter(
                center: const Offset(16, 21.5), width: 5, height: 6.5),
            f);
      case Desenho.chave:
        canvas.drawCircle(const Offset(10, 16), 5.5, t);
        ponto(10, 16, 1.2);
        canvas.drawLine(const Offset(15.5, 16), const Offset(28, 16), t);
        canvas.drawLine(const Offset(23, 16), const Offset(23, 20), t);
        canvas.drawLine(const Offset(27, 16), const Offset(27, 19), t);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorDeIcone old) =>
      old.desenho != desenho ||
      old.cor != cor ||
      old.espiao != espiao ||
      old.gotejo != gotejo;
}

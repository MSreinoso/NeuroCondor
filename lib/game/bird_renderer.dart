import 'package:flutter/material.dart';

import '../models/character.dart';

/// Ilustrador vectorial de las aves ecuatorianas.
///
/// Cada especie tiene anatomía, silueta y marcas propias. El ave mira hacia la
/// derecha y [wingPosition] anima el aleteo entre -1 (arriba) y 1 (abajo).
class BirdRenderer {
  const BirdRenderer._();

  static const _ink = Color(0xff13282d);

  static void paint({
    required Canvas canvas,
    required Character character,
    required Offset center,
    required double scale,
    double wingPosition = 0,
    double tilt = 0,
    bool shadow = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.scale(scale);

    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(-2, 25),
          width: character == Character.colibri ? 43 : 62,
          height: 9,
        ),
        Paint()..color = _ink.withValues(alpha: .14),
      );
    }

    switch (character) {
      case Character.condor:
        _paintCondor(canvas, wingPosition);
      case Character.piquero:
        _paintBooby(canvas, wingPosition);
      case Character.tucan:
        _paintMountainToucan(canvas, wingPosition);
      case Character.colibri:
        _paintWoodstar(canvas, wingPosition);
      case Character.guacamayo:
        _paintScarletMacaw(canvas, wingPosition);
      case Character.fragata:
        _paintFrigatebird(canvas, wingPosition);
      case Character.gallitoRoca:
        _paintCockOfTheRock(canvas, wingPosition);
      case Character.curiquingue:
        _paintCaracara(canvas, wingPosition);
    }

    canvas.restore();
  }

  static void _paintCondor(Canvas canvas, double wingPosition) {
    const black = Color(0xff202b30);
    const blackSoft = Color(0xff39474c);
    const white = Color(0xfff4f0df);
    const skin = Color(0xffb85a43);
    final y = _wingY(wingPosition, up: -42, down: 29);

    _shape(
      canvas,
      Path()
        ..moveTo(-18, 2)
        ..lineTo(-45, -1)
        ..lineTo(-37, 7)
        ..lineTo(-49, 12)
        ..lineTo(-35, 14)
        ..lineTo(-46, 20)
        ..lineTo(-15, 14)
        ..close(),
      black,
    );
    _condorWing(canvas, y + 7, blackSoft, far: true);
    _oval(canvas, const Rect.fromLTWH(-22, -12, 44, 28), black);
    _condorWing(canvas, y, black);

    final wingPanel = Path()
      ..moveTo(-8, -5)
      ..quadraticBezierTo(-20, y * .42, -37, y + 4)
      ..quadraticBezierTo(-31, y + 12, -22, y + 15)
      ..quadraticBezierTo(-16, 7, -6, 8)
      ..close();
    _shape(canvas, wingPanel, white, outline: false);

    _oval(canvas, const Rect.fromLTWH(7, -15, 22, 18), white);
    _circle(canvas, const Offset(20, -9), 8.3, skin);
    _shape(
      canvas,
      Path()
        ..moveTo(15, -16)
        ..quadraticBezierTo(19, -23, 23, -16)
        ..lineTo(24, -12)
        ..lineTo(17, -12)
        ..close(),
      const Color(0xff8f3f32),
      strokeWidth: 1.3,
    );
    _hookedBeak(
      canvas,
      start: const Offset(26, -12),
      length: 15,
      color: const Color(0xffe7c78a),
      darkTip: true,
    );
    _eye(canvas, const Offset(22, -11), iris: const Color(0xff7c4a2f));
  }

  static void _condorWing(
    Canvas canvas,
    double y,
    Color color, {
    bool far = false,
  }) {
    final span = far ? 48.0 : 57.0;
    final wing = Path()
      ..moveTo(-7, -8)
      ..quadraticBezierTo(-18, y * .45, -34, y - 2)
      ..lineTo(-span, y - 6)
      ..lineTo(-span + 9, y + 1)
      ..lineTo(-span - 1, y + 3)
      ..lineTo(-span + 11, y + 8)
      ..lineTo(-span + 3, y + 11)
      ..lineTo(-span + 18, y + 14)
      ..quadraticBezierTo(-27, 16, -5, 10)
      ..close();
    _shape(canvas, wing, color, strokeWidth: far ? 1.4 : 2);
    if (!far) {
      final feather = Paint()
        ..color = const Color(0xff76858a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round;
      for (var index = 0; index < 3; index++) {
        canvas.drawLine(
          Offset(-23 - index * 7, y * .48 + index * 2),
          Offset(-46 + index * 2, y + 5 + index * 3),
          feather,
        );
      }
    }
  }

  static void _paintBooby(Canvas canvas, double wingPosition) {
    const brown = Color(0xff715447);
    const lightBrown = Color(0xffc6a987);
    const white = Color(0xfffffbef);
    const blue = Color(0xff21afe1);
    final y = _wingY(wingPosition, up: -37, down: 30);

    _shape(
      canvas,
      Path()
        ..moveTo(-19, 1)
        ..lineTo(-44, 2)
        ..lineTo(-28, 12)
        ..lineTo(-17, 13)
        ..close(),
      brown,
    );
    _pointedWing(canvas, y + 6, const Color(0xff967564), far: true);
    _oval(canvas, const Rect.fromLTWH(-24, -10, 46, 25), white);
    canvas.drawArc(
      const Rect.fromLTWH(-22, -10, 37, 17),
      3.35,
      2.65,
      false,
      Paint()
        ..color = lightBrown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    _pointedWing(canvas, y, brown);

    _oval(canvas, const Rect.fromLTWH(10, -17, 21, 20), lightBrown);
    final neckSpeckles = Paint()
      ..color = const Color(0xff8e7160)
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 4; index++) {
      canvas.drawLine(
        Offset(13 + index * 3, -12 + (index.isEven ? 0 : 3)),
        Offset(15 + index * 3, -10 + (index.isEven ? 0 : 3)),
        neckSpeckles,
      );
    }
    _longBeak(
      canvas,
      start: const Offset(27, -13),
      length: 22,
      color: const Color(0xff82949c),
    );

    final legs = Paint()
      ..color = blue
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(-5, 12), const Offset(-8, 20), legs)
      ..drawLine(const Offset(7, 12), const Offset(9, 20), legs);
    _webbedFoot(canvas, const Offset(-8, 20), blue);
    _webbedFoot(canvas, const Offset(9, 20), blue);
    _eye(
      canvas,
      const Offset(22, -12),
      iris: const Color(0xffd9b733),
      radius: 3.1,
    );
  }

  static void _pointedWing(
    Canvas canvas,
    double y,
    Color color, {
    bool far = false,
  }) {
    final span = far ? 43.0 : 51.0;
    _shape(
      canvas,
      Path()
        ..moveTo(-7, -7)
        ..quadraticBezierTo(-18, y * .42, -span, y)
        ..quadraticBezierTo(-35, y + 9, -17, 12)
        ..lineTo(-4, 7)
        ..close(),
      color,
      strokeWidth: far ? 1.3 : 1.9,
    );
  }

  static void _webbedFoot(Canvas canvas, Offset ankle, Color color) {
    _shape(
      canvas,
      Path()
        ..moveTo(ankle.dx, ankle.dy - 1)
        ..lineTo(ankle.dx - 6, ankle.dy + 3)
        ..lineTo(ankle.dx + 1, ankle.dy + 2)
        ..lineTo(ankle.dx + 7, ankle.dy + 4)
        ..close(),
      color,
      strokeWidth: 1.1,
    );
  }

  static void _paintMountainToucan(Canvas canvas, double wingPosition) {
    const olive = Color(0xff536044);
    const blueGray = Color(0xff718a91);
    const black = Color(0xff1d292b);
    const yellow = Color(0xffedc84d);
    const chestnut = Color(0xffa6573f);
    final y = _wingY(wingPosition, up: -33, down: 27);

    _shape(
      canvas,
      Path()
        ..moveTo(-17, 1)
        ..lineTo(-43, -1)
        ..lineTo(-34, 8)
        ..lineTo(-42, 14)
        ..lineTo(-22, 12)
        ..close(),
      black,
    );
    canvas.drawLine(
      const Offset(-38, 10),
      const Offset(-30, 10),
      Paint()
        ..color = chestnut
        ..strokeWidth = 4,
    );
    _roundedWing(canvas, y + 5, const Color(0xff738063), far: true);
    _oval(canvas, const Rect.fromLTWH(-20, -12, 39, 29), blueGray);
    canvas.drawOval(
      const Rect.fromLTWH(-17, 6, 16, 9),
      Paint()..color = const Color(0xffe34f43),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-18, -4, 11, 13),
      Paint()..color = yellow,
    );
    _roundedWing(canvas, y, olive);
    _circle(canvas, const Offset(17, -11), 10.2, black);

    canvas.drawCircle(
      const Offset(19, -12),
      5.2,
      Paint()..color = const Color(0xff62b9c4),
    );
    final beak = Path()
      ..moveTo(21, -18)
      ..quadraticBezierTo(39, -20, 51, -12)
      ..quadraticBezierTo(48, -3, 23, -2)
      ..close();
    _shape(canvas, beak, const Color(0xffb9b64f), strokeWidth: 1.8);
    final billPlate = Path()
      ..moveTo(45, -14)
      ..lineTo(51, -12)
      ..quadraticBezierTo(49, -5, 43, -4)
      ..close();
    _shape(canvas, billPlate, black, outline: false);
    canvas.drawLine(
      const Offset(25, -15),
      const Offset(46, -10),
      Paint()
        ..color = const Color(0xfff0d96c)
        ..strokeWidth = 2,
    );
    _eye(canvas, const Offset(19, -12), radius: 2.7);
  }

  static void _roundedWing(
    Canvas canvas,
    double y,
    Color color, {
    bool far = false,
  }) {
    final span = far ? 35.0 : 41.0;
    _shape(
      canvas,
      Path()
        ..moveTo(-8, -8)
        ..quadraticBezierTo(-17, y * .45, -span, y)
        ..quadraticBezierTo(-span + 2, y + 13, -26, y + 17)
        ..quadraticBezierTo(-16, 14, -5, 8)
        ..close(),
      color,
      strokeWidth: far ? 1.3 : 1.9,
    );
  }

  static void _paintWoodstar(Canvas canvas, double wingPosition) {
    const green = Color(0xff087d67);
    const emerald = Color(0xff20a77f);
    const purple = Color(0xff843fa1);
    const white = Color(0xfffffbef);
    final y = _wingY(wingPosition, up: -39, down: 31);

    _shape(
      canvas,
      Path()
        ..moveTo(-12, 3)
        ..lineTo(-39, -2)
        ..lineTo(-28, 8)
        ..lineTo(-42, 14)
        ..lineTo(-11, 12)
        ..close(),
      const Color(0xff155b58),
      strokeWidth: 1.4,
    );
    _hummingbirdWing(canvas, y + 5, const Color(0xff7ac9c0), far: true);
    _oval(canvas, const Rect.fromLTWH(-16, -9, 31, 21), emerald);
    canvas.drawOval(
      const Rect.fromLTWH(-1, -2, 16, 14),
      Paint()..color = white,
    );
    _hummingbirdWing(canvas, y, const Color(0xff287f82));
    _circle(canvas, const Offset(14, -8), 7.3, green);
    canvas.drawOval(
      const Rect.fromLTWH(8, -5, 13, 11),
      Paint()..color = purple,
    );
    canvas.drawLine(
      const Offset(10, -11),
      const Offset(20, -9),
      Paint()
        ..color = white
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(20, -10),
      const Offset(50, -13),
      Paint()
        ..color = _ink
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    _eye(canvas, const Offset(16, -10), radius: 2.4);
  }

  static void _hummingbirdWing(
    Canvas canvas,
    double y,
    Color color, {
    bool far = false,
  }) {
    final span = far ? 34.0 : 40.0;
    final wing = Path()
      ..moveTo(-4, -5)
      ..quadraticBezierTo(-11, y * .35, -span, y)
      ..quadraticBezierTo(-24, y + 6, -5, 7)
      ..close();
    _shape(
      canvas,
      wing,
      color.withValues(alpha: far ? .46 : .78),
      strokeWidth: 1.2,
    );
    if (!far) {
      canvas.drawLine(
        Offset(-9, y * .25),
        Offset(-span + 5, y + 1),
        Paint()
          ..color = const Color(0xffb5e7df).withValues(alpha: .7)
          ..strokeWidth = 1,
      );
    }
  }

  static void _paintScarletMacaw(Canvas canvas, double wingPosition) {
    const red = Color(0xffdc3f34);
    const blue = Color(0xff287bb5);
    final y = _wingY(wingPosition, up: -39, down: 31);

    _shape(
      canvas,
      Path()
        ..moveTo(-15, 4)
        ..quadraticBezierTo(-39, 17, -57, 37)
        ..quadraticBezierTo(-36, 29, -8, 13)
        ..close(),
      red,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(-18, 7)
        ..quadraticBezierTo(-38, 20, -52, 34)
        ..quadraticBezierTo(-38, 30, -13, 12)
        ..close(),
      blue,
      outline: false,
    );
    _macawWing(canvas, y + 6, const Color(0xffef6a43), far: true);
    _oval(canvas, const Rect.fromLTWH(-19, -12, 39, 28), red);
    _macawWing(canvas, y, red);
    _circle(canvas, const Offset(18, -10), 10.2, red);
    canvas.drawOval(
      const Rect.fromLTWH(13, -14, 13, 13),
      Paint()..color = const Color(0xfffff4df),
    );
    _parrotBeak(canvas);
    _eye(
      canvas,
      const Offset(19, -11),
      iris: const Color(0xffe0c35a),
      radius: 2.8,
    );
  }

  static void _macawWing(
    Canvas canvas,
    double y,
    Color base, {
    bool far = false,
  }) {
    final span = far ? 42.0 : 49.0;
    final wing = Path()
      ..moveTo(-7, -8)
      ..quadraticBezierTo(-18, y * .42, -span, y)
      ..quadraticBezierTo(-span + 5, y + 12, -30, y + 16)
      ..quadraticBezierTo(-19, 14, -5, 9)
      ..close();
    _shape(canvas, wing, base, strokeWidth: far ? 1.3 : 1.9);
    if (!far) {
      final yellowBand = Path()
        ..moveTo(-11, -1)
        ..quadraticBezierTo(-22, y * .48, -38, y + 4)
        ..quadraticBezierTo(-34, y + 10, -24, 10)
        ..close();
      _shape(canvas, yellowBand, const Color(0xffffc83d), outline: false);
      final blueTip = Path()
        ..moveTo(-24, y * .52)
        ..quadraticBezierTo(-36, y - 1, -span, y)
        ..quadraticBezierTo(-span + 5, y + 12, -31, y + 13)
        ..close();
      _shape(canvas, blueTip, const Color(0xff287bb5), outline: false);
    }
  }

  static void _parrotBeak(Canvas canvas) {
    final upper = Path()
      ..moveTo(24, -15)
      ..quadraticBezierTo(40, -14, 38, -5)
      ..quadraticBezierTo(34, 2, 26, -4)
      ..close();
    _shape(canvas, upper, const Color(0xffe6d5ae), strokeWidth: 1.6);
    _shape(
      canvas,
      Path()
        ..moveTo(27, -5)
        ..quadraticBezierTo(35, -2, 30, 3)
        ..quadraticBezierTo(24, 1, 23, -3)
        ..close(),
      const Color(0xff273136),
      strokeWidth: 1.3,
    );
  }

  static void _paintFrigatebird(Canvas canvas, double wingPosition) {
    const black = Color(0xff202c31);
    const sheen = Color(0xff344c4a);
    final y = _wingY(wingPosition, up: -43, down: 28);

    _shape(
      canvas,
      Path()
        ..moveTo(-13, 2)
        ..lineTo(-53, -2)
        ..lineTo(-34, 7)
        ..lineTo(-54, 18)
        ..lineTo(-13, 12)
        ..close(),
      black,
    );
    _frigateWing(canvas, y + 6, sheen, far: true);
    _oval(canvas, const Rect.fromLTWH(-17, -8, 33, 20), black);
    _frigateWing(canvas, y, black);
    _circle(canvas, const Offset(16, -8), 7.2, black);
    _shape(
      canvas,
      Path()
        ..moveTo(7, -3)
        ..quadraticBezierTo(21, -1, 19, 14)
        ..quadraticBezierTo(4, 14, 5, -2)
        ..close(),
      const Color(0xffd9433c),
      strokeWidth: 1.4,
    );
    _hookedBeak(
      canvas,
      start: const Offset(21, -11),
      length: 23,
      color: const Color(0xffcbbd98),
      narrow: true,
    );
    _eye(canvas, const Offset(17, -10), radius: 2.4);
  }

  static void _frigateWing(
    Canvas canvas,
    double y,
    Color color, {
    bool far = false,
  }) {
    final span = far ? 55.0 : 64.0;
    _shape(
      canvas,
      Path()
        ..moveTo(-4, -6)
        ..quadraticBezierTo(-20, y * .45, -span, y)
        ..lineTo(-span + 4, y + 5)
        ..quadraticBezierTo(-28, y + 13, -3, 8)
        ..close(),
      color,
      strokeWidth: far ? 1.2 : 1.8,
    );
  }

  static void _paintCockOfTheRock(Canvas canvas, double wingPosition) {
    const orange = Color(0xfff05a36);
    const black = Color(0xff252c31);
    const silver = Color(0xffb9c1be);
    final y = _wingY(wingPosition, up: -33, down: 29);

    _shape(
      canvas,
      Path()
        ..moveTo(-13, 4)
        ..lineTo(-36, 3)
        ..lineTo(-27, 12)
        ..lineTo(-38, 16)
        ..lineTo(-13, 14)
        ..close(),
      black,
    );
    _roundedWing(canvas, y + 5, const Color(0xff424b50), far: true);
    _oval(canvas, const Rect.fromLTWH(-18, -11, 35, 28), orange);
    _roundedWing(canvas, y, black);
    canvas.drawPath(
      Path()
        ..moveTo(-12, -1)
        ..quadraticBezierTo(-20, y * .4, -32, y + 5),
      Paint()
        ..color = silver
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    final crest = Path()
      ..moveTo(7, -7)
      ..quadraticBezierTo(8, -26, 22, -29)
      ..quadraticBezierTo(36, -25, 31, -11)
      ..quadraticBezierTo(28, -2, 15, 1)
      ..close();
    _shape(canvas, crest, const Color(0xffff673e), strokeWidth: 1.8);
    _shortBeak(
      canvas,
      start: const Offset(27, -10),
      color: const Color(0xfff2c85b),
    );
    _eye(
      canvas,
      const Offset(22, -12),
      iris: const Color(0xffe9d785),
      radius: 3,
    );
  }

  static void _paintCaracara(Canvas canvas, double wingPosition) {
    const black = Color(0xff272e31);
    const white = Color(0xfff2ead8);
    const orange = Color(0xffed7b31);
    final y = _wingY(wingPosition, up: -38, down: 30);

    _shape(
      canvas,
      Path()
        ..moveTo(-18, 2)
        ..lineTo(-45, 1)
        ..lineTo(-35, 8)
        ..lineTo(-44, 14)
        ..lineTo(-17, 15)
        ..close(),
      black,
    );
    canvas.drawLine(
      const Offset(-37, 5),
      const Offset(-28, 6),
      Paint()
        ..color = white
        ..strokeWidth = 4,
    );
    _caracaraWing(canvas, y + 6, const Color(0xff50595b), far: true);
    _oval(canvas, const Rect.fromLTWH(-21, -11, 42, 28), white);
    canvas.drawArc(
      const Rect.fromLTWH(-22, -12, 42, 21),
      3.3,
      2.55,
      false,
      Paint()
        ..color = black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    _caracaraWing(canvas, y, black);
    _shape(
      canvas,
      Path()
        ..moveTo(-8, -5)
        ..quadraticBezierTo(-20, y * .43, -38, y + 4)
        ..quadraticBezierTo(-32, y + 10, -21, 9)
        ..close(),
      white,
      outline: false,
    );

    _oval(canvas, const Rect.fromLTWH(5, -14, 22, 22), white);
    _circle(canvas, const Offset(20, -10), 8.2, black);
    canvas.drawOval(
      const Rect.fromLTWH(18, -14, 11, 10),
      Paint()..color = orange,
    );
    _hookedBeak(
      canvas,
      start: const Offset(25, -11),
      length: 15,
      color: const Color(0xffd8c9a6),
      darkTip: true,
    );

    final streakPaint = Paint()
      ..color = black
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 4; index++) {
      canvas.drawLine(
        Offset(-1 + index * 4, -1),
        Offset(2 + index * 4, 7),
        streakPaint,
      );
    }
    _eye(
      canvas,
      const Offset(22, -11),
      iris: const Color(0xff5d321f),
      radius: 2.7,
    );
  }

  static void _caracaraWing(
    Canvas canvas,
    double y,
    Color color, {
    bool far = false,
  }) {
    final span = far ? 47.0 : 54.0;
    _shape(
      canvas,
      Path()
        ..moveTo(-7, -8)
        ..quadraticBezierTo(-19, y * .44, -37, y - 1)
        ..lineTo(-span, y - 4)
        ..lineTo(-span + 8, y + 2)
        ..lineTo(-span, y + 6)
        ..lineTo(-span + 12, y + 10)
        ..quadraticBezierTo(-28, 16, -5, 9)
        ..close(),
      color,
      strokeWidth: far ? 1.3 : 1.9,
    );
  }

  static double _wingY(
    double position, {
    required double up,
    required double down,
  }) {
    final t = ((position.clamp(-1.0, 1.0) + 1) / 2).toDouble();
    return up + ((down - up) * t);
  }

  static void _hookedBeak(
    Canvas canvas, {
    required Offset start,
    required double length,
    required Color color,
    bool darkTip = false,
    bool narrow = false,
  }) {
    final beak = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        start.dx + length,
        start.dy + (narrow ? 1 : 2),
        start.dx + length,
        start.dy + (narrow ? 5 : 7),
      )
      ..quadraticBezierTo(
        start.dx + length - 4,
        start.dy + (narrow ? 9 : 12),
        start.dx + length - 8,
        start.dy + (narrow ? 5 : 7),
      )
      ..lineTo(start.dx, start.dy + 7)
      ..close();
    _shape(canvas, beak, color, strokeWidth: 1.5);
    if (darkTip) {
      canvas.drawCircle(
        Offset(start.dx + length - 1.8, start.dy + 5),
        2.2,
        Paint()..color = _ink,
      );
    }
  }

  static void _longBeak(
    Canvas canvas, {
    required Offset start,
    required double length,
    required Color color,
  }) {
    _shape(
      canvas,
      Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(start.dx + length, start.dy + 4)
        ..lineTo(start.dx, start.dy + 7)
        ..close(),
      color,
      strokeWidth: 1.4,
    );
  }

  static void _shortBeak(
    Canvas canvas, {
    required Offset start,
    required Color color,
  }) {
    _shape(
      canvas,
      Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(start.dx + 9, start.dy + 4)
        ..lineTo(start.dx, start.dy + 7)
        ..close(),
      color,
      strokeWidth: 1.3,
    );
  }

  static void _eye(
    Canvas canvas,
    Offset center, {
    Color iris = const Color(0xff4a3527),
    double radius = 2.8,
  }) {
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xfffffbef));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(center, radius * .58, Paint()..color = iris);
    canvas.drawCircle(center, radius * .34, Paint()..color = _ink);
    canvas.drawCircle(
      center.translate(radius * .18, -radius * .2),
      radius * .13,
      Paint()..color = Colors.white,
    );
  }

  static void _shape(
    Canvas canvas,
    Path path,
    Color color, {
    double strokeWidth = 1.7,
    bool outline = true,
  }) {
    canvas.drawPath(path, Paint()..color = color);
    if (!outline) return;
    canvas.drawPath(
      path,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _oval(
    Canvas canvas,
    Rect rect,
    Color color, {
    double strokeWidth = 1.7,
  }) {
    canvas.drawOval(rect, Paint()..color = color);
    canvas.drawOval(
      rect,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  static void _circle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
  }
}

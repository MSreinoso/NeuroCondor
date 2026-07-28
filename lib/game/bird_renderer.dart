import 'package:flutter/material.dart';

import '../models/character.dart';

/// Ilustrador vectorial compartido por los retratos y el juego.
///
/// El ave mira hacia la derecha y se dibuja alrededor de [center]. El valor
/// [wingPosition] va de -1 (alas arriba) a 1 (alas abajo).
class BirdRenderer {
  const BirdRenderer._();

  static const _outline = Color(0xff17282d);

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
          center: const Offset(-2, 24),
          width: 58,
          height: 10,
        ),
        Paint()..color = _outline.withValues(alpha: .13),
      );
    }

    final colors = _BirdColors.forCharacter(character);
    _drawTail(canvas, character, colors);
    _drawFarWing(canvas, character, colors, wingPosition);
    _drawBody(canvas, character, colors);
    _drawNearWing(canvas, character, colors, wingPosition);
    _drawHead(canvas, character, colors);
    _drawSpeciesDetails(canvas, character, colors);
    _drawEye(canvas, character);

    canvas.restore();
  }

  static void _drawTail(
    Canvas canvas,
    Character character,
    _BirdColors colors,
  ) {
    late Path tail;
    if (character == Character.guacamayo) {
      tail = Path()
        ..moveTo(-15, 6)
        ..quadraticBezierTo(-38, 14, -52, 34)
        ..quadraticBezierTo(-28, 25, -6, 12)
        ..close();
      _drawOutlined(canvas, tail, colors.tail);
      canvas.drawPath(
        Path()
          ..moveTo(-17, 8)
          ..quadraticBezierTo(-34, 17, -45, 29)
          ..quadraticBezierTo(-31, 23, -10, 12)
          ..close(),
        Paint()..color = const Color(0xff287bb5),
      );
      return;
    }
    if (character == Character.fragata) {
      tail = Path()
        ..moveTo(-14, 4)
        ..lineTo(-42, 2)
        ..lineTo(-31, 12)
        ..lineTo(-45, 22)
        ..lineTo(-12, 13)
        ..close();
      _drawOutlined(canvas, tail, colors.tail);
      return;
    }
    if (character == Character.colibri) {
      tail = Path()
        ..moveTo(-12, 5)
        ..lineTo(-34, 2)
        ..lineTo(-25, 10)
        ..lineTo(-37, 15)
        ..lineTo(-10, 13)
        ..close();
      _drawOutlined(canvas, tail, colors.tail);
      return;
    }

    tail = Path()
      ..moveTo(-14, 3)
      ..lineTo(-36, -1)
      ..lineTo(-28, 8)
      ..lineTo(-38, 14)
      ..lineTo(-12, 13)
      ..close();
    _drawOutlined(canvas, tail, colors.tail);

    canvas.drawLine(
      const Offset(-17, 7),
      const Offset(-32, 5),
      Paint()
        ..color = colors.detail.withValues(alpha: .6)
        ..strokeWidth = 1.5,
    );
  }

  static void _drawFarWing(
    Canvas canvas,
    Character character,
    _BirdColors colors,
    double wingPosition,
  ) {
    final tipY = -29 + ((wingPosition + 1) / 2) * 52;
    final span = character == Character.colibri ? 30.0 : 40.0;
    final path = Path()
      ..moveTo(-5, -3)
      ..quadraticBezierTo(-13, tipY * .45, -span, tipY)
      ..quadraticBezierTo(-span + 8, tipY + 9, -span + 15, tipY + 10)
      ..quadraticBezierTo(-span + 14, tipY + 15, -span + 7, tipY + 18)
      ..quadraticBezierTo(-19, 13, -3, 8)
      ..close();
    _drawOutlined(canvas, path, colors.farWing, strokeWidth: 1.6);
  }

  static void _drawBody(
    Canvas canvas,
    Character character,
    _BirdColors colors,
  ) {
    final bodyRect = character == Character.colibri
        ? const Rect.fromLTWH(-15, -10, 32, 23)
        : const Rect.fromLTWH(-18, -12, 38, 27);
    _drawOutlinedOval(canvas, bodyRect, colors.body, strokeWidth: 1.8);

    if (character == Character.piquero ||
        character == Character.tucan ||
        character == Character.curiquingue) {
      canvas.drawOval(
        const Rect.fromLTWH(-5, -7, 22, 20),
        Paint()..color = colors.chest,
      );
    }
  }

  static void _drawNearWing(
    Canvas canvas,
    Character character,
    _BirdColors colors,
    double wingPosition,
  ) {
    final t = ((wingPosition + 1) / 2).clamp(0.0, 1.0);
    final tipY = -34 + t * 65;
    final span = switch (character) {
      Character.condor || Character.fragata => 47.0,
      Character.colibri => 34.0,
      _ => 41.0,
    };

    final wing = Path()
      ..moveTo(-7, -7)
      ..quadraticBezierTo(-17, tipY * .42, -span, tipY)
      ..quadraticBezierTo(-span + 8, tipY + 8, -span + 15, tipY + 9)
      ..quadraticBezierTo(-span + 10, tipY + 14, -span + 4, tipY + 17)
      ..quadraticBezierTo(-27, 13, -5, 10)
      ..quadraticBezierTo(1, 0, -7, -7)
      ..close();
    _drawOutlined(canvas, wing, colors.wing, strokeWidth: 2);

    final featherPaint = Paint()
      ..color = colors.detail.withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      final offset = index * 5.0;
      final feather = Path()
        ..moveTo(-11 - offset, -1 + t * 6)
        ..quadraticBezierTo(
          -23 - offset,
          tipY * .45 + offset,
          -span + 10 + offset * .35,
          tipY + 8 + offset * .6,
        );
      canvas.drawPath(feather, featherPaint);
    }

    if (character == Character.guacamayo) {
      final band = Path()
        ..moveTo(-8, 1)
        ..quadraticBezierTo(-20, tipY * .42, -34, tipY + 5)
        ..quadraticBezierTo(-28, tipY + 10, -20, 9)
        ..close();
      canvas.drawPath(band, Paint()..color = const Color(0xffffc83d));
      canvas.drawPath(
        Path()
          ..moveTo(-18, 7)
          ..quadraticBezierTo(-28, tipY * .55, -40, tipY + 10)
          ..quadraticBezierTo(-34, tipY + 15, -24, 12)
          ..close(),
        Paint()..color = const Color(0xff287bb5),
      );
    }
  }

  static void _drawHead(
    Canvas canvas,
    Character character,
    _BirdColors colors,
  ) {
    final headCenter = switch (character) {
      Character.colibri => const Offset(15, -7),
      Character.tucan => const Offset(15, -9),
      _ => const Offset(16, -8),
    };
    final radius = character == Character.gallitoRoca ? 11.0 : 9.5;
    _drawOutlinedCircle(canvas, headCenter, radius, colors.head);

    if (character == Character.gallitoRoca) {
      final crest = Path()
        ..moveTo(8, -12)
        ..quadraticBezierTo(13, -27, 29, -19)
        ..quadraticBezierTo(25, -12, 18, -7)
        ..close();
      _drawOutlined(canvas, crest, colors.head, strokeWidth: 1.6);
    }
  }

  static void _drawSpeciesDetails(
    Canvas canvas,
    Character character,
    _BirdColors colors,
  ) {
    switch (character) {
      case Character.condor:
        canvas.drawArc(
          const Rect.fromLTWH(7, -13, 20, 15),
          .05,
          3.0,
          false,
          Paint()
            ..color = const Color(0xfff8f1dc)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        _hookedBeak(canvas, const Color(0xffffc447), length: 14);
        break;
      case Character.piquero:
        _longBeak(canvas, const Color(0xff8d9ca2), length: 18);
        final feet = Paint()
          ..color = const Color(0xff27b8e8)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(const Offset(-2, 13), const Offset(-5, 19), feet)
          ..drawLine(const Offset(8, 12), const Offset(9, 19), feet)
          ..drawLine(const Offset(-9, 19), const Offset(-1, 19), feet)
          ..drawLine(const Offset(5, 19), const Offset(13, 19), feet);
        break;
      case Character.tucan:
        final beak = Path()
          ..moveTo(20, -14)
          ..quadraticBezierTo(39, -15, 48, -7)
          ..quadraticBezierTo(38, 1, 20, -2)
          ..close();
        final shader = const LinearGradient(
          colors: [Color(0xffffd44f), Color(0xffff8a3d)],
        ).createShader(const Rect.fromLTWH(19, -15, 30, 16));
        _drawOutlined(canvas, beak, Colors.transparent, strokeWidth: 1.8);
        canvas.drawPath(beak, Paint()..shader = shader);
        canvas.drawLine(
          const Offset(42, -9),
          const Offset(44, -4),
          Paint()
            ..color = const Color(0xff17282d)
            ..strokeWidth = 2,
        );
        break;
      case Character.colibri:
        canvas.drawOval(
          const Rect.fromLTWH(9, -3, 13, 13),
          Paint()..color = const Color(0xffe84f7b),
        );
        canvas.drawLine(
          const Offset(23, -9),
          const Offset(50, -12),
          Paint()
            ..color = const Color(0xff1a3134)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
        break;
      case Character.guacamayo:
        canvas.drawCircle(
          const Offset(17, -9),
          7,
          Paint()..color = const Color(0xfffff2dc),
        );
        _hookedBeak(canvas, const Color(0xff30383b), length: 15);
        break;
      case Character.fragata:
        final throat = Path()
          ..moveTo(11, -2)
          ..quadraticBezierTo(23, 3, 16, 14)
          ..quadraticBezierTo(5, 9, 7, -1)
          ..close();
        canvas.drawPath(throat, Paint()..color = const Color(0xffdf493f));
        _hookedBeak(canvas, const Color(0xffc9b88e), length: 18);
        break;
      case Character.gallitoRoca:
        canvas.drawOval(
          const Rect.fromLTWH(-2, -4, 18, 17),
          Paint()..color = const Color(0xff252c32),
        );
        _shortBeak(canvas, const Color(0xffffd166));
        break;
      case Character.curiquingue:
        canvas.drawArc(
          const Rect.fromLTWH(7, -14, 20, 17),
          .2,
          2.9,
          false,
          Paint()
            ..color = const Color(0xffffd04d)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        _hookedBeak(canvas, const Color(0xffe5b63f), length: 13);
        break;
    }
  }

  static void _drawEye(Canvas canvas, Character character) {
    final eye = character == Character.tucan
        ? const Offset(17, -11)
        : const Offset(18, -10);
    canvas.drawCircle(eye, 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(eye, 1.65, Paint()..color = _outline);
    canvas.drawCircle(
      eye.translate(.55, -.65),
      .55,
      Paint()..color = Colors.white,
    );
  }

  static void _hookedBeak(Canvas canvas, Color color, {double length = 14}) {
    final beak = Path()
      ..moveTo(23, -12)
      ..quadraticBezierTo(23 + length, -10, 23 + length, -5)
      ..quadraticBezierTo(30, -1, 22, -5)
      ..close();
    _drawOutlined(canvas, beak, color, strokeWidth: 1.6);
  }

  static void _longBeak(Canvas canvas, Color color, {double length = 17}) {
    final beak = Path()
      ..moveTo(23, -12)
      ..lineTo(23 + length, -8)
      ..lineTo(23, -5)
      ..close();
    _drawOutlined(canvas, beak, color, strokeWidth: 1.5);
  }

  static void _shortBeak(Canvas canvas, Color color) {
    final beak = Path()
      ..moveTo(23, -11)
      ..lineTo(32, -7)
      ..lineTo(22, -4)
      ..close();
    _drawOutlined(canvas, beak, color, strokeWidth: 1.5);
  }

  static void _drawOutlined(
    Canvas canvas,
    Path path,
    Color color, {
    double strokeWidth = 2,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round,
    );
    if (color != Colors.transparent) {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  static void _drawOutlinedOval(
    Canvas canvas,
    Rect rect,
    Color color, {
    double strokeWidth = 2,
  }) {
    canvas.drawOval(rect, Paint()..color = color);
    canvas.drawOval(
      rect,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  static void _drawOutlinedCircle(
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
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }
}

class _BirdColors {
  const _BirdColors({
    required this.body,
    required this.head,
    required this.wing,
    required this.farWing,
    required this.tail,
    required this.chest,
    required this.detail,
  });

  final Color body;
  final Color head;
  final Color wing;
  final Color farWing;
  final Color tail;
  final Color chest;
  final Color detail;

  factory _BirdColors.forCharacter(Character character) => switch (character) {
        Character.condor => const _BirdColors(
            body: Color(0xff2d383d),
            head: Color(0xff303a3e),
            wing: Color(0xff202a2f),
            farWing: Color(0xff465359),
            tail: Color(0xff222c31),
            chest: Color(0xfff8f1dc),
            detail: Color(0xff9eafb2),
          ),
        Character.piquero => const _BirdColors(
            body: Color(0xfff5f0df),
            head: Color(0xffd9c3a2),
            wing: Color(0xff72594c),
            farWing: Color(0xffa4826e),
            tail: Color(0xff5c4a42),
            chest: Color(0xfffffbef),
            detail: Color(0xffd9c9b4),
          ),
        Character.tucan => const _BirdColors(
            body: Color(0xff222b2d),
            head: Color(0xff222b2d),
            wing: Color(0xff172125),
            farWing: Color(0xff394649),
            tail: Color(0xff172125),
            chest: Color(0xfffff1cf),
            detail: Color(0xff68777a),
          ),
        Character.colibri => const _BirdColors(
            body: Color(0xff15947f),
            head: Color(0xff0b7569),
            wing: Color(0xff176c70),
            farWing: Color(0xff63c8b3),
            tail: Color(0xff135f64),
            chest: Color(0xff8ee2c6),
            detail: Color(0xff8ee2c6),
          ),
        Character.guacamayo => const _BirdColors(
            body: Color(0xffdf4738),
            head: Color(0xffdf4738),
            wing: Color(0xffd83932),
            farWing: Color(0xfff0713e),
            tail: Color(0xffd83932),
            chest: Color(0xffffc83d),
            detail: Color(0xffffd86a),
          ),
        Character.fragata => const _BirdColors(
            body: Color(0xff263438),
            head: Color(0xff263438),
            wing: Color(0xff1b282d),
            farWing: Color(0xff44555a),
            tail: Color(0xff1d292d),
            chest: Color(0xffdf493f),
            detail: Color(0xff708084),
          ),
        Character.gallitoRoca => const _BirdColors(
            body: Color(0xffef5b35),
            head: Color(0xffff6840),
            wing: Color(0xff252c32),
            farWing: Color(0xff465159),
            tail: Color(0xff252c32),
            chest: Color(0xffef5b35),
            detail: Color(0xff78838a),
          ),
        Character.curiquingue => const _BirdColors(
            body: Color(0xff805c42),
            head: Color(0xff3b302b),
            wing: Color(0xff644635),
            farWing: Color(0xff98765b),
            tail: Color(0xff4c3a31),
            chest: Color(0xfff3ead2),
            detail: Color(0xffc2a985),
          ),
      };
}

import 'package:flutter/material.dart';

import '../game/bird_renderer.dart';
import '../models/character.dart';

class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({
    super.key,
    required this.character,
    this.size = 72,
    this.locked = false,
  });

  final Character character;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) => Semantics(
        label: character.displayName,
        image: true,
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  character.accentColor.withValues(alpha: .52),
                  const Color(0xfffff9ea),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .95),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff173f4b).withValues(alpha: .16),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _PortraitBackgroundPainter(
                      character.primaryColor,
                    ),
                  ),
                  CustomPaint(
                    painter: _CharacterPortraitPainter(character),
                  ),
                  if (locked)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xff173f4b).withValues(alpha: .66),
                      ),
                      child: Center(
                        child: Container(
                          width: size * .38,
                          height: size * .38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            color: const Color(0xff173f4b),
                            size: size * .22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _PortraitBackgroundPainter extends CustomPainter {
  const _PortraitBackgroundPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .025;
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .22),
      size.width * .25,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .76),
      size.width * .31,
      paint,
    );

    final ground = Path()
      ..moveTo(0, size.height * .78)
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .67,
        size.width * .55,
        size.height * .81,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .92,
        size.width,
        size.height * .75,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      ground,
      Paint()..color = color.withValues(alpha: .08),
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CharacterPortraitPainter extends CustomPainter {
  const _CharacterPortraitPainter(this.character);
  final Character character;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 92;
    BirdRenderer.paint(
      canvas: canvas,
      character: character,
      center: Offset(size.width * .48, size.height * .53),
      scale: scale,
      wingPosition: -.48,
      tilt: -.06,
      shadow: true,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterPortraitPainter oldDelegate) =>
      oldDelegate.character != character;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/level_config.dart';
import 'bird_renderer.dart';
import 'game_engine.dart';

class GamePainter extends CustomPainter {
  GamePainter(this.engine, this.avatar);

  final GameEngine engine;
  final Character avatar;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = _WorldPalette.forTheme(engine.level.theme);
    _drawSky(canvas, size, palette);
    _drawSun(canvas, size, palette);
    _drawClouds(canvas, size, palette);
    _drawMountainLayer(canvas, size, .58, palette.mountainBack, .8);
    _drawMountainLayer(canvas, size, .69, palette.mountainFront, 1.15);
    _drawVegetation(canvas, size, palette);
    _drawPlatforms(canvas, size, palette);
    _drawEffects(canvas, size, foreground: false);
    _drawFlightTrail(canvas, size);
    _drawAvatar(canvas, size);
    _drawEffects(canvas, size, foreground: true);
  }

  void _drawSky(Canvas canvas, Size size, _WorldPalette palette) {
    final sky = Paint()
      ..shader = LinearGradient(
        colors: [palette.skyTop, palette.skyBottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final haze = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: .22),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .68, size.height * .25),
          radius: size.width * .58,
        ),
      );
    canvas.drawRect(Offset.zero & size, haze);
  }

  void _drawSun(Canvas canvas, Size size, _WorldPalette palette) {
    final center = Offset(size.width * .78, size.height * .15);
    canvas.drawCircle(
      center,
      34,
      Paint()..color = palette.sun.withValues(alpha: .12),
    );
    canvas.drawCircle(
      center,
      22,
      Paint()..color = palette.sun.withValues(alpha: .82),
    );
  }

  void _drawClouds(Canvas canvas, Size size, _WorldPalette palette) {
    final drift = (engine.simulationTime * 5) % (size.width + 150);
    _cloud(
      canvas,
      Offset((40 + drift) % (size.width + 130) - 70, size.height * .19),
      1,
      palette.cloud,
    );
    _cloud(
      canvas,
      Offset(
        (size.width * .55 + drift * .55) % (size.width + 170) - 80,
        size.height * .32,
      ),
      .72,
      palette.cloud.withValues(alpha: .7),
    );
  }

  void _cloud(Canvas canvas, Offset center, double scale, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 88 * scale,
        height: 22 * scale,
      ),
      paint,
    );
    canvas.drawCircle(
      center.translate(-24 * scale, -8 * scale),
      17 * scale,
      paint,
    );
    canvas.drawCircle(
      center.translate(4 * scale, -14 * scale),
      23 * scale,
      paint,
    );
    canvas.drawCircle(
      center.translate(29 * scale, -7 * scale),
      15 * scale,
      paint,
    );
  }

  void _drawMountainLayer(
    Canvas canvas,
    Size size,
    double baseline,
    Color color,
    double phase,
  ) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, size.height * baseline);
    final points = <Offset>[];
    for (var index = 0; index <= 8; index++) {
      final x = size.width * index / 8;
      final wave = math.sin(index * 1.55 + phase) * .055;
      final peak = index.isEven ? -.09 : .025;
      points.add(Offset(x, size.height * (baseline + wave + peak)));
    }
    path.lineTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      path.quadraticBezierTo(
        (previous.dx + current.dx) / 2,
        previous.dy,
        current.dx,
        current.dy,
      );
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    if (engine.level.theme == LevelTheme.andes) {
      for (var index = 1; index < points.length; index += 2) {
        final peak = points[index];
        final snow = Path()
          ..moveTo(peak.dx - 18, peak.dy + 13)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(peak.dx + 18, peak.dy + 13)
          ..lineTo(peak.dx + 7, peak.dy + 9)
          ..lineTo(peak.dx, peak.dy + 14)
          ..lineTo(peak.dx - 7, peak.dy + 8)
          ..close();
        canvas.drawPath(
          snow,
          Paint()..color = Colors.white.withValues(alpha: .48),
        );
      }
    }
  }

  void _drawVegetation(
    Canvas canvas,
    Size size,
    _WorldPalette palette,
  ) {
    if (engine.level.theme != LevelTheme.amazon) return;
    final paint = Paint()..color = palette.vegetation;
    for (var index = 0; index < 12; index++) {
      final x = size.width * index / 11;
      final baseY = size.height * (.72 + math.sin(index * 2.1) * .018);
      canvas.drawRect(Rect.fromLTWH(x - 2, baseY - 28, 4, 30), paint);
      canvas.drawCircle(Offset(x, baseY - 35), 15, paint);
      canvas.drawCircle(Offset(x - 10, baseY - 28), 11, paint);
      canvas.drawCircle(Offset(x + 10, baseY - 27), 12, paint);
    }
  }

  void _drawPlatforms(
    Canvas canvas,
    Size size,
    _WorldPalette palette,
  ) {
    for (var index = 0; index < engine.level.platforms.length; index++) {
      final platform = engine.level.platforms[index];
      final x = engine.platformX(index) * size.width;
      final y = platform.y * size.height;
      final width = platform.width * size.width;
      final isFinish = index == engine.level.platforms.length - 1;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x + 3, y + 8, width, size.height - y + 8),
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
        ),
        Paint()..color = Colors.black.withValues(alpha: .14),
      );

      final platformRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, width, size.height - y + 8),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      );
      canvas.drawRRect(
        platformRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isFinish ? palette.finishTop : palette.platformTop,
              isFinish ? palette.finishBottom : palette.platformBottom,
            ],
          ).createShader(platformRect.outerRect),
      );

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y - 2, width, 10),
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
        Paint()..color = palette.grass,
      );

      final texture = Paint()
        ..color = Colors.white.withValues(alpha: .12)
        ..strokeWidth = 2;
      for (var lineX = x + 14; lineX < x + width; lineX += 25) {
        canvas.drawLine(
          Offset(lineX, y + 18),
          Offset(lineX - 8, y + 29),
          texture,
        );
      }

      if (platform.hasSpikes) {
        _spikes(canvas, x + width * .30, y, width * .40);
      }
      if (platform.isMoving) {
        canvas.drawCircle(
          Offset(x + width / 2, y + 25),
          9,
          Paint()..color = const Color(0xffffd166),
        );
        canvas.drawCircle(
          Offset(x + width / 2, y + 25),
          4,
          Paint()..color = const Color(0xff6d5636),
        );
      }
      if (isFinish) _finishFlag(canvas, x + width - 18, y);
    }
  }

  void _finishFlag(Canvas canvas, double x, double y) {
    canvas.drawLine(
      Offset(x, y - 47),
      Offset(x, y + 2),
      Paint()
        ..color = const Color(0xfff7efe0)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final flag = Path()
      ..moveTo(x + 1, y - 45)
      ..quadraticBezierTo(x + 19, y - 40, x + 32, y - 45)
      ..lineTo(x + 32, y - 29)
      ..quadraticBezierTo(x + 18, y - 24, x + 1, y - 29)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xffffd166));
  }

  void _spikes(Canvas canvas, double startX, double top, double width) {
    final path = Path()..moveTo(startX, top);
    const count = 4;
    for (var index = 0; index < count; index++) {
      final left = startX + width * index / count;
      path
        ..lineTo(left + width / count / 2, top - 20)
        ..lineTo(left + width / count, top);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffff8567), Color(0xffb83d3d)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(startX, top - 20, width, 20)),
    );
  }

  void _drawFlightTrail(Canvas canvas, Size size) {
    if (engine.state != PlayState.flying) return;
    final center = _avatarCenter(size);
    final speedOpacity = (engine.velocityX * 2.2).clamp(.18, .7);
    for (var index = 0; index < 3; index++) {
      final phase = engine.simulationTime * 7 + index * 1.7;
      final y = center.dy + math.sin(phase) * 7 + index * 4;
      final length = 22.0 + index * 13;
      final trail = Path()
        ..moveTo(center.dx - 26 - index * 10, y)
        ..quadraticBezierTo(
          center.dx - 26 - length * .5,
          y - 5,
          center.dx - 26 - length,
          y + 1,
        );
      canvas.drawPath(
        trail,
        Paint()
          ..color = Colors.white.withValues(
            alpha: speedOpacity * (1 - index * .22),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 - index * .55
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  Offset _avatarCenter(Size size) {
    final bob = switch (engine.state) {
      PlayState.ready ||
      PlayState.charging =>
        math.sin(engine.simulationTime * 3) * 1.5,
      PlayState.completed => math.sin(engine.simulationTime * 5) * 4,
      _ => 0.0,
    };
    return Offset(
      (engine.condorX + .025) * size.width,
      (engine.condorY + .032) * size.height + bob,
    );
  }

  void _drawAvatar(Canvas canvas, Size size) {
    final flying = engine.state == PlayState.flying;
    final speed = switch (avatar) {
      Character.colibri => 10.0,
      Character.piquero || Character.fragata => 4.2,
      Character.condor => 3.2,
      _ => 5.0,
    };
    final wingPosition = switch (engine.state) {
      PlayState.flying => math.sin(engine.simulationTime * speed * math.pi * 2),
      PlayState.completed =>
        math.sin(engine.simulationTime * 4.5 * math.pi * 2),
      PlayState.charging => .46 + math.sin(engine.simulationTime * 3) * .18,
      PlayState.ready => .62 + math.sin(engine.simulationTime * 2.2) * .08,
      PlayState.failed => .95,
    };
    final tilt = flying
        ? (engine.velocityY * .48).clamp(-.30, .42).toDouble()
        : engine.state == PlayState.failed
            ? .38
            : -.04;
    final scale = (size.width / 365).clamp(.82, 1.18).toDouble();

    BirdRenderer.paint(
      canvas: canvas,
      character: avatar,
      center: _avatarCenter(size),
      scale: scale,
      wingPosition: wingPosition,
      tilt: tilt,
      shadow: !flying,
    );
  }

  void _drawEffects(
    Canvas canvas,
    Size size, {
    required bool foreground,
  }) {
    for (final effect in engine.activeEffects) {
      final progress = 1.0 - (effect.timeLeft / effect.maxTime);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      if (!foreground && effect.type == EffectType.dust) {
        final center = Offset(effect.x * size.width, effect.y * size.height);
        for (var index = 0; index < 5; index++) {
          final angle = index * 1.25;
          final distance = 8 + progress * 30;
          canvas.drawCircle(
            center.translate(
              math.cos(angle) * distance,
              -math.sin(angle).abs() * distance * .35,
            ),
            3 + (1 - progress) * 4,
            Paint()..color = Colors.white.withValues(alpha: opacity * .56),
          );
        }
      }

      if (foreground && effect.type == EffectType.flash) {
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xffff5b55).withValues(alpha: opacity * .32),
        );
      }

      if (foreground && effect.type == EffectType.perfect) {
        final x = effect.x * size.width;
        final y = effect.y * size.height - progress * 42;
        final textPainter = TextPainter(
          text: TextSpan(
            text: '¡Precisión!',
            style: TextStyle(
              color: const Color(0xffffd166).withValues(alpha: opacity),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: opacity * .55),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}

class _WorldPalette {
  const _WorldPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.cloud,
    required this.mountainBack,
    required this.mountainFront,
    required this.vegetation,
    required this.platformTop,
    required this.platformBottom,
    required this.finishTop,
    required this.finishBottom,
    required this.grass,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color sun;
  final Color cloud;
  final Color mountainBack;
  final Color mountainFront;
  final Color vegetation;
  final Color platformTop;
  final Color platformBottom;
  final Color finishTop;
  final Color finishBottom;
  final Color grass;

  factory _WorldPalette.forTheme(LevelTheme theme) => switch (theme) {
        LevelTheme.andes => const _WorldPalette(
            skyTop: Color(0xff76b5c5),
            skyBottom: Color(0xffe7d8bd),
            sun: Color(0xffffd166),
            cloud: Color(0xfff7f3e8),
            mountainBack: Color(0xff78938d),
            mountainFront: Color(0xff526f68),
            vegetation: Color(0xff3f6256),
            platformTop: Color(0xff5d7b6d),
            platformBottom: Color(0xff344f48),
            finishTop: Color(0xffb37a4c),
            finishBottom: Color(0xff70462f),
            grass: Color(0xff9dc96f),
          ),
        LevelTheme.coast => const _WorldPalette(
            skyTop: Color(0xff70c3ce),
            skyBottom: Color(0xffffe1a6),
            sun: Color(0xffffc34d),
            cloud: Color(0xfffffbeb),
            mountainBack: Color(0xffd1b78d),
            mountainFront: Color(0xffac8c68),
            vegetation: Color(0xff587c57),
            platformTop: Color(0xffa47b55),
            platformBottom: Color(0xff694c38),
            finishTop: Color(0xff527f8e),
            finishBottom: Color(0xff315462),
            grass: Color(0xff3a9b9a),
          ),
        LevelTheme.amazon => const _WorldPalette(
            skyTop: Color(0xff5a9d88),
            skyBottom: Color(0xffb7d39c),
            sun: Color(0xffffdb72),
            cloud: Color(0xffe8f2dd),
            mountainBack: Color(0xff47745b),
            mountainFront: Color(0xff2d563f),
            vegetation: Color(0xff224c37),
            platformTop: Color(0xff795a3b),
            platformBottom: Color(0xff493522),
            finishTop: Color(0xffab6a3b),
            finishBottom: Color(0xff694126),
            grass: Color(0xff74b85d),
          ),
        LevelTheme.sunset => const _WorldPalette(
            skyTop: Color(0xff534d72),
            skyBottom: Color(0xffe58a6e),
            sun: Color(0xffffd174),
            cloud: Color(0xfff0c5ba),
            mountainBack: Color(0xff4d405d),
            mountainFront: Color(0xff30293f),
            vegetation: Color(0xff2c2638),
            platformTop: Color(0xff67516b),
            platformBottom: Color(0xff3c3046),
            finishTop: Color(0xffb75b44),
            finishBottom: Color(0xff71372f),
            grass: Color(0xffe27b46),
          ),
      };
}

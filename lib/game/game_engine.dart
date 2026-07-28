import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../ble/mirror_protocol.dart';
import '../models/level_config.dart';

enum PlayState { ready, charging, flying, failed, completed }

enum EffectType { dust, perfect, flash }

class VisualEffect {
  VisualEffect({
    required this.type,
    required this.x,
    required this.y,
    required this.maxTime,
  }) : timeLeft = maxTime;

  final EffectType type;
  final double x;
  final double y;
  final double maxTime;
  double timeLeft;
}

class GameEngine extends ChangeNotifier {
  GameEngine(this.level);

  static const condorHeight = .065;
  // La potencia aumenta mientras la mano permanece abierta en modo espejo.
  static const maxCharge = Duration(seconds: 10);
  final LevelConfig level;
  final Stopwatch stopwatch = Stopwatch();
  Timer? _ticker;
  DateTime? _lastTick;

  PlayState state = PlayState.ready;
  double condorX = 0;
  double condorY = 0;
  double velocityX = 0;
  double velocityY = 0;
  double charge = 0;
  double simulationTime = 0;
  int currentPlatform = 0;
  int streak = 0;
  String hint = 'Abre la mano para cargar el vuelo';
  List<VisualEffect> activeEffects = [];
  bool _completionReported = false;
  bool get completionReported => _completionReported;
  Duration get elapsed => stopwatch.elapsed;

  void start() {
    reset();
    stopwatch.start();
    _lastTick = DateTime.now();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _update(),
    );
  }

  double platformX(int index) {
    final platform = level.platforms[index];
    if (!platform.isMoving) return platform.x;
    return platform.x +
        math.sin(simulationTime * platform.moveSpeed * math.pi * 2) *
            platform.moveRange;
  }

  void handleMirrorState(MirrorHandState handState) {
    if (handState == MirrorHandState.stopped && state == PlayState.charging) {
      state = PlayState.ready;
      charge = 0;
      hint = 'Control detenido · abre la mano para cargar';
      notifyListeners();
    } else if (handState == MirrorHandState.open && state == PlayState.ready) {
      state = PlayState.charging;
      hint = 'Mano abierta · cargando…';
      notifyListeners();
    } else if (handState == MirrorHandState.closed &&
        state == PlayState.charging) {
      _jump();
    }
  }

  void _jump() {
    final effectiveCharge = charge.clamp(.16, 1.0);
    velocityX = .20 + .25 * effectiveCharge;
    velocityY = -.52 - .18 * effectiveCharge;
    state = PlayState.flying;
    hint = '¡Vuela!';
    notifyListeners();
  }

  void _update() {
    final now = DateTime.now();
    final dt = math.min(
      now.difference(_lastTick ?? now).inMicroseconds / 1000000,
      .05,
    );
    _lastTick = now;
    simulationTime += dt;

    for (var e in activeEffects) {
      e.timeLeft -= dt;
    }
    activeEffects.removeWhere((e) => e.timeLeft <= 0);

    if (state == PlayState.charging) {
      charge = (charge + dt / (maxCharge.inMilliseconds / 1000)).clamp(0, 1);
    } else if (state == PlayState.ready) {
      final previousX = platformX(currentPlatform);
      final previousTime = simulationTime;
      simulationTime += dt;
      final movement = platformX(currentPlatform) - previousX;
      simulationTime = previousTime;
      condorX += movement;
    } else if (state == PlayState.flying) {
      final oldFeet = condorY + condorHeight;
      condorX += velocityX * dt;
      velocityY += 1.25 * dt;
      condorY += velocityY * dt;
      final newFeet = condorY + condorHeight;
      if (velocityY > 0) _tryLanding(oldFeet, newFeet);
      if (condorY > 1.05 || condorX > 1.08) {
        _fail('El ave cayó. Inténtalo de nuevo.');
      }
    }
    notifyListeners();
  }

  void _tryLanding(double oldFeet, double newFeet) {
    for (var index = currentPlatform + 1;
        index < level.platforms.length;
        index++) {
      final platform = level.platforms[index];
      final x = platformX(index);
      final center = condorX + .025;
      final crossesTop = oldFeet <= platform.y && newFeet >= platform.y;
      if (!crossesTop || center < x || center > x + platform.width) continue;
      final spikeStart = x + platform.width * .30;
      final spikeEnd = x + platform.width * .70;
      if (platform.hasSpikes && center >= spikeStart && center <= spikeEnd) {
        _fail('Cuidado con las espinas.');
        return;
      }
      currentPlatform = index;
      condorY = platform.y - condorHeight;
      velocityX = 0;
      velocityY = 0;
      charge = 0;
      streak++;

      activeEffects.add(
        VisualEffect(
          type: EffectType.dust,
          x: center,
          y: platform.y,
          maxTime: 0.5,
        ),
      );
      final platformCenter = x + platform.width / 2;
      if ((center - platformCenter).abs() < 0.05) {
        activeEffects.add(
          VisualEffect(
            type: EffectType.perfect,
            x: center,
            y: condorY - 0.05,
            maxTime: 1.0,
          ),
        );
      }

      if (index == level.platforms.length - 1) {
        state = PlayState.completed;
        stopwatch.stop();
        hint = '¡Nivel completado! · $streak saltos seguidos';
      } else {
        state = PlayState.ready;
        hint = _getPositiveMessage(streak);
      }
      return;
    }
  }

  String _getPositiveMessage(int streakCount) {
    if (streakCount == 1) return '¡Bien hecho! Abre para continuar';
    if (streakCount == 2) return '¡Excelente! Mantén el ritmo 🔥';
    if (streakCount == 3) return '¡Imparable! Racha x3 🦅';
    if (streakCount >= 4) return '¡Modo Dios! Racha x$streakCount 🚀';
    return 'Abre la mano para el siguiente vuelo';
  }

  void _fail(String message) {
    state = PlayState.failed;
    stopwatch.stop();
    streak = 0;
    hint = message;
    activeEffects.add(
      VisualEffect(type: EffectType.flash, x: 0, y: 0, maxTime: 0.3),
    );
  }

  void markCompletionReported() => _completionReported = true;

  void reset() {
    stopwatch
      ..stop()
      ..reset();
    final first = level.platforms.first;
    simulationTime = 0;
    currentPlatform = 0;
    condorX = first.x + first.width * .55;
    condorY = first.y - condorHeight;
    velocityX = 0;
    velocityY = 0;
    charge = 0;
    streak = 0;
    state = PlayState.ready;
    hint = 'Abre la mano para cargar el vuelo';
    activeEffects.clear();
    _completionReported = false;
  }

  void restart() {
    reset();
    stopwatch.start();
    _lastTick = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    stopwatch.stop();
    super.dispose();
  }
}

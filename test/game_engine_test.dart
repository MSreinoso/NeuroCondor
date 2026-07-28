import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/ble/mirror_protocol.dart';
import 'package:neuro_condor/game/game_engine.dart';
import 'package:neuro_condor/models/level_config.dart';

void main() {
  test('abrir carga y cerrar libera el vuelo', () {
    final engine = GameEngine(LevelConfig.tutorial);
    engine.start();
    addTearDown(engine.dispose);

    engine.handleMirrorState(MirrorHandState.closed);
    expect(engine.state, PlayState.ready);
    engine.handleMirrorState(MirrorHandState.open);
    expect(engine.state, PlayState.charging);
    engine.handleMirrorState(MirrorHandState.closed);
    expect(engine.state, PlayState.flying);
    engine.handleMirrorState(MirrorHandState.closed);
    expect(engine.state, PlayState.flying);
  });

  test('la parada segura cancela una carga activa', () {
    final engine = GameEngine(LevelConfig.tutorial);
    engine.start();
    addTearDown(engine.dispose);

    engine.handleMirrorState(MirrorHandState.open);
    expect(engine.state, PlayState.charging);
    engine.handleMirrorState(MirrorHandState.stopped);

    expect(engine.state, PlayState.ready);
    expect(engine.charge, 0);
  });
}

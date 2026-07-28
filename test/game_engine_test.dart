import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/ble/ble_protocol.dart';
import 'package:neuro_condor/game/game_engine.dart';
import 'package:neuro_condor/models/level_config.dart';

void main() {
  test('solo la transición pin 1 a pin 0 dispara el salto', () {
    final engine = GameEngine(LevelConfig.tutorial);
    engine.start();
    addTearDown(engine.dispose);

    engine.handleDigitalInput(DigitalPinState.inactive);
    expect(engine.state, PlayState.ready);
    engine.handleDigitalInput(DigitalPinState.active);
    expect(engine.state, PlayState.charging);
    engine.handleDigitalInput(DigitalPinState.inactive);
    expect(engine.state, PlayState.flying);
    engine.handleDigitalInput(DigitalPinState.inactive);
    expect(engine.state, PlayState.flying);
  });
}

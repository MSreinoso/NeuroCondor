import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/ble/ble_protocol.dart';

void main() {
  test('decodifica los estados del pin digital', () {
    expect(
      (parseDeviceMessage('P,1') as DigitalPinEvent).state,
      DigitalPinState.active,
    );
    expect(
      (parseDeviceMessage('P,0\n') as DigitalPinEvent).state,
      DigitalPinState.inactive,
    );
  });

  test('decodifica fase y cuenta regresiva del guante', () {
    final event = parseDeviceMessage('G,CLOSING,4') as GlovePhaseEvent;
    expect(event.phase, GlovePhase.closing);
    expect(event.secondsRemaining, 4);
    expect(
      (parseDeviceMessage('G,OPEN_READY,0') as GlovePhaseEvent).phase,
      GlovePhase.readyOpen,
    );
  });
}

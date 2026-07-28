import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/ble/mirror_protocol.dart';

void main() {
  test('modo espejo usa un único protocolo canónico', () {
    expect(MirrorHandState.open.command, 'M,0');
    expect(MirrorHandState.closed.command, 'M,1');
    expect(MirrorHandState.stopped.command, 'M,2');
  });
}

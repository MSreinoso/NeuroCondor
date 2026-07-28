import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/ble/mirror_protocol.dart';

void main() {
  test('el nivel del GPIO 35 se convierte en estado de mano', () {
    expect(parseMirrorControl('1\n'), MirrorHandState.open);
    expect(parseMirrorControl('0\n'), MirrorHandState.closed);
    expect(parseMirrorControl('M,0'), isNull);
  });
}

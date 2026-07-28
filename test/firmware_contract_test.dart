import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/ble/condor_ble_service.dart';

void main() {
  final firmware = File(
    'firmware/neuro_condor_esp32/neuro_condor_esp32.ino',
  ).readAsStringSync();

  test('app y firmware comparten los UUID de ANTARA', () {
    expect(firmware, contains(CondorBleService.serviceUuid.str));
    expect(firmware, contains(CondorBleService.mirrorRxUuid.str));
    expect(firmware, contains('"ANTARA"'));
  });

  test('firmware conserva únicamente el modo espejo', () {
    for (final command in ['M,0', 'M,1', 'M,2']) {
      expect(firmware, contains(command));
    }
    expect(firmware, isNot(contains('procesarAutomatico')));
    expect(firmware, isNot(contains('V,1010111')));
    expect(firmware, isNot(contains('PINES_VIBRADORES')));
  });

  test('firmware usa el cableado definitivo de ANTARA', () {
    expect(firmware, contains('PIN_MOTOR_PRINCIPAL = 27'));
    expect(firmware, contains('PIN_VALVULA_INFLAR = 25'));
    expect(firmware, contains('PIN_VALVULA_DESINFLAR = 32'));
    expect(firmware, contains('INTERBLOQUEO_MS = 35'));
  });
}

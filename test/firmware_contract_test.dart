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
    expect(firmware, contains(CondorBleService.mirrorTxUuid.str));
    expect(firmware, contains('"ANTARA"'));
  });

  test('firmware conserva únicamente el modo espejo', () {
    expect(firmware, contains('M,2'));
    expect(firmware, isNot(contains('comando == "M,0"')));
    expect(firmware, isNot(contains('comando == "M,1"')));
    expect(firmware, isNot(contains('procesarAutomatico')));
    expect(firmware, isNot(contains('V,1010111')));
    expect(firmware, isNot(contains('PINES_VIBRADORES')));
  });

  test('firmware usa el cableado definitivo de ANTARA', () {
    expect(firmware, contains('PIN_MOTOR_PRINCIPAL = 27'));
    expect(firmware, contains('PIN_VALVULA_INFLAR = 25'));
    expect(firmware, contains('PIN_VALVULA_DESINFLAR = 32'));
    expect(firmware, contains('PIN_CONTROL = 35'));
    expect(firmware, contains('pinMode(PIN_CONTROL, INPUT)'));
    expect(firmware, contains('ANTIRREBOTE_MS = 35'));
  });
}

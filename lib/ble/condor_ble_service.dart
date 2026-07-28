import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'mirror_protocol.dart';

class CondorBleService extends ChangeNotifier {
  static final serviceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  static final mirrorRxUuid = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e');

  final _mirrorEvents = StreamController<MirrorHandState>.broadcast();
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothCharacteristic? _mirrorCharacteristic;
  BluetoothDevice? _device;

  Stream<MirrorHandState> get mirrorEvents => _mirrorEvents.stream;
  bool get isConnected =>
      _device?.isConnected == true && _mirrorCharacteristic != null;
  bool get isWebIos => kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get canUseBle => _canUseBle;
  bool get bleCapabilityKnown => _bleCapabilityKnown;
  bool get isWebBluetoothUnsupported =>
      kIsWeb && _bleCapabilityKnown && !_canUseBle;
  MirrorHandState mirrorState = MirrorHandState.stopped;
  bool _canUseBle = !kIsWeb;
  bool _bleCapabilityKnown = !kIsWeb;
  String status = kIsWeb ? 'Comprobando Bluetooth…' : 'Sin conectar';

  Future<void> initialize() async {
    if (!kIsWeb || _bleCapabilityKnown) return;
    _canUseBle = await FlutterBluePlus.isSupported;
    _bleCapabilityKnown = true;
    status = _canUseBle
        ? 'Bluetooth disponible'
        : 'Web Bluetooth no disponible en este navegador';
    notifyListeners();
  }

  Future<List<ScanResult>> scan() async {
    await initialize();
    if (!canUseBle) {
      status = 'Web Bluetooth no disponible en este navegador';
      notifyListeners();
      throw UnsupportedError(
        'Usa Chrome o Edge en PC/Android, o Bluefy en iPhone.',
      );
    }

    status = 'Buscando ANTARA…';
    notifyListeners();
    final found = <String, ScanResult>{};
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        if (result.advertisementData.advName == 'ANTARA') {
          found[result.device.remoteId.str] = result;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        withServices: [serviceUuid],
      );
      await FlutterBluePlus.isScanning.where((value) => !value).first;
      status = found.isEmpty
          ? 'No se encontró el dispositivo ANTARA'
          : '${found.length} dispositivo(s) ANTARA';
      return found.values.toList();
    } finally {
      await subscription.cancel();
      notifyListeners();
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    status = 'Conectando con ANTARA…';
    notifyListeners();

    try {
      await device.connect(timeout: const Duration(seconds: 12));
      final services = await device.discoverServices();
      final service = services.firstWhere((item) => item.uuid == serviceUuid);
      final characteristic = service.characteristics.firstWhere(
        (item) => item.uuid == mirrorRxUuid,
      );
      if (!characteristic.properties.write &&
          !characteristic.properties.writeWithoutResponse) {
        throw StateError('La característica ANTARA RX no admite escritura.');
      }

      await _connectionSubscription?.cancel();
      _device = device;
      _mirrorCharacteristic = characteristic;
      mirrorState = MirrorHandState.stopped;
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            _device == device) {
          _device = null;
          _mirrorCharacteristic = null;
          mirrorState = MirrorHandState.stopped;
          status = 'ANTARA desconectado · actuadores detenidos';
          _mirrorEvents.add(MirrorHandState.stopped);
          notifyListeners();
        }
      });
      status = 'ANTARA conectado · modo espejo';
      notifyListeners();
    } catch (_) {
      await device.disconnect();
      status = 'No fue posible conectar con ANTARA';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMirrorState(MirrorHandState state) async {
    final characteristic = _mirrorCharacteristic;
    if (!isConnected || characteristic == null) {
      throw StateError('Conecta ANTARA antes de controlar el guante.');
    }

    final withoutResponse = characteristic.properties.writeWithoutResponse &&
        !characteristic.properties.write;
    await characteristic.write(
      utf8.encode('${state.command}\n'),
      withoutResponse: withoutResponse,
    );

    mirrorState = state;
    status = state.label;
    _mirrorEvents.add(state);
    notifyListeners();
  }

  Future<void> stopMirror() async {
    if (!isConnected) return;
    await sendMirrorState(MirrorHandState.stopped);
  }

  Future<void> disconnect() async {
    try {
      await stopMirror();
    } catch (_) {
      // La desconexión del ESP32 también apaga todas las salidas.
    }
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    final device = _device;
    _device = null;
    _mirrorCharacteristic = null;
    mirrorState = MirrorHandState.stopped;
    await device?.disconnect();
    status = 'Sin conectar';
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _mirrorEvents.close();
    super.dispose();
  }
}

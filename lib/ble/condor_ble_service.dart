import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'mirror_protocol.dart';

class CondorBleService extends ChangeNotifier {
  static final serviceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  static final mirrorRxUuid = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
  static final mirrorTxUuid = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

  final _mirrorEvents = StreamController<MirrorHandState>.broadcast();
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _controlSubscription;
  BluetoothCharacteristic? _mirrorRx;
  BluetoothCharacteristic? _mirrorTx;
  BluetoothDevice? _device;
  String _receiveBuffer = '';

  Stream<MirrorHandState> get mirrorEvents => _mirrorEvents.stream;
  bool get isConnected =>
      _device?.isConnected == true && _mirrorRx != null && _mirrorTx != null;
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
      final rx = service.characteristics.firstWhere(
        (item) => item.uuid == mirrorRxUuid,
      );
      final tx = service.characteristics.firstWhere(
        (item) => item.uuid == mirrorTxUuid,
      );
      if (!rx.properties.write && !rx.properties.writeWithoutResponse) {
        throw StateError('La característica ANTARA RX no admite escritura.');
      }
      if (!tx.properties.notify || !tx.properties.read) {
        throw StateError('La característica ANTARA TX no admite read/notify.');
      }

      await _connectionSubscription?.cancel();
      await _controlSubscription?.cancel();
      _device = device;
      _mirrorRx = rx;
      _mirrorTx = tx;
      _receiveBuffer = '';
      mirrorState = MirrorHandState.stopped;

      _controlSubscription = tx.onValueReceived.listen(_receiveControl);
      await tx.setNotifyValue(true);
      _receiveControl(await tx.read());

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            _device == device) {
          unawaited(_controlSubscription?.cancel());
          _controlSubscription = null;
          _device = null;
          _mirrorRx = null;
          _mirrorTx = null;
          _receiveBuffer = '';
          _publishState(MirrorHandState.stopped);
          status = 'ANTARA desconectado · actuadores detenidos';
          notifyListeners();
        }
      });
      status = 'ANTARA conectado · GPIO 35 activo';
      notifyListeners();
    } catch (_) {
      await device.disconnect();
      status = 'No fue posible conectar con ANTARA';
      notifyListeners();
      rethrow;
    }
  }

  void _receiveControl(List<int> bytes) {
    _receiveBuffer += utf8.decode(bytes, allowMalformed: true);
    while (true) {
      final lineEnd = _receiveBuffer.indexOf('\n');
      if (lineEnd < 0) break;
      final line = _receiveBuffer.substring(0, lineEnd);
      _receiveBuffer = _receiveBuffer.substring(lineEnd + 1);
      final state = parseMirrorControl(line);
      if (state != null) _publishState(state);
    }
  }

  void _publishState(MirrorHandState state) {
    mirrorState = state;
    status = state.label;
    _mirrorEvents.add(state);
    notifyListeners();
  }

  Future<void> stopMirror() async {
    final characteristic = _mirrorRx;
    if (!isConnected || characteristic == null) return;
    final withoutResponse = characteristic.properties.writeWithoutResponse &&
        !characteristic.properties.write;
    await characteristic.write(
      utf8.encode('M,2\n'),
      withoutResponse: withoutResponse,
    );
    _publishState(MirrorHandState.stopped);
  }

  Future<void> disconnect() async {
    try {
      await stopMirror();
    } catch (_) {
      // La desconexión del ESP32 también apaga todas las salidas.
    }
    final tx = _mirrorTx;
    if (tx != null) {
      try {
        await tx.setNotifyValue(false);
      } catch (_) {
        // El enlace puede haberse cerrado antes de desactivar notify.
      }
    }
    await _controlSubscription?.cancel();
    _controlSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    final device = _device;
    _device = null;
    _mirrorRx = null;
    _mirrorTx = null;
    _receiveBuffer = '';
    mirrorState = MirrorHandState.stopped;
    await device?.disconnect();
    status = 'Sin conectar';
    notifyListeners();
  }

  @override
  void dispose() {
    _controlSubscription?.cancel();
    _connectionSubscription?.cancel();
    _mirrorEvents.close();
    super.dispose();
  }
}

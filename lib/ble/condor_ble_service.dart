import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_protocol.dart';

class CondorBleService extends ChangeNotifier {
  static final serviceUuid = Guid('7d9b0001-8e7f-4b7f-a8d1-3a6b5c2d1000');
  static final notifyUuid = Guid('7d9b0002-8e7f-4b7f-a8d1-3a6b5c2d1000');

  final _events = StreamController<DeviceEvent>.broadcast();
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothDevice? _device;

  Stream<DeviceEvent> get events => _events.stream;
  bool get isConnected => _device?.isConnected ?? false;
  bool get isDemoMode => _demoMode;
  bool get isWebIos => kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get canUseBle => _canUseBle;
  bool get bleCapabilityKnown => _bleCapabilityKnown;
  bool get isWebBluetoothUnsupported =>
      kIsWeb && _bleCapabilityKnown && !_canUseBle;
  bool _demoMode = false;
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
    status = 'Buscando ESP32…';
    notifyListeners();
    final found = <String, ScanResult>{};
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.advertisementData.advName;
        if (name.startsWith('NeuroCondor')) {
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
          ? 'No se encontró NeuroCondor-ESP32'
          : '${found.length} dispositivo(s)';
      return found.values.toList();
    } finally {
      await subscription.cancel();
      notifyListeners();
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    status = 'Conectando…';
    notifyListeners();
    await device.connect(timeout: const Duration(seconds: 12));
    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected && _device == device) {
        _device = null;
        status = 'ESP32 desconectado';
        notifyListeners();
      }
    });
    final services = await device.discoverServices();
    final service = services.where((item) => item.uuid == serviceUuid).first;
    final notify =
        service.characteristics.where((item) => item.uuid == notifyUuid).first;
    await notify.setNotifyValue(true);
    _notificationSubscription = notify.onValueReceived.listen((bytes) {
      for (final line in utf8.decode(bytes, allowMalformed: true).split('\n')) {
        final event = parseDeviceMessage(line);
        if (event != null) _events.add(event);
      }
    });
    _device = device;
    _demoMode = false;
    status =
        'Conectado a ${device.platformName.isEmpty ? 'ESP32' : device.platformName}';
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _device?.disconnect();
    _device = null;
    status = 'Sin conectar';
    notifyListeners();
  }

  void enableDemoMode() {
    _demoMode = true;
    status = 'Modo demostración';
    notifyListeners();
  }

  void emitDemoPin(DigitalPinState state) {
    if (_demoMode) _events.add(DigitalPinEvent(state));
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _events.close();
    super.dispose();
  }
}

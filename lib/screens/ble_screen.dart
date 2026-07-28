import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble/condor_ble_service.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({super.key, required this.ble});
  final CondorBleService ble;

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  List<ScanResult> results = [];
  bool busy = false;
  String? error;

  Future<void> scan() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      results = await widget.ble.scan();
    } catch (exception) {
      error =
          'No fue posible buscar dispositivos. Verifica Bluetooth y permisos.\n$exception';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> connect(BluetoothDevice device) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.ble.connect(device);
      if (mounted) Navigator.pop(context);
    } catch (exception) {
      error = 'Falló la conexión: $exception';
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Control BLE')),
        body: AnimatedBuilder(
          animation: widget.ble,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.ble.isWebBluetoothUnsupported) ...[
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Versión web para iPhone',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.ble.isWebIos
                              ? 'Chrome y Safari para iPhone no ofrecen Web '
                                  'Bluetooth. Instala Bluefy, abre allí la '
                                  'dirección de Neuro Cóndor y pulsa Buscar '
                                  'ESP32.'
                              : 'Este navegador no ofrece Web Bluetooth. Abre '
                                  'la aplicación con Chrome o Edge en una PC '
                                  'con Bluetooth, usando la dirección HTTPS.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: ListTile(
                  leading: Icon(
                    widget.ble.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth,
                  ),
                  title: Text(widget.ble.status),
                  subtitle: const Text(
                    'El ESP32 debe anunciarse como NeuroCondor-ESP32',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              for (final result in results)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.memory),
                    title: Text(
                      result.advertisementData.advName.isEmpty
                          ? 'NeuroCondor ESP32'
                          : result.advertisementData.advName,
                    ),
                    subtitle: Text(
                      '${result.rssi} dBm · ${result.device.remoteId.str}',
                    ),
                    trailing: FilledButton(
                      onPressed: busy ? null : () => connect(result.device),
                      child: const Text('Conectar'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy ||
                        !widget.ble.bleCapabilityKnown ||
                        !widget.ble.canUseBle
                    ? null
                    : scan,
                icon: const Icon(Icons.radar),
                label: Text(
                  !widget.ble.bleCapabilityKnown
                      ? 'Comprobando Bluetooth…'
                      : !widget.ble.canUseBle
                          ? 'Bluetooth no disponible aquí'
                          : busy
                              ? 'Buscando…'
                              : 'Buscar ESP32',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () {
                        widget.ble.enableDemoMode();
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.science_outlined),
                label: Text(
                  widget.ble.isWebBluetoothUnsupported
                      ? 'Continuar sin Bluetooth'
                      : 'Usar modo demostración',
                ),
              ),
              if (widget.ble.isConnected) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.ble.disconnect,
                  child: const Text('Desconectar'),
                ),
              ],
            ],
          ),
        ),
      );
}

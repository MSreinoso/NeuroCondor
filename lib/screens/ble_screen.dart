import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble/condor_ble_service.dart';
import '../ble/mirror_protocol.dart';

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
          'No fue posible buscar ANTARA. Verifica Bluetooth y permisos.\n$exception';
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
    } catch (exception) {
      error = 'Falló la conexión con ANTARA: $exception';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> send(MirrorHandState state) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.ble.sendMirrorState(state);
    } catch (exception) {
      error = 'No se pudo enviar ${state.command}: $exception';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> disconnect() async {
    setState(() => busy = true);
    await widget.ble.disconnect();
    if (mounted) {
      setState(() {
        busy = false;
        results = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ANTARA · modo espejo')),
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
                                'Navegador sin Web Bluetooth',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.ble.isWebIos
                              ? 'En iPhone abre Neuro Cóndor desde Bluefy para '
                                  'conectarte con ANTARA.'
                              : 'Abre la aplicación con Chrome o Edge y usa '
                                  'una dirección HTTPS.',
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
                    'Nombre BLE: ANTARA · servicio 6e400001…',
                  ),
                ),
              ),
              if (widget.ble.isConnected) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Prueba del modo espejo',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Abrir infla el guante; cerrar lo desinfla. La parada '
                          'apaga motor y válvulas.',
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed:
                              busy ? null : () => send(MirrorHandState.open),
                          icon: const Icon(Icons.pan_tool_outlined),
                          label: const Text('Abrir mano · M,0'),
                        ),
                        const SizedBox(height: 9),
                        FilledButton.tonalIcon(
                          onPressed:
                              busy ? null : () => send(MirrorHandState.closed),
                          icon: const Icon(Icons.front_hand_outlined),
                          label: const Text('Cerrar mano · M,1'),
                        ),
                        const SizedBox(height: 9),
                        OutlinedButton.icon(
                          onPressed:
                              busy ? null : () => send(MirrorHandState.stopped),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Parada segura · M,2'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              for (final result in results)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.memory),
                    title: Text(
                      result.advertisementData.advName.isEmpty
                          ? 'ANTARA'
                          : result.advertisementData.advName,
                    ),
                    subtitle: Text(
                      '${result.rssi} dBm · ${result.device.remoteId.str}',
                    ),
                    trailing: FilledButton(
                      onPressed: busy || widget.ble.isConnected
                          ? null
                          : () => connect(result.device),
                      child: const Text('Conectar'),
                    ),
                  ),
                ),
              if (!widget.ble.isConnected)
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
                                : 'Buscar ANTARA',
                  ),
                )
              else
                TextButton.icon(
                  onPressed: busy ? null : disconnect,
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('Detener y desconectar'),
                ),
            ],
          ),
        ),
      );
}

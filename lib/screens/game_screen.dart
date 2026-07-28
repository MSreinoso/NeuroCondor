import 'dart:async';

import 'package:flutter/material.dart';

import '../ble/condor_ble_service.dart';
import '../ble/mirror_protocol.dart';
import '../data/local_progress_repository.dart';
import '../game/game_engine.dart';
import '../game/game_painter.dart';
import '../models/character.dart';
import '../models/level_config.dart';
import '../widgets/time_text.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.repository,
    required this.ble,
  });
  final LevelConfig level;
  final LocalProgressRepository repository;
  final CondorBleService ble;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameEngine engine = GameEngine(widget.level);
  StreamSubscription<MirrorHandState>? mirrorSubscription;
  bool saving = false;
  bool commandBusy = false;
  int? earnedCoins;

  @override
  void initState() {
    super.initState();
    engine.addListener(onEngineChanged);
    mirrorSubscription = widget.ble.mirrorEvents.listen(
      engine.handleMirrorState,
    );
    engine.start();
  }

  void onEngineChanged() {
    if (engine.state == PlayState.completed &&
        !engine.completionReported &&
        !saving) {
      engine.markCompletionReported();
      saving = true;
      unawaited(widget.ble.stopMirror());
      widget.repository.completeLevel(widget.level.id, engine.elapsed).then((
        reward,
      ) {
        if (!mounted) return;
        setState(() {
          saving = false;
          earnedCoins = reward;
        });
      });
    }
  }

  @override
  void dispose() {
    unawaited(widget.ble.stopMirror());
    mirrorSubscription?.cancel();
    engine.removeListener(onEngineChanged);
    engine.dispose();
    super.dispose();
  }

  Future<void> sendMirrorState(MirrorHandState state) async {
    if (commandBusy) return;
    setState(() => commandBusy = true);
    try {
      await widget.ble.sendMirrorState(state);
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo controlar ANTARA: $exception')),
      );
    } finally {
      if (mounted) setState(() => commandBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.level.id == 0 ? '' : 'Nivel ${widget.level.id} · '}${widget.level.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge([engine, widget.ble]),
          builder: (context, _) => SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _StatusChip(
                        icon: Icons.timer_outlined,
                        text: formatDuration(engine.elapsed),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatusChip(
                          icon: Icons.back_hand_outlined,
                          text: widget.ble.isConnected
                              ? widget.ble.mirrorState.label
                              : 'ANTARA sin conectar',
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.level.id == 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Abre la mano para cargar. Ciérrala para liberar el vuelo.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: GamePainter(
                          engine,
                          Character.values.firstWhere(
                            (c) =>
                                c.name ==
                                (widget.repository.profile?.selectedCharacter ??
                                    'condor'),
                            orElse: () => Character.condor,
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Semantics(
                              label:
                                  'Potencia ${(engine.charge * 100).round()} por ciento',
                              child: LinearProgressIndicator(
                                value: engine.charge,
                                minHeight: 16,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        engine.hint,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      if (engine.state == PlayState.failed)
                        FilledButton.icon(
                          onPressed: engine.restart,
                          icon: const Icon(Icons.replay),
                          label: const Text('Reintentar'),
                        )
                      else if (engine.state == PlayState.completed)
                        _CompletionPanel(
                          reward: earnedCoins,
                          onContinue: () => Navigator.pop(context),
                        )
                      else if (widget.ble.isConnected)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final open = FilledButton.tonalIcon(
                              onPressed: commandBusy
                                  ? null
                                  : () => sendMirrorState(
                                        MirrorHandState.open,
                                      ),
                              icon: const Icon(Icons.pan_tool_outlined),
                              label: const Text('Abrir mano'),
                            );
                            final close = FilledButton.tonalIcon(
                              onPressed: commandBusy
                                  ? null
                                  : () => sendMirrorState(
                                        MirrorHandState.closed,
                                      ),
                              icon: const Icon(Icons.front_hand_outlined),
                              label: const Text('Cerrar mano'),
                            );
                            if (constraints.maxWidth < 360) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  open,
                                  const SizedBox(height: 8),
                                  close,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: open),
                                const SizedBox(width: 10),
                                Expanded(child: close),
                              ],
                            );
                          },
                        )
                      else
                        const Text(
                          'Conecta el dispositivo ANTARA desde el menú Bluetooth.',
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({required this.reward, required this.onContinue});

  final int? reward;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration_rounded),
                const SizedBox(width: 8),
                Text(
                  '¡Nivel completado!',
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reward == null
                  ? 'Guardando recompensa…'
                  : '+$reward monedas para tu bandada',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: reward == null ? null : onContinue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continuar viaje'),
              ),
            ),
          ],
        ),
      );
}
